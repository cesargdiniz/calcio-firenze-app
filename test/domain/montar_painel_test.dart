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
}
