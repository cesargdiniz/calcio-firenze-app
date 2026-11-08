import 'package:calcio_regras/calcio_regras.dart';

import '../entities/temporada.dart';

/// Uma pendência como o Participante vê.
class ItemPendencia {
  final String titulo;

  /// Ex.: "Rodada 3 · SAM 2:1 UDI".
  final String origem;
  final int valor;
  final DateTime? prazo;
  final StatusPendencia status;
  final bool multaAtraso;
  final String pessoaId;

  const ItemPendencia({
    required this.titulo,
    required this.origem,
    required this.valor,
    required this.prazo,
    required this.status,
    required this.multaAtraso,
    required this.pessoaId,
  });
}

/// Situação de quem está logado (tela P1).
class SituacaoPessoa {
  final Pessoa pessoa;
  final Time time;
  final Partida? proximoJogo;

  /// Amarelos que contam para o acúmulo no ciclo do próximo jogo.
  final int amarelosNoCiclo;
  final bool suspenso;
  final String? motivoSuspensao;
  final bool pendurado;

  /// Impedido no próximo jogo por pendência vencida.
  final bool impedido;
  final List<ItemPendencia> pendencias;

  const SituacaoPessoa({
    required this.pessoa,
    required this.time,
    required this.proximoJogo,
    required this.amarelosNoCiclo,
    required this.suspenso,
    required this.motivoSuspensao,
    required this.pendurado,
    required this.impedido,
    required this.pendencias,
  });

  List<ItemPendencia> get emAberto =>
      pendencias.where((p) => p.status != StatusPendencia.quitada).toList();

  int get totalEmAberto => emAberto.fold(0, (s, p) => s + p.valor);

  /// Prazo mais próximo entre as pendências em aberto.
  DateTime? get proximoPrazo {
    final prazos = [
      for (final p in emAberto)
        if (p.prazo != null) p.prazo!,
    ]..sort();
    return prazos.isEmpty ? null : prazos.first;
  }
}

enum SituacaoAtleta { liberado, pendurado, pendencia, impedido, suspenso }

class LinhaElenco {
  final Pessoa pessoa;
  final SituacaoAtleta situacao;

  /// Ex.: "Cartão vermelho", "2 amarelos", "R$ 30,00 até Qui 18/02".
  final String? detalhe;

  const LinhaElenco(this.pessoa, this.situacao, this.detalhe);
}

/// Situação do time de quem está logado (tela P2).
class SituacaoTime {
  final Time time;
  final Partida? proximoJogo;
  final List<LinhaElenco> elenco;

  /// Só preenchido para dirigente e técnico.
  final List<ItemPendencia> pendenciasDoTime;

  const SituacaoTime({
    required this.time,
    required this.proximoJogo,
    required this.elenco,
    required this.pendenciasDoTime,
  });

  int contar(SituacaoAtleta s) => elenco.where((l) => l.situacao == s).length;
}

/// Calcula a situação pessoal e do time a partir das regras.
class MontarSituacao {
  final DateTime Function() _agora;
  final Parametros params;

  MontarSituacao({DateTime Function()? agora, this.params = Parametros.master2027})
    : _agora = agora ?? DateTime.now;

