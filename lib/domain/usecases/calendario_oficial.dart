import 'package:calcio_regras/calcio_regras.dart';

import '../entities/categoria.dart';
import 'gerar_calendario.dart';

/// Leva os jogos já criados de uma categoria de volta aos horários oficiais
/// (os do código, sem as mudanças feitas na Gestão). Devolve só os que
/// mudam: id → novo início. Jogos com súmula encerrada ficam onde estão.
///
/// Cada rodada volta para os horários oficiais dela, na ordem em que os jogos
/// estão hoje; cada etapa do mata-mata, para o dia oficial da etapa.
Map<String, DateTime> voltarAoOficial(Categoria c, List<Partida> partidas) {
  final oficiais = horariosOficiaisDe(c);
  final porRodada = c.times ~/ 2;
  final classificatorios = c.rodadas * porRodada;
  final mudancas = <String, DateTime>{};

  void encaixar(Iterable<Partida> jogos, List<DateTime> horarios) {
    final lista = jogos.where((p) => !p.encerrada).toList()
      ..sort((a, b) {
        final porData = a.inicio.compareTo(b.inicio);
        return porData != 0 ? porData : a.id.compareTo(b.id);
      });
    final ordenados = [...horarios]..sort();
    for (final (i, p) in lista.indexed) {
      if (i >= ordenados.length) break;
      if (p.inicio != ordenados[i]) mudancas[p.id] = ordenados[i];
    }
  }

  for (final turno in [1, 2]) {
    final slots = oficiais[turno] ?? const <DateTime>[];
    final doTurno = partidas.where((p) => p.turno == turno);
    for (var r = 1; r <= c.rodadas; r++) {
      final inicio = (r - 1) * porRodada;
      if (inicio >= slots.length) break;
      encaixar(
        doTurno.where((p) => p.fase == Fase.classificatoria && p.rodada == r),
        slots.sublist(inicio, (inicio + porRodada).clamp(0, slots.length)),
      );
    }
    // Mata-mata: um dia oficial por etapa, na ordem do calendário.
    final dias = <DateTime, List<DateTime>>{};
    for (final h in slots.skip(classificatorios)) {
      (dias[DateTime(h.year, h.month, h.day)] ??= []).add(h);
    }
    final fases = [if (c.temQuartas) Fase.quartas, Fase.semifinal, Fase.finalTurno];
    for (final (i, horarios) in dias.values.indexed) {
      if (i >= fases.length) break;
      encaixar(doTurno.where((p) => p.fase == fases[i]), horarios);
    }
  }
  encaixar(partidas.where((p) => p.fase == Fase.grandeFinal), oficiais[0] ?? const []);
  return mudancas;
}
