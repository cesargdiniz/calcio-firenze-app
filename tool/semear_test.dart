// Gera a temporada de lançamento (times e elencos fictícios, dois turnos
// sorteados, sem resultados) das três categorias em JSON, no formato do
// Firestore, para o workflow semear.yml gravar. Rodar com
// TZ=America/Sao_Paulo: os horários são de Brasília.
import 'dart:convert';
import 'dart:io';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/firebase/mapeadores.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_regras/calcio_regras.dart';
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
    // Dirigentes do Master (lista da Organização), sem apagar nada.
    const dirigentes = {
      'UDI': 'Wendell',
      'FOG': 'Netão',
      'BEN': 'The Boa',
      'SAS': 'Ferreira',
      'MIL': 'Teen',
      'INT': 'Carneiro',
      'COM': 'Junior',
      'SAM': 'Alex',
      'FIO': 'Jhovan',
      'JUV': 'Makoto',
    };
    saida[Categoria.master.temporadaId] = {
      'somenteGravar': true,
      'pessoas': {
        for (final e in dirigentes.entries)
          '${e.key.toLowerCase()}-dirigente': _json(
            pessoaParaMapa(
              Pessoa(
                id: '${e.key.toLowerCase()}-dirigente',
                nome: e.value,
                timeId: e.key,
                funcao: Funcao.atleta,
                dirigente: true,
              ),
            ),
          ),
      },
    };
    File(Platform.environment['SAIDA'] ?? 'semente.json').writeAsStringSync(jsonEncode(saida));
  });
}
