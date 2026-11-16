import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/preferencias_repository.dart';

/// Preferências no armazenamento do aparelho (shared_preferences).
class PreferenciasDoAparelho implements PreferenciasRepository {
  static const _chave = 'categoria';

  const PreferenciasDoAparelho();

  @override
  Future<String?> categoria() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_chave);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> salvarCategoria(String temporadaId) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_chave, temporadaId);
    } catch (_) {
      // Sem armazenamento, a escolha vale só até fechar o app.
    }
  }
}
