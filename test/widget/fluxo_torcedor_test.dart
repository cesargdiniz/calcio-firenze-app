import 'package:calcio_firenze/app/app.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> abrirComoTorcedor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(414 * 3, 896 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    CalcioApp(
      repository: TemporadaExemploRepository(),
      montarPainel: MontarPainel(agora: () => TemporadaExemploRepository.agora),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1300)); // Splash
  await tester.pumpAndSettle();
  await tester.tap(find.text('Torcedor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash leva a "Como você quer entrar?"', (tester) async {
    await tester.pumpWidget(
      CalcioApp(
        repository: TemporadaExemploRepository(),
        montarPainel: MontarPainel(agora: () => TemporadaExemploRepository.agora),
      ),
    );
    expect(find.text('Como você quer entrar?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
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
    expect(find.text('Volta na Rodada 5'), findsOneWidget);

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
