import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'org@exemplo.com');

void main() {
  testWidgets('trocar de perfil e voltar para onde estava', (tester) async {
    await abrirApp(tester, inicio: '/torcedor');
    await tester.tap(find.byTooltip('Trocar de perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Como você quer entrar?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voltar')));
    await tester.pumpAndSettle();
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);
  });

  testWidgets('detalhe do jogo volta para a lista', (tester) async {
    final dados = montarTemporadaExemplo(demonstracao: false);
    final jogo = dados.partidas.firstWhere((p) => p.encerrada);
    await abrirApp(tester, inicio: '/torcedor/jogos/${jogo.id}', dados: dados);
    // Torcedor só vê o jogo.
    expect(find.text('Editar placar e súmula'), findsNothing);
    await tester.tap(find.byKey(const Key('voltar')));
    await tester.pumpAndSettle();
    expect(find.text('Jogos'), findsWidgets);
    expect(find.byKey(const Key('voltar')), findsNothing);
  });

  testWidgets('nem quem organiza lança súmula pelo detalhe público', (tester) async {
    final dados = montarTemporadaExemplo(demonstracao: false);
    final jogo = dados.partidas.firstWhere((p) => p.encerrada);
    await abrirApp(
      tester,
      inicio: '/torcedor/jogos/${jogo.id}',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    // Súmula e placar só pela área da Organização.
    expect(find.text('Editar placar e súmula'), findsNothing);
    expect(find.text('Lançar placar e súmula'), findsNothing);
  });
}
