import 'dart:async';
import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/gerar_calendario.dart';
import '../../domain/usecases/movimentacoes.dart';

sealed class OrgStatus {
  const OrgStatus();
}

final class OrgCarregando extends OrgStatus {
  const OrgCarregando();
}

final class OrgSemLogin extends OrgStatus {
  const OrgSemLogin();
}

/// Logado, mas a conta não está em `organizacao/{uid}`.
final class OrgSemAcesso extends OrgStatus {
  final Sessao sessao;
  const OrgSemAcesso(this.sessao);
}

final class OrgPronta extends OrgStatus {
  final Sessao sessao;
  final DadosTemporada dados;
  final List<Usuario> pedidos;
  final List<Usuario> aprovados;
  final List<Movimentacao> movimentacoes;

  const OrgPronta(this.sessao, this.dados, this.pedidos, this.aprovados, this.movimentacoes);

  Pessoa? pessoa(String id) => dados.pessoas.where((p) => p.id == id).firstOrNull;
  Time? time(String id) => dados.times.where((t) => t.id == id).firstOrNull;

  /// Outra conta já aprovada para a mesma pessoa do elenco.
  Usuario? conflito(Usuario pedido) => aprovados
      .where((u) => u.uid != pedido.uid && u.vinculo?.pessoaId == pedido.vinculo?.pessoaId)
      .firstOrNull;
}

final class OrgFalha extends OrgStatus {
  final String mensagem;
  const OrgFalha(this.mensagem);
}

class OrganizacaoController extends Cubit<OrgStatus> {
  final AuthRepository _auth;
  final OrganizacaoRepository _org;
  final GestaoRepository _gestao;
  final TemporadaRepository _temporada;

  final List<StreamSubscription<void>> _porConta = [];
  StreamSubscription<void>? _subSessao;
  StreamSubscription<void>? _subTemporada;

  Sessao? _sessao;
  bool _sessaoCarregada = false;
  bool? _ehOrg;
  DadosTemporada? _dados;
  List<Usuario>? _pedidos;
  List<Usuario>? _aprovados;
  List<Movimentacao>? _movimentacoes;

  OrganizacaoController(this._auth, this._org, this._gestao, this._temporada)
    : super(const OrgCarregando());

  void iniciar() {
    _subTemporada = _temporada.observar().listen((d) {
      _dados = d;
      _recalcular();
    }, onError: _falhar);
    _subSessao = _auth.observarSessao().listen((s) {
      _sessao = s;
      _sessaoCarregada = true;
      _ehOrg = null;
      _pedidos = null;
      _aprovados = null;
      _movimentacoes = null;
      for (final x in _porConta) {
        x.cancel();
      }
      _porConta.clear();
      if (s != null) {
        _porConta.add(
          _org.ehOrganizacao(s.uid).listen((v) {
            final antes = _ehOrg;
            _ehOrg = v;
            if (v && antes != true) _ouvirGestao();
            _recalcular();
          }, onError: _falhar),
        );
      }
      _recalcular();
    }, onError: _falhar);
  }

  void _ouvirGestao() {
    _porConta.add(
      _gestao.observarPedidos().listen((l) {
        _pedidos = l;
        _recalcular();
      }, onError: _falhar),
    );
    _porConta.add(
      _gestao.observarAprovados().listen((l) {
        _aprovados = l;
        _recalcular();
      }, onError: _falhar),
    );
    _porConta.add(
      _gestao.observarMovimentacoes().listen(
        (l) {
          _movimentacoes = l;
          _recalcular();
        },
        // Sem a lista de movimentações, o resto da área continua funcionando.
        onError: (Object _) {
          _movimentacoes = const [];
          _recalcular();
        },
      ),
    );
  }

  void _falhar(Object _) {
    if (!isClosed) emit(const OrgFalha('Não foi possível carregar os dados da Organização.'));
  }

  void _recalcular() {
    if (isClosed) return;
    final sessao = _sessao;
    if (!_sessaoCarregada) return emit(const OrgCarregando());
    if (sessao == null) return emit(const OrgSemLogin());
    if (_ehOrg == null) return emit(const OrgCarregando());
    if (_ehOrg == false) return emit(OrgSemAcesso(sessao));
    final dados = _dados;
    final movimentacoes = _movimentacoes;
    if (dados == null || _pedidos == null || _aprovados == null || movimentacoes == null) {
      return emit(const OrgCarregando());
    }
    emit(OrgPronta(sessao, dados, _pedidos!, _aprovados!, movimentacoes));
  }

  Future<void> aprovar(String uid) => _gestao.decidirPedido(uid, StatusVinculo.aprovado);
  Future<void> recusar(String uid) => _gestao.decidirPedido(uid, StatusVinculo.recusado);

  Future<void> salvarTime(Time t) => _gestao.salvarTimes(_dados!.id, [t]);

  Future<void> importarElencos(Map<String, List<Pessoa>> porTime) =>
      _gestao.importarElencos(_dados!.id, porTime);

  /// Sorteia os confrontos e grava as 9 rodadas do turno nas datas do
  /// regulamento. Substitui jogos do turno que ainda não tenham súmula.
  Future<void> gerarTurno(int turno) async {
    final d = _dados!;
    // Na demonstração, os jogos de exemplo não contam (saem ao gerar).
    final antigos = d.demonstracao
        ? const <Partida>[]
        : d.partidas.where((p) => p.turno == turno && p.fase == Fase.classificatoria);
    if (antigos.any((p) => p.encerrada)) {
      throw StateError('O turno já tem súmulas encerradas.');
    }
    final novos = const GerarCalendario()(
      turno: turno,
      times: [for (final t in d.times) t.id],
      horarios: horariosMaster2027[turno]!,
      sorteio: Random(),
    );
    final ids = {for (final p in novos) p.id};
    final remover = [
      for (final p in antigos)
        if (!ids.contains(p.id)) p.id,
    ];
    if (remover.isNotEmpty) await _gestao.excluirPartidas(d.id, remover);
    await _gestao.salvarPartidas(d.id, novos);
  }

  Future<void> salvarPartida(Partida p) => _gestao.salvarPartidas(_dados!.id, [p]);

  Future<void> registrarPagamento(String pendenciaId) =>
      _gestao.registrarPagamento(_dados!.id, pendenciaId, DateTime.now());

  Future<void> desfazerPagamento(String pendenciaId) =>
      _gestao.desfazerPagamento(_dados!.id, pendenciaId);

  Future<void> salvarDecisao(DecisaoDisciplinar d) => _gestao.salvarDecisao(_dados!.id, d);

  Future<void> excluirDecisao(String id) => _gestao.excluirDecisao(_dados!.id, id);

  Future<void> salvarParametros(Parametros p) => _gestao.salvarParametros(_dados!.id, p);

  Future<void> registrarMovimentacao(Movimentacao m, {Pessoa? substituto}) =>
      _gestao.registrarMovimentacao(_dados!.id, m, substituto: substituto);

  /// Desfaz a saída. Na troca de goleiro, só enquanto o substituto não
  /// aparecer em súmula nem em decisão.
  Future<void> desfazerMovimentacao(Movimentacao m) async {
    final d = _dados!;
    final substituto = m.substitutoId;
    if (substituto != null && citadoNaTemporada(d, substituto)) {
      throw const MovimentacaoEmUso();
    }
    await _gestao.desfazerMovimentacao(d.id, m);
  }

  Future<void> sair() => _auth.sair();

  @override
  Future<void> close() async {
    await _subSessao?.cancel();
    await _subTemporada?.cancel();
    for (final x in _porConta) {
      await x.cancel();
    }
    return super.close();
  }
}
