import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

const _pedido = Usuario(
  uid: 'u1',
  email: 'rafael@exemplo.com',
  nome: 'Rafael Souza',
  vinculo: Vinculo(
    temporadaId: 'master-2027',
    pessoaId: 'rafael-souza',
    timeId: 'SAM',
    papel: Papel.atleta,
  ),
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
    final aprovados = await gestao.observarAprovados().first;
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
    await tester.ensureVisible(find.text('Conferir'));
    await tester.tap(find.text('Conferir'));
    await tester.pumpAndSettle();

    expect(find.text('Pronto'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Importar 1 time'), 200);
    await tester.ensureVisible(find.text('Importar 1 time'));
    await tester.tap(find.text('Importar 1 time'));
    await tester.pumpAndSettle();

    expect(find.text('Elenco importado: Sampdoria.'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField), 'Sampdoria Firenze');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(gestao.temporada.dados.times.firstWhere((t) => t.id == 'SAM').nome, 'Sampdoria Firenze');
  });
}
