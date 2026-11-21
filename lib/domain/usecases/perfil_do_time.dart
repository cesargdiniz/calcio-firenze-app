import 'package:calcio_regras/calcio_regras.dart';

import '../entities/campeoes.dart';
import '../entities/temporada.dart';
import 'montar_painel.dart';

/// Um destaque do time: as pessoas (empatadas) e o número que as destaca.
class DestaqueDoTime {
  final List<String> nomes;
  final int valor;
  const DestaqueDoTime(this.nomes, this.valor);
}

/// O que a tela do time mostra: dirigentes, títulos, campanha e destaques
/// da temporada (todos os jogos com súmula, os dois turnos somados).
class PerfilDoTime {
  final Time time;
  final List<String> dirigentes;
  final String? tecnico;
  final List<int> titulos;
  final LinhaClassificacao? campanha;
  final int? posicao;
  final DestaqueDoTime? artilheiro;
  final DestaqueDoTime? melhorDaPartida;

  /// Mais cartões: vermelho pesa como três amarelos.
  final DestaqueDoTime? indisciplinado;
  final int amarelosDoLider;
  final int vermelhosDoLider;

  const PerfilDoTime({
    required this.time,
    required this.dirigentes,
    required this.tecnico,
    required this.titulos,
    required this.campanha,
    required this.posicao,
    required this.artilheiro,
    required this.melhorDaPartida,
    required this.indisciplinado,
    this.amarelosDoLider = 0,
    this.vermelhosDoLider = 0,
  });
}

PerfilDoTime perfilDoTime(Painel painel, String timeId) {
  final time = painel.time(timeId);
  final elenco = [
    for (final p in painel.pessoas)
      if (p.timeId == timeId && p.ativo) p,
  ];
  String nome(String id) => painel.nomes[id] ?? 'Atleta';

  DestaqueDoTime? lider<T>(Iterable<T> itens, String Function(T) pessoa, int Function(T) valor) {
    final doTime = itens.toList();
    if (doTime.isEmpty) return null;
    final maior = doTime.map(valor).reduce((a, b) => a > b ? a : b);
    if (maior <= 0) return null;
    return DestaqueDoTime([
      for (final i in doTime)
        if (valor(i) == maior) nome(pessoa(i)),
    ], maior);
  }

  final partidas = painel.partidas;
  final cartoes = [
    for (final c in cartoesPorPessoa(partidas))
      if (c.timeId == timeId && c.funcao == Funcao.atleta) c,
  ];
  int pontos(CartoesDaPessoa c) => c.amarelos + 3 * c.vermelhos;
  final indisciplinado = lider(cartoes, (c) => c.pessoaId, pontos);
  final primeiro = indisciplinado == null
      ? null
      : cartoes.firstWhere((c) => pontos(c) == indisciplinado.valor);

  final tabela = painel.tabela;
  final i = tabela.indexWhere((l) => l.timeId == timeId);

  return PerfilDoTime(
    time: time,
    dirigentes: [
      for (final p in elenco)
        if (p.dirigente) p.nome,
    ],
    tecnico: elenco.where((p) => p.funcao == Funcao.tecnico).firstOrNull?.nome,
    titulos: [
      for (final t in campeoesDe(painel.categoria))
        if (t.campeao == time.nome) t.ano,
    ]..sort(),
    campanha: i < 0 ? null : tabela[i],
    posicao: i < 0 ? null : i + 1,
    artilheiro: lider(
      artilharia(partidas).where((a) => a.timeId == timeId),
      (a) => a.pessoaId,
      (a) => a.gols,
    ),
    melhorDaPartida: lider(
      melhoresDaPartida(partidas).where((m) => m.timeId == timeId),
      (m) => m.pessoaId,
      (m) => m.vezes,
    ),
    indisciplinado: indisciplinado,
    amarelosDoLider: primeiro?.amarelos ?? 0,
    vermelhosDoLider: primeiro?.vermelhos ?? 0,
  );
}
