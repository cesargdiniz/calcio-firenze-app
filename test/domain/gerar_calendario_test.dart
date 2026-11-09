import 'dart:math';

import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final times = ['INT', 'FIO', 'SAM', 'FOG', 'NAP', 'ROM', 'UDI', 'MON', 'CAS', 'SAS'];
  const gerar = GerarCalendario();

  test('1º turno do regulamento: 9 semanas de classificatória e 3 de mata-mata', () {
    final s = semanas(datasMaster2027[1]!);
    expect(s, hasLength(12));
    expect(s.first, [DateTime(2027, 1, 29), DateTime(2027, 1, 30)]);
    expect(s[8], [DateTime(2027, 5, 11), DateTime(2027, 5, 13), DateTime(2027, 5, 14)]);
  });

  test('todos contra todos: 45 jogos, cada par uma vez, 5 por rodada', () {
    final p = gerar(turno: 1, times: times, datas: datasMaster2027[1]!, sorteio: Random(1));
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
    final p = gerar(turno: 1, times: times, datas: datasMaster2027[1]!, sorteio: Random(7));
    for (final t in times) {
      final casa = p.where((x) => x.mandanteId == t).length;
      expect(casa >= 4 && casa <= 5, isTrue, reason: '$t foi mandante $casa vezes');
    }
  });

  test('horários: 2 jogos por noite; a Rodada 1 (2 noites) usa um 3º horário', () {
    final p = gerar(turno: 1, times: times, datas: datasMaster2027[1]!, sorteio: Random(3));
    final r1 = p.where((x) => x.rodada == 1).map((x) => x.inicio).toList();
    expect(r1, [
      DateTime(2027, 1, 29, 19, 30),
      DateTime(2027, 1, 29, 20, 45),
      DateTime(2027, 1, 29, 22, 0),
      DateTime(2027, 1, 30, 19, 30),
      DateTime(2027, 1, 30, 20, 45),
    ]);
    final r2 = p.where((x) => x.rodada == 2).map((x) => x.inicio).toList();
    expect(r2.first, DateTime(2027, 2, 2, 19, 30));
    expect(r2.last, DateTime(2027, 2, 5, 19, 30));
    expect(p.every((x) => x.local == 'Arena Gugu'), isTrue);
  });

  test('sorteios diferentes geram tabelas diferentes', () {
    String assinatura(int s) => gerar(
      turno: 1,
      times: times,
      datas: datasMaster2027[1]!,
      sorteio: Random(s),
    ).take(5).map((x) => '${x.mandanteId}${x.visitanteId}').join();
    expect(assinatura(1) == assinatura(2), isFalse);
  });

  test('2º turno também cabe nas datas do regulamento', () {
    final p = gerar(turno: 2, times: times, datas: datasMaster2027[2]!, sorteio: Random(1));
    expect(p, hasLength(45));
    expect(p.first.id, 't2-r1-j1');
  });
}
