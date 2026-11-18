import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';

import '../entities/categoria.dart';

DateTime _h(int mes, int dia, int hora, [int minuto = 0]) => DateTime(2027, mes, dia, hora, minuto);

/// Horários de um dia de jogos: em dia de semana, a partir das 20:30, um por
/// hora; no sábado, a partir das 17h, um por hora. Jogo único de sábado
/// (finais) às 19h. Os horários exatos de cada jogo podem ser ajustados pela
/// Organização na tela do jogo.
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

/// Livre 2027: 8 times, 7 rodadas de 4 jogos por turno.
final horariosLivre2027 = <int, List<DateTime>>{
  1: _dias(const [
    (2, 27, 4), // 1ª rodada
    (3, 10, 2), (3, 12, 2),
    (3, 24, 2), (3, 25, 2),
    (4, 7, 2), (4, 9, 2),
    (4, 24, 4),
    (5, 5, 2), (5, 7, 2),
    (5, 19, 2), (5, 21, 2), // 7ª rodada
    (6, 2, 2), // quartas
    (6, 23, 2), // semifinais
    (6, 26, 1), // final do 1º turno
  ]),
  2: _dias(const [
    (7, 31, 4), // 1ª rodada
    (8, 11, 2), (8, 13, 2),
    (8, 25, 2), (8, 27, 2),
    (9, 8, 2), (9, 10, 2),
    (10, 14, 2), (10, 15, 2),
    (10, 18, 2), (10, 19, 2),
    (10, 20, 2), (10, 22, 2), // 7ª rodada
    (11, 5, 2), // quartas
    (11, 17, 2), // semifinais
    (11, 20, 1), // final do 2º turno
  ]),
  0: _dias(const [(12, 15, 1)]), // grande final
};

/// Super Master 2027: 6 times, 5 rodadas de 3 jogos por turno, semifinal
/// direta.
final horariosSuperMaster2027 = <int, List<DateTime>>{
  1: _dias(const [
    (3, 13, 3), // 1ª rodada
    (3, 22, 1), (3, 23, 2),
    (4, 5, 1), (4, 8, 2),
    (4, 19, 2), (4, 23, 1),
    (5, 3, 1), (5, 6, 2), // 5ª rodada
    (5, 20, 2), // semifinais
    (6, 5, 1), // final do 1º turno
  ]),
  2: _dias(const [
    (8, 9, 1), (8, 10, 2), // 1ª rodada
    // 2ª rodada sem o sábado 14/08 (classificatória do SM não joga sábado).
    (8, 12, 2), (8, 23, 1),
    (8, 24, 1), (8, 26, 2),
    (9, 6, 1), (9, 9, 2),
    (10, 11, 2), (10, 13, 1), // 5ª rodada
    (10, 16, 2), // semifinais
    (10, 23, 1), // final do 2º turno
  ]),
  0: _dias(const [(11, 6, 1)]), // grande final
};

/// Um dia reservado no calendário, com os horários dos jogos. Os confrontos
/// ainda não estão definidos.
class DiaReservado {
  final String etapa;
  final List<DateTime> horarios;
  const DiaReservado(this.etapa, this.horarios);
}

/// Copa Master 2027: mata-mata exclusivo dos times do Master. Por enquanto
/// só as datas ficam reservadas; quem joga é definido depois.
final datasCopaMaster2027 = [
  DiaReservado('Preliminar', _dia(4, 6, 2)),
  DiaReservado('Quartas de final', _dia(4, 20, 2)),
  DiaReservado('Quartas de final', _dia(4, 22, 2)),
  DiaReservado('Semifinais', _dia(5, 18, 2)),
  DiaReservado('Final', _dia(6, 11, 1)),
];

/// Horários oficiais da categoria, por turno (0 = grande final).
Map<int, List<DateTime>> horariosDe(Categoria c) => switch (c) {
  Categoria.master => horariosMaster2027,
  Categoria.superMaster => horariosSuperMaster2027,
  Categoria.livre => horariosLivre2027,
};

/// Sorteia a tabela da fase classificatória de um turno (todos contra todos,
/// art. 16) e ocupa os horários na ordem: os primeiros jogos (metade do
/// número de times) são a Rodada 1, os seguintes a Rodada 2, e assim por
/// diante.
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
      final jogos = [
        for (var i = 0; i < jogosPorRodada; i++)
          // Mando equilibrado (4 ou 5 por time): o time fixo alterna a cada
          // rodada; os demais pares invertem conforme a posição.
          (i == 0 ? r.isEven : i.isOdd)
              ? (lista[i], lista[lista.length - 1 - i])
              : (lista[lista.length - 1 - i], lista[i]),
      ];
      for (var i = 0; i < jogosPorRodada; i++) {
        final horario = slots[k++];
        // Quem jogou na véspera não entra de novo: dentro da rodada, o jogo
        // do dia seguinte fica com times descansados, quando possível.
        final vespera = {
          for (final p in partidas)
            if (_diasEntre(p.inicio, horario) == 1) ...[p.mandanteId, p.visitanteId],
        };
        final escolhido = jogos.firstWhere(
          (j) => !vespera.contains(j.$1) && !vespera.contains(j.$2),
          orElse: () => jogos.first,
        );
        jogos.remove(escolhido);
        partidas.add(
          Partida(
            id: 't$turno-r${r + 1}-j${i + 1}',
            turno: turno,
            fase: Fase.classificatoria,
            rodada: r + 1,
            mandanteId: escolhido.$1,
            visitanteId: escolhido.$2,
            inicio: horario,
            local: local,
          ),
        );
      }
    }
    return partidas;
  }
}

int _diasEntre(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
