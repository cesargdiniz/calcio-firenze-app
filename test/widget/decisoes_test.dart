import 'dart:math';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/shared/widgets/basicos.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

/// Temporada "real" com o 1º turno sorteado e a súmula do primeiro jogo
/// encerrada. Devolve também esse jogo e um atleta do mandante.
(DadosTemporada, Partida, Pessoa) _real({
  List<DecisaoDisciplinar> Function(Partida jogo, Pessoa atleta)? decisoes,
  List<Pagamento> pagamentos = const [],
}) {
  final exemplo = montarTemporadaExemplo();
  final sorteadas = const GerarCalendario()(
    turno: 1,
    times: [for (final t in exemplo.times) t.id],
    horarios: horariosMaster2027[1]!,
    sorteio: Random(1),
  );
  final jogo = sorteadas.first.comSumula(const Sumula(golsMandante: 1));
  final atleta = exemplo.pessoas.firstWhere(
    (p) => p.timeId == jogo.mandanteId && p.funcao == Funcao.atleta,
  );
  final dados = DadosTemporada(
    id: 'master-2027',
    nome: exemplo.nome,
    local: exemplo.local,
    times: exemplo.times,
    pessoas: exemplo.pessoas,
    partidas: [jogo, ...sorteadas.skip(1)],
    decisoes: decisoes?.call(jogo, atleta) ?? const [],
    pagamentos: pagamentos,
  );
  return (dados, jogo, atleta);
}

DecisaoDisciplinar _multaDe250(Partida jogo, Pessoa atleta) => DecisaoDisciplinar(
  id: 'dec-9',
  pessoaId: atleta.id,
  timeId: atleta.timeId,
  partidaOrigemId: jogo.id,
  motivo: 'Desrespeito à arbitragem na condição de torcedor',
  multa: 25000,
);

/// Rola até o texto e aciona o item que o contém (chip ou linha da lista).
Future<void> _escolher<T extends Widget>(
  WidgetTester tester,
  String texto,
  VoidCallback? Function(T) toque,
) async {
  final alvo = find.text(texto);
  await tester.scrollUntilVisible(alvo, 200, scrollable: find.byType(Scrollable).first);
  toque(tester.widget<T>(find.ancestor(of: alvo, matching: find.byType(T)).first))!();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('registrar decisão com suspensão e multa', (tester) async {
    final (dados, jogo, atleta) = _real();
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/decisoes/nova',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    expect(find.text('Nova decisão'), findsOneWidget);

    final sigla = dados.times.firstWhere((t) => t.id == jogo.mandanteId).sigla;
    await _escolher<ChipFiltro>(tester, sigla, (c) => c.onTap);
    await _escolher<ListTile>(tester, atleta.nome.toUpperCase(), (l) => l.onTap);
    await _escolher<ChipFiltro>(tester, 'Prejudicar a própria equipe', (c) => c.onTap);
    await acionar(tester, 'Salvar decisão');

    final salva = gestao.temporada.dados.decisoes.single;
    expect(salva.pessoaId, atleta.id);
    expect(salva.timeId, jogo.mandanteId);
    expect(salva.partidaOrigemId, jogo.id);
    expect(salva.jogosSuspensao, 1);
    expect(salva.multa, 10000);
    expect(salva.fundamento, 'Art. 88');

    expect(find.text('1 decisão registrada'), findsOneWidget);
    expect(find.text('Suspensão · 1 jogo'), findsOneWidget);
    expect(find.text('Multa R\$ 100,00'), findsOneWidget);
  });

  testWidgets('sem suspensão nem multa não dá para salvar', (tester) async {
    final (dados, jogo, atleta) = _real();
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/decisoes/nova',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    final sigla = dados.times.firstWhere((t) => t.id == jogo.mandanteId).sigla;
    await _escolher<ChipFiltro>(tester, sigla, (c) => c.onTap);
    await _escolher<ListTile>(tester, atleta.nome.toUpperCase(), (l) => l.onTap);

    final lista = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Salvar decisão'), 200, scrollable: lista);
    expect(find.text('Informe a suspensão, a multa ou as duas.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar decisão')).onPressed,
      isNull,
    );
    expect(gestao.temporada.dados.decisoes, isEmpty);
  });

  testWidgets('multa da decisão aparece na Disciplina', (tester) async {
    final (dados, _, _) = _real(decisoes: (j, a) => [_multaDe250(j, a)]);
    await abrirApp(
      tester,
      inicio: '/organizacao/disciplina',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    expect(find.text('Em aberto (1)'), findsOneWidget);
    expect(find.text('R\$ 250,00'), findsOneWidget);
  });

  testWidgets('excluir decisão apaga também a quitação da multa', (tester) async {
    final (dados, _, _) = _real(
      decisoes: (j, a) => [_multaDe250(j, a)],
      pagamentos: [Pagamento(idPendenciaDaDecisao('dec-9'), DateTime(2027, 1, 30))],
    );
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/decisoes/dec-9',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    expect(find.text('Editar decisão'), findsOneWidget);
    await acionar(tester, 'Excluir decisão');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(gestao.temporada.dados.decisoes, isEmpty);
    expect(gestao.temporada.dados.pagamentos, isEmpty);
    expect(find.text('Nenhuma decisão'), findsOneWidget);
  });
}
