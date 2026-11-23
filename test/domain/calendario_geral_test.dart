import 'dart:math';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/usecases/calendario_geral.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sem nada sorteado: todos os horários oficiais, com confronto a definir', () {
    final jogos = montarCalendarioGeral(const {});
    int de(Competicao c) => jogos.where((j) => j.competicao == c).length;
    // Por turno: classificatória + quartas (2) + semis (2) + final; mais a grande final.
    expect(de(Competicao.master), 2 * (45 + 5) + 1);
    expect(de(Competicao.livre), 2 * (28 + 5) + 1);
    expect(de(Competicao.superMaster), 2 * (15 + 3) + 1);
    expect(de(Competicao.copaMaster), 9);
    expect(jogos.every((j) => j.aDefinir), isTrue);

    // Em ordem de data.
    for (var i = 1; i < jogos.length; i++) {
      expect(jogos[i].inicio.isBefore(jogos[i - 1].inicio), isFalse);
    }
    expect(jogos.first.inicio, DateTime(2027, 1, 22, 20, 30));
    expect(jogos.first.etapa, 'Rodada 1');
    expect(jogos.last.etapa, 'Grande final');
  });

  test('etapas dos horários vagos', () {
    final livre = [
      for (final j in montarCalendarioGeral(const {}))
        if (j.competicao == Competicao.livre) j,
    ];
    expect(livre.first.etapa, 'Rodada 1');
    expect(livre[27].etapa, 'Rodada 7');
    expect(livre.sublist(28, 33).map((j) => j.etapa), [
      'Quartas de final',
      'Quartas de final',
      'Semifinais',
      'Semifinais',
      'Final do 1º turno',
    ]);
    final superMaster = [
      for (final j in montarCalendarioGeral(const {}))
        if (j.competicao == Competicao.superMaster) j,
    ];
    expect(superMaster[15].etapa, 'Semifinais', reason: 'sem quartas');
  });

  test('turno sorteado entra com os times; o resto continua a definir', () {
    final times = timesMaster2027;
    final partidas = const GerarCalendario()(
      turno: 1,
      times: [for (final t in times) t.id],
      horarios: horariosMaster2027[1]!,
      sorteio: Random(1),
    );
    final jogos = montarCalendarioGeral({
      Categoria.master: DadosCalendario(times: times, partidas: partidas),
    });
    final master = [
      for (final j in jogos)
        if (j.competicao == Competicao.master) j,
    ];
    expect(master, hasLength(101), reason: 'mesmo total: só trocam os vagos pelos reais');
    final primeiro = master.first;
    expect(primeiro.aDefinir, isFalse);
    expect(primeiro.mandante, isNotNull);
    expect(master.where((j) => !j.aDefinir), hasLength(45));
  });

  test('drafts de cada categoria entram no calendário, em ordem de data', () {
    final jogos = montarCalendarioGeral({
      Categoria.master: DadosCalendario(drafts: {1: DateTime(2026, 12, 8), 2: DateTime(2027, 6, 26)}),
      Categoria.livre: DadosCalendario(drafts: {1: DateTime(2027, 1, 16)}),
    });
    final drafts = jogos.where((j) => j.ehDraft).toList();
    expect([for (final d in drafts) (d.competicao, d.draft)], [
      (Competicao.master, 1),
      (Competicao.livre, 1),
      (Competicao.master, 2),
    ]);
    expect(jogos.first.etapa, 'Draft-1');
    expect(drafts.every((d) => d.aDefinir), isTrue);
  });
}
