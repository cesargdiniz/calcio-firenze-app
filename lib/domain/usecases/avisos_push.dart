import 'package:calcio_regras/calcio_regras.dart';

import '../entities/aviso_push.dart';
import '../entities/categoria.dart';
import '../entities/temporada.dart';
import '../entities/usuario.dart';

/// Tópicos de notificação. Os mesmos nomes são usados pelo serviço do
/// Firebase (functions/index.js): mudou aqui, muda lá.
abstract final class Topicos {
  /// Resultados da categoria: todo mundo que escolheu a categoria no app.
  static String resultados(String temporadaId) => _limpo('res_$temporadaId');

  /// Elenco do time (atletas, dirigentes, técnico): lembrete dos jogos.
  static String time(String temporadaId, String timeId) => _limpo('time_${temporadaId}_$timeId');

  /// Dirigentes do time: suspensões dos jogadores.
  static String dirigentes(String temporadaId, String timeId) =>
      _limpo('dir_${temporadaId}_$timeId');

  /// Uma pessoa do elenco: a própria suspensão.
  static String pessoa(String temporadaId, String pessoaId) =>
      _limpo('pessoa_${temporadaId}_$pessoaId');

  /// O FCM só aceita letras, números e `-_.~%` no nome do tópico.
  static String _limpo(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
}

/// Tópicos em que o celular deve estar inscrito: os resultados da categoria
/// escolhida e, para quem tem vínculo aprovado, o time, a própria pessoa e,
/// se dirigente, o aviso de suspensões do time.
Set<String> topicosDoAparelho({Categoria? categoria, Usuario? usuario}) => {
  if (categoria != null) Topicos.resultados(categoria.temporadaId),
  for (final v in usuario?.vinculos ?? const <Vinculo>[])
    if (v.status == StatusVinculo.aprovado) ...[
      Topicos.time(v.temporadaId, v.timeId),
      Topicos.pessoa(v.temporadaId, v.pessoaId),
      if (v.papel == Papel.dirigente) Topicos.dirigentes(v.temporadaId, v.timeId),
    ],
};

/// Avisos ao encerrar a súmula de [partida]: o resultado (só no primeiro
/// encerramento, não nas correções) e as suspensões novas que ela gerou, para
/// o jogador e para os dirigentes do time.
List<AvisoPush> avisosDoEncerramento({
  required DadosTemporada antes,
  required Partida partida,
  required DateTime agora,
}) {
  final sumula = partida.sumula;
  if (sumula == null) return const [];
  final anterior = antes.partidas.where((p) => p.id == partida.id).firstOrNull;
  final times = {for (final t in antes.times) t.id: t.nome};
  final pessoas = {for (final p in antes.pessoas) p.id: p.nome};
  final m = times[partida.mandanteId] ?? partida.mandanteId;
  final v = times[partida.visitanteId] ?? partida.visitanteId;
  final confronto = '$m x $v';
  final categoria = Categoria.deTemporada(antes.id)?.nome ?? antes.nome;
  final avisos = <AvisoPush>[];

  if (anterior?.sumula == null) {
    final placar = sumula.ausenteWo != null
        ? '$m x $v · W.O. (${times[sumula.ausenteWo] ?? sumula.ausenteWo} não compareceu)'
        : '$m ${sumula.golsMandante} x ${sumula.golsVisitante} $v'
              '${sumula.penaltis == null ? '' : ' · pênaltis ${sumula.penaltis!.mandante} x ${sumula.penaltis!.visitante}'}';
    avisos.add(
      AvisoPush(
        topico: Topicos.resultados(antes.id),
        titulo: 'Fim de jogo · $categoria',
        corpo: placar,
        rota: '/torcedor/jogos/${partida.id}',
      ),
    );
  }

  List<Partida> ordenar(Iterable<Partida> ps) => ps.toList()..sort((a, b) => a.inicio.compareTo(b.inicio));
  Set<String> geradas(List<Partida> partidas) => {
    for (final s in MotorDisciplinar(
      partidas: partidas,
      pagamentos: antes.pagamentos,
      decisoes: antes.decisoes,
      agora: agora,
      params: antes.parametros,
    ).suspensoes)
      if (s.partidaOrigemId == partida.id && s.motivo != MotivoSuspensao.decisao)
        '${s.pessoaId}|${s.motivo.name}',
  };
  final depois = ordenar([
    for (final p in antes.partidas)
      if (p.id != partida.id) p,
    partida,
  ]);
  final motor = MotorDisciplinar(
    partidas: depois,
    pagamentos: antes.pagamentos,
    decisoes: antes.decisoes,
    agora: agora,
    params: antes.parametros,
  );
  final jaAvisadas = geradas(ordenar(antes.partidas));
  for (final s in motor.suspensoes) {
    if (s.partidaOrigemId != partida.id || s.motivo == MotivoSuspensao.decisao) continue;
    if (jaAvisadas.contains('${s.pessoaId}|${s.motivo.name}')) continue;
    final nome = pessoas[s.pessoaId] ?? 'Jogador';
    final motivo = s.motivo == MotivoSuspensao.expulsao ? 'Cartão vermelho' : '3º cartão amarelo';
    final jogos = s.jogos == 1 ? '1 jogo' : '${s.jogos} jogos';
    avisos
      ..add(
        AvisoPush(
          topico: Topicos.pessoa(antes.id, s.pessoaId),
          titulo: 'Você está suspenso · $categoria',
          corpo: '$motivo em $confronto. Cumpre $jogos de suspensão.',
          rota: '/participante',
        ),
      )
      ..add(
        AvisoPush(
          topico: Topicos.dirigentes(antes.id, s.timeId),
          titulo: '$nome está suspenso',
          corpo: '$motivo em $confronto. Cumpre $jogos de suspensão.',
          rota: '/torcedor/suspensos',
        ),
      );
  }
  return avisos;
}
