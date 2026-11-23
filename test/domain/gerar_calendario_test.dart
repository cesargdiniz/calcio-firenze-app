import 'dart:math';

import 'package:calcio_regras/calcio_regras.dart';
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

  test('horários oficiais: abertura em 22 e 23/01', () {
    final p = gerar(turno: 1, times: times, horarios: turno1, sorteio: Random(3));
    List<DateTime> da(int r) => [
      for (final x in p)
        if (x.rodada == r) x.inicio,
    ];
    expect(da(1), [
      DateTime(2027, 1, 22, 20, 30),
      DateTime(2027, 1, 22, 21, 30),
      DateTime(2027, 1, 23, 17),
      DateTime(2027, 1, 23, 18),
      DateTime(2027, 1, 23, 19),
    ]);
    expect(da(2).first, DateTime(2027, 1, 26, 20, 30));
    expect(da(2).last, DateTime(2027, 1, 29, 20, 30));
    expect(da(7).first, DateTime(2027, 3, 30, 20, 30));
    expect(da(9).last, DateTime(2027, 4, 30, 20, 30));
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

  test('2º turno: abertura em 06 e 07/08, última rodada até 10/11', () {
    final p = gerar(turno: 2, times: times, horarios: horariosMaster2027[2]!, sorteio: Random(3));
    expect(p, hasLength(45));
    final inicios = p.map((x) => x.inicio).toList()..sort();
    expect(inicios.first, DateTime(2027, 8, 6, 20, 30));
    expect(inicios[2], DateTime(2027, 8, 7, 17));
    expect(inicios.last, DateTime(2027, 11, 10, 20, 30));
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
      expect(horariosLivre2027[0], [DateTime(2027, 12, 18, 19)]);
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
      expect(inicios.first, DateTime(2027, 8, 14, 17));
      expect(inicios.last, DateTime(2027, 11, 3, 21, 30));
      expect(horariosSuperMaster2027[0], [DateTime(2027, 12, 16, 20, 30)]);
    });

    test('cada categoria usa o próprio calendário', () {
      expect(horariosDe(Categoria.master), same(horariosMaster2027));
      expect(horariosDe(Categoria.livre), same(horariosLivre2027));
      expect(horariosDe(Categoria.superMaster), same(horariosSuperMaster2027));
    });
  });

  test('Copa Master: 9 jogos em 5 datas reservadas, de 15/05 a 16/06', () {
    expect(datasCopaMaster2027.map((d) => d.etapa), [
      'Preliminar',
      'Quartas de final',
      'Quartas de final',
      'Semifinais',
      'Final',
    ]);
    expect(datasCopaMaster2027.expand((d) => d.horarios), hasLength(9));
    expect(datasCopaMaster2027.first.horarios, [
      DateTime(2027, 5, 15, 17),
      DateTime(2027, 5, 15, 18),
    ]);
    // Final em dia de semana: os sábados são das finais de turno.
    expect(datasCopaMaster2027.last.horarios, [DateTime(2027, 6, 16, 20, 30)]);
    // Nenhuma data da Copa cai em horário do Master.
    final master = {...horariosMaster2027[1]!, ...horariosMaster2027[2]!};
    expect(datasCopaMaster2027.expand((d) => d.horarios).where(master.contains), isEmpty);
  });

  test('nenhum jogo em julho, em nenhuma categoria nem na Copa', () {
    final todos = [
      for (final c in Categoria.values)
        for (final l in horariosDe(c).values) ...l,
      for (final d in datasCopaMaster2027) ...d.horarios,
    ];
    expect(todos.where((h) => h.month == DateTime.july), isEmpty);
  });

  group('datas do mata-mata', () {
    test('Master 1º turno: quartas 11/05, semis 24/05 e final no sábado 12/06', () {
      final d = datasMataMata(Categoria.master, 1);
      expect(d.map((e) => e.fase), [Fase.quartas, Fase.semifinal, Fase.finalTurno]);
      expect(d.map((e) => e.etapa), ['Quartas de final', 'Semifinais', 'Final do 1º turno']);
      expect(d.map((e) => e.horarios.length), [2, 2, 1]);
      expect(d[0].horarios.first, DateTime(2027, 5, 11, 20, 30));
      expect(d[1].horarios.first, DateTime(2027, 5, 24, 20, 30));
      expect(d[2].horarios.single, DateTime(2027, 6, 12, 19));
    });

    test('2º turno inclui a grande final', () {
      final d = datasMataMata(Categoria.master, 2);
      expect(d.last.fase, Fase.grandeFinal);
      expect(d.last.horarios.single.month, 12);
      expect(d.last.horarios.single.day, 11);
    });

    test('Super Master não tem quartas', () {
      final d = datasMataMata(Categoria.superMaster, 1);
      expect(d.map((e) => e.fase), [Fase.semifinal, Fase.finalTurno]);
      expect(d.first.horarios.first.month, 5);
      expect(d.first.horarios.first.day, 20);
    });

    test('Livre: quartas, semis e final em cada turno', () {
      for (final t in [1, 2]) {
        expect(
          datasMataMata(Categoria.livre, t).where((e) => e.fase != Fase.grandeFinal).map((e) => e.fase),
          [Fase.quartas, Fase.semifinal, Fase.finalTurno],
        );
      }
    });
  });
}
