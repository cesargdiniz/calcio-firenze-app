import 'package:calcio_firenze/shared/widgets/coluna_larga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<Size> tamanhoVisto(WidgetTester t, double largura) async {
    t.view.physicalSize = Size(largura, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late Size visto;
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => ColunaLarga(child: child!),
        home: Builder(
          builder: (context) {
            visto = MediaQuery.sizeOf(context);
            return const Text('tela');
          },
        ),
      ),
    );
    return visto;
  }

  testWidgets('no computador o app fica numa coluna de 700 px', (t) async {
    expect((await tamanhoVisto(t, 1440)).width, 700);
    expect(t.getSize(find.text('tela').hitTestable()).width, lessThanOrEqualTo(700));
  });

  testWidgets('no celular nada muda', (t) async {
    expect((await tamanhoVisto(t, 400)).width, 400);
  });
}