  ({SituacaoPessoa pessoal, SituacaoTime time}) call(
    DadosTemporada d,
    String pessoaId, {
    bool verPendenciasDoTime = false,
  }) {
    final agora = _agora();
    final pessoa = d.pessoas.firstWhere((p) => p.id == pessoaId);
    final times = {for (final t in d.times) t.id: t};
    final time = times[pessoa.timeId]!;
    final partidas = [...d.partidas]..sort((a, b) => a.inicio.compareTo(b.inicio));

    final motor = MotorDisciplinar(
      partidas: partidas,
      pagamentos: d.pagamentos,
      decisoes: d.decisoes,
      agora: agora,
      params: params,
    );

    final proximo = partidas.where((p) => !p.encerrada && p.envolve(time.id)).firstOrNull;

    String origem(String partidaId) {
      final p = partidas.firstWhere((x) => x.id == partidaId);
      final fase = p.rodada != null ? 'Rodada ${p.rodada}' : 'Mata-mata';
      final s = p.sumula;
      final placar = s == null ? 'x' : '${s.golsMandante}:${s.golsVisitante}';
      return '$fase · ${times[p.mandanteId]!.sigla} $placar ${times[p.visitanteId]!.sigla}';
    }

    ItemPendencia item(Pendencia p) => ItemPendencia(
      titulo: p.descricao,
      origem: origem(p.partidaOrigemId),
      valor: p.valor,
      prazo: p.prazo,
      status: p.status(agora),
      multaAtraso: p.multaAtraso,
      pessoaId: p.pessoaId,
    );

    final suspensos = proximo == null ? <Suspensao>[] : motor.suspensosPara(proximo.id);
    final pendurados = proximo == null ? <Pendurado>[] : motor.penduradosPara(proximo.id);
    final impedidos = proximo == null ? <String>{} : motor.impedidosPara(proximo.id);

    String motivo(Suspensao s) => switch (s.motivo) {
      MotivoSuspensao.expulsao => 'Cartão vermelho',
      MotivoSuspensao.amarelos => '3 amarelos',
      MotivoSuspensao.decisao => 'Decisão da Organização',
    };

    final minhaSuspensao = suspensos.where((s) => s.pessoaId == pessoaId).firstOrNull;
    final ciclo = proximo != null
        ? cicloDe(proximo)
        : (turno: partidas.isEmpty ? 1 : partidas.last.turno, eliminatoria: false);

    final pessoal = SituacaoPessoa(
      pessoa: pessoa,
      time: time,
      proximoJogo: proximo,
      amarelosNoCiclo: motor.amarelosNoCiclo(pessoaId, ciclo),
      suspenso: minhaSuspensao != null,
      motivoSuspensao: minhaSuspensao == null ? null : motivo(minhaSuspensao),
      pendurado: pendurados.any((x) => x.pessoaId == pessoaId),
      impedido: impedidos.contains(pessoaId),
      pendencias: [for (final p in motor.pendenciasDe(pessoaId)) item(p)],
    );

    final abertasDoTime = [
      for (final p in motor.pendenciasEmAberto())
        if (p.timeId == time.id) item(p),
    ];

    LinhaElenco linha(Pessoa x) {
      final susp = suspensos.where((s) => s.pessoaId == x.id).firstOrNull;
      if (susp != null) return LinhaElenco(x, SituacaoAtleta.suspenso, motivo(susp));
      if (impedidos.contains(x.id)) {
        return LinhaElenco(x, SituacaoAtleta.impedido, 'Pendência vencida');
      }
      if (verPendenciasDoTime && abertasDoTime.any((p) => p.pessoaId == x.id)) {
        return LinhaElenco(x, SituacaoAtleta.pendencia, 'Pendência a pagar');
      }
      final pend = pendurados.where((p) => p.pessoaId == x.id).firstOrNull;
      if (pend != null) {
        return LinhaElenco(x, SituacaoAtleta.pendurado, '${pend.amarelos} amarelos');
      }
      return LinhaElenco(x, SituacaoAtleta.liberado, null);
    }

    final elenco = d.pessoas.where((p) => p.timeId == time.id).toList()
      ..sort((a, b) {
        if (a.funcao != b.funcao) return a.funcao == Funcao.tecnico ? 1 : -1;
        return (a.numero ?? 999).compareTo(b.numero ?? 999);
      });

    return (
      pessoal: pessoal,
      time: SituacaoTime(
        time: time,
        proximoJogo: proximo,
        elenco: [for (final x in elenco) linha(x)],
        pendenciasDoTime: verPendenciasDoTime ? abertasDoTime : const [],
      ),
    );
  }
}
