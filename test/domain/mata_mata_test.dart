import 'dart:math';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/entities/etapa.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/domain/usecases/mata_mata.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

/// Temporada de exemplo com o calendário real e resultados previsíveis: na
/// classificatória, o time de índice menor sempre vence por 1 x 0. A tabela
/// fica na ordem dos times, sem empates.
class _Temporada {
  final base = montarTemporadaExemplo();
  late final ids = [for (final t in base.times) t.id];
  final partidas = <Partida>[];

  _Temporada() {
    partidas.addAll(_turno(1, horariosMaster2027[1]!));
  }

  List<Partida> _turno(int turno, List<DateTime> horarios) => [
    for (final p in const GerarCalendario()(
      turno: turno,
      times: ids,
      horarios: horarios,
      sorteio: Random(3),
    ))
      p.comSumula(
        ids.indexOf(p.mandanteId) < ids.indexOf(p.visitanteId)
            ? const Sumula(golsMandante: 1)
            : const Sumula(golsVisitante: 1),
      ),
  ];

  void segundoTurno() {
    partidas.addAll(_turno(2, horariosMaster2027[2]!));
  }

  DadosTemporada get dados => DadosTemporada(
    id: base.id,
    nome: base.nome,
    local: base.local,
    times: base.times,
    pessoas: base.pessoas,
    partidas: partidas,
  );

  void criar(SituacaoMataMata s) => partidas.addAll(s.propostos);

  void resultado(String id, Sumula s) {
    final i = partidas.indexWhere((p) => p.id == id);
    partidas[i] = partidas[i].comSumula(s);
  }

  String pos(int i) => ids[i - 1];
}

