import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

const _pedido = Usuario(
  uid: 'u1',
  email: 'rafael@exemplo.com',
  nome: 'Rafael Souza',
  vinculos: [Vinculo(
    temporadaId: 'master-2027',
    pessoaId: 'rafael-souza',
    timeId: 'SAM',
    papel: Papel.atleta,
  )],
);

void main() {
  testWidgets('conta que não é da Organização vê "acesso restrito" com o UID', (tester) async {
    await abrirApp(tester, inicio: '/organizacao', sessao: _org);
    expect(find.text('Esta conta não é da Organização'), findsOneWidget);
    expect(find.text('org1'), findsOneWidget);
  });

  testWidgets('Início da Organização mostra pedidos e elencos pendentes', (tester) async {
    await abrirApp(
      tester,
      inicio: '/organizacao',
      sessao: _org,
      organizacao: {'org1'},
      usuarios: {'u1': _pedido},
    );
    expect(find.text('1 pedido de vínculo aguardando'), findsOneWidget);
    expect(find.textContaining('Elencos ainda não importados'), findsOneWidget);
  });

  testWidgets('aprovar pedido de vínculo', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/pedidos',
      sessao: _org,
      organizacao: {'org1'},
      usuarios: {'u1': _pedido},
    );
    expect(find.text('RAFAEL SOUZA'), findsOneWidget);
    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum pedido'), findsOneWidget);
    final aprovados = await gestao.observarAprovados('master-2027').first;
    expect(aprovados.single.uid, 'u1');
  });

  testWidgets('importar elenco colado da planilha', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/elencos',
      sessao: _org,
      organizacao: {'org1'},
    );
    final linhas = StringBuffer();
    for (var n = 1; n <= 12; n++) {
      linhas.writeln(
        'SAM\t$n\tAtleta $n\t${n == 1 ? 'Goleiro' : 'Linha'}\t${n == 9 ? 'Dirigente' : 'Atleta'}',
      );
    }
    linhas.writeln('SAM\t\tHélio Ramos\t\tTécnico');
    await tester.enterText(find.byType(TextField), linhas.toString());
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    // Rola até o botão existir na lista e aciona direto (o foco simulado do
    // campo de texto atrapalha o toque nesta tela longa).
    final lista = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Conferir'), 200, scrollable: lista);
    tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Conferir')).onPressed!();
    await tester.pumpAndSettle();

    // Rola a lista direto até o fim: arrastar pelo meio da tela cairia no
    // campo de texto, que tem rolagem própria.
    Future<void> irAoFim() async {
      for (var i = 0; i < 3; i++) {
        final p = tester.state<ScrollableState>(lista).position;
        p.jumpTo(p.maxScrollExtent);
        await tester.pumpAndSettle();
      }
    }

    await irAoFim();
    expect(find.text('Pronto'), findsOneWidget);
    expect(find.text('12 atletas · 13 pessoas'), findsOneWidget);

    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Importar 1 time')).onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Elenco importado: Marinai Blu.'), findsOneWidget);
    final d = gestao.temporada.dados;
    expect(d.demonstracao, isFalse);
    expect(d.pessoas.where((p) => p.timeId == 'SAM'), hasLength(13));
  });

  testWidgets('editar a cor e o nome de um time', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/times/SAM',
      sessao: _org,
      organizacao: {'org1'},
    );
    await tester.enterText(find.byType(TextField), 'Marinai Blu Firenze');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(gestao.temporada.dados.times.firstWhere((t) => t.id == 'SAM').nome, 'Marinai Blu Firenze');
  });
}
