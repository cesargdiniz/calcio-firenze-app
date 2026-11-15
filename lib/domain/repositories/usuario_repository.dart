import '../entities/usuario.dart';

abstract interface class UsuarioRepository {
  /// Cadastro do usuário com os vínculos de todas as categorias, ou nulo se
  /// ainda não pediu nenhum vínculo.
  Stream<Usuario?> observar(String uid);

  /// Cria ou refaz o pedido de vínculo numa categoria (sempre pendente).
  Future<void> pedirVinculo(Usuario usuario, Vinculo vinculo);

  /// Apaga o cadastro e os vínculos de todas as categorias.
  Future<void> excluir(String uid);
}