void main() {
  const mm = MataMata();

  test('sem horário oficial livre, propõe uma semana depois e marca como provisória', () {
    final t = _Temporada();
    // Ocupa os horários oficiais das quartas com outro jogo qualquer.
    for (final h in horariosMaster2027[1]!.skip(45)) {
      t.partidas.add(
        Partida(id: 'x$h', turno: 9, fase: Fase.classificatoria, mandanteId: 'a', visitanteId: 'b', inicio: h),
      );
    }
    final s = mm.turno(t.dados, 1);
    expect(s.dataProvisoria, isTrue);
    expect(s.propostos.first.inicio, DateTime(2027, 5, 21, 20, 30));
  });

  test('sem calendário, pede para gerar', () {
    final t = _Temporada()..partidas.clear();
    expect(mm.turno(t.dados, 1).aguardando, contains('Gere o calendário'));
  });

  test('com jogos pendentes, informa quantos faltam', () {
    final t = _Temporada();
    t.partidas[0] = t.partidas[0].comSumula(null);
    t.partidas[1] = t.partidas[1].comSumula(null);
    final s = mm.turno(t.dados, 1);
    expect(s.proxima, isNull);
    expect(s.aguardando, 'Faltam 2 jogos da fase classificatória.');
  });

  test('1º turno completo: quartas de final, final e campeão', () {
    final t = _Temporada();

    // Quartas: 3º x 6º e 4º x 5º, nos horários oficiais de 27/05.
    var s = mm.turno(t.dados, 1);
    expect(s.proxima, Fase.quartas);
    expect(s.propostos.map((p) => '${p.mandanteId} x ${p.visitanteId}'), [
      '${t.pos(3)} x ${t.pos(6)}',
      '${t.pos(4)} x ${t.pos(5)}',
    ]);
    expect(s.propostos.map((p) => p.id), ['t1-quartas-1', 't1-quartas-2']);
    expect(s.propostos.map((p) => p.inicio), [
      DateTime(2027, 5, 28, 20, 30),
      DateTime(2027, 5, 28, 21, 30),
    ]);
    expect(s.dataProvisoria, isFalse);
    expect(s.vantagem.keys, [t.pos(3), t.pos(4)]);

    t.criar(s);
    s = mm.turno(t.dados, 1);
    expect(s.aguardando, contains('quartas'));
    expect(s.desfazivel, Fase.quartas);
    expect(s.idsDesfaziveis, ['t1-quartas-1', 't1-quartas-2']);

    // 3º empata com o 6º e avança; o 5º vence o 4º.
    t.resultado('t1-quartas-1', const Sumula(golsMandante: 1, golsVisitante: 1));
    t.resultado('t1-quartas-2', const Sumula(golsVisitante: 2));
    s = mm.turno(t.dados, 1);
    expect(s.desfazivel, isNull, reason: 'quartas já têm súmula');
    expect(s.proxima, Fase.semifinal);
    // 1º pega o pior colocado (5º); 2º pega o 3º.
    expect(s.propostos.map((p) => '${p.mandanteId} x ${p.visitanteId}'), [
      '${t.pos(1)} x ${t.pos(5)}',
      '${t.pos(2)} x ${t.pos(3)}',
    ]);
    expect(s.propostos.first.inicio, DateTime(2027, 6, 10, 20, 30));

    t.criar(s);
    t.resultado('t1-semi-1', const Sumula(golsMandante: 3));
    t.resultado(
      't1-semi-2',
      const Sumula(golsMandante: 1, golsVisitante: 1, penaltis: Penaltis(3, 4)),
    );

    // Final: 1º x 3º, no horário oficial de 19/06.
    s = mm.turno(t.dados, 1);
    expect(s.proxima, Fase.finalTurno);
    expect(s.propostos.single.id, 't1-final');
    expect('${s.propostos.single.mandanteId} x ${s.propostos.single.visitanteId}',
        '${t.pos(1)} x ${t.pos(3)}');
    expect(s.dataProvisoria, isFalse);
    expect(s.propostos.single.inicio, DateTime(2027, 7, 3, 19));

    t.criar(s);
    t.resultado('t1-final', const Sumula(golsVisitante: 1));
    s = mm.turno(t.dados, 1);
    expect(s.proxima, isNull);
    expect(s.campeao, t.pos(3));
    expect(
      resultadoMataMata(t.partidas.last, (id) => id),
      'Campeão do 1º turno: ${t.pos(3)}',
    );
  });

  test('empate entre os 7 primeiros decidido só por sorteio trava o mata-mata', () {
    final t = _Temporada();
    // Todos os jogos 0 x 0: todos empatados em tudo.
    for (var i = 0; i < t.partidas.length; i++) {
      t.partidas[i] = t.partidas[i].comSumula(const Sumula());
    }
    final s = mm.turno(t.dados, 1);
    expect(s.proxima, isNull);
    expect(s.aguardando, contains('sorteio'));
  });

  group('grande final', () {
    _Temporada campeoes(String c1Pos, String c2Pos) {
      final t = _Temporada()..segundoTurno();
      for (final turno in [1, 2]) {
        t.criar(mm.turno(t.dados, turno));
        for (final p in t.partidas.where((p) => p.turno == turno && p.fase == Fase.quartas)) {
          t.resultado(p.id, const Sumula(golsMandante: 1));
        }
        t.criar(mm.turno(t.dados, turno));
        for (final p in t.partidas.where((p) => p.turno == turno && p.fase == Fase.semifinal)) {
          t.resultado(p.id, const Sumula(golsMandante: 1));
        }
        final f = mm.turno(t.dados, turno);
        t.criar(f);
        final quem = turno == 1 ? c1Pos : c2Pos;
        t.resultado(
          't$turno-final',
          quem == 'mandante' ? const Sumula(golsMandante: 1) : const Sumula(golsVisitante: 1),
        );
      }
      return t;
    }

    test('mesmo campeão nos dois turnos: campeão direto, sem jogo', () {
      final t = campeoes('mandante', 'mandante');
      final s = mm.grandeFinal(t.dados);
      expect(s.proxima, isNull);
      expect(s.campeao, t.pos(1));
    });

    test('campeões diferentes: grande final com o campeão do 1º turno de mandante', () {
      final t = campeoes('mandante', 'visitante');
      var s = mm.grandeFinal(t.dados);
      expect(s.proxima, Fase.grandeFinal);
      final jogo = s.propostos.single;
      expect(jogo.id, 'grande-final');
      expect(jogo.turno, 0);
      expect('${jogo.mandanteId} x ${jogo.visitanteId}', '${t.pos(1)} x ${t.pos(2)}');
      expect(jogo.inicio, DateTime(2027, 12, 11, 19));
      expect(s.dataProvisoria, isFalse);

      t.criar(s);
      expect(mm.grandeFinal(t.dados).idsDesfaziveis, ['grande-final']);
      t.resultado('grande-final', const Sumula(golsVisitante: 2));
      s = mm.grandeFinal(t.dados);
      expect(s.campeao, t.pos(2));
      expect(etapasDe(t.partidas).last, const Etapa(0, Fase.grandeFinal));
    });
  });

  test('Super Master: sem quartas, semifinal direta 1º x 4º e 2º x 3º', () {
    final base = montarTemporadaExemplo();
    final ids = [for (final t in base.times.take(6)) t.id];
    final partidas = [
      for (final p in const GerarCalendario()(
        turno: 1,
        times: ids,
        horarios: horariosSuperMaster2027[1]!,
        sorteio: Random(5),
      ))
        p.comSumula(
          ids.indexOf(p.mandanteId) < ids.indexOf(p.visitanteId)
              ? const Sumula(golsMandante: 1)
              : const Sumula(golsVisitante: 1),
        ),
    ];
    final d = DadosTemporada(
      id: Categoria.superMaster.temporadaId,
      nome: Categoria.superMaster.titulo,
      local: 'Arena Gugu',
      times: base.times.take(6).toList(),
      pessoas: const [],
      partidas: partidas,
    );
    final s = mm.turno(d, 1);
    expect(s.proxima, Fase.semifinal);
    expect(s.propostos.map((p) => '${p.mandanteId} x ${p.visitanteId}'), [
      '${ids[0]} x ${ids[3]}',
      '${ids[1]} x ${ids[2]}',
    ]);
    expect(s.propostos.map((p) => p.id), ['t1-semi-1', 't1-semi-2']);
    expect(s.propostos.first.inicio, DateTime(2027, 5, 20, 20, 30));
    expect(s.vantagem, isEmpty);
  });
}
