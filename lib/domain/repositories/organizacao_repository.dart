import '../entities/temporada.dart';
import '../entities/usuario.dart';

/// Quem é da Organização (documento `organizacao/{uid}`).
abstract interface class OrganizacaoRepository {
  Stream<bool> ehOrganizacao(String uid);
}

/// Gravações da Organização na temporada.
abstract interface class GestaoRepository {
  /// Pedidos de vínculo aguardando decisão.
  Stream<List<Usuario>> observarPedidos();

  /// Contas já aprovadas (para avisar de nome vinculado a duas contas).
  Stream<List<Usuario>> observarAprovados();

  Future<void> decidirPedido(String uid, StatusVinculo status);

  /// Cria ou atualiza os times da temporada.
  Future<void> salvarTimes(String temporadaId, List<Time> times);

  /// Substitui o elenco de cada time informado.
  Future<void> importarElencos(String temporadaId, Map<String, List<Pessoa>> porTime);
}
