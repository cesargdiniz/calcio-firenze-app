import '../entities/usuario.dart';

/// Erro de login com mensagem pronta para mostrar ao usuário.
class FalhaLogin implements Exception {
  final String mensagem;
  const FalhaLogin(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Login do Participante e da Organização. Três formas (especificação):
/// Google, link por e-mail e, como alternativa, e-mail e senha.
/// O login com Apple entra junto com o app de iPhone.
abstract interface class AuthRepository {
  /// Emite a sessão atual e cada mudança (login, saída).
  Stream<Sessao?> observarSessao();

  Future<void> entrarComGoogle();

  /// Envia o link de acesso para o e-mail.
  Future<void> enviarLinkPorEmail(String email);

  /// Se [link] for um link de acesso enviado por e-mail, conclui o login e
  /// devolve verdadeiro.
  Future<bool> concluirLinkSeHouver(String link);

  Future<void> entrarComSenha(String email, String senha);
  Future<void> criarContaComSenha(String email, String senha);
  Future<void> redefinirSenha(String email);

  Future<void> sair();
  Future<void> excluirConta();
}
