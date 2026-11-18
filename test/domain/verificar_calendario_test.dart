import 'dart:math';

import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/usecases/calendario_geral.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/domain/usecases/verificar_calendario.dart';
import 'package:calcio_firenze/modules/calendario/consistencia_calendario.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

JogoDoCalendario _j(
  DateTime inicio,
  Competicao c, {
  Fase? fase = Fase.classificatoria,
  int? rodada = 2,
  int turno = 1,
}) => JogoDoCalendario(
  inicio: inicio,
  competicao: c,
  etapa: switch (fase) {
    Fase.classificatoria => 'Rodada $rodada',
    Fase.finalTurno => 'Final do $turnoº turno',
    Fase.grandeFinal => 'Grande final',
    Fase.quartas => 'Quartas de final',
    _ => 'Semifinais',
  },
  turno: turno,
  fase: fase,
  rodada: fase == Fase.classificatoria ? rodada : null,
);

List<String> _detalhes(List<JogoDoCalendario> jogos) => [
  for (final i in verificarCalendario(jogos)) 'R${i.regra.numero} ${i.detalhe}',
];

void main() {
  test('calendário oficial: grande final do Livre fora do sábado e descansos curtos', () {
    final problemas = verificarCalendario(montarCalendarioGeral(const {}));
    final detalhes = [for (final p in problemas) 'R${p.regra.numero} ${p.detalhe}'];
    expect(detalhes, contains('R5 Qua 15/12: L · Grande final.'));
    expect(detalhes.where((d) => d.startsWith('R7')), hasLength(10));
    expect(detalhes.where((d) => d.startsWith('R4')), ['R4 Sáb 24/04: L · 1º turno · Rodada 5.']);
    expect(
      detalhes.where((d) => !d.startsWith('R4') && !d.startsWith('R5') && !d.startsWith('R7')),
      isEmpty,
    );
    expect(
      detalhes,
      containsAll([
        'R7 L Rodada 6 do 2º turno → L Rodada 7 do 2º turno: quem joga Seg 18/10 '
            'pode voltar a jogar Qua 20/10 (2 dias).',
        'R7 L Semifinais do 2º turno → L Final do 2º turno: quem joga Qua 17/11 '
            'pode voltar a jogar Sáb 20/11 (3 dias).',
        'R7 CM Quartas de final → M Rodada 8 do 1º turno: quem joga Qua 28/04 '
            'pode voltar a jogar Ter 27/04 (etapas no mesmo período).',
      ]),
    );
  });

  test('SM do 2º turno: 2ª rodada em 12/08 e 23/08, 3ª em 24/08 e 26/08', () {
    final t2 = horariosSuperMaster2027[2]!;
    expect(t2.sublist(3, 9), [
      DateTime(2027, 8, 12, 20, 30),
      DateTime(2027, 8, 12, 21, 30),
      DateTime(2027, 8, 23, 20, 30),
      DateTime(2027, 8, 24, 20, 30),
      DateTime(2027, 8, 26, 20, 30),
      DateTime(2027, 8, 26, 21, 30),
    ]);
  });

  test('quem joga em 23/08 não volta a jogar em 24/08', () {
    for (var semente = 0; semente < 40; semente++) {
      final partidas = const GerarCalendario()(
        turno: 2,
        times: const ['A', 'B', 'C', 'D', 'E', 'F'],
        horarios: horariosSuperMaster2027[2]!,
        sorteio: Random(semente),
      );
      Partida em(int dia) => partidas.singleWhere((p) => p.inicio.month == 8 && p.inicio.day == dia);
      final dia23 = em(23);
      final dia24 = em(24);
      expect(dia23.rodada, 2);
      expect(dia24.rodada, 3);
      expect(
        {dia23.mandanteId, dia23.visitanteId}.intersection({dia24.mandanteId, dia24.visitanteId}),
        isEmpty,
        reason: 'semente $semente',
      );
    }
  });

  test('regra 1: no máximo duas partidas por dia útil; sábado pode mais', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 8, 25, 20, 30), Competicao.livre),
        _j(DateTime(2027, 8, 25, 21, 30), Competicao.livre),
        _j(DateTime(2027, 8, 25, 22, 30), Competicao.superMaster),
        for (var h = 17; h < 21; h++) _j(DateTime(2027, 8, 28, h), Competicao.livre, rodada: 1),
      ]).where((d) => d.startsWith('R1') || d.startsWith('R8')),
      ['R1 Qua 25/08: 3 partidas (SM1, L2).'],
    );
  });

  test('regra 2: nenhuma partida aos domingos', () {
    expect(_detalhes([_j(DateTime(2027, 8, 15, 10), Competicao.livre)]), [
      'R2 Dom 15/08: L1.',
    ]);
  });

  test('regra 3: semana do Master (e da Copa Master) sem Livre nem Super Master', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 4, 6, 20, 30), Competicao.copaMaster, fase: null),
        _j(DateTime(2027, 4, 7, 20, 30), Competicao.livre),
        _j(DateTime(2027, 9, 14, 20, 30), Competicao.master),
        _j(DateTime(2027, 9, 16, 20, 30), Competicao.livre),
      ]),
      [
        'R3 Semana de 05/04 a 11/04: CM1 com L em Qua 07/04.',
        'R3 Semana de 13/09 a 19/09: M1 com L em Qui 16/09.',
      ],
    );
  });

  test('regra 4: sábado só para aberturas de turno e mata-mata, em todas as categorias', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 8, 14, 19), Competicao.superMaster, turno: 2),
        _j(DateTime(2027, 3, 13, 17), Competicao.superMaster, rodada: 1),
        _j(DateTime(2027, 4, 24, 17), Competicao.livre, rodada: 5),
        _j(DateTime(2027, 5, 29, 17), Competicao.master, fase: Fase.semifinal),
      ]).where((d) => d.startsWith('R4')),
      ['R4 Sáb 24/04: L · 1º turno · Rodada 5.', 'R4 Sáb 14/08: SM · 2º turno · Rodada 2.'],
    );
  });

  test('regra 8: sábado com até 4 jogos, a partir das 17:00', () {
    expect(
      _detalhes([
        for (var h = 16; h < 21; h++)
          _j(DateTime(2027, 2, 27, h), Competicao.livre, rodada: 1),
      ]).where((d) => d.startsWith('R8')),
      ['R8 Sáb 27/02: 5 partidas (L5).'],
    );
    expect(
      _detalhes([_j(DateTime(2027, 6, 19, 16), Competicao.master, fase: Fase.finalTurno)]),
      ['R8 Sáb 19/06: jogo antes das 17:00.'],
    );
  });

  test('regra 5: finais de turno e grandes finais no sábado', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 6, 18, 20, 30), Competicao.master, fase: Fase.finalTurno),
        _j(DateTime(2027, 6, 19, 19), Competicao.master, fase: Fase.finalTurno),
      ]),
      ['R5 Sex 18/06: M · Final do 1º turno.'],
    );
  });

  test('regra 6: o mesmo time não joga três vezes na semana', () {
    // Horários a definir: quartas, semifinais e final na mesma semana.
    expect(
      _detalhes([
        _j(DateTime(2027, 11, 1, 20, 30), Competicao.livre, fase: Fase.quartas, turno: 2),
        _j(DateTime(2027, 11, 4, 20, 30), Competicao.livre, fase: Fase.semifinal, turno: 2),
        _j(DateTime(2027, 11, 6, 17), Competicao.livre, fase: Fase.finalTurno, turno: 2),
        // Outra categoria na mesma semana não soma para os times do Livre.
        _j(DateTime(2027, 11, 6, 19), Competicao.superMaster, fase: Fase.grandeFinal, turno: 0),
      ]).where((d) => d.startsWith('R6')),
      [
        'R6 Semana de 01/11 a 07/11: L Quartas de final do 2º turno, '
            'L Semifinais do 2º turno, L Final do 2º turno (o mesmo time pode jogar 3 vezes).',
      ],
    );

    // Confrontos definidos: conta os jogos de cada time.
    JogoDoCalendario jogo(int dia, int rodada, String m, String v) => JogoDoCalendario(
      inicio: DateTime(2027, 3, dia, 20, 30),
      competicao: Competicao.master,
      etapa: 'Rodada $rodada',
      partida: Partida(
        id: 'r$rodada-$m',
        turno: 1,
        fase: Fase.classificatoria,
        rodada: rodada,
        mandanteId: m,
        visitanteId: v,
        inicio: DateTime(2027, 3, dia, 20, 30),
      ),
      turno: 1,
      fase: Fase.classificatoria,
      rodada: rodada,
    );
    expect(
      _detalhes([jogo(1, 1, 'A', 'B'), jogo(3, 2, 'C', 'D'), jogo(5, 3, 'E', 'F')]),
      isEmpty,
    );
    expect(
      _detalhes([
        jogo(1, 1, 'A', 'B'),
        jogo(3, 2, 'A', 'C'),
        jogo(5, 3, 'D', 'A'),
      ]).where((d) => d.startsWith('R6')),
      [
        'R6 Semana de 01/03 a 07/03: A (M) joga 3 vezes.',
      ],
    );
  });

  test('regra 7: 4 dias entre jogos do mesmo time (segunda → sexta)', () {
    JogoDoCalendario jogo(DateTime inicio, int rodada, String m, String v) => JogoDoCalendario(
      inicio: inicio,
      competicao: Competicao.livre,
      etapa: 'Rodada $rodada',
      partida: Partida(
        id: 'r$rodada-$m',
        turno: 1,
        fase: Fase.classificatoria,
        rodada: rodada,
        mandanteId: m,
        visitanteId: v,
        inicio: inicio,
      ),
      turno: 1,
      fase: Fase.classificatoria,
      rodada: rodada,
    );
    expect(
      _detalhes([
        jogo(DateTime(2027, 3, 8, 21, 30), 2, 'A', 'B'),
        jogo(DateTime(2027, 3, 12, 20, 30), 3, 'A', 'C'),
        jogo(DateTime(2027, 3, 9, 20, 30), 2, 'D', 'E'),
        jogo(DateTime(2027, 3, 13, 17), 3, 'D', 'F'),
      ]).where((d) => d.startsWith('R7')),
      isEmpty,
      reason: 'segunda → sexta e terça → sábado',
    );
    expect(
      _detalhes([
        jogo(DateTime(2027, 3, 9, 20, 30), 2, 'A', 'B'),
        jogo(DateTime(2027, 3, 12, 20, 30), 3, 'A', 'C'),
      ]),
      ['R7 A (L): Ter 09/03 e Sex 12/03 (3 dias).'],
    );
  });

  test('nova data de uma partida: só os avisos que a envolvem', () {
    final p = Partida(
      id: 't2-r2-j3',
      turno: 2,
      fase: Fase.classificatoria,
      rodada: 2,
      mandanteId: 'A',
      visitanteId: 'B',
      inicio: DateTime(2027, 8, 23, 20, 30),
    );
    final eventos = [
      JogoDoCalendario(
        inicio: p.inicio,
        competicao: Competicao.superMaster,
        etapa: 'Rodada 2',
        partida: p,
        turno: 2,
        fase: Fase.classificatoria,
        rodada: 2,
      ),
      _j(DateTime(2027, 12, 15, 20, 30), Competicao.livre, fase: Fase.grandeFinal, turno: 0),
    ];
    expect(AvisoNovaData.simular(eventos, p.id, p.inicio), isEmpty);
    final noSabado = AvisoNovaData.simular(eventos, p.id, DateTime(2027, 8, 14, 19));
    expect([for (final i in noSabado) i.regra], [RegraCalendario.sabadoClassificatorio]);
  });

  test('siglas das categorias', () {
    expect([for (final c in Categoria.values) c.sigla], ['M', 'SM', 'L']);
  });
}
