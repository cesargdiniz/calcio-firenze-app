import 'package:calcio_regras/calcio_regras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/temporada.dart';

T _porNome<T extends Enum>(List<T> valores, Object? nome, T padrao) =>
    valores.where((e) => e.name == nome).firstOrNull ?? padrao;

Map<String, dynamic> timeParaMapa(Time t) => {'nome': t.nome, 'sigla': t.sigla, 'cor': t.cor};

Time timeDeMapa(String id, Map<String, dynamic> m) => Time(
  id: id,
  nome: m['nome'] as String? ?? id,
  sigla: m['sigla'] as String? ?? id,
  cor: (m['cor'] as num?)?.toInt() ?? 0xFF6E6E6E,
  escudoUrl: m['escudoUrl'] as String?,
);

Map<String, dynamic> pessoaParaMapa(Pessoa p) => {
  'nome': p.nome,
  'timeId': p.timeId,
  'funcao': p.funcao.name,
  'numero': p.numero,
  'goleiro': p.goleiro,
  'dirigente': p.dirigente,
  'saiuEm': p.saiuEm == null ? null : Timestamp.fromDate(p.saiuEm!),
};

Pessoa pessoaDeMapa(String id, Map<String, dynamic> m) => Pessoa(
  id: id,
  nome: m['nome'] as String? ?? '',
  timeId: m['timeId'] as String? ?? '',
  funcao: _porNome(Funcao.values, m['funcao'], Funcao.atleta),
  numero: (m['numero'] as num?)?.toInt(),
  goleiro: m['goleiro'] == true,
  dirigente: m['dirigente'] == true,
  saiuEm: (m['saiuEm'] as Timestamp?)?.toDate(),
);

Map<String, dynamic> sumulaParaMapa(Sumula s) => {
  'golsMandante': s.golsMandante,
  'golsVisitante': s.golsVisitante,
  'ausenteWo': s.ausenteWo,
  'penaltis': s.penaltis == null
      ? null
      : {'mandante': s.penaltis!.mandante, 'visitante': s.penaltis!.visitante},
  'gols': [
    for (final g in s.gols)
      {'timeId': g.timeId, 'autorId': g.autorId, 'contra': g.contra, 'tempo': g.tempo},
  ],
  'cartoes': [
    for (final c in s.cartoes)
      {'pessoaId': c.pessoaId, 'timeId': c.timeId, 'funcao': c.funcao.name, 'tipo': c.tipo.name},
  ],
  'timesSemPontos': s.timesSemPontos.toList(),
  'observacoes': s.observacoes,
  'youtubeUrl': s.youtubeUrl,
};

Sumula sumulaDeMapa(Map<String, dynamic> m) {
  final pen = m['penaltis'] as Map<String, dynamic>?;
  int n(Object? v) => (v as num?)?.toInt() ?? 0;
  return Sumula(
    golsMandante: n(m['golsMandante']),
    golsVisitante: n(m['golsVisitante']),
    ausenteWo: m['ausenteWo'] as String?,
    penaltis: pen == null ? null : Penaltis(n(pen['mandante']), n(pen['visitante'])),
    gols: [
      for (final g in (m['gols'] as List? ?? const []).cast<Map<String, dynamic>>())
        Gol(
          timeId: g['timeId'] as String,
          autorId: g['autorId'] as String?,
          contra: g['contra'] == true,
          tempo: n(g['tempo']) == 0 ? 1 : n(g['tempo']),
        ),
    ],
    cartoes: [
      for (final c in (m['cartoes'] as List? ?? const []).cast<Map<String, dynamic>>())
        CartaoAplicado(
          pessoaId: c['pessoaId'] as String,
          timeId: c['timeId'] as String,
          funcao: _porNome(Funcao.values, c['funcao'], Funcao.atleta),
          tipo: _porNome(TipoCartao.values, c['tipo'], TipoCartao.amarelo),
        ),
    ],
    timesSemPontos: {...(m['timesSemPontos'] as List? ?? const []).cast<String>()},
    observacoes: m['observacoes'] as String?,
    youtubeUrl: m['youtubeUrl'] as String?,
  );
}

Map<String, dynamic> partidaParaMapa(Partida p) => {
  'turno': p.turno,
  'fase': p.fase.name,
  'rodada': p.rodada,
  'mandanteId': p.mandanteId,
  'visitanteId': p.visitanteId,
  'inicio': Timestamp.fromDate(p.inicio),
  'local': p.local,
  'sumula': p.sumula == null ? null : sumulaParaMapa(p.sumula!),
};

