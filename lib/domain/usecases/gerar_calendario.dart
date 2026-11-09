import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';

DateTime _h(int mes, int dia, int hora, [int minuto = 0]) => DateTime(2027, mes, dia, hora, minuto);

/// Horários oficiais do Master 2027 (calendário atualizado da Organização).
/// Datas ainda "a definir" (19/06, 13/10, 11/12 e 18/12) ficam de fora até
/// terem horário.
final horariosMaster2027 = <int, List<DateTime>>{
  1: [
    // Rodada 1: abertura, sexta e sábado.
    _h(1, 29, 20, 30), _h(1, 29, 21, 30), _h(1, 30, 17), _h(1, 30, 18), _h(1, 30, 19),
    for (final (m, t, q, s) in const [
      (2, 2, 4, 5),
      (2, 16, 18, 19),
      (3, 2, 4, 5),
      (3, 16, 18, 19),
    ]) ...[
      _h(m, t, 20, 30),
      _h(m, t, 21, 30),
      _h(m, q, 20, 30),
      _h(m, q, 21, 30),
      _h(m, s, 20, 30),
    ],
    // Rodada 6: 30/03 (terça), 01/04 (quinta) e 02/04 (sexta).
    _h(3, 30, 20, 30), _h(3, 30, 21, 30), _h(4, 1, 20, 30), _h(4, 1, 21, 30), _h(4, 2, 20, 30),
    for (final (m, t, q, s) in const [(4, 13, 15, 16), (4, 27, 29, 30), (5, 11, 13, 14)]) ...[
      _h(m, t, 20, 30),
      _h(m, t, 21, 30),
      _h(m, q, 20, 30),
      _h(m, q, 21, 30),
      _h(m, s, 20, 30),
    ],
    // Mata-mata: quartas 27/05, semifinais 10/06 (final em 19/06, a definir).
    _h(5, 27, 20, 30), _h(5, 27, 21, 30), _h(6, 10, 20, 30), _h(6, 10, 21, 30),
  ],
  2: [
    _h(8, 5, 20, 30),
    _h(8, 5, 21, 30),
    _h(8, 6, 20, 30),
    _h(8, 17, 20, 30),
    _h(8, 17, 21, 30),
    _h(8, 19, 20, 30),
    _h(8, 19, 21, 30),
    _h(8, 20, 20, 30),
    _h(8, 31, 20, 30),
    _h(8, 31, 21, 30),
    _h(9, 2, 20, 30),
    _h(9, 2, 21, 30),
    _h(9, 3, 20, 30),
    _h(9, 16, 20, 30),
    _h(9, 16, 21, 30),
    _h(9, 17, 20, 30),
    _h(9, 28, 20, 30),
    _h(9, 28, 21, 30),
    _h(9, 30, 20, 30),
    _h(9, 30, 21, 30),
    _h(10, 1, 20, 30),
    _h(10, 14, 20, 30),
    _h(10, 14, 21, 30),
    _h(10, 15, 20, 30),
    _h(10, 26, 20, 30),
    _h(10, 26, 21, 30),
    _h(10, 28, 20, 30),
    _h(10, 28, 21, 30),
    _h(10, 29, 20, 30),
    _h(11, 9, 20, 30),
    _h(11, 9, 21, 30),
    _h(11, 11, 20, 30),
    _h(11, 11, 21, 30),
    _h(11, 12, 20, 30),
    _h(11, 23, 20, 30),
    _h(11, 23, 21, 30),
    _h(11, 30, 20, 30),
    _h(11, 30, 21, 30),
    _h(12, 7, 20, 30),
    _h(12, 7, 21, 30),
  ],
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
