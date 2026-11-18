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
  test('calendário 2027 cumpre as 8 regras', () {
    expect(
      [for (final p in verificarCalendario(montarCalendarioGeral(const {}))) p.detalhe],
      isEmpty,
    );
  });

  test('sorteio respeita 4 dias de descanso em todas as categorias e turnos', () {
    for (final c in Categoria.values) {
      for (final turno in [1, 2]) {
        for (var semente = 0; semente < 5; semente++) {
          final partidas = const GerarCalendario()(
            turno: turno,
            times: [for (var i = 0; i < c.times; i++) 'T$i'],
            horarios: horariosDe(c)[turno]!,
            sorteio: Random(semente),
          );
          for (var i = 0; i < c.times; i++) {
            final datas = [
              for (final p in partidas)
                if (p.envolve('T$i')) p.inicio,
            ]..sort();
            for (var k = 1; k < datas.length; k++) {
              final dias = DateTime.utc(datas[k].year, datas[k].month, datas[k].day)
                  .difference(DateTime.utc(datas[k - 1].year, datas[k - 1].month, datas[k - 1].day))
                  .inDays;
              expect(dias, greaterThanOrEqualTo(4), reason: '${c.sigla} $turnoº turno, T$i, semente $semente');
            }
          }
        }
      }
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
    expect(_detalhes([_j(DateTime(2027, 8, 22, 10), Competicao.livre)]), [
      'R2 Dom 22/08: L1.',
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

  test('regra 9: nenhum jogo em feriado, nem nos facultativos', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 11, 2, 20, 30), Competicao.master),
        _j(DateTime(2027, 10, 25, 20, 30), Competicao.livre, rodada: 7),
      ]).where((d) => d.startsWith('R9')),
      [
        'R9 Seg 25/10 (Data local a confirmar): L1.',
        'R9 Ter 02/11 (Finados): M1.',
      ],
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
