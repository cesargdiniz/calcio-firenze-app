import 'package:calcio_firenze/domain/entities/campeoes.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/modules/campeoes/campeoes_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final foggia = campeoesDe(Categoria.master).firstWhere((t) => t.ano == 2023);

  test('Foggia 2023: goleiro e 2-2-1 titulares com número, oito reservas', () {
    expect(foggia.campeao, 'Foggia');
    expect(foggia.titulares.map((j) => j.nome), [
      'Toupeira', 'Cesar', 'Netão', 'Pedro Reis', 'Klelio', 'Daniel Diniz', //
    ]);
    expect(foggia.titularesDe(PosicaoCampeao.zagueiro), hasLength(2));
    expect(foggia.titularesDe(PosicaoCampeao.meia), hasLength(2));
    expect(foggia.titularesDe(PosicaoCampeao.ataque), hasLength(1));
    expect(foggia.reservas, hasLength(8));
    expect(foggia.titulares.map((j) => j.numero), [1, 3, 6, 7, 10, 9]);
  });

  testWidgets('tocar no campeão abre o campinho com titulares e reservas', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: ListaCampeoes(categoria: Categoria.master),
      ))),
    );
    // Só quem tem elenco cadastrado abre a escalação.
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    await t.tap(find.text('Foggia'));
    await t.pumpAndSettle();
    expect(find.text('Campeão Master 2023'), findsOneWidget);
    expect(find.text('Toupeira'), findsOneWidget);
    expect(find.text('Daniel Diniz'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Reservas (8)'), findsOneWidget);
    expect(find.textContaining('Cleuby'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
