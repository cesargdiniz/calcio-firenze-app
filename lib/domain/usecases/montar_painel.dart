import 'package:calcio_regras/calcio_regras.dart';

import '../entities/categoria.dart';
import '../entities/etapa.dart';
import '../entities/temporada.dart';
import 'mata_mata.dart';

/// Alguém fora da próxima partida do time, para a tela "Suspensos".
class ItemSuspenso {
  final Pessoa pessoa;
  final Time time;
  final String motivo;

  /// Ex.: "Volta na Rodada 5". Nulo se o calendário ainda não permite saber.
  final String? retorno;

  const ItemSuspenso(this.pessoa, this.time, this.motivo, this.retorno);
}

/// Suspensão já cumprida, para o histórico da tela "Suspensos".
class ItemCumprido {
  final Pessoa pessoa;
  final Time time;
  final String motivo;

  /// Onde terminou de cumprir: "Rodada 3", "Semifinais".
  final String cumpriuEm;

  const ItemCumprido(this.pessoa, this.time, this.motivo, this.cumpriuEm);
}

class ItemPendurado {
  final Pessoa pessoa;
  final Time time;
  final int amarelos;
  const ItemPendurado(this.pessoa, this.time, this.amarelos);
}

/// Visão pública da temporada: o que o Torcedor vê. Não inclui valores nem
/// motivos financeiros (perfil Torcedor, especificação).
class Painel {
  final String nomeTemporada;
  final String local;
  final Map<String, Time> times;

  /// Nome de cada pessoa, para súmula e listas.
  final Map<String, String> nomes;

  /// Elencos da temporada (atletas, técnicos e dirigentes).
  final List<Pessoa> pessoas;

  /// Posição de cada time ao fim de cada rodada da fase classificatória,
  /// por turno: `evolucao[turno][rodada - 1][timeId]`. Só vai até a última
  /// rodada com jogo encerrado.
  final Map<int, List<Map<String, int>>> evolucao;
  final List<LinhaClassificacao> tabela;

  /// Goleadores do turno, do que mais marcou para o que menos marcou.
  final List<Artilheiro> artilharia;

  /// Estatísticas do turno.
  final List<EscolhidoMelhor> melhoresDaPartida;
  final List<GolsDoTime> melhorAtaque;
  final List<GolsDoTime> melhorDefesa;
  final List<CartoesDaPessoa> amarelos;
  final List<CartoesDaPessoa> vermelhos;
  final List<CartoesDaPessoa> cartoes;
  final List<Partida> partidas;

  /// Rodada com os próximos jogos (a primeira com partida sem súmula).
  final int? proximaRodada;

  /// Etapa dos próximos jogos: uma rodada ou uma fase do mata-mata.
  final Etapa? proximaEtapa;
  final List<Partida> proximosJogos;
  final List<ItemSuspenso> suspensos;
  final List<ItemPendurado> pendurados;

  /// Suspensões já cumpridas, da mais recente para a mais antiga.
  final List<ItemCumprido> cumpridas;

  /// Categoria da temporada (o Master também mostra as datas da Copa).
  final Categoria categoria;

  /// Turno da tabela e das estatísticas: 1, 2 ou [geral] (soma dos dois).
  final int turno;

  /// Turno em andamento (o do próximo jogo, ou o do último).
  final int turnoAtual;

  /// Times rebaixados (só na classificação geral, art. 89).
  final List<String> rebaixados;

  /// Dados de exemplo: a temporada ainda não foi cadastrada.
  final bool demonstracao;

  /// Valor de [turno] para a classificação geral.
  static const geral = 0;

  const Painel({
    this.pessoas = const [],
    this.evolucao = const {},
    this.categoria = Categoria.master,
    this.turno = 1,
    this.turnoAtual = 1,
    this.rebaixados = const [],
    this.demonstracao = false,
    this.cumpridas = const [],
    required this.nomeTemporada,
    required this.local,
    required this.times,
    required this.nomes,
    required this.tabela,
    required this.artilharia,
    required this.melhoresDaPartida,
    required this.melhorAtaque,
    required this.melhorDefesa,
    required this.amarelos,
    required this.vermelhos,
    required this.cartoes,
    required this.partidas,
    required this.proximaRodada,
    required this.proximaEtapa,
    required this.proximosJogos,
    required this.suspensos,
    required this.pendurados,
  });

