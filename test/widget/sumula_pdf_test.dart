import 'dart:typed_data';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/shared/pdf/saida_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

class _SaidaGuardada implements SaidaPdf {
  Uint8List? bytes;
  String? nome;

  @override
  Future<void> abrir(Uint8List bytes, String nomeArquivo) async {
    this.bytes = bytes;
    nome = nomeArquivo;
  }
}

void main() {
  testWidgets('Organização gera a súmula para imprimir em PDF', (tester) async {
    final exemplo = montarTemporadaExemplo();
    final jogo = exemplo.partidas.firstWhere((p) => !p.encerrada);
    final saida = _SaidaGuardada();
    await abrirApp(
      tester,
      inicio: '/organizacao/jogos/${jogo.id}',
      sessao: _org,
      organizacao: {'org1'},
      saidaPdf: saida,
      dados: DadosTemporada(
        id: exemplo.id,
        nome: exemplo.nome,
        local: exemplo.local,
        times: exemplo.times,
        pessoas: exemplo.pessoas,
        partidas: exemplo.partidas,
        decisoes: exemplo.decisoes,
        relogio: exemplo.relogio,
      ),
    );
    final botao = find.ancestor(
      of: find.text('Súmula para imprimir (PDF)'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    // Gerar o PDF lê as fontes do disco, o que precisa de tempo real.
    await tester.runAsync(() async {
      (tester.widget(botao.first) as ButtonStyleButton).onPressed!();
      for (var i = 0; i < 100 && saida.bytes == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    expect(saida.nome, startsWith('sumula-'));
    expect(saida.nome, endsWith('.pdf'));
    expect(String.fromCharCodes(saida.bytes!.take(5)), '%PDF-');
  });
}
