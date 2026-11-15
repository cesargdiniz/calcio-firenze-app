import 'package:calcio_regras/calcio_regras.dart';

import '../../domain/usecases/montar_situacao.dart';
import '../../shared/format.dart';

/// Quanto o aviso pede atenção. A ordem é a da lista: o mais grave primeiro.
enum GravidadeAviso {
  /// Tira do jogo ou já passou do prazo.
  critico,

  /// Ainda dá tempo de resolver.
  atencao,

  /// Só para saber.
  informativo,
}

/// Um aviso dentro do app, calculado da situação atual. Some sozinho quando
/// a causa deixa de existir (pendência quitada, suspensão cumprida).
class Aviso {
  final String titulo;
  final String texto;
  final GravidadeAviso gravidade;

  /// Sobre outra pessoa do elenco (só dirigente e técnico recebem).
  final bool doTime;

  const Aviso(this.titulo, this.texto, this.gravidade, {this.doTime = false});
}

/// Avisos de pendência de cartão e de suspensão para quem está logado e,
/// quando [veTime], também os do elenco.
List<Aviso> montarAvisos(SituacaoPessoa s, SituacaoTime t, {required bool veTime}) {
  final rodada = s.proximoJogo?.rodada;
  final quando = rodada == null ? 'no próximo jogo' : 'na Rodada $rodada';
  final avisos = <Aviso>[];

  if (s.suspenso) {
    avisos.add(
      Aviso(
        'Você está suspenso $quando',
        '${s.motivoSuspensao ?? 'Suspensão'}. Você não joga esta partida.',
        GravidadeAviso.critico,
      ),
    );
  }
  if (s.impedido) {
    avisos.add(
      Aviso(
        'Você está impedido $quando',
        'Há pendência vencida. Quite com a Organização para voltar a ficar liberado.',
        GravidadeAviso.critico,
      ),
    );
  }
  for (final p in s.emAberto) {
    avisos.add(_pendencia(p, 'Você', deOutro: false));
  }
  if (s.pendurado && !s.suspenso) {
    avisos.add(
      Aviso(
        'Você está pendurado',
        '${s.amarelosNoCiclo} amarelos no turno. O próximo amarelo suspende por 1 jogo.',
        GravidadeAviso.atencao,
      ),
    );
  }

  if (veTime) {
    final nomes = {for (final l in t.elenco) l.pessoa.id: l.pessoa.nome};
    for (final l in t.elenco) {
      if (l.pessoa.id == s.pessoa.id) continue;
      if (l.situacao == SituacaoAtleta.suspenso) {
        avisos.add(
          Aviso(
            '${l.pessoa.nome} está suspenso $quando',
            '${l.detalhe ?? 'Suspensão'}. Não pode ser relacionado nesta partida.',
            GravidadeAviso.atencao,
            doTime: true,
          ),
        );
      } else if (l.situacao == SituacaoAtleta.impedido) {
        avisos.add(
          Aviso(
            '${l.pessoa.nome} está impedido $quando',
            'Tem pendência vencida. Se jogar assim, o time perde os pontos da partida.',
            GravidadeAviso.critico,
            doTime: true,
          ),
        );
      }
    }
    for (final p in t.pendenciasDoTime) {
      if (p.pessoaId == s.pessoa.id || p.status == StatusPendencia.quitada) continue;
      avisos.add(_pendencia(p, nomes[p.pessoaId] ?? 'Atleta', deOutro: true));
    }
  }

  // Ordenação estável: mantém a ordem de chegada dentro da mesma gravidade.
  return [
    for (final g in GravidadeAviso.values) ...avisos.where((a) => a.gravidade == g),
  ];
}

Aviso _pendencia(ItemPendencia p, String quem, {required bool deOutro}) {
  final valor = reais(p.valor);
  final origem = '${p.titulo} · ${p.origem}.';
  return switch (p.status) {
    StatusPendencia.vencida => Aviso(
      deOutro ? '$quem tem pendência vencida de $valor' : 'Pendência vencida de $valor',
      p.multaAtraso
          ? origem
          : '$origem O prazo passou: há multa por atraso do mesmo valor e impedimento de jogar.',
      GravidadeAviso.critico,
      doTime: deOutro,
    ),
    StatusPendencia.aVencer => Aviso(
      deOutro
          ? '$quem deve $valor até ${dataHoraJogo(p.prazo!)}'
          : 'Pague $valor até ${dataHoraJogo(p.prazo!)}',
      '$origem Depois do prazo, a multa é do mesmo valor e não é permitido jogar.',
      GravidadeAviso.atencao,
      doTime: deOutro,
    ),
    _ => Aviso(
      deOutro ? '$quem tem pendência de $valor' : 'Pendência de $valor',
      '$origem Sem prazo enquanto o time não tiver próximo jogo marcado.',
      GravidadeAviso.informativo,
      doTime: deOutro,
    ),
  };
}
