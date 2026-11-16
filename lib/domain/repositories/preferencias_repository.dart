/// Escolhas guardadas no aparelho.
abstract interface class PreferenciasRepository {
  /// Temporada (categoria) que o usuário escolheu ver; nula na primeira vez.
  Future<String?> categoria();

  Future<void> salvarCategoria(String temporadaId);

  /// Rota do último perfil escolhido ('/torcedor', '/participante' ou
  /// '/organizacao'); nula na primeira vez.
  Future<String?> perfil();

  Future<void> salvarPerfil(String rota);
}
