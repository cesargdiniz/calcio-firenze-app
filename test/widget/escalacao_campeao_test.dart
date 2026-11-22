import 'package:calcio_firenze/domain/entities/campeoes.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/modules/campeoes/campeoes_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final foggia = campeoesDe(Categoria.master).firstWhere((t) => t.ano == 2023);

  test('Foggia 2023: goleiro e 2-2-1 titulares com número, oito reservas', () {
    expect(foggia.campeao, 'Foggia');
    expect(foggia.titulares.map((j) => j.nome), [
      'Toupeira', 'Cesar', 'Netão', 'Pedro Reis', 'Klelio', 'Daniel Diniz', //
    ]);
    expect(foggia.titularesDe(PosicaoCampeao.zagueiro), hasLength(2));
    expect(foggia.titularesDe(PosicaoCampeao.meia), hasLength(2));
    expect(foggia.titularesDe(PosicaoCampeao.ataque), hasLength(1));
    expect(foggia.reservas, hasLength(8));
    expect(foggia.titulares.map((j) => j.numero), [1, 3, 6, 7, 10, 9]);
  });

  test('Sampdoria 2024: titulares com número e nome curto, sete reservas', () {
    final samp = campeoesDe(Categoria.master).firstWhere((t) => t.ano == 2024);
    expect(samp.titulares.map((j) => '${j.numero} ${j.noCampo}'), [
      '94 M Jr', '4 Marcelo', '100 Saymon', '10 Pedreiro', '20 Eddy', '9 Paulinho', //
    ]);
    expect(samp.titularesDe(PosicaoCampeao.zagueiro), hasLength(2));
    expect(samp.reservas, hasLength(7));
  });

  test('Juventus 2021: Santana, Sagica e Robledo, Tárik e Renato Cajá, Daniel Diniz', () {
    final juve = campeoesDe(Categoria.master).firstWhere((t) => t.ano == 2021);
    expect(juve.elenco, hasLength(11));
    expect(juve.titulares.map((j) => j.nome), [
      'Santana', 'Sagica', 'Robledo', 'Tárik Toda', 'Renato Cajá', 'Daniel Diniz', //
    ]);
    expect(juve.titularesDe(PosicaoCampeao.meia), hasLength(2));
    expect(juve.reservas.map((j) => j.nome), [
      'Ivo Barbosa', 'Antonio Marcos', 'Jhovan', 'Henrique Bezerra', 'Marcilio Guerreiro', //
    ]);
    expect(juve.premios.map((p) => p.nome).toSet(), {'Daniel Diniz'});
  });

  test('Inter 2025 e Brasil 2022: titulares no 2-2-1, cores do time', () {
    final master = campeoesDe(Categoria.master);
    final inter = master.firstWhere((t) => t.ano == 2025);
    expect(inter.titulares.map((j) => '${j.numero} ${j.noCampo}'), [
      '1 Galvão', '5 Berg', '16 Fabrício', '11 Marcelo Farias', '89 Rudd', '10 Carneiro', //
    ]);
    expect(inter.reservas, hasLength(6));
    expect(inter.cor, 0xFF0A3D91);
    final brasil = master.firstWhere((t) => t.ano == 2022);
    expect(brasil.titulares.map((j) => j.nome), [
      'Toupeira', 'Olavo', 'Maicon', 'Fabio', 'Macapá', 'Marcelo Cai Cai', //
    ]);
    expect(brasil.reservas, hasLength(7));
    // Todos os campeões do Master já têm elenco e cor.
    expect(master.every((t) => t.elenco.isNotEmpty && t.cor != null), isTrue);
  });

  test('Livre: Foggia 2025, Roma 2024 e Napoli 2023 com campinho', () {
    final livre = campeoesDe(Categoria.livre);
    final foggia = livre.firstWhere((t) => t.ano == 2025);
    expect(foggia.titulares.map((j) => j.numero), [1, 3, 4, 8, 10, 9]);
    expect(foggia.reservas, hasLength(7));
    final roma = livre.firstWhere((t) => t.ano == 2024);
    expect(roma.titulares.map((j) => j.noCampo), [
      'Gabriel Luz', 'Alex Nascimento', 'Cabeludo', 'Toupeira', 'Lucas Gabriel', 'Marcola', //
    ]);
    expect(roma.reservas, hasLength(8));
    final napoli = livre.firstWhere((t) => t.ano == 2023);
    expect(napoli.elenco, hasLength(14));
    expect(napoli.titulares.map((j) => j.noCampo), [
      'Gustavo', 'Alex Sorín', 'Victor Bezerra', 'New', 'Alessandro Melul', 'Vidal', //
    ]);
    expect(napoli.reservas, hasLength(8));
  });

  testWidgets('tocar no campeão abre o campinho com titulares e reservas', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: ListaCampeoes(categoria: Categoria.master),
      ))),
    );
    await t.tap(find.text('Foggia'));
    await t.pumpAndSettle();
    expect(find.text('Campeão Master 2023'), findsOneWidget);
    expect(find.text('Toupeira'), findsOneWidget);
    expect(find.text('Daniel Diniz'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Reservas (8)'), findsOneWidget);
    expect(find.textContaining('Cleuby'), findsOneWidget);
    expect(find.text('Premiações de 2023'), findsOneWidget);
    expect(find.text('Carmona (Sampdoria)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
