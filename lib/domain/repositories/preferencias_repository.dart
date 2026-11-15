/// Escolhas guardadas no aparelho.
abstract interface class PreferenciasRepository {
  /// Temporada (categoria) que o usuário escolheu ver; nula na primeira vez.
  Future<String?> categoria();

  Future<void> salvarCategoria(String temporadaId);
}