Partida partidaDeMapa(String id, Map<String, dynamic> m) {
  final s = m['sumula'] as Map<String, dynamic>?;
  return Partida(
    id: id,
    turno: (m['turno'] as num?)?.toInt() ?? 1,
    fase: _porNome(Fase.values, m['fase'], Fase.classificatoria),
    rodada: (m['rodada'] as num?)?.toInt(),
    mandanteId: m['mandanteId'] as String,
    visitanteId: m['visitanteId'] as String,
    inicio: (m['inicio'] as Timestamp).toDate(),
    local: m['local'] as String?,
    sumula: s == null ? null : sumulaDeMapa(s),
  );
}

Map<String, dynamic> decisaoParaMapa(DecisaoDisciplinar d) => {
  'pessoaId': d.pessoaId,
  'timeId': d.timeId,
  'partidaOrigemId': d.partidaOrigemId,
  'jogosSuspensao': d.jogosSuspensao,
  'multa': d.multa,
  'motivo': d.motivo,
  'fundamento': d.fundamento,
  'votacao': d.votacao,
};

DecisaoDisciplinar decisaoDeMapa(String id, Map<String, dynamic> m) => DecisaoDisciplinar(
  id: id,
  pessoaId: m['pessoaId'] as String? ?? '',
  timeId: m['timeId'] as String? ?? '',
  partidaOrigemId: m['partidaOrigemId'] as String? ?? '',
  jogosSuspensao: (m['jogosSuspensao'] as num?)?.toInt() ?? 0,
  multa: (m['multa'] as num?)?.toInt() ?? 0,
  motivo: m['motivo'] as String? ?? '',
  fundamento: m['fundamento'] as String?,
  votacao: m['votacao'] as String?,
);

Map<String, dynamic> parametrosParaMapa(Parametros p) => {
  'pontosVitoria': p.pontosVitoria,
  'pontosEmpate': p.pontosEmpate,
  'pontosDerrota': p.pontosDerrota,
  'valorAmarelo': p.valorAmarelo,
  'valorVermelho': p.valorVermelho,
  'amarelosParaSuspensao': p.amarelosParaSuspensao,
  'jogosPorExpulsao': p.jogosPorExpulsao,
  'prazoQuitacaoHoras': p.prazoQuitacao.inHours,
  'golsWo': p.golsWo,
  'deducaoWo': p.deducaoWo,
  'classificadosMataMata': p.classificadosMataMata,
  'rebaixados': p.rebaixados,
};

/// Campos ausentes ficam com o valor do regulamento de 2027.
Parametros parametrosDeMapa(Map<String, dynamic>? m) {
  const r = Parametros.master2027;
  if (m == null) return r;
  int n(String chave, int padrao) => (m[chave] as num?)?.toInt() ?? padrao;
  return Parametros(
    pontosVitoria: n('pontosVitoria', r.pontosVitoria),
    pontosEmpate: n('pontosEmpate', r.pontosEmpate),
    pontosDerrota: n('pontosDerrota', r.pontosDerrota),
    valorAmarelo: n('valorAmarelo', r.valorAmarelo),
    valorVermelho: n('valorVermelho', r.valorVermelho),
    amarelosParaSuspensao: n('amarelosParaSuspensao', r.amarelosParaSuspensao),
    jogosPorExpulsao: n('jogosPorExpulsao', r.jogosPorExpulsao),
    prazoQuitacao: Duration(hours: n('prazoQuitacaoHoras', r.prazoQuitacao.inHours)),
    golsWo: n('golsWo', r.golsWo),
    deducaoWo: n('deducaoWo', r.deducaoWo),
    classificadosMataMata: n('classificadosMataMata', r.classificadosMataMata),
    rebaixados: n('rebaixados', r.rebaixados),
  );
}

Map<String, dynamic> movimentacaoParaMapa(Movimentacao m) => {
  'tipo': m.tipo.name,
  'pessoaId': m.pessoaId,
  'timeId': m.timeId,
  'nome': m.nome,
  'data': Timestamp.fromDate(m.data),
  'laudo': m.laudo,
  'motivoTroca': m.motivoTroca?.name,
  'substitutoId': m.substitutoId,
  'substitutoNome': m.substitutoNome,
  'observacoes': m.observacoes,
};

Movimentacao movimentacaoDeMapa(String id, Map<String, dynamic> m) => Movimentacao(
  id: id,
  tipo: _porNome(TipoMovimentacao.values, m['tipo'], TipoMovimentacao.desligamento),
  pessoaId: m['pessoaId'] as String? ?? '',
  timeId: m['timeId'] as String? ?? '',
  nome: m['nome'] as String? ?? '',
  data: (m['data'] as Timestamp?)?.toDate() ?? DateTime(2027),
  laudo: m['laudo'] == true,
  motivoTroca: MotivoTroca.values.where((e) => e.name == m['motivoTroca']).firstOrNull,
  substitutoId: m['substitutoId'] as String?,
  substitutoNome: m['substitutoNome'] as String?,
  observacoes: m['observacoes'] as String?,
);
