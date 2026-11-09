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
};

Pessoa pessoaDeMapa(String id, Map<String, dynamic> m) => Pessoa(
  id: id,
  nome: m['nome'] as String? ?? '',
  timeId: m['timeId'] as String? ?? '',
  funcao: _porNome(Funcao.values, m['funcao'], Funcao.atleta),
  numero: (m['numero'] as num?)?.toInt(),
  goleiro: m['goleiro'] == true,
  dirigente: m['dirigente'] == true,
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
