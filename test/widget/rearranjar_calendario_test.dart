import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/shared/layout/tela_larga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'apoio.dart';

const _super = Sessao(uid: 'cesar', email: 'cesargdiniz@gmail.com');

void main() {
  setUp(() => TelaLarga.forcar = true);
  tearDown(() {
    TelaLarga.forcar = null;
    AjustesCalendario.definir(const {});
  });

  Future<void> abrir(WidgetTester t, {Sessao? sessao}) => abrirApp(
    t,
    inicio: '/calendario/rearranjar',
    sessao: sessao,
    organizacao: {sessao?.uid ?? ''},
    tela: const Size(1440, 1000),
    densidade: 1,
  );

  testWidgets('superconta arrasta a abertura do Master para outro dia', (t) async {
    await abrir(t, sessao: _super);
    expect(find.text('Rearranjar calendário'), findsOneWidget);

    // Primeira etiqueta "M 2" do ano: sexta 22/01. Leva para a segunda 25/01.
    final etiqueta = find.text('M 2').first;
    final destino = find.text('25').first;
    final gesto = await t.startGesture(t.getCenter(etiqueta));
    await t.pump();
    await gesto.moveBy(const Offset(10, 10));
    await t.pump();
    await gesto.moveTo(t.getCenter(destino));
    await t.pump();
    await gesto.up();
    await t.pumpAndSettle();

    expect(AjustesCalendario.atual, {
      DateTime(2027, 1, 22, 20, 30): DateTime(2027, 1, 25, 20, 30),
      DateTime(2027, 1, 22, 21, 30): DateTime(2027, 1, 25, 21, 30),
    });
    expect(find.textContaining('M: 2 jogos de'), findsOneWidget);

    // Desfazer devolve os jogos ao dia oficial.
    await t.tap(find.text('Desfazer'));
    await t.pumpAndSettle();
    expect(AjustesCalendario.atual, isEmpty);
  });

  testWidgets('conta comum não rearranja', (t) async {
    await abrir(t, sessao: const Sessao(uid: 'org1', email: 'cesar@exemplo.com'));
    expect(find.text('Acesso restrito'), findsOneWidget);
  });
}
