/// Mudanças de dia no calendário, feitas por uma superconta na Gestão.
abstract interface class CalendarioRepository {
  /// Datas oficiais que mudaram de dia: horário oficial → novo horário.
  Stream<Map<DateTime, DateTime>> observarAjustes();

  /// Grava todas as mudanças de datas oficiais (substitui as anteriores).
  Future<void> salvarAjustes(Map<DateTime, DateTime> ajustes);

  /// Muda o horário de jogos já sorteados de uma temporada (id → início).
  Future<void> moverPartidas(String temporadaId, Map<String, DateTime> inicios);
}
