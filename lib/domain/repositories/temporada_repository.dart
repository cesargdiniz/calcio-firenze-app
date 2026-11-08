import '../entities/temporada.dart';

/// Fonte dos dados da temporada. Hoje há a versão de exemplo
/// (`TemporadaExemploRepository`); a versão Firebase entra no lugar dela.
abstract interface class TemporadaRepository {
  /// Emite de novo sempre que algo muda (súmula encerrada, pagamento...).
  Stream<DadosTemporada> observar();
}
