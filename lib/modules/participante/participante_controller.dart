import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/organizacao_repository.dart';
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
  final String? detalhe;
  const ParticipanteFalha(this.mensagem, {this.detalhe});
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
  final GestaoRepository _gestao;

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

  /// Primeira falha de leitura; fica na tela até "Tentar de novo".
  String? _falha;

  ParticipanteController(
    this._auth,
    this._usuarios,
    this._temporada,
    this._montar,
    this._categorias,
    this._gestao,
  ) : super(const ParticipanteCarregando());

  void iniciar() {
    _subCategoria = _categorias.observar().listen((c) {
      _categoria = c;
      _dados = null;
      _subTemporada?.cancel();
      _ouvirTemporada(c);
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

  void _ouvirTemporada(Categoria c) {
    _subTemporada?.cancel();
    _subTemporada = _temporada.observar(c.temporadaId).listen((d) {
      _dados = d;
      _recalcular();
    }, onError: _falhar);
  }

  void _falhar(Object e) {
    final texto = e.toString();
    _falha ??= texto.length > 160 ? '${texto.substring(0, 160)}…' : texto;
    _recalcular();
  }

  /// Recomeça a leitura da categoria e do cadastro (botão "Tentar de novo").
  void tentarDeNovo() {
    _falha = null;
    final c = _categoria;
    if (c != null) {
      _dados = null;
      _ouvirTemporada(c);
    }
    final s = _sessao;
    if (s != null) {
      _subUsuario?.cancel();
      _usuarioCarregado = false;
      _subUsuario = _usuarios.observar(s.uid).listen((u) {
        _usuario = u;
        _usuarioCarregado = true;
        _sincronizarOutras();
        _recalcular();
      }, onError: _falhar);
    }
    _recalcular();
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
    if (_falha case final falha?) {
      return emit(ParticipanteFalha('Não foi possível carregar seus dados.', detalhe: falha));
    }
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
            ?Categoria.deTemporada(x.temporadaId),
      ];
      return emit(ParticipanteSemVinculo(sessao, dados, comVinculo: comVinculo));
    }

    switch (v.status) {
      case StatusVinculo.pendente:
        final time =
            dados.times.where((t) => t.id == pessoa.timeId).firstOrNull ??
            Time(id: pessoa.timeId, nome: pessoa.timeId, sigla: pessoa.timeId, cor: 0xFF6E6E6E);
        emit(ParticipanteAguardando(usuario, v, pessoa, time));
      case StatusVinculo.recusado:
        emit(ParticipanteRecusado(sessao, dados));
      case StatusVinculo.aprovado:
        final ({SituacaoPessoa pessoal, SituacaoTime time}) s;
        try {
          s = _montar(dados, pessoa.id, verPendenciasDoTime: v.papel.veTime);
        } catch (e) {
          return _falhar(e);
        }
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

  /// O dirigente troca o escudo do próprio time (ou tira, com nulo). As
  /// regras do Firestore só deixam mudar o escudo, e só do time dele.
  Future<void> trocarEscudo(Uint8List? png) async {
    final s = state;
    final dados = _dados;
    if (s is! ParticipantePronto || s.papel != Papel.dirigente || dados == null) return;
    final t = s.time.time;
    await _gestao.salvarTimes(dados.id, [
      Time(id: t.id, nome: t.nome, sigla: t.sigla, cor: t.cor, escudo: png),
    ]);
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
