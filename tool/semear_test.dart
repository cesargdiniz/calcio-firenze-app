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
    // Master volta a zero com os 10 times reais (Livre e Super Master ficam).
    const reais = {
      'INT': ('Inter', 'INT'),
      'FIO': ('Fiorentina', 'FIO'),
      'SAM': ('Sampdoria', 'SAM'),
      'FOG': ('Foggia', 'FOG'),
      'BEN': ('Benevento', 'BEN'),
      'MIL': ('Milan', 'MIL'),
      'UDI': ('Udinese', 'UDI'),
      'COM': ('Como 1907', 'COM'),
      'JUV': ('Juventus', 'JUV'),
      'SAS': ('Sassuolo', 'SAS'),
    };
    saida[Categoria.master.temporadaId] = {
      'times': {
        for (final t in timesMaster2027)
          t.id: {..._json(timeParaMapa(t))! as Map<String, dynamic>, 'nome': reais[t.id]!.$1, 'sigla': reais[t.id]!.$2},
      },
      'pessoas': <String, Object?>{},
      'partidas': <String, Object?>{},
    };
    File(Platform.environment['SAIDA'] ?? 'semente.json').writeAsStringSync(jsonEncode(saida));
  });
}
