import '../entities/usuario.dart';

abstract interface class UsuarioRepository {
  /// Cadastro do usuário, ou nulo se ainda não pediu vínculo.
  Stream<Usuario?> observar(String uid);

  /// Cria ou refaz o pedido de vínculo (sempre como pendente).
  Future<void> pedirVinculo(Usuario usuario);

  Future<void> excluir(String uid);
}
