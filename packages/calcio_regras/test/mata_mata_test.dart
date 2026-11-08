import 'package:calcio_regras/calcio_regras.dart';
import 'package:test/test.dart';

import 'apoio.dart';

List<LinhaClassificacao> tabela(List<String> ids) => [
  for (var i = 0; i < ids.length; i++) LinhaClassificacao(ids[i])..posicao = i + 1,
];

void main() {
  final t = tabela(['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7']);

  test('quartas: 3º x 6º e 4º x 5º, com vantagem do 3º e do 4º (art. 16.1)', () {
    final q = chaveamentoQuartas(t);
    expect(q.map((c) => '$c'), ['P3 x P6', 'P4 x P5']);
    expect(q.map((c) => c.vantagemEmpate), ['P3', 'P4']);
  });

  test('semis: 1º pega o pior índice técnico; 2º, o melhor (art. 16.2)', () {
    final s = chaveamentoSemifinais(t, ['P6', 'P4']);
    expect(s.map((c) => '$c'), ['P1 x P6', 'P2 x P4']);
    expect(s.every((c) => c.vantagemEmpate == null), isTrue);
  });

  group('vencedor', () {
    final c = Calendario();
    Partida jogo(Sumula s) => c.jogo('A', 'B', fase: Fase.semifinal, sumula: s);

    test('placar', () => expect(vencedor(jogo(placar(2, 1))), 'A'));
    test(
      'empate com vantagem',
      () => expect(vencedor(jogo(placar(1, 1)), vantagemEmpate: 'B'), 'B'),
    );
    test('empate decidido nos pênaltis', () {
      expect(vencedor(jogo(placar(1, 1, penaltis: const Penaltis(2, 3)))), 'B');
    });
    test('empate sem pênaltis lançados: indefinido', () {
      expect(vencedor(jogo(placar(0, 0))), isNull);
    });
    test('W.O.', () => expect(vencedor(jogo(const Sumula(ausenteWo: 'A'))), 'B'));
    test('irregularidade elimina quem venceu irregularmente', () {
      expect(vencedor(jogo(placar(3, 0, semPontos: {'A'}))), 'B');
    });
  });

  test('mesmo campeão nos dois turnos dispensa a grande final (art. 16.4)', () {
    expect(campeaoSemGrandeFinal('A', 'A'), 'A');
    expect(campeaoSemGrandeFinal('A', 'B'), isNull);
  });
}
