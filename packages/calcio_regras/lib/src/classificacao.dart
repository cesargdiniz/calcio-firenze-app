import 'entidades.dart';
import 'parametros.dart';

/// Uma linha da tabela.
class LinhaClassificacao {
  final String timeId;
  int posicao = 0;
  int jogos = 0;
  int vitorias = 0;
  int empates = 0;
  int derrotas = 0;
  int golsPro = 0;
  int golsContra = 0;

  /// Pontos já com W.O., perdas por irregularidade e ajustes da Governança.
  int pontos = 0;
  int amarelos = 0;
  int vermelhos = 0;

  /// Verdadeiro quando os 7 critérios não desempataram e falta o sorteio (art. 42).
  bool aguardaSorteio = false;

  LinhaClassificacao(this.timeId);

  int get saldo => golsPro - golsContra;

  @override
  String toString() =>
      '$posicao. $timeId ${pontos}pts ${vitorias}V ${empates}E ${derrotas}D $golsPro:$golsContra';
}

/// Placar e pontos de um time numa partida encerrada.
class Desfecho {
  final int golsPro;
  final int golsContra;
  final int pontos;

  /// Dedução por W.O. (art. 75): já está descontada de [pontos].
  final int deducao;

  const Desfecho(this.golsPro, this.golsContra, this.pontos, this.deducao);

  bool get vitoria => golsPro > golsContra;
  bool get empate => golsPro == golsContra;
}

/// Calcula o desfecho de [timeId] em [p] (que precisa ter súmula).
Desfecho desfecho(Partida p, String timeId, [Parametros params = Parametros.master2027]) {
  final s = p.sumula!;
  final ehMandante = timeId == p.mandanteId;

  if (s.ausenteWo != null) {
    final ausente = s.ausenteWo == timeId;
    return ausente
        ? Desfecho(0, params.golsWo, -params.deducaoWo, params.deducaoWo)
        : Desfecho(params.golsWo, 0, params.pontosVitoria, 0);
  }

  final pro = ehMandante ? s.golsMandante : s.golsVisitante;
  final contra = ehMandante ? s.golsVisitante : s.golsMandante;
  var pontos = pro > contra
      ? params.pontosVitoria
      : pro == contra
      ? params.pontosEmpate
      : params.pontosDerrota;
  // Arts. 4, 43.1 e 68: o time irregular fica com 0 pontos; o adversário
  // mantém o que conquistou.
  if (s.timesSemPontos.contains(timeId)) pontos = 0;
  return Desfecho(pro, contra, pontos, 0);
}

/// Tabela de um conjunto de partidas, com os desempates do art. 42.
///
/// [ordemSorteio] resolve empates que sobrarem depois dos 7 critérios: o time
/// que aparece antes na lista fica à frente. Sem ela, os times empatados ficam
/// marcados com [LinhaClassificacao.aguardaSorteio].
List<LinhaClassificacao> calcularClassificacao({
  required Iterable<String> times,
  required Iterable<Partida> partidas,
  Iterable<AjustePontos> ajustes = const [],
  List<String> ordemSorteio = const [],
  Parametros params = Parametros.master2027,
}) {
  final encerradas = partidas.where((p) => p.encerrada).toList();
  final linhas = {for (final t in times) t: LinhaClassificacao(t)};

  for (final p in encerradas) {
    for (final t in [p.mandanteId, p.visitanteId]) {
      final l = linhas[t];
      if (l == null) continue;
      final d = desfecho(p, t, params);
      l.jogos++;
      l.golsPro += d.golsPro;
      l.golsContra += d.golsContra;
      l.pontos += d.pontos;
      if (d.vitoria) {
        l.vitorias++;
      } else if (d.empate) {
        l.empates++;
      } else {
        l.derrotas++;
      }
    }
    for (final c in p.sumula!.cartoes) {
      final l = linhas[c.timeId];
      if (l == null) continue;
      if (c.tipo.expulsao) {
        l.vermelhos++;
      } else {
        l.amarelos++;
      }
    }
  }
  for (final a in ajustes) {
    linhas[a.timeId]?.pontos += a.pontos;
  }

  final ordenados = <LinhaClassificacao>[];
  for (final grupo in _agrupar(linhas.values.toList(), (l) => l.pontos)) {
    ordenados.addAll(_desempatar(grupo, 0, encerradas, ordemSorteio, params));
  }
  for (var i = 0; i < ordenados.length; i++) {
    ordenados[i].posicao = i + 1;
  }
  return ordenados;
}

