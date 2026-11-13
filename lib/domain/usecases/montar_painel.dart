import 'package:calcio_regras/calcio_regras.dart';

import '../entities/temporada.dart';

/// Alguém fora da próxima partida do time, para a tela "Suspensos".
class ItemSuspenso {
  final Pessoa pessoa;
  final Time time;
  final String motivo;

  /// Ex.: "Volta na Rodada 5". Nulo se o calendário ainda não permite saber.
  final String? retorno;

  const ItemSuspenso(this.pessoa, this.time, this.motivo, this.retorno);
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
  final List<LinhaClassificacao> tabela;
  final List<Partida> partidas;

  /// Rodada com os próximos jogos (a primeira com partida sem súmula).
  final int? proximaRodada;
  final List<Partida> proximosJogos;
  final List<ItemSuspenso> suspensos;
  final List<ItemPendurado> pendurados;

  const Painel({
    required this.nomeTemporada,
    required this.local,
    required this.times,
    required this.nomes,
    required this.tabela,
    required this.partidas,
    required this.proximaRodada,
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

  Partida partida(String id) => partidas.firstWhere((p) => p.id == id);
}

/// Junta os dados da temporada com as regras e devolve o [Painel].
class MontarPainel {
  final DateTime Function() _agora;

  MontarPainel({DateTime Function()? agora}) : _agora = agora ?? DateTime.now;

  Painel call(DadosTemporada d, {int turno = 1}) {
    final times = {for (final t in d.times) t.id: t};
    final pessoas = {for (final p in d.pessoas) p.id: p};
    final partidas = [...d.partidas]..sort((a, b) => a.inicio.compareTo(b.inicio));

    final tabela = classificacaoDoTurno(
      turno: turno,
      times: times.keys,
      partidas: partidas,
      ajustes: d.ajustes,
      ordemSorteio: d.ordemSorteio,
      params: d.parametros,
    );

    final motor = MotorDisciplinar(
      partidas: partidas,
      pagamentos: d.pagamentos,
      decisoes: d.decisoes,
      agora: d.relogio ?? _agora(),
      params: d.parametros,
    );

    final pendentes = partidas.where((p) => !p.encerrada).toList();
    final proximaRodada = pendentes.isEmpty ? null : pendentes.first.rodada;
    final proximos = proximaRodada == null
        ? <Partida>[]
        : partidas
              .where((p) => p.rodada == proximaRodada && p.turno == pendentes.first.turno)
              .toList();

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

    return Painel(
      nomeTemporada: d.nome,
      local: d.local,
      times: times,
      nomes: {for (final p in d.pessoas) p.id: p.nome},
      tabela: tabela,
      partidas: partidas,
      proximaRodada: proximaRodada,
      proximosJogos: proximos,
      suspensos: suspensos,
      pendurados: pendurados,
    );
  }
}
