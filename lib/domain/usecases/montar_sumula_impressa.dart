import 'package:calcio_regras/calcio_regras.dart';

import '../entities/temporada.dart';

/// Uma linha da lista de jogadores na súmula de papel.
class LinhaSumulaImpressa {
  final String nome;
  final int? numero;

  /// Suspenso ou impedido por pendência nesta partida: o nome sai riscado.
  final bool fora;

  /// Cartões já lançados (só em jogo encerrado).
  final int amarelos;
  final bool vermelho;

  const LinhaSumulaImpressa({
    required this.nome,
    this.numero,
    this.fora = false,
    this.amarelos = 0,
    this.vermelho = false,
  });
}

class TimeSumulaImpresso {
  final String nome;
  final String sigla;
  final List<LinhaSumulaImpressa> jogadores;
  final String? tecnico;

  /// Gols no placar, quando a súmula já foi encerrada.
  final int? gols;

  const TimeSumulaImpresso({
    required this.nome,
    required this.sigla,
    required this.jogadores,
    this.tecnico,
    this.gols,
  });
}

/// Conteúdo da súmula de papel de uma partida: em branco antes do jogo, ou
/// com placar e cartões depois de encerrada.
class SumulaImpressa {
  final String competicao;
  final String categoria;
  final String fase;
  final String? rodada;
  final String local;
  final DateTime inicio;
  final TimeSumulaImpresso mandante;
  final TimeSumulaImpresso visitante;

  const SumulaImpressa({
    required this.competicao,
    required this.categoria,
    required this.fase,
    required this.rodada,
    required this.local,
    required this.inicio,
    required this.mandante,
    required this.visitante,
  });

  /// Ex.: "sumula-sam-x-int.pdf"
  String get nomeArquivo =>
      'sumula-${mandante.sigla.toLowerCase()}-x-${visitante.sigla.toLowerCase()}.pdf';
}

/// Monta a súmula de papel da partida com o elenco na data do jogo, em ordem
/// alfabética, e risca quem está suspenso ou impedido.
class MontarSumulaImpressa {
  final DateTime Function() _agora;

  MontarSumulaImpressa({DateTime Function()? agora}) : _agora = agora ?? DateTime.now;

  SumulaImpressa call(DadosTemporada d, String partidaId) {
    final p = d.partidas.firstWhere((x) => x.id == partidaId);
    final motor = MotorDisciplinar(
      partidas: d.partidas,
      pagamentos: d.pagamentos,
      decisoes: d.decisoes,
      agora: d.relogio ?? _agora(),
      params: d.parametros,
    );
    final fora = {
      for (final s in motor.suspensosPara(p.id)) s.pessoaId,
      ...motor.impedidosPara(p.id),
    };
    final sumula = p.sumula;
    final cartoes = sumula?.cartoes ?? const <CartaoAplicado>[];

    TimeSumulaImpresso time(String id, int? gols) {
      final t = d.times.firstWhere((x) => x.id == id);
      final elenco = d.pessoas.where((x) => x.timeId == id && x.noElencoEm(p.inicio)).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      final meus = cartoes.where((c) => c.timeId == id);
      return TimeSumulaImpresso(
        nome: t.nome,
        sigla: t.sigla,
        gols: gols,
        tecnico: elenco.where((x) => x.funcao == Funcao.tecnico).firstOrNull?.nome,
        jogadores: [
          for (final x in elenco.where((x) => x.funcao == Funcao.atleta))
            LinhaSumulaImpressa(
              nome: x.nome,
              numero: x.numero,
              fora: fora.contains(x.id),
              amarelos: meus
                  .where((c) => c.pessoaId == x.id)
                  .fold(
                    0,
                    (n, c) => switch (c.tipo) {
                      TipoCartao.amarelo => n + 1,
                      TipoCartao.segundoAmarelo => 2,
                      TipoCartao.vermelho => n,
                    },
                  ),
              vermelho: meus.any((c) => c.pessoaId == x.id && c.tipo.expulsao),
            ),
        ],
      );
    }

    // No W.O. vale o placar do regulamento, não o digitado.
    final wo = sumula?.ausenteWo;
    int? gols(String timeId, int digitado) => sumula == null
        ? null
        : wo == null
        ? digitado
        : (wo == timeId ? 0 : d.parametros.golsWo);

    return SumulaImpressa(
      // "CF CASA ASSIS 2027"; sem patrocinador, "CF 2027".
      competicao: [
        'CF',
        if (d.patrocinador case final nome?) nome,
        '${p.inicio.year}',
      ].join(' '),
      categoria: d.nome.replaceAll(' · ', ' '),
      fase: switch (p.fase) {
        Fase.classificatoria => '${p.turno}º Turno',
        Fase.quartas => 'Quartas · ${p.turno}º Turno',
        Fase.semifinal => 'Semifinal · ${p.turno}º Turno',
        Fase.finalTurno => 'Final · ${p.turno}º Turno',
        Fase.grandeFinal => 'Grande final',
      },
      rodada: p.rodada == null ? null : '${p.rodada}ª Rodada',
      local: p.local ?? d.local,
      inicio: p.inicio,
      mandante: time(p.mandanteId, gols(p.mandanteId, sumula?.golsMandante ?? 0)),
      visitante: time(p.visitanteId, gols(p.visitanteId, sumula?.golsVisitante ?? 0)),
    );
  }
}