/// Separa em grupos pela chave, do maior valor para o menor.
List<List<LinhaClassificacao>> _agrupar(
  List<LinhaClassificacao> linhas,
  int Function(LinhaClassificacao) chave,
) {
  final mapa = <int, List<LinhaClassificacao>>{};
  for (final l in linhas) {
    mapa.putIfAbsent(chave(l), () => []).add(l);
  }
  final chaves = mapa.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final k in chaves) mapa[k]!];
}

List<LinhaClassificacao> _desempatar(
  List<LinhaClassificacao> grupo,
  int criterio,
  List<Partida> partidas,
  List<String> ordemSorteio,
  Parametros params,
) {
  if (grupo.length == 1) return grupo;

  // Art. 42: 1 vitórias, 2 saldo, 3 gols pró, 4 menos gols sofridos,
  // 5 confronto direto, 6 menos vermelhos, 7 menos amarelos.
  final int Function(LinhaClassificacao)? chave = switch (criterio) {
    0 => (l) => l.vitorias,
    1 => (l) => l.saldo,
    2 => (l) => l.golsPro,
    3 => (l) => -l.golsContra,
    4 => _confrontoDireto(grupo, partidas, params),
    5 => (l) => -l.vermelhos,
    6 => (l) => -l.amarelos,
    _ => null,
  };

  if (chave == null) return _sorteio(grupo, ordemSorteio);

  return [
    for (final sub in _agrupar(grupo, chave))
      ..._desempatar(sub, criterio + 1, partidas, ordemSorteio, params),
  ];
}

/// Pontos de cada time só nos jogos entre os empatados (mini-tabela).
/// Com dois times, é o resultado do jogo entre eles.
int Function(LinhaClassificacao) _confrontoDireto(
  List<LinhaClassificacao> grupo,
  List<Partida> partidas,
  Parametros params,
) {
  final ids = grupo.map((l) => l.timeId).toSet();
  final pontos = {for (final id in ids) id: 0};
  for (final p in partidas) {
    if (!ids.contains(p.mandanteId) || !ids.contains(p.visitanteId)) continue;
    for (final t in [p.mandanteId, p.visitanteId]) {
      pontos[t] = pontos[t]! + desfecho(p, t, params).pontos;
    }
  }
  return (l) => pontos[l.timeId]!;
}

List<LinhaClassificacao> _sorteio(List<LinhaClassificacao> grupo, List<String> ordemSorteio) {
  final todosSorteados = grupo.every((l) => ordemSorteio.contains(l.timeId));
  if (!todosSorteados) {
    for (final l in grupo) {
      l.aguardaSorteio = true;
    }
    return grupo;
  }
  return [...grupo]
    ..sort((a, b) => ordemSorteio.indexOf(a.timeId).compareTo(ordemSorteio.indexOf(b.timeId)));
}

/// Tabela da fase classificatória de um turno.
List<LinhaClassificacao> classificacaoDoTurno({
  required int turno,
  required Iterable<String> times,
  required Iterable<Partida> partidas,
  Iterable<AjustePontos> ajustes = const [],
  List<String> ordemSorteio = const [],
  Parametros params = Parametros.master2027,
}) => calcularClassificacao(
  times: times,
  partidas: partidas.where((p) => p.turno == turno && p.fase == Fase.classificatoria),
  ajustes: ajustes.where((a) => a.turno == turno),
  ordemSorteio: ordemSorteio,
  params: params,
);

/// Classificação geral da temporada: fases classificatórias dos dois turnos
/// somadas, com os mesmos desempates (art. 89).
List<LinhaClassificacao> classificacaoGeral({
  required Iterable<String> times,
  required Iterable<Partida> partidas,
  Iterable<AjustePontos> ajustes = const [],
  List<String> ordemSorteio = const [],
  Parametros params = Parametros.master2027,
}) => calcularClassificacao(
  times: times,
  partidas: partidas.where((p) => p.fase == Fase.classificatoria),
  ajustes: ajustes,
  ordemSorteio: ordemSorteio,
  params: params,
);

/// Os dois rebaixados (art. 89). O campeão do Calcio Master nunca cai
/// (art. 89.4): cai em seu lugar o próximo pior colocado.
List<String> rebaixados(
  List<LinhaClassificacao> geral, {
  String? campeao,
  Parametros params = Parametros.master2027,
}) {
  final resultado = <String>[];
  for (final l in geral.reversed) {
    if (resultado.length == params.rebaixados) break;
    if (l.timeId == campeao) continue;
    resultado.add(l.timeId);
  }
  return resultado;
}
