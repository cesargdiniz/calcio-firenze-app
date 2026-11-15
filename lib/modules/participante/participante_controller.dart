import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../domain/usecases/montar_situacao.dart';
import '../categoria/categoria_controller.dart';

sealed class ParticipanteStatus {
  const ParticipanteStatus();
}

final class ParticipanteCarregando extends ParticipanteStatus {
  const ParticipanteCarregando();
}

/// Ninguém logado: mostra a tela de login.
final class ParticipanteSemLogin extends ParticipanteStatus {
  const ParticipanteSemLogin();
}

/// Logado, mas sem vínculo nesta categoria: tela "Vincular ao elenco".
/// [comVinculo] lista as outras categorias em que a conta já tem vínculo.
final class ParticipanteSemVinculo extends ParticipanteStatus {
  final Sessao sessao;
  final DadosTemporada dados;
  final List<Categoria> comVinculo;
  const ParticipanteSemVinculo(this.sessao, this.dados, {this.comVinculo = const []});
}

final class ParticipanteAguardando extends ParticipanteStatus {
  final Usuario usuario;
  final Vinculo vinculo;
  final Pessoa pessoa;
  final Time time;
  const ParticipanteAguardando(this.usuario, this.vinculo, this.pessoa, this.time);
}

final class ParticipanteRecusado extends ParticipanteStatus {
  final Sessao sessao;
  final DadosTemporada dados;
  const ParticipanteRecusado(this.sessao, this.dados);
}

/// Situação do participante numa categoria (a escolhida ou outra em que ele
/// também joga).
class SituacaoNaCategoria {
  final Categoria categoria;
  final Papel papel;
  final SituacaoPessoa pessoal;
  final SituacaoTime time;
  const SituacaoNaCategoria(this.categoria, this.papel, this.pessoal, this.time);
}

final class ParticipantePronto extends ParticipanteStatus {
  final Usuario usuario;
  final Papel papel;
  final SituacaoPessoa pessoal;
  final SituacaoTime time;

  /// Outras categorias em que a conta tem vínculo aprovado (para os avisos).
  final List<SituacaoNaCategoria> outras;

  const ParticipantePronto(
    this.usuario,
    this.papel,
    this.pessoal,
    this.time, {
    this.outras = const [],
  });
}

final class ParticipanteFalha extends ParticipanteStatus {
  final String mensagem;
  const ParticipanteFalha(this.mensagem);
}

/// Junta sessão (login), cadastro do usuário e a temporada da categoria
/// escolhida, e decide o que o Participante vê. Também acompanha as outras
/// categorias em que a conta tem vínculo aprovado, para os avisos.
class ParticipanteController extends Cubit<ParticipanteStatus> {
  final AuthRepository _auth;
  final UsuarioRepository _usuarios;
  final TemporadaRepository _temporada;
  final MontarSituacao _montar;
  final CategoriaController _categorias;

  StreamSubscription<void>? _subSessao;
  StreamSubscription<void>? _subUsuario;
  StreamSubscription<void>? _subCategoria;
  StreamSubscription<void>? _subTemporada;
  final Map<String, StreamSubscription<void>> _subsOutras = {};

  Sessao? _sessao;
  bool _sessaoCarregada = false;
  Usuario? _usuario;
  bool _usuarioCarregado = false;
  Categoria? _categoria;
  DadosTemporada? _dados;
  final Map<String, DadosTemporada> _outras = {};

  ParticipanteController(
    this._auth,
    this._usuarios,
    this._temporada,
    this._montar,
    this._categorias,
  ) : super(const ParticipanteCarregando());

  void iniciar() {
    _subCategoria = _categorias.observar().listen((c) {
      _categoria = c;
      _dados = null;
      _subTemporada?.cancel();
      _subTemporada = _temporada.observar(c.temporadaId).listen((d) {
        _dados = d;
        _recalcular();
      }, onError: _falhar);
      _sincronizarOutras();
      _recalcular();
    });

    _subSessao = _auth.observarSessao().listen((s) {
      _sessao = s;
      _sessaoCarregada = true;
      _usuario = null;
      _usuarioCarregado = false;
      _subUsuario?.cancel();
      if (s != null) {
        _subUsuario = _usuarios.observar(s.uid).listen((u) {
          _usuario = u;
          _usuarioCarregado = true;
          _sincronizarOutras();
          _recalcular();
        }, onError: _falhar);
      }
      _sincronizarOutras();
      _recalcular();
    }, onError: _falhar);
  }

