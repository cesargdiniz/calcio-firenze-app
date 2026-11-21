// Gera a temporada de lançamento (times e elencos fictícios, dois turnos
// sorteados, sem resultados) das três categorias em JSON, no formato do
// Firestore, para o workflow semear.yml gravar. Rodar com
// TZ=America/Sao_Paulo: os horários são de Brasília.
import 'dart:convert';
import 'dart:io';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/firebase/mapeadores.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _json(Object? v) => switch (v) {
  Timestamp t => {'__ts': t.millisecondsSinceEpoch},
  Map<String, dynamic> m => {for (final e in m.entries) e.key: _json(e.value)},
  List<dynamic> l => [for (final x in l) _json(x)],
  _ => v,
};

void main() {
  test('semente das três categorias', () {
    expect(DateTime(2027, 3, 1, 20, 30).timeZoneOffset, const Duration(hours: -3));
    final saida = <String, Object?>{};
    for (final c in Categoria.values) {
      final d = montarCategoriaSorteada(c, demonstracao: false);
      expect(d.times, hasLength(c.times));
      saida[c.temporadaId] = {
        'times': {for (final t in d.times) t.id: _json(timeParaMapa(t))},
        'pessoas': {for (final p in d.pessoas) p.id: _json(pessoaParaMapa(p))},
        'partidas': {for (final p in d.partidas) p.id: _json(partidaParaMapa(p))},
      };
    }
    File(Platform.environment['SAIDA'] ?? 'semente.json').writeAsStringSync(jsonEncode(saida));
  });
}
