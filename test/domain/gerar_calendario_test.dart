import 'dart:math';

import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final times = ['INT', 'FIO', 'SAM', 'FOG', 'BEN', 'MIL', 'UDI', 'COM', 'JUV', 'SAS'];
  const gerar = GerarCalendario();
  final turno1 = horariosMaster2027[1]!;

  test('cada turno: 45 horários da classificatória e 5 do mata-mata', () {
    for (final t in [1, 2]) {
      expect(horariosMaster2027[t], hasLength(50));
      expect(horariosMaster2027[t]!.toSet(), hasLength(50));
    }
    expect(horariosMaster2027[0], [DateTime(2027, 12, 11, 19)]);
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

  test('2º turno: abertura em 06 e 07/08, última rodada até 09/11', () {
    final p = gerar(turno: 2, times: times, horarios: horariosMaster2027[2]!, sorteio: Random(3));
    expect(p, hasLength(45));
    final inicios = p.map((x) => x.inicio).toList()..sort();
    expect(inicios.first, DateTime(2027, 8, 6, 20, 30));
    expect(inicios[2], DateTime(2027, 8, 7, 17));
    expect(inicios.last, DateTime(2027, 11, 9, 21, 30));
  });

  test('horários que faltam: avisa quantos', () {
    expect(
      () => gerar(turno: 2, times: times, horarios: horariosMaster2027[2]!.take(40).toList()),
      throwsA(predicate((e) => e is StateError && e.message.contains('faltam 5'))),
    );
  });

  group('outras categorias', () {
    test('Livre: 8 times, 7 rodadas de 4 jogos, a partir de 27/02', () {
      final oito = times.take(8).toList();
      for (final t in [1, 2]) {
        expect(horariosLivre2027[t], hasLength(28 + 5), reason: '$tº turno');
      }
      final p = gerar(turno: 1, times: oito, horarios: horariosLivre2027[1]!, sorteio: Random(2));
      expect(p, hasLength(28));
      expect(p.map((x) => x.rodada).toSet(), {1, 2, 3, 4, 5, 6, 7});
      final inicios = p.map((x) => x.inicio).toList()..sort();
      expect(inicios.first, DateTime(2027, 2, 27, 17));
      expect(inicios.last, DateTime(2027, 5, 21, 21, 30));
      expect(horariosLivre2027[0], [DateTime(2027, 11, 27, 19)]);
    });

    test('Super Master: 6 times, 5 rodadas de 3 jogos, semifinal e final', () {
      final seis = times.take(6).toList();
      for (final t in [1, 2]) {
        expect(horariosSuperMaster2027[t], hasLength(15 + 3), reason: '$tº turno');
      }
      final p = gerar(
        turno: 2,
        times: seis,
        horarios: horariosSuperMaster2027[2]!,
        sorteio: Random(2),
      );
      expect(p, hasLength(15));
      final inicios = p.map((x) => x.inicio).toList()..sort();
      expect(inicios.first, DateTime(2027, 7, 30, 20, 30));
      expect(inicios.last, DateTime(2027, 10, 12, 20, 30));
      expect(horariosSuperMaster2027[0], [DateTime(2027, 10, 30, 19)]);
    });

    test('cada categoria usa o próprio calendário', () {
      expect(horariosDe(Categoria.master), same(horariosMaster2027));
      expect(horariosDe(Categoria.livre), same(horariosLivre2027));
      expect(horariosDe(Categoria.superMaster), same(horariosSuperMaster2027));
    });
  });

  test('Copa Master: 9 jogos em 5 datas reservadas, de 24/05 a 29/06', () {
    expect(datasCopaMaster2027.map((d) => d.etapa), [
      'Preliminar',
      'Quartas de final',
      'Quartas de final',
      'Semifinais',
      'Final',
    ]);
    expect(datasCopaMaster2027.expand((d) => d.horarios), hasLength(9));
    expect(datasCopaMaster2027.first.horarios, [
      DateTime(2027, 5, 24, 20, 30),
      DateTime(2027, 5, 24, 21, 30),
    ]);
    expect(datasCopaMaster2027.last.horarios, [DateTime(2027, 6, 29, 20, 30)]);
    // Nenhuma data da Copa cai em horário do Master.
    final master = {...horariosMaster2027[1]!, ...horariosMaster2027[2]!};
    expect(datasCopaMaster2027.expand((d) => d.horarios).where(master.contains), isEmpty);
  });
}
