import 'dart:math';

import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/usecases/calendario_oficial.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

Partida _em(Partida p, DateTime h) => Partida(
  id: p.id,
  turno: p.turno,
  fase: p.fase,
  rodada: p.rodada,
  mandanteId: p.mandanteId,
  visitanteId: p.visitanteId,
  inicio: h,
  local: p.local,
);

void main() {
  final times = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

  test('jogos no oficial não mudam', () {
    final p = const GerarCalendario()(
      turno: 1,
      times: times,
      horarios: horariosMaster2027[1]!,
      sorteio: Random(1),
    );
    expect(voltarAoOficial(Categoria.master, p), isEmpty);
  });

  test('rodada movida volta aos horários oficiais dela, com os mesmos confrontos', () {
    final p = const GerarCalendario()(
      turno: 1,
      times: times,
      horarios: horariosMaster2027[1]!,
      sorteio: Random(1),
    );
    final r1 = p.where((x) => x.rodada == 1).toList();
    // A abertura foi arrastada para segunda 25/01 (e um jogo para 26/01).
    final movidos = [
      for (final x in p)
        if (x.rodada == 1)
          _em(x, DateTime(2027, 1, x == r1.last ? 26 : 25, 20, 30))
        else
          x,
    ];
    final m = voltarAoOficial(Categoria.master, movidos);
    expect(m.keys.toSet(), {for (final x in r1) x.id});
    expect(m.values.toSet(), horariosMaster2027[1]!.take(5).toSet());
  });

  test('jogo com súmula encerrada fica onde está', () {
    final p = const GerarCalendario()(
      turno: 1,
      times: times,
      horarios: horariosMaster2027[1]!,
      sorteio: Random(1),
    );
    final x = p.first;
    final jogado = Partida(
      id: x.id,
      turno: x.turno,
      fase: x.fase,
      rodada: x.rodada,
      mandanteId: x.mandanteId,
      visitanteId: x.visitanteId,
      inicio: DateTime(2027, 1, 25, 20, 30),
      sumula: const Sumula(golsMandante: 1, golsVisitante: 0),
    );
    expect(voltarAoOficial(Categoria.master, [jogado, ...p.skip(1)]), isEmpty);
  });
}
