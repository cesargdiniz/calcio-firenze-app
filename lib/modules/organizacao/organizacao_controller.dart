import 'dart:async';
import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/avisos_push.dart';
import '../../domain/usecases/gerar_calendario.dart';
import '../../domain/usecases/movimentacoes.dart';
import '../categoria/categoria_controller.dart';

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

/// Conta da Organização que ainda não informou no perfil a categoria que
/// organiza.
final class OrgSemCategoria extends OrgStatus {
  final Sessao sessao;
  const OrgSemCategoria(this.sessao);
}

final class OrgPronta extends OrgStatus {
  final Sessao sessao;
  final DadosTemporada dados;
  final List<Usuario> pedidos;
  final List<Usuario> aprovados;
  final List<Movimentacao> movimentacoes;

  /// Categorias que esta conta organiza (a de [dados] é uma delas).
  final List<Categoria> categorias;

  const OrgPronta(
    this.sessao,
    this.dados,
    this.pedidos,
    this.aprovados,
    this.movimentacoes, {
    this.categorias = Categoria.values,
  });

  Categoria get categoria => dados.categoria;

  Pessoa? pessoa(String id) => dados.pessoas.where((p) => p.id == id).firstOrNull;
  Time? time(String id) => dados.times.where((t) => t.id == id).firstOrNull;

  /// Vínculo do pedido nesta categoria.
  Vinculo? vinculo(Usuario u) => u.vinculoEm(dados.id);

  /// Outra conta já aprovada para a mesma pessoa do elenco.
  Usuario? conflito(Usuario pedido) => aprovados
      .where((u) => u.uid != pedido.uid && vinculo(u)?.pessoaId == vinculo(pedido)?.pessoaId)
      .firstOrNull;
}

final class OrgFalha extends OrgStatus {
  final String mensagem;

  /// Detalhe técnico (o que falhou), para quem for investigar.
  final String? detalhe;
  const OrgFalha(this.mensagem, {this.detalhe});
}

/// Área da Organização. Cada conta organiza uma ou mais categorias; a área
/// mostra a categoria escolhida no seletor, se a conta a organiza, ou a
/// primeira que ela organiza.
class OrganizacaoController extends Cubit<OrgStatus> {
  final AuthRepository _auth;
  final OrganizacaoRepository _org;
  final GestaoRepository _gestao;
  final TemporadaRepository _temporada;
  final CategoriaController _escolha;

  final List<StreamSubscription<void>> _porConta = [];
  final List<StreamSubscription<void>> _porCategoria = [];
  StreamSubscription<void>? _subSessao;
  StreamSubscription<void>? _subEscolha;

  Sessao? _sessao;
  bool _sessaoCarregada = false;

  /// Primeira falha de leitura da categoria; fica até "Tentar de novo" (antes,
  /// a próxima atualização de outra lista voltava a tela para o carregando).
  String? _falha;
  Timer? _demora;
  AcessoOrganizacao? _acesso;
  Categoria? _categoria;
  DadosTemporada? _dados;
  List<Usuario>? _pedidos;
  List<Usuario>? _aprovados;
  List<Movimentacao>? _movimentacoes;

  OrganizacaoController(this._auth, this._org, this._gestao, this._temporada, this._escolha)
    : super(const OrgCarregando());

  void iniciar() {
    _subEscolha = _escolha.stream.listen((_) => _definirCategoria());
    _subSessao = _auth.observarSessao().listen((s) {
      _sessao = s;
      _sessaoCarregada = true;
      _acesso = null;
      for (final x in _porConta) {
        x.cancel();
      }
      _porConta.clear();
      _pararCategoria();
      _categoria = null;
      if (s != null) {
        _porConta.add(
          _org.acesso(s.uid).listen((a) {
            _acesso = a;
            _definirCategoria();
          }, onError: _falhar),
        );
      }
      _recalcular();
    }, onError: _falhar);
  }

  /// Categoria a mostrar: a do seletor, se esta conta organiza; se não, a
  /// primeira que organiza.
  void _definirCategoria() {
    final permitidas = _acesso?.categorias;
    if (permitidas == null || permitidas.isEmpty) return _recalcular();
    final escolhida = _escolha.atual;
    final c = permitidas.contains(escolhida) ? escolhida! : permitidas.first;
    if (c != _categoria) {
      _categoria = c;
      _ouvirCategoria(c);
    }
    _recalcular();
  }

