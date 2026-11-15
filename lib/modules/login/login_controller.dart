import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

sealed class LoginStatus {
  const LoginStatus();
}

final class LoginOcioso extends LoginStatus {
  const LoginOcioso();
}

final class LoginEnviando extends LoginStatus {
  const LoginEnviando();
}

final class LoginLinkEnviado extends LoginStatus {
  final String email;
  const LoginLinkEnviado(this.email);
}

final class LoginSenhaRedefinida extends LoginStatus {
  final String email;
  const LoginSenhaRedefinida(this.email);
}

final class LoginErro extends LoginStatus {
  final String mensagem;
  const LoginErro(this.mensagem);
}

/// Validação simples de e-mail para o formulário.
bool emailValido(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

/// Telas 03 e 03b. Quando o login dá certo, a sessão muda e o
/// ParticipanteController troca de tela sozinho.
class LoginController extends Cubit<LoginStatus> {
  final AuthRepository _auth;
  LoginController(this._auth) : super(const LoginOcioso());

  Future<void> _executar(Future<LoginStatus?> Function() acao) async {
    emit(const LoginEnviando());
    try {
      final depois = await acao();
      if (!isClosed) emit(depois ?? const LoginOcioso());
    } on FalhaLogin catch (e) {
      if (!isClosed) emit(LoginErro(e.mensagem));
    } catch (_) {
      if (!isClosed) emit(const LoginErro('Algo deu errado. Tente de novo.'));
    }
  }

  Future<void> entrarComGoogle() => _executar(() async {
    await _auth.entrarComGoogle();
    return null;
  });

  Future<void> entrarComApple() => _executar(() async {
    await _auth.entrarComApple();
    return null;
  });

  Future<void> enviarLink(String email) => _executar(() async {
    final e = email.trim();
    if (!emailValido(e)) return const LoginErro('Digite um e-mail válido.');
    await _auth.enviarLinkPorEmail(e);
    return LoginLinkEnviado(e);
  });

  Future<void> entrarComSenha(String email, String senha) => _executar(() async {
    if (!emailValido(email)) return const LoginErro('Digite um e-mail válido.');
    await _auth.entrarComSenha(email.trim(), senha);
    return null;
  });

  Future<void> criarConta(String email, String senha) => _executar(() async {
    if (!emailValido(email)) return const LoginErro('Digite um e-mail válido.');
    if (senha.length < 6) return const LoginErro('A senha precisa ter pelo menos 6 caracteres.');
    await _auth.criarContaComSenha(email.trim(), senha);
    return null;
  });

  Future<void> redefinirSenha(String email) => _executar(() async {
    if (!emailValido(email)) return const LoginErro('Digite o seu e-mail primeiro.');
    await _auth.redefinirSenha(email.trim());
    return LoginSenhaRedefinida(email.trim());
  });

  void voltar() => emit(const LoginOcioso());
}
