import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  /// O link de acesso precisa do e-mail de novo ao voltar; guardamos no aparelho.
  static const _chaveEmail = 'calcio.emailDoLink';

  FirebaseAuthRepository(this._auth);

  @override
  Stream<Sessao?> observarSessao() => _auth.authStateChanges().map(
    (u) => u == null ? null : Sessao(uid: u.uid, email: u.email ?? '', nome: u.displayName),
  );

  Future<T> _tentar<T>(Future<T> Function() acao) async {
    try {
      return await acao();
    } on FirebaseAuthException catch (e) {
      throw FalhaLogin(_mensagem(e.code));
    }
  }

  @override
  Future<void> entrarComGoogle() => _tentar(() async {
    final provedor = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      await _auth.signInWithPopup(provedor);
    } else {
      await _auth.signInWithProvider(provedor);
    }
  });

  @override
  Future<void> entrarComApple() => _tentar(() async {
    final provedor = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    if (kIsWeb) {
      await _auth.signInWithPopup(provedor);
    } else {
      await _auth.signInWithProvider(provedor);
    }
  });

  // No celular, o link ainda não volta para o app.
  @override
  bool get aceitaLinkPorEmail => kIsWeb;

  @override
  Future<void> enviarLinkPorEmail(String email) => _tentar(() async {
    if (!kIsWeb) {
      throw const FalhaLogin('O link por e-mail chega ao celular na próxima versão.');
    }
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(url: '${Uri.base.origin}/', handleCodeInApp: true),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveEmail, email);
  });

  @override
  Future<bool> concluirLinkSeHouver(String link) => _tentar(() async {
    if (!_auth.isSignInWithEmailLink(link)) return false;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_chaveEmail);
    if (email == null) {
      throw const FalhaLogin(
        'Abra o link no mesmo aparelho e navegador em que você pediu o acesso.',
      );
    }
    await _auth.signInWithEmailLink(email: email, emailLink: link);
    await prefs.remove(_chaveEmail);
    return true;
  });

  @override
  Future<void> entrarComSenha(String email, String senha) =>
      _tentar(() => _auth.signInWithEmailAndPassword(email: email, password: senha));

  @override
  Future<void> criarContaComSenha(String email, String senha) =>
      _tentar(() => _auth.createUserWithEmailAndPassword(email: email, password: senha));

  @override
  Future<void> redefinirSenha(String email) =>
      _tentar(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> sair() => _auth.signOut();

  @override
  Future<void> excluirConta() => _tentar(() async {
    await _auth.currentUser?.delete();
  });

  static String _mensagem(String codigo) => switch (codigo) {
    'invalid-email' => 'Esse e-mail não parece válido.',
    'user-disabled' => 'Esta conta foi desativada. Fale com a Organização.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' => 'E-mail ou senha incorretos.',
    'email-already-in-use' => 'Já existe uma conta com esse e-mail. Tente entrar.',
    'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' ||
    'canceled' ||
    'web-context-canceled' => 'Login cancelado.',
    'popup-blocked' => 'O navegador bloqueou a janela do Google. Permita pop-ups e tente de novo.',
    'invalid-action-code' ||
    'expired-action-code' => 'Esse link já foi usado ou expirou. Peça um novo.',
    'requires-recent-login' => 'Por segurança, saia e entre de novo antes de excluir a conta.',
    'network-request-failed' => 'Sem conexão. Verifique a internet e tente de novo.',
    'too-many-requests' => 'Muitas tentativas. Aguarde alguns minutos.',
    _ => 'Não foi possível entrar ($codigo).',
  };
}
