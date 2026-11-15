import 'classificacao.dart';
import 'entidades.dart';

/// Posições com empate dividido: quem tem o mesmo valor fica na mesma
/// colocação, e a seguinte é pulada (1º, 1º, 3º). [valores] já ordenados.
List<int> _posicoes<T>(List<T> valores) {
  final posicoes = <int>[];
  for (var i = 0; i < valores.length; i++) {
    posicoes.add(i > 0 && valores[i] == valores[i - 1] ? posicoes.last : i + 1);
  }
  return posicoes;
}

Iterable<Sumula> _sumulas(Iterable<Partida> partidas, int? turno) => [
  for (final p in partidas)
    if (p.sumula != null && (turno == null || p.turno == turno)) p.sumula!,
];

// ---------------------------------------------------------------- cartões

/// Qual contagem de cartões ordena a lista.
enum CriterioCartoes { amarelos, vermelhos, todos }

/// Cartões recebidos por uma pessoa (atleta ou técnico).
class CartoesDaPessoa {
  final String pessoaId;
  final String timeId;
  final Funcao funcao;
  final int amarelos;
  final int vermelhos;
  final int posicao;

  const CartoesDaPessoa({
    required this.pessoaId,
    required this.timeId,
    required this.funcao,
    required this.amarelos,
    required this.vermelhos,
    required this.posicao,
  });

  int get total => amarelos + vermelhos;
}

/// Cartões por pessoa, do turno ou, sem ele, da temporada, ordenados pelo
/// [criterio]. Só aparece quem tem ao menos um cartão daquele tipo.
///
/// Em cada partida:
/// - o 2º amarelo (art. 67) conta como dois amarelos e um vermelho, porque
///   foram mostrados dois amarelos e houve expulsão;
/// - o vermelho direto conta como um vermelho, e um amarelo anterior na
///   mesma partida continua contando como amarelo (art. 73.1).
///
/// Cartões do W.O. também contam: foram mostrados antes de o jogo acabar.
List<CartoesDaPessoa> cartoesPorPessoa(
  Iterable<Partida> partidas, {
  int? turno,
  CriterioCartoes criterio = CriterioCartoes.todos,
}) {
  final amarelos = <String, int>{};
  final vermelhos = <String, int>{};
  final dados = <String, CartaoAplicado>{};

  for (final s in _sumulas(partidas, turno)) {
    final porPessoa = <String, List<CartaoAplicado>>{};
    for (final c in s.cartoes) {
      porPessoa.putIfAbsent(c.pessoaId, () => []).add(c);
    }
    porPessoa.forEach((pessoa, cartoes) {
      dados[pessoa] = cartoes.first;
      final segundoAmarelo = cartoes.any((c) => c.tipo == TipoCartao.segundoAmarelo);
      final a = segundoAmarelo ? 2 : cartoes.where((c) => c.tipo == TipoCartao.amarelo).length;
      final v =
          cartoes.where((c) => c.tipo == TipoCartao.vermelho).length + (segundoAmarelo ? 1 : 0);
      amarelos[pessoa] = (amarelos[pessoa] ?? 0) + a;
      vermelhos[pessoa] = (vermelhos[pessoa] ?? 0) + v;
    });
  }

  int valor(String id) => switch (criterio) {
    CriterioCartoes.amarelos => amarelos[id]!,
    CriterioCartoes.vermelhos => vermelhos[id]!,
    CriterioCartoes.todos => amarelos[id]! + vermelhos[id]!,
  };

  // No total, quem tem mais vermelhos fica à frente no empate.
  (int, int) chave(String id) =>
      (valor(id), criterio == CriterioCartoes.todos ? vermelhos[id]! : 0);

  final ordem = dados.keys.where((id) => valor(id) > 0).toList()
    ..sort((a, b) {
      final (va, ra) = chave(a);
      final (vb, rb) = chave(b);
      if (va != vb) return vb.compareTo(va);
      if (ra != rb) return rb.compareTo(ra);
      return a.compareTo(b);
    });
  final posicoes = _posicoes([for (final id in ordem) chave(id)]);

  return [
    for (final (i, id) in ordem.indexed)
      CartoesDaPessoa(
        pessoaId: id,
        timeId: dados[id]!.timeId,
        funcao: dados[id]!.funcao,
        amarelos: amarelos[id]!,
        vermelhos: vermelhos[id]!,
        posicao: posicoes[i],
      ),
  ];
}

