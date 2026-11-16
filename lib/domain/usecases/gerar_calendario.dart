import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';

DateTime _h(int mes, int dia, int hora, [int minuto = 0]) => DateTime(2027, mes, dia, hora, minuto);

/// Horários de um dia de jogos do Master: em dia de semana, 20:30 e 21:30;
/// no sábado, a partir das 17h, um por hora. Jogo único de sábado (finais)
/// às 19h.
List<DateTime> _dia(int mes, int dia, int jogos) {
  final sabado = DateTime(2027, mes, dia).weekday == DateTime.saturday;
  if (sabado) {
    return jogos == 1
        ? [_h(mes, dia, 19)]
        : [for (var i = 0; i < jogos; i++) _h(mes, dia, 17 + i)];
  }
  return [for (var i = 0; i < jogos; i++) _h(mes, dia, 20 + i, 30)];
}

/// Dias de jogo de uma lista `(mês, dia, jogos)`.
List<DateTime> _dias(List<(int, int, int)> dias) => [
  for (final (m, d, n) in dias) ..._dia(m, d, n),
];

/// Horários oficiais do Master 2027, conforme "Calcio Firenze 2027 —
/// Rodadas e Datas". Cada turno: 9 rodadas de 5 jogos, quartas (2), semis
/// (2) e final (1). A chave 0 é a grande final.
final horariosMaster2027 = <int, List<DateTime>>{
  1: _dias(const [
    (1, 29, 2), (1, 30, 3), // 1ª rodada
    (2, 2, 2), (2, 4, 2), (2, 5, 1),
    (2, 16, 2), (2, 18, 2), (2, 19, 1),
    (3, 2, 2), (3, 4, 2), (3, 5, 1),
    (3, 16, 2), (3, 18, 2), (3, 19, 1),
    (3, 30, 2), (4, 1, 2), (4, 2, 1),
    (4, 13, 2), (4, 15, 2), (4, 16, 1),
    (4, 27, 2), (4, 29, 2), (4, 30, 1),
    (5, 11, 2), (5, 13, 2), (5, 14, 1), // 9ª rodada
    (5, 27, 2), // quartas
    (6, 10, 2), // semifinais
    (6, 19, 1), // final do 1º turno
  ]),
  2: _dias(const [
    (8, 6, 2), (8, 7, 3), // 1ª rodada
    (8, 17, 2), (8, 19, 2), (8, 20, 1),
    (8, 31, 2), (9, 2, 2), (9, 3, 1),
    (9, 14, 2), (9, 16, 2), (9, 17, 1),
    (9, 21, 2), (9, 23, 2), (9, 24, 1),
    (9, 28, 2), (9, 30, 2), (10, 1, 1),
    (10, 5, 2), (10, 7, 2), (10, 8, 1),
    (10, 26, 2), (10, 28, 2), (10, 29, 1),
    (11, 9, 2), (11, 11, 2), (11, 12, 1), // 9ª rodada
    (11, 23, 2), // quartas
    (11, 30, 2), // semifinais
    (12, 4, 1), // final do 2º turno
  ]),
  0: _dias(const [(12, 11, 1)]), // grande final
};

/// Sorteia a tabela da fase classificatória de um turno (todos contra todos,
/// art. 16) e ocupa os horários na ordem: os primeiros 5 jogos são a
/// Rodada 1, os 5 seguintes a Rodada 2, e assim por diante.
class GerarCalendario {
  final String local;

  const GerarCalendario({this.local = 'Arena Gugu'});

  List<Partida> call({
    required int turno,
    required List<String> times,
    required List<DateTime> horarios,
    Random? sorteio,
  }) {
    if (times.length.isOdd) {
      throw ArgumentError('O número de times precisa ser par (${times.length}).');
    }
    final rodadas = times.length - 1;
    final jogosPorRodada = times.length ~/ 2;
    final necessarios = rodadas * jogosPorRodada;
    final slots = [...horarios]..sort();
    if (slots.length < necessarios) {
      throw StateError(
        'O $turnoº turno tem ${slots.length} horários definidos para $necessarios jogos '
        '(faltam ${necessarios - slots.length}). Defina os horários que faltam no calendário.',
      );
    }

    final ordem = [...times]..shuffle(sorteio ?? Random());
    final fixo = ordem.first;
    final roda = ordem.sublist(1);
    final partidas = <Partida>[];
    var k = 0;

    for (var r = 0; r < rodadas; r++) {
      final girado = [...roda.sublist(r), ...roda.sublist(0, r)];
      final lista = [fixo, ...girado];
      for (var i = 0; i < jogosPorRodada; i++) {
        // Mando equilibrado (4 ou 5 por time): o time fixo alterna a cada
        // rodada; os demais pares invertem conforme a posição.
        final (mandante, visitante) = (i == 0 ? r.isEven : i.isOdd)
            ? (lista[i], lista[lista.length - 1 - i])
            : (lista[lista.length - 1 - i], lista[i]);
        partidas.add(
          Partida(
            id: 't$turno-r${r + 1}-j${i + 1}',
            turno: turno,
            fase: Fase.classificatoria,
            rodada: r + 1,
            mandanteId: mandante,
            visitanteId: visitante,
            inicio: slots[k++],
            local: local,
          ),
        );
      }
    }
    return partidas;
  }
}
