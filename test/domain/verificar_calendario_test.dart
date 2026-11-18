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
  test('calendário oficial: só a grande final do Livre (quarta, 15/12) fere as regras', () {
    final problemas = verificarCalendario(montarCalendarioGeral(const {}));
    expect([for (final p in problemas) (p.regra, p.detalhe)], [
      (RegraCalendario.finalNoSabado, 'Qua 15/12: L · Grande final.'),
    ]);
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
        for (var h = 17; h < 20; h++) _j(DateTime(2027, 8, 28, h), Competicao.livre),
      ]),
      ['R1 Qua 25/08: 3 partidas (SM1, L2).'],
    );
  });

  test('regra 2: nenhuma partida aos domingos', () {
    expect(_detalhes([_j(DateTime(2027, 8, 15, 10), Competicao.livre)]), [
      'R2 Dom 15/08: L1.',
    ]);
  });

  test('regra 3: semana do Master sem Livre nem Super Master; a Copa não conta', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 9, 14, 20, 30), Competicao.master),
        _j(DateTime(2027, 9, 16, 20, 30), Competicao.livre),
        _j(DateTime(2027, 4, 6, 20, 30), Competicao.copaMaster, fase: null),
        _j(DateTime(2027, 4, 7, 20, 30), Competicao.livre),
      ]),
      ['R3 Semana de 13/09 a 19/09: M1 com L em Qui 16/09.'],
    );
  });

  test('regra 4: classificatória do M e do SM no sábado só na abertura do turno', () {
    expect(
      _detalhes([
        _j(DateTime(2027, 8, 14, 19), Competicao.superMaster, turno: 2),
        _j(DateTime(2027, 3, 13, 17), Competicao.superMaster, rodada: 1),
        _j(DateTime(2027, 4, 24, 17), Competicao.livre, rodada: 4),
        _j(DateTime(2027, 5, 29, 17), Competicao.master, fase: Fase.semifinal),
      ]),
      ['R4 Sáb 14/08: SM · 2º turno · Rodada 2.'],
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