// ------------------------------------------------------- melhor da partida

/// Quantas vezes um atleta foi escolhido o melhor da partida.
class EscolhidoMelhor {
  final String pessoaId;
  final String timeId;
  final int vezes;
  final int posicao;

  const EscolhidoMelhor({
    required this.pessoaId,
    required this.timeId,
    required this.vezes,
    required this.posicao,
  });
}

/// Ranking de melhor da partida, do turno ou, sem ele, da temporada. Jogo
/// decidido por W.O. não tem melhor da partida.
List<EscolhidoMelhor> melhoresDaPartida(Iterable<Partida> partidas, {int? turno}) {
  final vezes = <String, int>{};
  final time = <String, String>{};
  for (final s in _sumulas(partidas, turno)) {
    final m = s.melhorDaPartida;
    if (m == null || s.ausenteWo != null) continue;
    vezes[m.pessoaId] = (vezes[m.pessoaId] ?? 0) + 1;
    time[m.pessoaId] = m.timeId;
  }
  final ordem = vezes.keys.toList()
    ..sort((a, b) {
      final c = vezes[b]!.compareTo(vezes[a]!);
      return c != 0 ? c : a.compareTo(b);
    });
  final posicoes = _posicoes([for (final id in ordem) vezes[id]]);
  return [
    for (final (i, id) in ordem.indexed)
      EscolhidoMelhor(pessoaId: id, timeId: time[id]!, vezes: vezes[id]!, posicao: posicoes[i]),
  ];
}

// ------------------------------------------------------- ataque e defesa

/// Gols de um time numa tabela: marcados (ataque) ou sofridos (defesa).
class GolsDoTime {
  final String timeId;
  final int gols;
  final int jogos;
  final int posicao;

  const GolsDoTime({
    required this.timeId,
    required this.gols,
    required this.jogos,
    required this.posicao,
  });
}

List<GolsDoTime> _porGols(
  List<LinhaClassificacao> tabela,
  int Function(LinhaClassificacao) gols, {
  required bool maiorPrimeiro,
}) {
  // Só times que já jogaram. No empate, mantém a ordem da classificação.
  final linhas = tabela.where((l) => l.jogos > 0).toList();
  final ordem = [...linhas]
    ..sort((a, b) {
      final c = maiorPrimeiro ? gols(b).compareTo(gols(a)) : gols(a).compareTo(gols(b));
      return c != 0 ? c : linhas.indexOf(a).compareTo(linhas.indexOf(b));
    });
  final posicoes = _posicoes([for (final l in ordem) gols(l)]);
  return [
    for (final (i, l) in ordem.indexed)
      GolsDoTime(timeId: l.timeId, gols: gols(l), jogos: l.jogos, posicao: posicoes[i]),
  ];
}

/// Mais gols marcados primeiro. Usa os gols da tabela, então os do W.O.
/// contam (art. 75).
List<GolsDoTime> melhorAtaque(List<LinhaClassificacao> tabela) =>
    _porGols(tabela, (l) => l.golsPro, maiorPrimeiro: true);

/// Menos gols sofridos primeiro. Usa os gols da tabela, então os do W.O.
/// contam (art. 75).
List<GolsDoTime> melhorDefesa(List<LinhaClassificacao> tabela) =>
    _porGols(tabela, (l) => l.golsContra, maiorPrimeiro: false);
