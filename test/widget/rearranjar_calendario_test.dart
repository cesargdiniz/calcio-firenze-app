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

  testWidgets('na edição o mês anda de um em um', (t) async {
    await abrir(t, sessao: _super);
    expect(find.text('Janeiro e Fevereiro de 2027'), findsOneWidget);
    await t.tap(find.byTooltip('Próximo mês'));
    await t.pumpAndSettle();
    expect(find.text('Fevereiro e Março de 2027'), findsOneWidget);
    await t.tap(find.byTooltip('Mês anterior'));
    await t.pumpAndSettle();
    expect(find.text('Janeiro e Fevereiro de 2027'), findsOneWidget);
  });

  testWidgets('seta para baixo mostra quatro meses', (t) async {
    await abrir(t, sessao: _super);
    expect(find.text('Março 2027'), findsNothing);
    await t.ensureVisible(find.byTooltip('Ver mais 2 meses'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Ver mais 2 meses'));
    await t.pumpAndSettle();
    expect(find.text('Janeiro a Abril de 2027'), findsOneWidget);
    expect(find.text('Março 2027'), findsOneWidget);
    expect(find.text('Abril 2027'), findsOneWidget);
  });

  testWidgets('desmembrar um dia: uma etiqueta por jogo', (t) async {
    await abrir(t, sessao: _super);
    // Sábado 23/01: 3 jogos do Master (a primeira etiqueta "M 3" é a da legenda).
    await t.tap(find.text('M 3').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Desmembrar'));
    await t.pumpAndSettle();
    expect(find.text('M 17:00'), findsOneWidget);
    expect(find.text('M 18:00'), findsOneWidget);
    expect(find.text('M 19:00'), findsOneWidget);

    // Só o jogo das 19h vai para quinta 25/02 (fevereiro, ao lado: a grade de
    // janeiro cresce com as etiquetas separadas).
    final gesto = await t.startGesture(t.getCenter(find.text('M 19:00')));
    await t.pump();
    await gesto.moveBy(const Offset(10, 10));
    await t.pump();
    await gesto.moveTo(t.getCenter(find.text('25').last));
    await t.pump();
    await gesto.up();
    await t.pumpAndSettle();
    expect(AjustesCalendario.atual, {DateTime(2027, 1, 23, 19): DateTime(2027, 2, 25, 20, 30)});
  });

  testWidgets('conta comum não rearranja', (t) async {
    await abrir(t, sessao: const Sessao(uid: 'org1', email: 'cesar@exemplo.com'));
    expect(find.text('Acesso restrito'), findsOneWidget);
  });
}
