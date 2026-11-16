import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

/// Abre a prévia e toca em "Compartilhar imagem". A captura da imagem roda
/// fora do relógio falso dos testes.
Future<void> _compartilhar(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('compartilhar')));
  await tester.pumpAndSettle();
  expect(find.text('Compartilhar imagem'), findsOneWidget);
  await tester.runAsync(() async {
    await tester.tap(find.text('Compartilhar imagem'));
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('classificação vira imagem para compartilhar', (tester) async {
    final saida = ImagensCompartilhadas();
    await abrirApp(tester, inicio: '/torcedor/tabela', saidaImagem: saida);
    await _compartilhar(tester);
    expect(saida.enviadas, hasLength(1));
    final (nome, legenda, bytes) = saida.enviadas.single;
    expect(nome, 'calcio-master-t1-classificacao.png');
    expect(legenda, 'Classificação · Master 2027 · 1º Turno');
    expect(bytes, greaterThan(1000));
  });

  testWidgets('estatística escolhida vira imagem', (tester) async {
    final saida = ImagensCompartilhadas();
    await abrirApp(tester, inicio: '/torcedor/tabela', saidaImagem: saida);
    await tester.tap(find.text('Estatísticas'));
    await tester.pumpAndSettle();
    await _compartilhar(tester);
    expect(saida.enviadas.single.$1, 'calcio-master-t1-artilharia.png');
  });

  testWidgets('suspensos e jogos da rodada também', (tester) async {
    final saida = ImagensCompartilhadas();
    await abrirApp(tester, inicio: '/torcedor/suspensos', saidaImagem: saida);
    await _compartilhar(tester);
    expect(saida.enviadas.single.$1, 'calcio-master-suspensos.png');
  });

  testWidgets('jogos da rodada viram imagem', (tester) async {
    final saida = ImagensCompartilhadas();
    await abrirApp(tester, inicio: '/torcedor/jogos', saidaImagem: saida);
    await _compartilhar(tester);
    expect(saida.enviadas.single.$1, 'calcio-master-t1-r3.png');
    expect(saida.enviadas.single.$2, 'Rodada 3 · Master 2027 · 1º Turno');
  });
}
