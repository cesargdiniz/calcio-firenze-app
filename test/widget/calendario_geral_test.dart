import 'package:calcio_firenze/shared/pdf/saida_pdf.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  testWidgets('calendário completo a partir de Jogos, com filtro por categoria', (tester) async {
    await abrirApp(tester, inicio: '/torcedor/jogos');
    await tester.tap(find.text('Calendário completo'));
    await tester.pumpAndSettle();
    expect(find.text('Todos os jogos do Calcio Firenze 2027'), findsOneWidget);
    // Todas: o primeiro jogo do ano é do Master.
    expect(find.text('Janeiro 2027'), findsOneWidget);

    await tester.tap(find.text('Livre'));
    await tester.pumpAndSettle();
    expect(find.text('Janeiro 2027'), findsNothing);
    expect(find.text('Fevereiro 2027'), findsOneWidget);
    expect(find.text('SÁB 27/02'), findsOneWidget);
    expect(find.text('Master'), findsOneWidget, reason: 'só o botão do filtro');

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Calendário completo'), findsOneWidget);
  });

  testWidgets('baixa o calendário anual em PDF', (tester) async {
    final saida = _PdfGuardado();
    await abrirApp(tester, inicio: '/calendario', saidaPdf: saida);
    await tester.runAsync(() async {
      await tester.tap(find.text('Baixar calendário anual (PDF)'));
      for (var i = 0; i < 40 && saida.nome == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    expect(saida.nome, 'Calcio_Firenze_2027_Calendario.pdf');
    expect(String.fromCharCodes(saida.bytes!.take(5)), '%PDF-');
  });
}

class _PdfGuardado implements SaidaPdf {
  Uint8List? bytes;
  String? nome;

  @override
  Future<void> abrir(Uint8List bytes, String nomeArquivo) async {
    this.bytes = bytes;
    nome = nomeArquivo;
  }
}
