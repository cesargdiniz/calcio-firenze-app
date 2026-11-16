import 'dart:math';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/domain/usecases/mata_mata.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'org@exemplo.com');

/// 1º turno inteiro com o mesmo placar (1 x 1): todos empatam em tudo.
DadosTemporada _tudoEmpatado() {
  final e = montarTemporadaExemplo(demonstracao: false);
  final ids = [for (final t in e.times) t.id];
  return DadosTemporada(
    id: e.id,
    nome: e.nome,
    local: e.local,
    times: e.times,
    pessoas: e.pessoas,
    partidas: [
      for (final p in const GerarCalendario()(
        turno: 1,
        times: ids,
        horarios: horariosMaster2027[1]!,
        sorteio: Random(1),
      ))
        p.comSumula(const Sumula(golsMandante: 1, golsVisitante: 1)),
    ],
  );
}

void main() {
  testWidgets('Organização registra o sorteio do art. 42 e o mata-mata destrava', (tester) async {
    final dados = _tudoEmpatado();
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/tabela',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    expect(const MataMata().turno(gestao.temporada.dados, 1).proxima, isNull);
    expect(find.text('Empate em todos os critérios (art. 42)'), findsOneWidget);

    await tester.tap(find.text('Registrar resultado do sorteio'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado do sorteio'), findsOneWidget);
    final ordem = [for (final t in dados.times) t.nome].reversed.toList();
    // O último entra sozinho.
    for (final nome in ordem.take(ordem.length - 1)) {
      await tester.ensureVisible(find.text(nome).last);
      await tester.tap(find.text(nome).last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Confirmar ordem'));
    await tester.tap(find.text('Confirmar ordem'));
    await tester.pumpAndSettle();

    final d = gestao.temporada.dados;
    expect(d.ordemSorteio(1), [for (final t in dados.times) t.id].reversed);
    expect(find.textContaining('Decidido por sorteio'), findsOneWidget);
    expect(const MataMata().turno(d, 1).proxima, Fase.quartas);
  });

  testWidgets('Torcedor não vê o registro do sorteio', (tester) async {
    await abrirApp(tester, inicio: '/torcedor/tabela', dados: _tudoEmpatado());
    expect(find.text('Empate em todos os critérios (art. 42)'), findsNothing);
    final nota = find.text('* Empate em todos os critérios: decidido por sorteio (art. 42).');
    await tester.scrollUntilVisible(nota, 200);
    expect(nota, findsOneWidget);
  });
}
