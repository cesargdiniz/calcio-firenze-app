import '../entities/temporada.dart';

/// Fonte dos dados de cada temporada (uma por categoria).
abstract interface class TemporadaRepository {
  /// Emite de novo sempre que algo muda (súmula encerrada, pagamento...).
  Stream<DadosTemporada> observar(String temporadaId);
}
