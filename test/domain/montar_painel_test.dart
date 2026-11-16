import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dados = montarTemporadaExemplo();
  final painel = MontarPainel(agora: () => TemporadaExemploRepository.agora)(dados);

  test('calendário de exemplo: 9 rodadas, todos se enfrentam uma vez', () {
    expect(painel.rodadas, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    final pares = {
      for (final p in painel.partidas) ([p.mandanteId, p.visitanteId]..sort()).join('-'),
    };
    expect(pares, hasLength(45));
  });

  test('cada time joga 3 vezes até a Rodada 3', () {
    expect(painel.tabela, hasLength(10));
    expect(painel.tabela.every((l) => l.jogos == 3), isTrue);
  });

  test('próximos jogos são os da Rodada 4', () {
    expect(painel.proximaRodada, 4);
    expect(painel.proximosJogos, hasLength(5));
  });

  test('suspensos da Rodada 4: vermelho, 3 amarelos e decisão', () {
    final nomes = painel.suspensos.map((s) => s.pessoa.nome).toSet();
    expect(nomes, {'Marcos Lima', 'Paulo Ribeiro', 'Ricardo Alves'});
    final ricardo = painel.suspensos.firstWhere((s) => s.pessoa.nome == 'Ricardo Alves');
    expect(ricardo.retorno, 'Volta na Rodada 6');
    final marcos = painel.suspensos.firstWhere((s) => s.pessoa.nome == 'Marcos Lima');
    expect(marcos.retorno, 'Volta na Rodada 5');
  });

  test('pendurados da Rodada 4: quem tem 2 amarelos', () {
    expect(painel.pendurados.map((p) => p.pessoa.nome).toSet(), {'Fábio Costa', 'Tiago Moura'});
  });

  group('turnos', () {
    test('sem escolha, segue o turno em andamento', () {
      expect(painel.turno, 1);
      expect(painel.turnoAtual, 1);
    });

    test('2º turno ainda sem jogos: tabela zerada', () {
      final p2 = MontarPainel(agora: () => TemporadaExemploRepository.agora)(dados, turno: 2);
      expect(p2.turno, 2);
      expect(p2.tabela.every((l) => l.jogos == 0), isTrue);
      expect(p2.artilharia, isEmpty);
    });

    test('geral soma os turnos e só aponta rebaixados com o 2º turno em jogo', () {
      final g = MontarPainel(agora: () => TemporadaExemploRepository.agora)(
        dados,
        turno: Painel.geral,
      );
      expect(g.turno, Painel.geral);
      expect(g.tabela.map((l) => l.pontos), painel.tabela.map((l) => l.pontos));
      expect(g.rebaixados, isEmpty);
    });

    test('a grande final conta como 2º turno', () {
      expect(MontarPainel.turnoAtualDe(const []), 1);
    });
  });
}
