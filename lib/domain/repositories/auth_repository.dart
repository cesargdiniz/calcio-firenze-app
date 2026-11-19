import '../entities/usuario.dart';

/// Erro de login com mensagem pronta para mostrar ao usuário.
class FalhaLogin implements Exception {
  final String mensagem;
  const FalhaLogin(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Login do Participante e da Organização: Google, link por e-mail e, como
/// alternativa, e-mail e senha. No iPhone há também o login com Apple, que a
/// App Store exige de apps que oferecem login com Google.
abstract interface class AuthRepository {
  /// Emite a sessão atual e cada mudança (login, saída).
  Stream<Sessao?> observarSessao();

  Future<void> entrarComGoogle();

  /// Só é oferecido no iPhone.
  Future<void> entrarComApple();

  /// Envia o link de acesso para o e-mail.
  Future<void> enviarLinkPorEmail(String email);

  /// Se o login por link no e-mail funciona nesta plataforma.
  bool get aceitaLinkPorEmail;

  /// Se [link] for um link de acesso enviado por e-mail, conclui o login e
  /// devolve verdadeiro.
  Future<bool> concluirLinkSeHouver(String link);

  Future<void> entrarComSenha(String email, String senha);
  Future<void> criarContaComSenha(String email, String senha);
  Future<void> redefinirSenha(String email);

  Future<void> sair();
  Future<void> excluirConta();
}
