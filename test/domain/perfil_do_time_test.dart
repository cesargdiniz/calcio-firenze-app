import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_firenze/domain/usecases/perfil_do_time.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d = montarTemporadaExemplo();
  final painel = MontarPainel(agora: () => TemporadaExemploRepository.agora)(d, turno: Painel.geral);

  test('dirigente, técnico e títulos do time', () {
    final p = perfilDoTime(painel, 'INT');
    expect(p.time.nome, 'Inter');
    expect(p.titulos, [2025]);
    expect(p.dirigentes, isNotEmpty);
    expect(p.tecnico, isNotNull);
    expect(perfilDoTime(painel, 'UDI').titulos, isEmpty);
  });

  test('destaques saem dos jogos do próprio time', () {
    for (final t in d.times) {
      final p = perfilDoTime(painel, t.id);
      final gols = artilharia(painel.partidas).where((a) => a.timeId == t.id);
      if (gols.isEmpty) {
        expect(p.artilheiro, isNull);
      } else {
        final max = gols.map((a) => a.gols).reduce((a, b) => a > b ? a : b);
        expect(p.artilheiro!.valor, max);
      }
      if (p.indisciplinado != null) {
        expect(p.amarelosDoLider + 3 * p.vermelhosDoLider, p.indisciplinado!.valor);
      }
    }
  });

  test('evolução: posição de cada time ao fim de cada rodada jogada', () {
    final evo = painel.evolucao[1]!;
    expect(evo, isNotEmpty);
    for (final rodada in evo) {
      expect(rodada.keys.toSet(), {for (final t in d.times) t.id});
      expect(rodada.values.toSet(), {for (var i = 1; i <= d.times.length; i++) i});
    }
    // A última rodada jogada bate com a tabela do 1º turno.
    final tabela = MontarPainel(agora: () => TemporadaExemploRepository.agora)(d, turno: 1).tabela;
    for (final (i, l) in tabela.indexed) {
      expect(evo.last[l.timeId], i + 1);
    }
    expect(painel.evolucao[2], isEmpty);
  });
}