  Time time(String id) => times[id]!;

  List<int> get rodadas => {
    for (final p in partidas)
      if (p.rodada != null) p.rodada!,
  }.toList()..sort();

  List<Partida> jogosDaRodada(int rodada) => partidas.where((p) => p.rodada == rodada).toList();

  /// Rodadas e etapas do mata-mata, em ordem.
  List<Etapa> get etapas => etapasDe(partidas);

  List<Partida> jogosDa(Etapa e) => partidas.where(e.contem).toList();

  Partida partida(String id) => partidas.firstWhere((p) => p.id == id);
}

/// Junta os dados da temporada com as regras e devolve o [Painel].
class MontarPainel {
  final DateTime Function() _agora;

  MontarPainel({DateTime Function()? agora}) : _agora = agora ?? DateTime.now;

  /// Turno em andamento: o do próximo jogo (a grande final conta como 2º) ou,
  /// com tudo encerrado, o do último jogo.
  static int turnoAtualDe(List<Partida> partidas) {
    final pendente = partidas.where((p) => !p.encerrada).firstOrNull;
    final referencia = pendente ?? partidas.lastOrNull;
    if (referencia == null) return 1;
    return referencia.turno == 0 ? 2 : referencia.turno;
  }

  /// [turno] nulo: o turno em andamento. [Painel.geral]: os dois somados.
  /// Classificação do turno ao fim de cada rodada já disputada.
  List<Map<String, int>> _evolucao(
    DadosTemporada d,
    List<Partida> partidas,
    int turno,
    Iterable<String> times,
  ) {
    final doTurno = [
      for (final p in partidas)
        if (p.turno == turno && p.fase == Fase.classificatoria && p.rodada != null) p,
    ];
    final ultima = doTurno
        .where((p) => p.encerrada)
        .fold<int>(0, (m, p) => p.rodada! > m ? p.rodada! : m);
    return [
      for (var r = 1; r <= ultima; r++)
        {
          for (final (i, l) in classificacaoDoTurno(
            turno: turno,
            times: times,
            partidas: doTurno.where((p) => p.rodada! <= r),
            ajustes: d.ajustes,
            ordemSorteio: d.ordemSorteio(turno),
            params: d.parametros,
          ).indexed)
            l.timeId: i + 1,
        },
    ];
  }

