import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/shared/layout/lista_e_detalhe.dart';
import 'package:calcio_firenze/shared/layout/menu_lateral.dart';
import 'package:calcio_firenze/shared/layout/tela_larga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'apoio.dart';

const _computador = Size(1440, 900);
const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');
const _sessao = Sessao(uid: 'u1', email: 'rafael@exemplo.com');
final _rafael = Usuario(
  uid: 'u1',
  email: 'rafael@exemplo.com',
  nome: 'Rafael Souza',
  vinculos: [
    Vinculo(
      temporadaId: 'master-2027',
      pessoaId: 'rafael-souza',
      timeId: 'SAM',
      papel: Papel.atleta,
      status: StatusVinculo.aprovado,
    ),
  ],
);

void main() {
  // Os testes rodam fora do navegador: liga o layout de computador à força.
  setUp(() => TelaLarga.forcar = true);
  tearDown(() => TelaLarga.forcar = null);

  Future<void> abrirNoComputador(
    WidgetTester t,
    String rota, {
    Sessao? sessao,
    Set<String> organizacao = const {},
    Map<String, Usuario>? usuarios,
  }) async {
    await abrirApp(
      t,
      inicio: rota,
      sessao: sessao,
      organizacao: organizacao,
      usuarios: usuarios,
      dados: montarTemporadaExemplo(demonstracao: false),
      tela: _computador,
      densidade: 1,
    );
    expect(t.takeException(), isNull, reason: rota);
  }

  testWidgets('torcedor: menu lateral em todas as telas', (t) async {
    for (final rota in const [
      '/torcedor',
      '/torcedor/jogos',
      '/torcedor/tabela',
      '/torcedor/suspensos',
      '/torcedor/campeoes',
      '/torcedor/calendario',
    ]) {
      await abrirNoComputador(t, rota);
      expect(find.byType(MenuLateral), findsOneWidget, reason: rota);
      expect(find.byType(NavigationBar), findsNothing, reason: rota);
    }
  });

  testWidgets('início: próximos jogos e classificação lado a lado', (t) async {
    await abrirNoComputador(t, '/torcedor');
    expect(find.byType(PaginaLarga), findsOneWidget);
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);
    expect(find.text('Classificação · 1º Turno'), findsOneWidget);
  });

  testWidgets('suspensos: aba de histórico', (t) async {
    await abrirNoComputador(t, '/torcedor/suspensos');
    await t.tap(find.textContaining('Histórico ('));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('menu troca de tela e de categoria', (t) async {
    await abrirNoComputador(t, '/torcedor');
    await t.tap(find.descendant(of: find.byType(MenuLateral), matching: find.text('Tabela')));
    await t.pumpAndSettle();
    expect(find.text('Classificação'), findsWidgets);
    await t.tap(find.byKey(const Key('seletor-categoria')));
    await t.pumpAndSettle();
    expect(find.text('Livre'), findsOneWidget);
    await t.tap(find.text('Livre'));
    await t.pumpAndSettle();
    expect(find.text('LIVRE'), findsOneWidget);
  });

  testWidgets('organização: jogos e súmula lado a lado', (t) async {
    await abrirNoComputador(t, '/organizacao/jogos', sessao: _org, organizacao: {'org1'});
    expect(find.byType(MenuLateral), findsOneWidget);
    expect(find.byType(ListaEDetalhe), findsOneWidget);
    expect(find.byType(DetalheVazio), findsOneWidget);
    for (final rota in const [
      '/organizacao/disciplina',
      '/organizacao/gestao',
      '/organizacao/gestao/parametros',
      '/organizacao/tabela',
    ]) {
      await abrirNoComputador(t, rota, sessao: _org, organizacao: {'org1'});
      expect(find.byType(MenuLateral), findsOneWidget, reason: rota);
    }
  });

  testWidgets('participante: menu lateral', (t) async {
    for (final rota in const ['/participante', '/participante/time', '/participante/perfil']) {
      await abrirNoComputador(t, rota, sessao: _sessao, usuarios: {'u1': _rafael});
      expect(find.byType(MenuLateral), findsOneWidget, reason: rota);
    }
  });

  testWidgets('no celular nada muda, mesmo com o layout ligado', (t) async {
    await abrirApp(t, inicio: '/torcedor');
    expect(find.byType(MenuLateral), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
