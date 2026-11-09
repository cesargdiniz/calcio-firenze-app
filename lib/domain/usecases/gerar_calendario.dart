import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';

/// Datas do Master no calendário anual do regulamento (última página).
/// As noites de cada semana formam uma rodada; as semanas depois da 9ª
/// ficam para o mata-mata.
final datasMaster2027 = <int, List<DateTime>>{
  1: [
    for (final (m, d) in const [
      (1, 29), (1, 30), (2, 2), (2, 4), (2, 5), (2, 16), (2, 18), (2, 19), //
      (3, 2), (3, 4), (3, 5), (3, 16), (3, 18), (3, 19), (3, 30), (4, 1), (4, 2),
      (4, 13), (4, 15), (4, 16), (4, 27), (4, 29), (4, 30), (5, 11), (5, 13), (5, 14),
      (5, 27), (6, 10), (6, 20),
    ])
      DateTime(2027, m, d),
  ],
  2: [
    for (final (m, d) in const [
      (8, 5), (8, 6), (8, 17), (8, 19), (8, 20), (8, 31), (9, 2), (9, 3), //
      (9, 16), (9, 17), (9, 28), (9, 30), (10, 1), (10, 13), (10, 14), (10, 15),
      (10, 26), (10, 28), (10, 29), (11, 9), (11, 11), (11, 12), (11, 23), (11, 30),
      (12, 7), (12, 11), (12, 18),
    ])
      DateTime(2027, m, d),
  ],
};

/// Agrupa as datas por semana (segunda a domingo), na ordem.
List<List<DateTime>> semanas(List<DateTime> datas) {
  final grupos = <DateTime, List<DateTime>>{};
  for (final d in [...datas]..sort()) {
    final segunda = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    grupos.putIfAbsent(segunda, () => []).add(d);
  }
  return grupos.values.toList();
}

/// Sorteia a tabela da fase classificatória de um turno (todos contra todos,
/// art. 16) e distribui os jogos nas semanas do Master: uma rodada por semana,
/// os jogos repartidos entre as noites, dois por noite por padrão.
class GerarCalendario {
  /// Horários de uma noite, em minutos desde a meia-noite (19h30 e 20h45).
  final List<int> horarios;

  /// Intervalo entre jogos quando uma noite precisa de mais horários.
  final int intervalo;
  final String local;

  const GerarCalendario({
    this.horarios = const [19 * 60 + 30, 20 * 60 + 45],
    this.intervalo = 75,
    this.local = 'Arena Gugu',
  });

  List<Partida> call({
    required int turno,
    required List<String> times,
    required List<DateTime> datas,
    Random? sorteio,
  }) {
    if (times.length.isOdd) {
      throw ArgumentError('O número de times precisa ser par (${times.length}).');
    }
    final ordem = [...times]..shuffle(sorteio ?? Random());
    final rodadas = times.length - 1;
    final porSemana = semanas(datas);
    if (porSemana.length < rodadas) {
      throw ArgumentError('São ${porSemana.length} semanas para $rodadas rodadas.');
    }

    final partidas = <Partida>[];
    final fixo = ordem.first;
    final roda = ordem.sublist(1);
    final jogosPorRodada = times.length ~/ 2;

    for (var r = 0; r < rodadas; r++) {
      final girado = [...roda.sublist(r), ...roda.sublist(0, r)];
      final lista = [fixo, ...girado];
      final confrontos = [
        for (var i = 0; i < jogosPorRodada; i++)
          // Mando equilibrado (4 ou 5 por time): o time fixo alterna a cada
          // rodada; os demais pares invertem conforme a posição.
          (i == 0 ? r.isEven : i.isOdd)
              ? (lista[i], lista[lista.length - 1 - i])
              : (lista[lista.length - 1 - i], lista[i]),
      ];

      final noites = porSemana[r];
      final horariosDaRodada = _distribuir(noites, confrontos.length);
      for (var i = 0; i < confrontos.length; i++) {
        partidas.add(
          Partida(
            id: 't$turno-r${r + 1}-j${i + 1}',
            turno: turno,
            fase: Fase.classificatoria,
            rodada: r + 1,
            mandanteId: confrontos[i].$1,
            visitanteId: confrontos[i].$2,
            inicio: horariosDaRodada[i],
            local: local,
          ),
        );
      }
    }
    return partidas;
  }

  /// Reparte [n] jogos entre as noites, o mais igual possível, as primeiras
  /// noites com mais jogos; dentro da noite, nos horários em sequência.
  List<DateTime> _distribuir(List<DateTime> noites, int n) {
    final base = n ~/ noites.length;
    final sobra = n % noites.length;
    final resultado = <DateTime>[];
    for (var i = 0; i < noites.length; i++) {
      final qtd = base + (i < sobra ? 1 : 0);
      for (var j = 0; j < qtd; j++) {
        final minutos = j < horarios.length
            ? horarios[j]
            : horarios.last + (j - horarios.length + 1) * intervalo;
        final d = noites[i];
        resultado.add(DateTime(d.year, d.month, d.day, minutos ~/ 60, minutos % 60));
      }
    }
    return resultado;
  }
}