  void _pararCategoria() {
    for (final x in _porCategoria) {
      x.cancel();
    }
    _porCategoria.clear();
    _dados = null;
    _pedidos = null;
    _aprovados = null;
    _movimentacoes = null;
  }

  void _ouvirCategoria(Categoria c) {
    _pararCategoria();
    final id = c.temporadaId;
    _falha = null;
    _demora?.cancel();
    // Se algo não chegar em 25 s, a tela diz o que falta em vez de girar sem fim.
    _demora = Timer(const Duration(seconds: 25), () {
      if (state is OrgCarregando && _categoria != null) {
        _falha = 'Demorou demais: ${_pendentes().join(', ')}';
        _recalcular();
      }
    });
    _porCategoria.add(
      _temporada.observar(id).listen((d) {
        _dados = d;
        _recalcular();
      }, onError: (Object e) => _falharEm('dados da categoria', e)),
    );
    _porCategoria.add(
      _gestao.observarPedidos(id).listen((l) {
        _pedidos = l;
        _recalcular();
      }, onError: (Object e) => _falharEm('pedidos de vínculo', e)),
    );
    _porCategoria.add(
      _gestao.observarAprovados(id).listen((l) {
        _aprovados = l;
        _recalcular();
      }, onError: (Object e) => _falharEm('vínculos aprovados', e)),
    );
    _porCategoria.add(
      _gestao.observarMovimentacoes(id).listen(
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

  /// Troca a categoria da área (e do seletor do app inteiro).
  Future<void> escolherCategoria(Categoria c) => _escolha.escolher(c);

  /// Primeira vez na área: o organizador informa a categoria que organiza.
  Future<void> definirMinhaCategoria(Categoria c) async {
    final s = _sessao;
    if (s == null) return;
    await _org.definirCategoria(s.uid, c);
    await _escolha.escolher(c);
  }

  void _falhar(Object e) => _falharEm('acesso da Organização', e);

  void _falharEm(String parte, Object e) {
    _falha ??= '$parte: ${_resumo(e)}';
    _recalcular();
  }

  static String _resumo(Object e) {
    final texto = e.toString();
    return texto.length > 160 ? '${texto.substring(0, 160)}…' : texto;
  }

  /// O que ainda não chegou do Firestore.
  List<String> _pendentes() => [
    if (_dados == null) 'dados da categoria',
    if (_pedidos == null) 'pedidos de vínculo',
    if (_aprovados == null) 'vínculos aprovados',
    if (_movimentacoes == null) 'movimentações',
  ];

  /// Recomeça as leituras da categoria (botão "Tentar de novo").
  void tentarDeNovo() {
    final c = _categoria;
    _falha = null;
    if (c == null) return _recalcular();
    _ouvirCategoria(c);
    _recalcular();
  }

  void _recalcular() {
    if (isClosed) return;
    final sessao = _sessao;
    if (!_sessaoCarregada) return emit(const OrgCarregando());
    if (sessao == null) return emit(const OrgSemLogin());
    final acesso = _acesso;
    if (acesso == null) return emit(const OrgCarregando());
    if (!acesso.ehOrganizacao) return emit(OrgSemAcesso(sessao));
    final categorias = acesso.categorias;
    if (categorias.isEmpty) return emit(OrgSemCategoria(sessao));
    final falha = _falha;
    if (falha != null) {
      return emit(OrgFalha('Não foi possível carregar os dados da Organização.', detalhe: falha));
    }
    final dados = _dados;
    final movimentacoes = _movimentacoes;
    if (dados == null || _pedidos == null || _aprovados == null || movimentacoes == null) {
      return emit(const OrgCarregando());
    }
    _demora?.cancel();
    emit(
      OrgPronta(sessao, dados, _pedidos!, _aprovados!, movimentacoes, categorias: categorias),
    );
  }

  Future<void> aprovar(String uid) =>
      _gestao.decidirPedido(_dados!.id, uid, StatusVinculo.aprovado);
  Future<void> recusar(String uid) =>
      _gestao.decidirPedido(_dados!.id, uid, StatusVinculo.recusado);

  Future<void> salvarTime(Time t) => _gestao.salvarTimes(_dados!.id, [t]);

  Future<void> importarElencos(Map<String, List<Pessoa>> porTime) =>
      _gestao.importarElencos(_dados!.id, porTime);

  /// Sorteia os confrontos e grava as rodadas do turno nas datas do
  /// calendário da categoria. Substitui jogos do turno que ainda não tenham súmula.
  Future<void> gerarTurno(int turno) async {
    final d = _dados!;
    // Na demonstração, os jogos de exemplo não contam (saem ao gerar).
    final antigos = d.demonstracao
        ? const <Partida>[]
        : d.partidas.where((p) => p.turno == turno && p.fase == Fase.classificatoria);
    if (antigos.any((p) => p.encerrada)) {
      throw StateError('O turno já tem súmulas encerradas.');
    }
    final esperados = d.categoria.times;
    if (d.times.length != esperados) {
      throw StateError(
        'A categoria ${d.categoria.nome} tem $esperados times e há ${d.times.length} '
        'cadastrados. Ajuste em Gestão › Times da temporada.',
      );
    }
    final novos = const GerarCalendario()(
      turno: turno,
      times: [for (final t in d.times) t.id],
      horarios: horariosDe(d.categoria)[turno]!,
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

  /// Salva a partida e, ao encerrar a súmula, pede as notificações de
  /// resultado e de suspensão (nunca na temporada de exemplo).
  Future<void> salvarPartida(Partida p) async {
    final antes = _dados!;
    await _gestao.salvarPartidas(antes.id, [p]);
    if (antes.demonstracao) return;
    try {
      final avisos = avisosDoEncerramento(antes: antes, partida: p, agora: DateTime.now());
      if (avisos.isNotEmpty) await _gestao.enviarAvisos(antes.id, avisos);
    } catch (e) {
      // A súmula já está salva; sem aviso, o resultado continua no app.
      debugPrint('Avisos do encerramento: $e');
    }
  }

  /// Resultado do sorteio do art. 42 (feito fora do app) para um grupo de
  /// times empatados em todos os critérios: [ordem] é a ordem sorteada, do
  /// mais bem colocado ao pior. [turno] 0 é a classificação geral.
  Future<void> registrarSorteio(int turno, List<String> ordem) {
    final d = _dados!;
    return _gestao.salvarSorteio(d.id, turno, registrarSorteioNaOrdem(d.ordemSorteio(turno), ordem));
  }

  /// Grava os jogos de uma etapa do mata-mata (quartas, semifinais, final).
  Future<void> criarEtapa(List<Partida> jogos) => _gestao.salvarPartidas(_dados!.id, jogos);

  /// Apaga os jogos de uma etapa do mata-mata que ainda não tem súmula.
  Future<void> desfazerEtapa(List<String> ids) => _gestao.excluirPartidas(_dados!.id, ids);

  Future<void> registrarPagamento(String pendenciaId) =>
      _gestao.registrarPagamento(_dados!.id, pendenciaId, DateTime.now());

  Future<void> desfazerPagamento(String pendenciaId) =>
      _gestao.desfazerPagamento(_dados!.id, pendenciaId);

  Future<void> salvarDecisao(DecisaoDisciplinar d) => _gestao.salvarDecisao(_dados!.id, d);

  Future<void> excluirDecisao(String id) => _gestao.excluirDecisao(_dados!.id, id);

  Future<void> salvarParametros(Parametros p) => _gestao.salvarParametros(_dados!.id, p);

  Future<void> salvarPatrocinador(String? nome) => _gestao.salvarPatrocinador(_dados!.id, nome);

  /// Datas do Draft-1 e do Draft-2 da categoria (chave 1 e 2).
  Future<void> salvarDrafts(Map<int, DateTime> drafts) => _gestao.salvarDrafts(_dados!.id, drafts);

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
    _demora?.cancel();
    await _subSessao?.cancel();
    await _subEscolha?.cancel();
    for (final x in [..._porConta, ..._porCategoria]) {
      await x.cancel();
    }
    return super.close();
  }
}
