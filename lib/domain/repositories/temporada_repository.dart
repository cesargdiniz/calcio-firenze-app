import '../entities/temporada.dart';
import '../usecases/calendario_geral.dart';

/// Fonte dos dados de cada temporada (uma por categoria).
abstract interface class TemporadaRepository {
  /// Emite de novo sempre que algo muda (súmula encerrada, pagamento...).
  Stream<DadosTemporada> observar(String temporadaId);

  /// Só times e jogos (calendário geral): bem menos leituras que [observar].
  /// Sem os dados de exemplo.
  Stream<DadosCalendario> observarCalendario(String temporadaId);
}
