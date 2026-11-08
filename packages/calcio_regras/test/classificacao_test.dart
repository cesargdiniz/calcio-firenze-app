import 'package:calcio_regras/calcio_regras.dart';
import 'package:test/test.dart';

import 'apoio.dart';

List<String> ordem(List<LinhaClassificacao> t) => [for (final l in t) l.timeId];

void main() {
  group('pontuação (art. 42)', () {
    test('vitória 3, empate 1, derrota 0', () {
      final c = Calendario()
        ..jogo('SAM', 'INT', sumula: placar(2, 1))
        ..jogo('SAM', 'UDI', sumula: placar(0, 0));
      final t = calcularClassificacao(times: ['SAM', 'INT', 'UDI'], partidas: c.partidas);
      final sam = t.firstWhere((l) => l.timeId == 'SAM');
      expect(sam.pontos, 4);
      expect((sam.vitorias, sam.empates, sam.derrotas), (1, 1, 0));
      expect((sam.golsPro, sam.golsContra, sam.saldo), (2, 1, 1));
      expect(t.firstWhere((l) => l.timeId == 'INT').pontos, 0);
    });

    test('partida sem súmula não conta', () {
      final c = Calendario()..jogo('SAM', 'INT');
      final t = calcularClassificacao(times: ['SAM', 'INT'], partidas: c.partidas);
      expect(t.every((l) => l.jogos == 0), isTrue);
    });
  });

  group('W.O. (art. 75)', () {
    test('presente vence 6 x 0; ausente perde e ainda desconta 3 pontos', () {
      final c = Calendario()
        ..jogo(
          'SAM',
          'INT',
          sumula: const Sumula(ausenteWo: 'INT', golsMandante: 1, golsVisitante: 5),
        );
      final t = calcularClassificacao(times: ['SAM', 'INT'], partidas: c.partidas);
      final sam = t[0], inter = t[1];
      expect(sam.timeId, 'SAM');
      expect((sam.pontos, sam.golsPro, sam.vitorias), (3, 6, 1));
      expect((inter.pontos, inter.golsContra, inter.derrotas), (-3, 6, 1));
    });
  });

  group('perda de pontos por irregularidade (arts. 4, 43.1, 68)', () {
    test('vencedor irregular fica com 0; perdedor segue com 0', () {
      final c = Calendario()..jogo('SAM', 'INT', sumula: placar(3, 0, semPontos: {'SAM'}));
      final t = calcularClassificacao(times: ['SAM', 'INT'], partidas: c.partidas);
      expect(t.map((l) => l.pontos), everyElement(0));
    });

    test('no empate, o irregular fica com 0 e o regular mantém 1', () {
      final c = Calendario()..jogo('SAM', 'INT', sumula: placar(1, 1, semPontos: {'SAM'}));
      final t = calcularClassificacao(times: ['SAM', 'INT'], partidas: c.partidas);
      expect(t.firstWhere((l) => l.timeId == 'INT').pontos, 1);
      expect(t.firstWhere((l) => l.timeId == 'SAM').pontos, 0);
    });

    test('ambos irregulares: os dois somam zero', () {
      final c = Calendario()..jogo('SAM', 'INT', sumula: placar(2, 2, semPontos: {'SAM', 'INT'}));
      final t = calcularClassificacao(times: ['SAM', 'INT'], partidas: c.partidas);
      expect(t.map((l) => l.pontos), everyElement(0));
    });
  });

  test('ajuste da Governança entra só no turno dele', () {
    final c = Calendario()..jogo('SAM', 'INT', sumula: placar(1, 0));
    const ajuste = AjustePontos(timeId: 'SAM', turno: 2, pontos: -3, motivo: 'teste');
    final t1 = classificacaoDoTurno(
      turno: 1,
      times: ['SAM', 'INT'],
      partidas: c.partidas,
      ajustes: [ajuste],
    );
    expect(t1.first.pontos, 3);
  });

  group('desempates (art. 42), na ordem', () {
    test('1 · mais vitórias', () {
      // A e B com 3 pontos: A com 1V 0E, B com 0V 3E.
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(1, 0))
        ..jogo('A', 'Y', sumula: placar(0, 1))
        ..jogo('B', 'X', sumula: placar(0, 0))
        ..jogo('B', 'Y', sumula: placar(0, 0))
        ..jogo('B', 'Z', sumula: placar(0, 0));
      final t = calcularClassificacao(times: ['B', 'A', 'X', 'Y', 'Z'], partidas: c.partidas);
      expect(ordem(t).indexOf('A'), lessThan(ordem(t).indexOf('B')));
    });

    test('2 · saldo de gols', () {
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(3, 0))
        ..jogo('B', 'Y', sumula: placar(1, 0));
      final t = calcularClassificacao(times: ['B', 'A', 'X', 'Y'], partidas: c.partidas);
      expect(ordem(t).take(2), ['A', 'B']);
    });

    test('3 · gols pró', () {
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(3, 2))
        ..jogo('B', 'Y', sumula: placar(2, 1));
      final t = calcularClassificacao(times: ['B', 'A', 'X', 'Y'], partidas: c.partidas);
      expect(ordem(t).take(2), ['A', 'B']);
    });

    test('4 · menos gols sofridos: com saldo e gols pró iguais, nunca decide sozinho', () {
      // Saldo = pró - sofridos. Se saldo e gols pró empatam, gols sofridos
      // também empatam; o critério 4 está no código para seguir o regulamento,
      // mas a disputa sempre passa adiante.
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(1, 0))
        ..jogo('B', 'Y', sumula: placar(1, 0));
      final t = calcularClassificacao(times: ['A', 'B', 'X', 'Y'], partidas: c.partidas);
      expect(t.take(2).every((l) => l.aguardaSorteio), isTrue);
    });

    test('5 · confronto direto', () {
      // A e B: 3 pts, 1V, saldo 0, GP 1, GC 1. A venceu B.
      final c = Calendario()
        ..jogo('A', 'B', sumula: placar(1, 0))
        ..jogo('B', 'X', sumula: placar(1, 0))
        ..jogo('A', 'Y', sumula: placar(0, 1))
        ..jogo('X', 'Y', sumula: placar(0, 0));
      final t = calcularClassificacao(times: ['B', 'A', 'X', 'Y'], partidas: c.partidas);
      final a = t.firstWhere((l) => l.timeId == 'A');
      final b = t.firstWhere((l) => l.timeId == 'B');
      expect(
        (a.pontos, a.vitorias, a.saldo, a.golsPro),
        (b.pontos, b.vitorias, b.saldo, b.golsPro),
      );
      expect(a.posicao, lessThan(b.posicao));
    });

    test('6 · menos vermelhos', () {
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(1, 0, cartoes: [amarelo('a1', 'A')]))
        ..jogo('B', 'Y', sumula: placar(1, 0, cartoes: [vermelho('b1', 'B')]));
      final t = calcularClassificacao(times: ['B', 'A', 'X', 'Y'], partidas: c.partidas);
      expect(ordem(t).take(2), ['A', 'B']);
    });

    test('7 · menos amarelos', () {
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(1, 0, cartoes: [amarelo('a1', 'A')]))
        ..jogo('B', 'Y', sumula: placar(1, 0, cartoes: [amarelo('b1', 'B'), amarelo('b2', 'B')]));
      final t = calcularClassificacao(times: ['B', 'A', 'X', 'Y'], partidas: c.partidas);
      expect(ordem(t).take(2), ['A', 'B']);
    });

    test('dois amarelos que viram vermelho contam como vermelho', () {
      final c = Calendario()
        ..jogo(
          'A',
          'X',
          sumula: placar(1, 0, cartoes: [amarelo('a1', 'A'), segundoAmarelo('a1', 'A')]),
        );
      final t = calcularClassificacao(times: ['A', 'X'], partidas: c.partidas);
      expect((t.first.vermelhos, t.first.amarelos), (1, 1));
    });

    test('empate persistente: aguarda sorteio, e a ordem do sorteio resolve', () {
      final c = Calendario()
        ..jogo('A', 'X', sumula: placar(1, 0))
        ..jogo('B', 'Y', sumula: placar(1, 0));
      final semSorteio = calcularClassificacao(times: ['A', 'B', 'X', 'Y'], partidas: c.partidas);
      expect(semSorteio.where((l) => l.aguardaSorteio).map((l) => l.timeId).toSet(), {
        'A',
        'B',
        'X',
        'Y',
      });
      final comSorteio = calcularClassificacao(
        times: ['A', 'B', 'X', 'Y'],
        partidas: c.partidas,
        ordemSorteio: ['B', 'A', 'Y', 'X'],
      );
      expect(ordem(comSorteio), ['B', 'A', 'Y', 'X']);
      expect(comSorteio.any((l) => l.aguardaSorteio), isFalse);
    });

    test('confronto direto entre três empatados usa a mini-tabela', () {
      // A, B, C: cada um vence um e perde um entre si por 1x0, e todos
      // vencem D por 1x0. A mini-tabela empata; segue para vermelhos.
      final c = Calendario()
        ..jogo('A', 'B', sumula: placar(1, 0))
        ..jogo('B', 'C', sumula: placar(1, 0))
        ..jogo('C', 'A', sumula: placar(1, 0, cartoes: [vermelho('c1', 'C')]))
        ..jogo('A', 'D', sumula: placar(1, 0))
        ..jogo('B', 'D', sumula: placar(1, 0))
        ..jogo('C', 'D', sumula: placar(1, 0));
      final t = calcularClassificacao(times: ['A', 'B', 'C', 'D'], partidas: c.partidas);
      expect(ordem(t).last, 'D');
      expect(ordem(t)[2], 'C');
      expect(t.take(2).every((l) => l.aguardaSorteio), isTrue);
    });
  });

  group('rebaixamento (art. 89)', () {
    test('caem os dois últimos da classificação geral', () {
      final c = Calendario()
        ..jogo('A', 'B', sumula: placar(1, 0))
        ..jogo('A', 'C', sumula: placar(1, 0))
        ..jogo('B', 'C', sumula: placar(1, 0))
        ..jogo('A', 'D', turno: 2, sumula: placar(1, 0))
        ..jogo('B', 'D', turno: 2, sumula: placar(1, 0))
        ..jogo('C', 'D', turno: 2, sumula: placar(1, 0))
        ..jogo('D', 'C', turno: 2, fase: Fase.finalTurno, sumula: placar(5, 0));
      final geral = classificacaoGeral(times: ['A', 'B', 'C', 'D'], partidas: c.partidas);
      expect(ordem(geral), ['A', 'B', 'C', 'D']);
      expect(rebaixados(geral), ['D', 'C']);
    });

    test('o campeão escapa e cai o próximo pior (art. 89.4)', () {
      final c = Calendario()
        ..jogo('A', 'B', sumula: placar(1, 0))
        ..jogo('A', 'C', sumula: placar(1, 0))
        ..jogo('B', 'C', sumula: placar(1, 0))
        ..jogo('A', 'D', sumula: placar(1, 0))
        ..jogo('B', 'D', sumula: placar(1, 0))
        ..jogo('C', 'D', sumula: placar(1, 0));
      final geral = classificacaoGeral(times: ['A', 'B', 'C', 'D'], partidas: c.partidas);
      expect(rebaixados(geral, campeao: 'D'), ['C', 'B']);
    });
  });
}
