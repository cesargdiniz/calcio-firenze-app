import 'dart:math';

import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final times = ['INT', 'FIO', 'SAM', 'FOG', 'NAP', 'ROM', 'UDI', 'MON', 'CAS', 'SAS'];
  const gerar = GerarCalendario();
  final turno1 = horariosMaster2027[1]!;

  test('1º turno: 45 horários da classificatória e 4 do mata-mata', () {
    expect(turno1, hasLength(49));
    expect(turno1.toSet(), hasLength(49));
  });

  test('todos contra todos: 45 jogos, cada par uma vez, 5 por rodada', () {
    final p = gerar(turno: 1, times: times, horarios: turno1, sorteio: Random(1));
    expect(p, hasLength(45));
    final pares = {
      for (final x in p) ([x.mandanteId, x.visitanteId]..sort()).join('-'),
    };
    expect(pares, hasLength(45));
    for (var r = 1; r <= 9; r++) {
      final daRodada = p.where((x) => x.rodada == r).toList();
      expect(daRodada, hasLength(5));
      final envolvidos = {
        for (final x in daRodada) ...[x.mandanteId, x.visitanteId],
      };
      expect(envolvidos, hasLength(10), reason: 'rodada $r: cada time joga uma vez');
    }
  });

  test('mandos equilibrados: cada time é mandante 4 ou 5 vezes', () {
    final p = gerar(turno: 1, times: times, horarios: turno1, sorteio: Random(7));
    for (final t in times) {
      final casa = p.where((x) => x.mandanteId == t).length;
      expect(casa >= 4 && casa <= 5, isTrue, reason: '$t foi mandante $casa vezes');
    }
  });

  test('horários oficiais: abertura em 29 e 30/01 e uma rodada por semana', () {
    final p = gerar(turno: 1, times: times, horarios: turno1, sorteio: Random(3));
    List<DateTime> da(int r) => [
      for (final x in p)
        if (x.rodada == r) x.inicio,
    ];
    expect(da(1), [
      DateTime(2027, 1, 29, 20, 30),
      DateTime(2027, 1, 29, 21, 30),
      DateTime(2027, 1, 30, 17),
      DateTime(2027, 1, 30, 18),
      DateTime(2027, 1, 30, 19),
    ]);
    expect(da(2).first, DateTime(2027, 2, 2, 20, 30));
    expect(da(2).last, DateTime(2027, 2, 5, 20, 30));
    expect(da(6).first, DateTime(2027, 3, 30, 20, 30));
    expect(da(9).last, DateTime(2027, 5, 14, 20, 30));
    expect(p.every((x) => x.local == 'Arena Gugu'), isTrue);
  });

  test('sorteios diferentes geram tabelas diferentes', () {
    String assinatura(int s) => gerar(
      turno: 1,
      times: times,
      horarios: turno1,
      sorteio: Random(s),
    ).take(5).map((x) => '${x.mandanteId}${x.visitanteId}').join();
    expect(assinatura(1) == assinatura(2), isFalse);
  });

  test('2º turno ainda não fecha: avisa quantos horários faltam', () {
    expect(
      () => gerar(turno: 2, times: times, horarios: horariosMaster2027[2]!),
      throwsA(predicate((e) => e is StateError && e.message.contains('faltam 5'))),
    );
  });
}
