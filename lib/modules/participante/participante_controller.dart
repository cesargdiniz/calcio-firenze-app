import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../domain/usecases/montar_situacao.dart';

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

/// Logado, mas ainda sem pedido de vínculo: tela "Vincular ao elenco".
final class ParticipanteSemVinculo extends ParticipanteStatus {
  final Sessao sessao;
  final DadosTemporada dados;
  const ParticipanteSemVinculo(this.sessao, this.dados);
}

final class ParticipanteAguardando extends ParticipanteStatus {
  final Usuario usuario;
  final Pessoa pessoa;
  final Time time;
  const ParticipanteAguardando(this.usuario, this.pessoa, this.time);
}

final class ParticipanteRecusado extends ParticipanteStatus {
  final Sessao sessao;
  final DadosTemporada dados;
  const ParticipanteRecusado(this.sessao, this.dados);
}

final class ParticipantePronto extends ParticipanteStatus {
  final Usuario usuario;
  final Papel papel;
  final SituacaoPessoa pessoal;
  final SituacaoTime time;
  const ParticipantePronto(this.usuario, this.papel, this.pessoal, this.time);
}

final class ParticipanteFalha extends ParticipanteStatus {
  final String mensagem;
  const ParticipanteFalha(this.mensagem);
}

/// Junta sessão (login), cadastro do usuário e temporada, e decide o que o
/// Participante vê.
class ParticipanteController extends Cubit<ParticipanteStatus> {
  final AuthRepository _auth;
  final UsuarioRepository _usuarios;
  final TemporadaRepository _temporada;
  final MontarSituacao _montar;

  StreamSubscription<void>? _subSessao;
  StreamSubscription<void>? _subUsuario;
  StreamSubscription<void>? _subTemporada;

  Sessao? _sessao;
  bool _sessaoCarregada = false;
  Usuario? _usuario;
  bool _usuarioCarregado = false;
  DadosTemporada? _dados;

  ParticipanteController(this._auth, this._usuarios, this._temporada, this._montar)
    : super(const ParticipanteCarregando());

  void iniciar() {
    _subTemporada = _temporada.observar().listen((d) {
      _dados = d;
      _recalcular();
    }, onError: _falhar);

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
          _recalcular();
        }, onError: _falhar);
      }
      _recalcular();
    }, onError: _falhar);
  }

  void _falhar(Object _) {
    if (!isClosed) emit(const ParticipanteFalha('Não foi possível carregar seus dados.'));
  }

  void _recalcular() {
    if (isClosed) return;
    final dados = _dados;
    final sessao = _sessao;
    if (dados == null || !_sessaoCarregada) return emit(const ParticipanteCarregando());
    if (sessao == null) return emit(const ParticipanteSemLogin());
    if (!_usuarioCarregado) return emit(const ParticipanteCarregando());

    final usuario = _usuario;
    final v = usuario?.vinculo;
    final pessoa = v == null ? null : dados.pessoas.where((p) => p.id == v.pessoaId).firstOrNull;
    if (usuario == null || v == null || pessoa == null || v.temporadaId != dados.id) {
      return emit(ParticipanteSemVinculo(sessao, dados));
    }

    switch (v.status) {
      case StatusVinculo.pendente:
        final time = dados.times.firstWhere((t) => t.id == pessoa.timeId);
        emit(ParticipanteAguardando(usuario, pessoa, time));
      case StatusVinculo.recusado:
        emit(ParticipanteRecusado(sessao, dados));
      case StatusVinculo.aprovado:
        final s = _montar(dados, pessoa.id, verPendenciasDoTime: v.papel.veTime);
        emit(ParticipantePronto(usuario, v.papel, s.pessoal, s.time));
    }
  }

  /// Envia o pedido de vínculo para a Organização aprovar.
  Future<void> pedirVinculo(Papel papel, Pessoa pessoa) async {
    final sessao = _sessao;
    final dados = _dados;
    if (sessao == null || dados == null) return;
    await _usuarios.pedirVinculo(
      Usuario(
        uid: sessao.uid,
        email: sessao.email,
        nome: pessoa.nome,
        vinculo: Vinculo(
          temporadaId: dados.id,
          pessoaId: pessoa.id,
          timeId: pessoa.timeId,
          papel: papel,
        ),
      ),
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
    await _subTemporada?.cancel();
    return super.close();
  }
}
