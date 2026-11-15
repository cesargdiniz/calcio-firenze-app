import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dados = montarTemporadaExemplo();
  final painel = MontarPainel(agora: () => TemporadaExemploRepository.agora)(dados);

  test('a artilharia do painel soma exatamente os gols com autor das súmulas', () {
    final golsNasSumulas = dados.partidas.fold<int>(
      0,
      (n, p) => n + (p.sumula?.gols.where((g) => g.autorId != null && !g.contra).length ?? 0),
    );
    expect(golsNasSumulas, greaterThan(0));
    expect(painel.artilharia.fold<int>(0, (n, a) => n + a.gols), golsNasSumulas);
  });

  test('os autores dos gols de exemplo batem com o placar de cada jogo', () {
    for (final p in dados.partidas.where((p) => p.encerrada)) {
      final s = p.sumula!;
      expect(s.gols.where((g) => g.timeId == p.mandanteId), hasLength(s.golsMandante), reason: p.id);
      expect(s.gols.where((g) => g.timeId == p.visitanteId), hasLength(s.golsVisitante), reason: p.id);
    }
  });

  test('todo artilheiro tem nome e time conhecidos pelo painel', () {
    for (final a in painel.artilharia) {
      expect(painel.nomes, contains(a.pessoaId));
      expect(painel.times, contains(a.timeId));
    }
  });
}
