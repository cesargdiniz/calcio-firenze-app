import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _sessao = Sessao(uid: 'u1', email: 'rafael@exemplo.com');

Usuario _rafael(StatusVinculo status, {Papel papel = Papel.atleta}) => Usuario(
  uid: 'u1',
  email: 'rafael@exemplo.com',
  nome: 'Rafael Souza',
  vinculo: Vinculo(
    temporadaId: 'master-2027',
    pessoaId: papel == Papel.tecnico ? 'helio-ramos' : 'rafael-souza',
    timeId: 'SAM',
    papel: papel,
    status: status,
  ),
);

void main() {
  testWidgets('sem login: Participante abre a tela de login', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Participante'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar como Participante'), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Receber link por e-mail'), findsOneWidget);
  });

  testWidgets('link por e-mail: valida o e-mail e mostra "Confira seu e-mail"', (tester) async {
    await abrirApp(tester, inicio: '/participante');
    await tester.tap(find.text('Receber link por e-mail'));
    await tester.pumpAndSettle();
    expect(find.text('Digite um e-mail válido.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rafael@exemplo.com');
    await tester.tap(find.text('Receber link por e-mail'));
    await tester.pumpAndSettle();
    expect(find.text('Confira seu e-mail'), findsOneWidget);
  });

  testWidgets('login com Google leva ao vínculo; pedido fica pendente', (tester) async {
    await abrirApp(tester, inicio: '/participante');
    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();
    expect(find.text('Vincular ao elenco'), findsOneWidget);

    await tester.tap(find.text('Sampdoria'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('RAFAEL SOUZA'), 200);
    await tester.ensureVisible(find.text('RAFAEL SOUZA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RAFAEL SOUZA'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Enviar para aprovação'), 200);
    await tester.ensureVisible(find.text('Enviar para aprovação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar para aprovação'));
    await tester.pumpAndSettle();

    expect(find.text('Pedido enviado'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('aprovado: Início mostra situação e a pendência de R\$ 30,00', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante',
      sessao: _sessao,
      usuarios: {'u1': _rafael(StatusVinculo.aprovado)},
    );
    expect(find.text('Olá, Rafael'), findsOneWidget);
    expect(find.text('Atleta · Sampdoria'), findsOneWidget);
    expect(find.text('1 amarelo'), findsOneWidget);
    expect(find.text('Liberado'), findsOneWidget);
    expect(find.text('Cartão amarelo'), findsOneWidget);
    expect(find.textContaining('R\$ 30,00'), findsWidgets);
  });

  testWidgets('atleta não vê pendências do time; técnico vê', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante/time',
      sessao: _sessao,
      usuarios: {'u1': _rafael(StatusVinculo.aprovado)},
    );
    expect(find.text('Elenco'), findsOneWidget);
    expect(find.text('Pendências do time'), findsNothing);
  });

  testWidgets('técnico vê as pendências do time', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante/time',
      sessao: _sessao,
      usuarios: {'u1': _rafael(StatusVinculo.aprovado, papel: Papel.tecnico)},
    );
    expect(find.text('Pendências do time'), findsOneWidget);
  });

  testWidgets('sino mostra quantos avisos há e abre a lista', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante',
      sessao: _sessao,
      usuarios: {'u1': _rafael(StatusVinculo.aprovado)},
    );
    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
    await tester.tap(find.byTooltip('Avisos (1)'));
    await tester.pumpAndSettle();

    expect(find.text('1 aviso'), findsOneWidget);
    expect(find.textContaining('Pague R\$ 30,00 até '), findsOneWidget);
  });

  testWidgets('recusado: volta ao vínculo com aviso', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante',
      sessao: _sessao,
      usuarios: {'u1': _rafael(StatusVinculo.recusado)},
    );
    expect(find.text('Vincular ao elenco'), findsOneWidget);
    expect(find.textContaining('não foi aprovado'), findsOneWidget);
  });
}