  /// Ouve as temporadas das outras categorias com vínculo aprovado.
  void _sincronizarOutras() {
    final querer = {
      for (final v in _usuario?.vinculos ?? const <Vinculo>[])
        if (v.status == StatusVinculo.aprovado && v.temporadaId != _categoria?.temporadaId)
          v.temporadaId,
    };
    for (final id in [..._subsOutras.keys]) {
      if (!querer.contains(id)) {
        _subsOutras.remove(id)!.cancel();
        _outras.remove(id);
      }
    }
    for (final id in querer) {
      _subsOutras[id] ??= _temporada.observar(id).listen(
        (d) {
          _outras[id] = d;
          _recalcular();
        },
        // Sem os dados de outra categoria, só os avisos dela ficam de fora.
        onError: (Object _) {},
      );
    }
  }

  void _falhar(Object _) {
    if (!isClosed) emit(const ParticipanteFalha('Não foi possível carregar seus dados.'));
  }

  /// Situação nas outras categorias já carregadas.
  List<SituacaoNaCategoria> _situacoesOutras(Usuario u) => [
    for (final v in u.vinculos)
      if (v.status == StatusVinculo.aprovado)
        if (_outras[v.temporadaId] case final d?)
          if (d.pessoas.any((p) => p.id == v.pessoaId)) _situacao(d, v),
  ];

  SituacaoNaCategoria _situacao(DadosTemporada d, Vinculo v) {
    final s = _montar(d, v.pessoaId, verPendenciasDoTime: v.papel.veTime);
    return SituacaoNaCategoria(d.categoria, v.papel, s.pessoal, s.time);
  }

  void _recalcular() {
    if (isClosed) return;
    final dados = _dados;
    final sessao = _sessao;
    if (dados == null || !_sessaoCarregada) return emit(const ParticipanteCarregando());
    if (sessao == null) return emit(const ParticipanteSemLogin());
    if (!_usuarioCarregado) return emit(const ParticipanteCarregando());

    final usuario = _usuario;
    final v = usuario?.vinculoEm(dados.id);
    final pessoa = v == null ? null : dados.pessoas.where((p) => p.id == v.pessoaId).firstOrNull;
    if (usuario == null || v == null || pessoa == null) {
      final comVinculo = [
        for (final x in usuario?.vinculos ?? const <Vinculo>[])
          if (x.temporadaId != dados.id && x.status != StatusVinculo.recusado)
            if (Categoria.deTemporada(x.temporadaId) case final c?) c,
      ];
      return emit(ParticipanteSemVinculo(sessao, dados, comVinculo: comVinculo));
    }

    switch (v.status) {
      case StatusVinculo.pendente:
        final time = dados.times.firstWhere((t) => t.id == pessoa.timeId);
        emit(ParticipanteAguardando(usuario, v, pessoa, time));
      case StatusVinculo.recusado:
        emit(ParticipanteRecusado(sessao, dados));
      case StatusVinculo.aprovado:
        final s = _montar(dados, pessoa.id, verPendenciasDoTime: v.papel.veTime);
        emit(
          ParticipantePronto(usuario, v.papel, s.pessoal, s.time, outras: _situacoesOutras(usuario)),
        );
    }
  }

  /// Envia o pedido de vínculo na categoria atual para a Organização dela
  /// aprovar.
  Future<void> pedirVinculo(Papel papel, Pessoa pessoa) async {
    final sessao = _sessao;
    final dados = _dados;
    if (sessao == null || dados == null) return;
    await _usuarios.pedirVinculo(
      Usuario(
        uid: sessao.uid,
        email: sessao.email,
        nome: pessoa.nome,
        vinculos: _usuario?.vinculos ?? const [],
      ),
      Vinculo(temporadaId: dados.id, pessoaId: pessoa.id, timeId: pessoa.timeId, papel: papel),
    );
  }

  Future<void> sair() => _auth.sair();

  /// Apaga o cadastro e a conta (exigência das lojas).
  Future<void> excluirConta() async {
    final uid = _sessao?.uid;
    if (uid == null) return;
    await _usuarios.excluir(uid);
    await _auth.excluirConta();
  }

  @override
  Future<void> close() async {
    await _subSessao?.cancel();
    await _subUsuario?.cancel();
    await _subCategoria?.cancel();
    await _subTemporada?.cancel();
    for (final s in _subsOutras.values) {
      await s.cancel();
    }
    return super.close();
  }
}
