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

/// Horários do Master 2027, ajustados às 8 regras do calendário (ver
/// verificar_calendario.dart). Cada turno: 9 rodadas de 5 jogos, quartas (2),
/// semis (2) e final (1). A chave 0 é a grande final.
final horariosMaster2027 = <int, List<DateTime>>{
  1: _dias(const [
    (1, 29, 2), (1, 30, 3), // 1ª rodada
    (2, 2, 2), (2, 4, 2), (2, 5, 1), // 2ª rodada
    (2, 16, 2), (2, 18, 2), (2, 19, 1), // 3ª rodada
    (3, 2, 2), (3, 4, 2), (3, 5, 1), // 4ª rodada
    (3, 16, 2), (3, 18, 2), (3, 19, 1), // 5ª rodada
    (3, 30, 2), (4, 1, 2), (4, 2, 1), // 6ª rodada
    (4, 13, 2), (4, 15, 2), (4, 16, 1), // 7ª rodada
    (4, 27, 2), (4, 29, 2), (4, 30, 1), // 8ª rodada
    (5, 11, 2), (5, 13, 2), (5, 14, 1), // 9ª rodada
    (5, 28, 2), // quartas
    (6, 10, 2), // semifinais
    (7, 3, 1), // final do 1º turno
  ]),
  2: _dias(const [
    (8, 6, 2), (8, 7, 3), // 1ª rodada
    (8, 17, 2), (8, 19, 2), (8, 20, 1), // 2ª rodada
    (8, 31, 2), (9, 2, 2), (9, 3, 1), // 3ª rodada
    (9, 14, 2), (9, 16, 2), (9, 17, 1), // 4ª rodada
    (9, 21, 2), (9, 23, 2), (9, 24, 1), // 5ª rodada
    (9, 28, 2), (9, 30, 2), (10, 1, 1), // 6ª rodada
    (10, 5, 2), (10, 7, 2), (10, 8, 1), // 7ª rodada
    (11, 1, 2), (11, 3, 2), (11, 4, 1), // 8ª rodada
    (11, 5, 1), (11, 8, 2), (11, 9, 2), // 9ª rodada
    (11, 13, 2), // quartas
    (11, 30, 2), // semifinais
    (12, 4, 1), // final do 2º turno
  ]),
  0: _dias(const [(12, 11, 1)]), // grande final
};

/// Livre 2027: 8 times, 7 rodadas de 4 jogos por turno.
final horariosLivre2027 = <int, List<DateTime>>{
  1: _dias(const [
    (2, 27, 4), // 1ª rodada
    (3, 10, 2), (3, 12, 2), // 2ª rodada
    (3, 22, 2), (3, 24, 2), // 3ª rodada
    (4, 7, 2), (4, 9, 2), // 4ª rodada
    (4, 20, 2), (4, 22, 2), // 5ª rodada
    (5, 5, 2), (5, 7, 2), // 6ª rodada
    (5, 19, 2), (5, 21, 2), // 7ª rodada
    (6, 2, 2), // quartas
    (6, 22, 2), // semifinais
    (6, 26, 1), // final do 1º turno
  ]),
  2: _dias(const [
    (7, 31, 4), // 1ª rodada
    (8, 10, 2), (8, 12, 2), // 2ª rodada
    (8, 25, 2), (8, 27, 2), // 3ª rodada
    (9, 8, 2), (9, 10, 2), // 4ª rodada
    (10, 14, 2), (10, 15, 2), // 5ª rodada
    (10, 18, 2), (10, 20, 2), // 6ª rodada
    (10, 22, 2), (10, 26, 2), // 7ª rodada
    (10, 30, 2), // quartas
    (11, 16, 2), // semifinais
    (11, 20, 1), // final do 2º turno
  ]),
  0: _dias(const [(11, 27, 1)]), // grande final
};

/// Super Master 2027: 6 times, 5 rodadas de 3 jogos por turno, semifinal
/// direta.
final horariosSuperMaster2027 = <int, List<DateTime>>{
  1: _dias(const [
    (3, 13, 3), // 1ª rodada
    (3, 23, 2), (3, 25, 1), // 2ª rodada
    (4, 6, 1), (4, 8, 2), // 3ª rodada
    (4, 19, 2), (4, 23, 1), // 4ª rodada
    (5, 4, 1), (5, 6, 2), // 5ª rodada
    (5, 20, 2), // semifinais
    (6, 5, 1), // final do 1º turno
  ]),
  2: _dias(const [
    (7, 29, 1), (7, 30, 2), // 1ª rodada
    (8, 11, 1), (8, 13, 2), // 2ª rodada
    (8, 24, 1), (8, 26, 2), // 3ª rodada
    (9, 6, 1), (9, 9, 2), // 4ª rodada
    (10, 11, 2), (10, 13, 1), // 5ª rodada
    (10, 19, 2), // semifinais
    (10, 23, 1), // final do 2º turno
  ]),
  0: _dias(const [(10, 30, 1)]), // grande final
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
  // Entre maio e junho, em semanas sem Livre e sem Super Master e com 4
  // dias de folga para os jogos do Master.
  DiaReservado('Preliminar', _dia(5, 24, 2)),
  DiaReservado('Quartas de final', _dia(6, 14, 2)),
  DiaReservado('Quartas de final', _dia(6, 15, 2)),
  DiaReservado('Semifinais', _dia(6, 19, 2)),
  DiaReservado('Final', _dia(6, 29, 1)),
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

    final rng = sorteio ?? Random();
    final ordem = [...times]..shuffle(rng);
    final pares = _sortearConfrontos(ordem.length, slots.take(necessarios).toList(), rng);
    final mandos = _equilibrarMandos(ordem.length, pares, rng);
    return [
      for (final (k, (a, b)) in pares.indexed)
        Partida(
          id: 't$turno-r${k ~/ jogosPorRodada + 1}-j${k % jogosPorRodada + 1}',
          turno: turno,
          fase: Fase.classificatoria,
          rodada: k ~/ jogosPorRodada + 1,
          mandanteId: ordem[mandos[k] ? a : b],
          visitanteId: ordem[mandos[k] ? b : a],
          inicio: slots[k],
          local: local,
        ),
    ];
  }
}

