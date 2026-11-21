import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'livre@exemplo.com');
const _marcos = Sessao(uid: 'u1', email: 'marcos@exemplo.com');

/// A temporada de exemplo copiada para outra categoria (mesmos elencos).
DadosTemporada _exemploEm(Categoria c) {
  final e = montarTemporadaExemplo();
  return DadosTemporada(
    id: c.temporadaId,
    nome: c.titulo,
    local: e.local,
    times: e.times,
    pessoas: e.pessoas,
    partidas: e.partidas,
    decisoes: e.decisoes,
    relogio: e.relogio,
  );
}

Vinculo _vinculo(Categoria c) => Vinculo(
  temporadaId: c.temporadaId,
  pessoaId: 'marcos-lima',
  timeId: 'UDI',
  papel: Papel.atleta,
  status: StatusVinculo.aprovado,
);

Future<void> _trocarPara(WidgetTester tester, String nome) async {
  await tester.tap(find.byKey(const Key('seletor-categoria')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nome).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('primeira abertura: escolhe a categoria antes de ver os jogos', (tester) async {
    await abrirApp(tester, inicio: '/torcedor', categoria: null);
    expect(find.text('Qual categoria você quer acompanhar?'), findsOneWidget);
    expect(find.text('8 times · temporada 2027'), findsOneWidget);

    await tester.tap(find.text('Livre'));
    await tester.pumpAndSettle();
    expect(find.text('LIVRE'), findsOneWidget);
    expect(find.text('Confrontos ainda não sorteados'), findsOneWidget);
  });

  testWidgets('a barra do topo troca a categoria do Torcedor', (tester) async {
    await abrirApp(tester, inicio: '/torcedor');
    expect(find.text('MASTER'), findsOneWidget);
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);

    await _trocarPara(tester, 'Super Master');
    expect(find.text('SUPER MASTER'), findsOneWidget);
    expect(find.text('Confrontos ainda não sorteados'), findsOneWidget);

    await _trocarPara(tester, 'Master');
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);
  });

  testWidgets('Organização da Livre só vê a Livre e cadastra os times dela', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/times',
      sessao: _org,
      organizacaoPorCategoria: {
        'org1': [Categoria.livre],
      },
    );
    // A conta organiza uma categoria só: a barra não abre lista.
    expect(find.text('LIVRE'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
    expect(find.text('0 de 8 clubes · Livre · Temporada 2027'), findsOneWidget);

    await acionar(tester, 'Adicionar time');
    await tester.enterText(find.widgetWithText(TextField, 'Nome do clube'), 'Real Firenze');
    await tester.enterText(find.widgetWithText(TextField, 'Sigla (não muda depois)'), 'rfi');
    await tester.pumpAndSettle();
    await acionar(tester, 'Adicionar time');

    final livre = gestao.temporada.daTemporada('livre-2027');
    expect(livre.times.single.id, 'RFI');
    expect(livre.times.single.nome, 'Real Firenze');
    expect(gestao.temporada.dados.times, hasLength(10), reason: 'o Master não muda');
  });

  testWidgets('sem vínculo na categoria, o Participante pode pedir ou voltar à dele', (
    tester,
  ) async {
    await abrirApp(
      tester,
      inicio: '/participante',
      sessao: _marcos,
      categoria: 'livre-2027',
      usuarios: {
        'u1': Usuario(
          uid: 'u1',
          email: 'marcos@exemplo.com',
          nome: 'Marcos Lima',
          vinculos: [_vinculo(Categoria.master)],
        ),
      },
    );
    expect(find.text('Vincular ao elenco'), findsOneWidget);
    expect(find.text('Ver Master, onde você já tem vínculo'), findsOneWidget);

    await tester.tap(find.text('Ver Master, onde você já tem vínculo'));
    await tester.pumpAndSettle();
    expect(find.text('MASTER'), findsOneWidget);
    expect(find.text('Vincular ao elenco'), findsNothing);
  });

  testWidgets('avisos juntam as categorias em que o atleta joga', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante/avisos',
      sessao: _marcos,
      outrasTemporadas: [_exemploEm(Categoria.livre)],
      usuarios: {
        'u1': Usuario(
          uid: 'u1',
          email: 'marcos@exemplo.com',
          nome: 'Marcos Lima',
          vinculos: [_vinculo(Categoria.master), _vinculo(Categoria.livre)],
        ),
      },
    );
    expect(find.textContaining('Você está suspenso'), findsNWidgets(2));
    expect(find.textContaining('Livre · Você está suspenso'), findsOneWidget);
  });

  testWidgets('Master mostra as datas reservadas da Copa em Jogos', (tester) async {
    await abrirApp(tester, inicio: '/torcedor/jogos');
    await tester.ensureVisible(find.text('Copa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copa'));
    await tester.pumpAndSettle();
    expect(find.text('Copa Master · datas reservadas'), findsOneWidget);
    expect(find.text('Preliminar'), findsOneWidget);
    expect(find.text('Seg 24/05 · 20:30 e 21:30 · 2 jogos'), findsOneWidget);

    await _trocarPara(tester, 'Livre');
    expect(find.text('Copa'), findsNothing);
  });

  testWidgets('Jogos separa turnos e eliminatórias, com as datas reservadas', (tester) async {
    await abrirApp(tester, inicio: '/torcedor/jogos');
    for (final t in ['1º Turno', 'Eliminatórias 1ºT', '2º Turno', 'Eliminatórias 2ºT']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.text('Eliminatórias 2ºT'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminatórias do 2º turno · datas reservadas'), findsOneWidget);
    expect(find.text('Quartas de final'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Grande final (se necessária)'), 200);
    expect(find.text('Grande final (se necessária)'), findsOneWidget);
  });

  testWidgets('troféu do Início abre os campeões da categoria', (tester) async {
    await abrirApp(tester, inicio: '/torcedor');
    await tester.tap(find.byTooltip('Campeões'));
    await tester.pumpAndSettle();
    expect(find.text('Calcio Firenze · Master'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2021'), findsOneWidget);
  });

  testWidgets('toque no escudo da Tabela abre a tela do time', (tester) async {
    await abrirApp(tester, inicio: '/torcedor/tabela');
    await tester.tap(find.bySemanticsLabel('Ver Leoni Azzurri').first);
    await tester.pumpAndSettle();
    expect(find.text('Destaques da temporada'), findsOneWidget);
    expect(find.textContaining('campeão (2025)'), findsOneWidget);
    expect(find.text('Artilheiro'), findsOneWidget);
    expect(find.text('Mais indisciplinado'), findsOneWidget);
  });

  testWidgets('organizador informa a categoria no primeiro acesso e fica só nela', (
    tester,
  ) async {
    await abrirApp(
      tester,
      inicio: '/organizacao',
      sessao: _org,
      organizacaoPorCategoria: {'org1': []},
    );
    expect(find.text('Qual categoria você organiza?'), findsOneWidget);

    await tester.tap(find.text('Super Master'));
    await tester.pumpAndSettle();
    expect(find.text('Organizar a categoria Super Master?'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('SUPER MASTER'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
    expect(find.text('Super Master · Temporada 2027'), findsOneWidget);
  });

  testWidgets('Tabela troca entre 1º turno, 2º turno e geral', (tester) async {
    await abrirApp(tester, inicio: '/torcedor/tabela');
    expect(find.text('Fase classificatória · 1º Turno'), findsOneWidget);

    await tester.tap(find.text('2º Turno'));
    await tester.pumpAndSettle();
    expect(find.text('Fase classificatória · 2º Turno'), findsOneWidget);

    await tester.tap(find.text('Geral'));
    await tester.pumpAndSettle();
    expect(find.text('Geral · os dois turnos somados'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('rebaixados'), 200);
    expect(find.textContaining('rebaixados'), findsOneWidget);
  });

  testWidgets('dados de exemplo: faixa de aviso para o Torcedor', (tester) async {
    await abrirApp(tester, inicio: '/torcedor');
    expect(find.byKey(const Key('faixa-exemplo')), findsOneWidget);
  });

  testWidgets('dados de exemplo: sem pedido de vínculo', (tester) async {
    await abrirApp(tester, inicio: '/participante', sessao: _marcos);
    expect(find.text('Vincular ao elenco'), findsOneWidget);
    expect(find.text('Enviar para aprovação'), findsNothing);
  });

  testWidgets('o app lembra o perfil e pula a escolha', (tester) async {
    await abrirApp(tester, perfilSalvo: '/torcedor');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Como você quer entrar?'), findsNothing);
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);
  });
}
