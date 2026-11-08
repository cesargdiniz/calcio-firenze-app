import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

Future<void> abrirComoTorcedor(WidgetTester tester) async {
  await abrirApp(tester);
  await tester.tap(find.text('Torcedor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash leva a "Como você quer entrar?"', (tester) async {
    await abrirApp(tester);
    expect(find.text('Como você quer entrar?'), findsOneWidget);
  });

  testWidgets('Início do Torcedor mostra aviso de suspensos e próximos jogos', (tester) async {
    await abrirComoTorcedor(tester);
    expect(find.text('3 suspensos para a Rodada 4'), findsOneWidget);
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);
  });

  testWidgets('aba Suspensos lista suspensos e pendurados', (tester) async {
    await abrirComoTorcedor(tester);
    await tester.tap(find.text('Suspensos').last);
    await tester.pumpAndSettle();
    expect(find.text('MARCOS LIMA'), findsOneWidget);
    expect(find.text('PAULO RIBEIRO'), findsOneWidget);
    expect(find.text('RICARDO ALVES'), findsOneWidget);
    // Marcos (vermelho) e Paulo (3 amarelos) voltam na Rodada 5; Ricardo
    // (decisão de 2 jogos) só na Rodada 6.
    expect(find.text('Volta na Rodada 5'), findsNWidgets(2));
    expect(find.text('Volta na Rodada 6'), findsOneWidget);

    await tester.tap(find.text('Pendurados (2)'));
    await tester.pumpAndSettle();
    expect(find.text('FÁBIO COSTA'), findsOneWidget);
  });

  testWidgets('aba Tabela mostra os 10 times', (tester) async {
    await abrirComoTorcedor(tester);
    await tester.tap(find.text('Tabela'));
    await tester.pumpAndSettle();
    expect(find.text('Classificação'), findsOneWidget);
    for (final nome in ['Inter', 'Sassuolo', 'Casale']) {
      expect(find.textContaining(nome), findsWidgets);
    }
  });
}