/// Confrontos de cada horário (índices dos times), todos contra todos: cada
/// par uma vez, cada time uma vez por rodada e, quando o calendário permite,
/// 4 dias entre dois jogos do mesmo time (regra 7). Busca com retrocesso, na
/// ordem do sorteio, recomeçando com outra ordem quando uma tentativa demora;
/// se o calendário não permitir o descanso, monta a tabela sem ele.
List<(int, int)> _sortearConfrontos(int n, List<DateTime> horarios, Random rng) {
  final porRodada = n ~/ 2;
  for (final exigirDescanso in [for (var i = 0; i < 150; i++) true, false]) {
    final jogou = <int>{};
    final ultimo = <int, DateTime>{};
    final saida = <(int, int)>[];
    var passos = 0;

    bool buscar(int k, Set<int> naRodada) {
      if (k == horarios.length) return true;
      if (exigirDescanso && ++passos > 20000) return false;
      if (k % porRodada == 0) naRodada = {};
      final h = horarios[k];
      final livres = [for (var t = 0; t < n; t++) if (!naRodada.contains(t)) t];
      // Poda: todo time livre ainda precisa de um adversário inédito.
      for (final t in livres) {
        if (!livres.any((u) => u != t && !jogou.contains(_par(t, u)))) return false;
      }
      final candidatos = <(int, int)>[
        for (final (i, a) in livres.indexed)
          for (final b in livres.skip(i + 1))
            if (!jogou.contains(_par(a, b)) &&
                (!exigirDescanso ||
                    [a, b].every((t) => ultimo[t] == null || _diasEntre(ultimo[t]!, h) >= 4)))
              (a, b),
      ]..shuffle(rng);
      // Jogos do mesmo dia: a ordem entre eles não importa.
      final mesmoDia = k % porRodada != 0 && horarios[k - 1] == h;
      for (final c in candidatos) {
        if (mesmoDia && _par(c.$1, c.$2) < _par(saida.last.$1, saida.last.$2)) continue;
        final antes = (ultimo[c.$1], ultimo[c.$2]);
        jogou.add(_par(c.$1, c.$2));
        ultimo[c.$1] = h;
        ultimo[c.$2] = h;
        saida.add(c);
        if (buscar(k + 1, {...naRodada, c.$1, c.$2})) return true;
        saida.removeLast();
        jogou.remove(_par(c.$1, c.$2));
        for (final (t, a) in [(c.$1, antes.$1), (c.$2, antes.$2)]) {
          if (a == null) {
            ultimo.remove(t);
          } else {
            ultimo[t] = a;
          }
        }
      }
      return false;
    }

    if (buscar(0, {})) return saida;
  }
  throw StateError('Não foi possível montar a tabela do turno.');
}

int _par(int a, int b) => a < b ? a * 100 + b : b * 100 + a;

/// Mando de cada jogo (verdadeiro: o primeiro time manda), com cada time
/// mandante metade das vezes, arredondando (4 ou 5 com 10 times).
List<bool> _equilibrarMandos(int n, List<(int, int)> pares, Random rng) {
  final casa = List.filled(n, 0);
  final mandos = <bool>[];
  for (final (a, b) in pares) {
    final primeiro = casa[a] != casa[b] ? casa[a] < casa[b] : rng.nextBool();
    mandos.add(primeiro);
    casa[primeiro ? a : b]++;
  }
  // Ajuste fino: inverte jogos até todos ficarem entre n/2 - 1 e n/2.
  final maximo = n ~/ 2;
  final minimo = maximo - 1;
  for (var mudou = true; mudou;) {
    mudou = false;
    for (final (k, (a, b)) in pares.indexed) {
      final (dono, outro) = mandos[k] ? (a, b) : (b, a);
      if ((casa[dono] > maximo && casa[outro] < maximo) ||
          (casa[outro] < minimo && casa[dono] > minimo)) {
        mandos[k] = !mandos[k];
        casa[dono]--;
        casa[outro]++;
        mudou = true;
      }
    }
  }
  return mandos;
}

int _diasEntre(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
