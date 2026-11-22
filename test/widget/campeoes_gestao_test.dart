import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

void main() {
  Future<void> abrir(WidgetTester t, String rota) => abrirApp(
    t,
    inicio: rota,
    sessao: _org,
    organizacao: {'org1'},
    dados: montarTemporadaExemplo(demonstracao: false),
  );

  testWidgets('Gestão lista os campeões da categoria', (t) async {
    await abrir(t, '/organizacao/gestao');
    await t.scrollUntilVisible(find.text('Campeões'), 200);
    await t.tap(find.text('Campeões'));
    await t.pumpAndSettle();
    expect(find.text('2025 · Inter'), findsOneWidget);
    expect(find.text('Novo campeão'), findsOneWidget);
  });

  testWidgets('cadastrar um campeão novo aparece na lista', (t) async {
    await abrir(t, '/organizacao/gestao/campeoes/novo');
    await t.enterText(find.byKey(const Key('campeao-ano')), '2026');
    await t.enterText(find.byKey(const Key('campeao-time')), 'Teste FC');
    await t.scrollUntilVisible(find.byKey(const Key('adicionar-jogador')), 200);
    await t.tap(find.byKey(const Key('adicionar-jogador')));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Nome').first, 'Fulano');
    await t.scrollUntilVisible(find.byKey(const Key('salvar-campeao')), 200);
    await t.tap(find.byKey(const Key('salvar-campeao')));
    await t.pumpAndSettle();
    expect(find.text('2026 · Teste FC'), findsOneWidget);
    expect(find.text('1 no elenco · sem titulares'), findsOneWidget);
  });

  testWidgets('não salva com ano repetido', (t) async {
    await abrir(t, '/organizacao/gestao/campeoes/novo');
    await t.enterText(find.byKey(const Key('campeao-ano')), '2025');
    await t.enterText(find.byKey(const Key('campeao-time')), 'Outro');
    await t.scrollUntilVisible(find.byKey(const Key('salvar-campeao')), 200);
    await t.tap(find.byKey(const Key('salvar-campeao')));
    await t.pumpAndSettle();
    expect(find.text('Já existe um campeão em 2025.'), findsOneWidget);
  });

  testWidgets('editar um título existente abre com o elenco preenchido', (t) async {
    await abrir(t, '/organizacao/gestao/campeoes/2023');
    expect(find.text('Editar campeão'), findsOneWidget);
    expect(find.text('Foggia'), findsWidgets);
    expect(
      find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Toupeira'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });
}
