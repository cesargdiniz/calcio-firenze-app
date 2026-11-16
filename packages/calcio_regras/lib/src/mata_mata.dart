import 'classificacao.dart';
import 'entidades.dart';

/// Um confronto do mata-mata, antes de virar partida no calendário.
class Confronto {
  final String mandanteId;
  final String visitanteId;

  /// Time que avança com empate no tempo normal (art. 16.1). Nulo quando o
  /// empate vai para os pênaltis.
  final String? vantagemEmpate;

  const Confronto(this.mandanteId, this.visitanteId, {this.vantagemEmpate});

  @override
  String toString() => '$mandanteId x $visitanteId';
}

/// Quartas de final (art. 16.1): 3º x 6º e 4º x 5º; 3º e 4º jogam pelo empate.
List<Confronto> chaveamentoQuartas(List<LinhaClassificacao> tabela) {
  String pos(int n) => tabela[n - 1].timeId;
  return [
    Confronto(pos(3), pos(6), vantagemEmpate: pos(3)),
    Confronto(pos(4), pos(5), vantagemEmpate: pos(4)),
  ];
}

/// Semifinais (art. 16.2): o 1º enfrenta o classificado das quartas com pior
/// posição na fase classificatória; o 2º, o de melhor posição. Sem vantagem.
List<Confronto> chaveamentoSemifinais(
  List<LinhaClassificacao> tabela,
  List<String> vencedoresQuartas,
) {
  int posicao(String id) => tabela.firstWhere((l) => l.timeId == id).posicao;
  final ordenados = [...vencedoresQuartas]..sort((a, b) => posicao(a).compareTo(posicao(b)));
  final melhor = ordenados.first;
  final pior = ordenados.last;
  return [Confronto(tabela[0].timeId, pior), Confronto(tabela[1].timeId, melhor)];
}

/// Quem avança numa partida de mata-mata encerrada.
///
/// Ordem: W.O.; time que perdeu os pontos por irregularidade; placar; vantagem
/// do empate; pênaltis. Devolve nulo se ainda não dá para saber (sem súmula,
/// ou empate sem vantagem e sem pênaltis lançados).
String? vencedor(Partida p, {String? vantagemEmpate}) {
  final s = p.sumula;
  if (s == null) return null;
  if (s.ausenteWo != null) return p.adversario(s.ausenteWo!);

  final irregulares = s.timesSemPontos;
  if (irregulares.length == 1) return p.adversario(irregulares.first);

  if (s.golsMandante > s.golsVisitante) return p.mandanteId;
  if (s.golsVisitante > s.golsMandante) return p.visitanteId;
  if (vantagemEmpate != null) return vantagemEmpate;

  final pen = s.penaltis;
  if (pen == null || pen.mandante == pen.visitante) return null;
  return pen.mandante > pen.visitante ? p.mandanteId : p.visitanteId;
}

/// Art. 16.4: se o mesmo time venceu os dois turnos, é o campeão e não há
/// grande final. Caso contrário, devolve nulo e a grande final decide.
String? campeaoSemGrandeFinal(String campeao1, String campeao2) =>
    campeao1 == campeao2 ? campeao1 : null;

/// Time que avança com empate no tempo normal. Só nas quartas (art. 16.1),
/// em que o mandante é sempre o mais bem colocado (3º ou 4º).
String? vantagemDoEmpate(Partida p) => p.fase == Fase.quartas ? p.mandanteId : null;

/// Quem avança numa partida de mata-mata, já com a vantagem das quartas.
String? vencedorMataMata(Partida p) => vencedor(p, vantagemEmpate: vantagemDoEmpate(p));
