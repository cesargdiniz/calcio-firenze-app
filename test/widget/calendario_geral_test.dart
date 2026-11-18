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
}
