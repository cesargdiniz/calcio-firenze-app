import '../domain/entities/campeoes.dart';

/// Título como mapa (Firestore), e de volta.
Map<String, Object?> tituloParaMapa(TituloTemporada t) => {
  'ano': t.ano,
  'campeao': t.campeao,
  'cor': ?t.cor,
  'corNumero': ?t.corNumero,
  'elenco': [
    for (final j in t.elenco)
      {
        'nome': j.nome,
        'posicao': ?j.posicao?.name,
        'titular': j.titular,
        'numero': ?j.numero,
        'curto': ?j.curto,
      },
  ],
  'premios': [
    for (final p in t.premios) {'premio': p.premio, 'nome': p.nome, 'time': ?p.time},
  ],
};

TituloTemporada tituloDeMapa(Map<String, Object?> m) {
  final elenco = (m['elenco'] as List?) ?? const [];
  final premios = (m['premios'] as List?) ?? const [];
  return TituloTemporada(
    (m['ano']! as num).toInt(),
    m['campeao']! as String,
    cor: (m['cor'] as num?)?.toInt(),
    corNumero: (m['corNumero'] as num?)?.toInt(),
    elenco: [
      for (final e in elenco.cast<Map<String, Object?>>())
        JogadorCampeao(
          e['nome']! as String,
          PosicaoCampeao.values.where((p) => p.name == e['posicao']).firstOrNull,
          titular: e['titular'] == true,
          numero: (e['numero'] as num?)?.toInt(),
          curto: e['curto'] as String?,
        ),
    ],
    premios: [
      for (final p in premios.cast<Map<String, Object?>>())
        PremioTemporada(p['premio']! as String, p['nome']! as String, time: p['time'] as String?),
    ],
  );
}