  Painel call(DadosTemporada d, {int? turno}) {
    final times = {for (final t in d.times) t.id: t};
    final pessoas = {for (final p in d.pessoas) p.id: p};
    final partidas = [...d.partidas]..sort((a, b) => a.inicio.compareTo(b.inicio));
    final atual = turnoAtualDe(partidas);
    final t = turno ?? atual;
    final geral = t == Painel.geral;
    // Estatísticas da temporada inteira na visão geral.
    final turnoStats = geral ? null : t;

    final tabela = geral
        ? classificacaoGeral(
            times: times.keys,
            partidas: partidas,
            ajustes: d.ajustes,
            ordemSorteio: d.ordemSorteio(Painel.geral),
            params: d.parametros,
          )
        : classificacaoDoTurno(
            turno: t,
            times: times.keys,
            partidas: partidas,
            ajustes: d.ajustes,
            ordemSorteio: d.ordemSorteio(t),
            params: d.parametros,
          );
    // Rebaixamento só faz sentido com jogos dos dois turnos lançados.
    final caem = geral && partidas.any((p) => p.turno == 2 && p.encerrada)
        ? rebaixados(tabela, campeao: const MataMata().grandeFinal(d).campeao, params: d.parametros)
        : const <String>[];

    final motor = MotorDisciplinar(
      partidas: partidas,
      pagamentos: d.pagamentos,
      decisoes: d.decisoes,
      agora: d.relogio ?? _agora(),
      params: d.parametros,
    );

    final pendentes = partidas.where((p) => !p.encerrada).toList();
    final proximaEtapa = pendentes.isEmpty ? null : Etapa.de(pendentes.first);
    final proximaRodada = proximaEtapa?.rodada;
    final proximos = proximaEtapa == null ? <Partida>[] : partidas.where(proximaEtapa.contem).toList();

    Pessoa pessoaOuAnonima(String id, String timeId) =>
        pessoas[id] ?? Pessoa(id: id, nome: id, timeId: timeId);

    String? retorno(Suspensao s) {
      if (s.semData > 0 || s.partidasACumprir.isEmpty) return null;
      final ultima = partidas.firstWhere((p) => p.id == s.partidasACumprir.last);
      final volta = partidas.where((p) => p.envolve(s.timeId) && p.inicio.isAfter(ultima.inicio));
      if (volta.isEmpty) return null;
      final r = volta.first.rodada;
      return r == null ? 'Volta no próximo jogo' : 'Volta na Rodada $r';
    }

    String motivo(Suspensao s) => switch (s.motivo) {
      MotivoSuspensao.expulsao => 'Cartão vermelho',
      MotivoSuspensao.amarelos => '3 amarelos',
      MotivoSuspensao.decisao =>
        s.jogos > 1 ? 'Decisão da Organização · ${s.jogos} jogos' : 'Decisão da Organização',
    };

    final suspensos = <ItemSuspenso>[];
    final pendurados = <ItemPendurado>[];
    final vistos = <String>{};
    for (final p in proximos) {
      for (final s in motor.suspensosPara(p.id)) {
        if (!vistos.add('s:${s.pessoaId}')) continue;
        suspensos.add(
          ItemSuspenso(
            pessoaOuAnonima(s.pessoaId, s.timeId),
            times[s.timeId]!,
            motivo(s),
            retorno(s),
          ),
        );
      }
      for (final x in motor.penduradosPara(p.id)) {
        if (!vistos.add('p:${x.pessoaId}')) continue;
        pendurados.add(
          ItemPendurado(pessoaOuAnonima(x.pessoaId, x.timeId), times[x.timeId]!, x.amarelos),
        );
      }
    }

    // Cumpridas: todos os jogos da suspensão já encerrados.
    final porId = {for (final p in partidas) p.id: p};
    final cumpridas = <(DateTime, ItemCumprido)>[];
    for (final s in motor.suspensoes) {
      if (s.partidasACumprir.isEmpty || s.semData > 0) continue;
      final jogos = [for (final id in s.partidasACumprir) ?porId[id]];
      if (jogos.length != s.partidasACumprir.length || !jogos.every((p) => p.encerrada)) continue;
      final ultima = jogos.reduce((a, b) => a.inicio.isAfter(b.inicio) ? a : b);
      final time = times[s.timeId];
      if (time == null) continue;
      cumpridas.add((
        ultima.inicio,
        ItemCumprido(pessoaOuAnonima(s.pessoaId, s.timeId), time, motivo(s), Etapa.de(ultima).rotulo),
      ));
    }
    cumpridas.sort((a, b) => b.$1.compareTo(a.$1));

    return Painel(
      cumpridas: [for (final (_, c) in cumpridas) c],
      categoria: d.categoria,
      turno: t,
      turnoAtual: atual,
      rebaixados: caem,
      demonstracao: d.demonstracao,
      nomeTemporada: d.nome,
      local: d.local,
      times: times,
      nomes: {for (final p in d.pessoas) p.id: p.nome},
      pessoas: d.pessoas,
      evolucao: {
        for (final turno in const [1, 2])
          turno: _evolucao(d, partidas, turno, times.keys),
      },
      tabela: tabela,
      artilharia: artilharia(partidas, turno: turnoStats),
      melhoresDaPartida: melhoresDaPartida(partidas, turno: turnoStats),
      melhorAtaque: melhorAtaque(tabela),
      melhorDefesa: melhorDefesa(tabela),
      amarelos: cartoesPorPessoa(partidas, turno: turnoStats, criterio: CriterioCartoes.amarelos),
      vermelhos: cartoesPorPessoa(partidas, turno: turnoStats, criterio: CriterioCartoes.vermelhos),
      cartoes: cartoesPorPessoa(partidas, turno: turnoStats),
      partidas: partidas,
      proximaRodada: proximaRodada,
      proximaEtapa: proximaEtapa,
      proximosJogos: proximos,
      suspensos: suspensos,
      pendurados: pendurados,
    );
  }
}
