import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

Future<void> abrirComoTorcedor(WidgetTester tester) async {
  await abrirApp(tester);
  await tester.tap(find.text('Torcedor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash leva a "Como você quer entrar?"', (tester) async {
    await abrirApp(tester);
    expect(find.text('Como você quer entrar?'), findsOneWidget);
  });

  testWidgets('Início do Torcedor mostra aviso de suspensos e próximos jogos', (tester) async {
    await abrirComoTorcedor(tester);
    expect(find.text('3 suspensos para a Rodada 4'), findsOneWidget);
    expect(find.text('Próximos jogos · Rodada 4'), findsOneWidget);
  });

  testWidgets('aba Suspensos lista suspensos e pendurados', (tester) async {
    await abrirComoTorcedor(tester);
    await tester.tap(find.text('Suspensos').last);
    await tester.pumpAndSettle();
    expect(find.text('MARCOS LIMA'), findsOneWidget);
    expect(find.text('PAULO RIBEIRO'), findsOneWidget);
    expect(find.text('RICARDO ALVES'), findsOneWidget);
    // Marcos (vermelho) e Paulo (3 amarelos) voltam na Rodada 5; Ricardo
    // (decisão de 2 jogos) só na Rodada 6.
    expect(find.text('Volta na Rodada 5'), findsNWidgets(2));
    expect(find.text('Volta na Rodada 6'), findsOneWidget);

    await tester.tap(find.text('Pendurados (2)'));
    await tester.pumpAndSettle();
    expect(find.text('FÁBIO COSTA'), findsOneWidget);
  });

  testWidgets('aba Tabela mostra os 10 times', (tester) async {
    await abrirComoTorcedor(tester);
    await tester.tap(find.text('Tabela'));
    await tester.pumpAndSettle();
    expect(find.text('Classificação'), findsWidgets);
    for (final nome in ['Leoni Azzurri', 'Cipressi Verdi', 'Corvi Neri']) {
      expect(find.textContaining(nome), findsWidgets);
    }
  });

  testWidgets('aba Tabela tem a artilharia do turno', (tester) async {
    await abrirComoTorcedor(tester);
    await tester.tap(find.text('Tabela'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estatísticas'));
    await tester.pumpAndSettle();

    final dados = montarTemporadaExemplo();
    final lider = artilharia(dados.partidas, turno: 1).first;
    final nome = dados.pessoas.firstWhere((p) => p.id == lider.pessoaId).nome.toUpperCase();
    expect(find.text('Artilharia'), findsWidgets);
    expect(find.text('1º'), findsWidgets);
    expect(find.text(nome), findsOneWidget);
  });

  testWidgets('Estatísticas: cada categoria mostra o seu ranking', (tester) async {
    await abrirComoTorcedor(tester);
    await tester.tap(find.text('Tabela'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estatísticas'));
    await tester.pumpAndSettle();

    final dados = montarTemporadaExemplo();
    final painel = MontarPainel(agora: () => TemporadaExemploRepository.agora)(dados);
    String nome(String id) => dados.pessoas.firstWhere((p) => p.id == id).nome.toUpperCase();
    String time(String id) => dados.times.firstWhere((t) => t.id == id).nome;

    final esperado = {
      'Melhor da partida': nome(painel.melhoresDaPartida.first.pessoaId),
      'Melhor ataque': time(painel.melhorAtaque.first.timeId),
      'Melhor defesa': time(painel.melhorDefesa.first.timeId),
      'Cartão amarelo': nome(painel.amarelos.first.pessoaId),
      'Cartão vermelho': nome(painel.vermelhos.first.pessoaId),
      'Todos os cartões': nome(painel.cartoes.first.pessoaId),
    };
    for (final MapEntry(key: categoria, value: primeiro) in esperado.entries) {
      final chip = find.text(categoria);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text(primeiro), findsWidgets, reason: categoria);
    }
  });
}
