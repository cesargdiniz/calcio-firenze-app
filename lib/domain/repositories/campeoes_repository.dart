import '../entities/campeoes.dart';
import '../entities/categoria.dart';

/// Campeões de cada categoria, cadastrados pela Organização em Gestão.
abstract interface class CampeoesRepository {
  /// A lista gravada da categoria. Nulo: a Organização ainda não mexeu nela,
  /// e o app mostra a lista que vem no próprio app ([campeoesDe]).
  Stream<List<TituloTemporada>?> observar(Categoria categoria);

  /// Grava a lista inteira da categoria, já ordenada.
  Future<void> salvarTodos(Categoria categoria, List<TituloTemporada> titulos);
}
