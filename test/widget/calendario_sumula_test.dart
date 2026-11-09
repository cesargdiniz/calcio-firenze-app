import 'dart:math';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

/// Temporada "real": elencos de exemplo e o 1º turno sorteado, sem súmulas.
DadosTemporada _real({List<Partida> Function(List<Partida>)? ajustar}) {
  final exemplo = montarTemporadaExemplo();
  var partidas = const GerarCalendario()(
    turno: 1,
    times: [for (final t in exemplo.times) t.id],
    horarios: horariosMaster2027[1]!,
    sorteio: Random(1),
  );
  if (ajustar != null) partidas = ajustar(partidas);
  return DadosTemporada(
    id: 'master-2027',
    nome: exemplo.nome,
    local: exemplo.local,
    times: exemplo.times,
    pessoas: exemplo.pessoas,
    partidas: partidas,
  );
}

void main() {
  testWidgets('Organização sorteia e gera o 1º turno', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/jogos',
      sessao: _org,
      organizacao: {'org1'},
    );
    expect(find.text('Calendário ainda não gerado'), findsOneWidget);
    await acionar(tester, 'Sortear e gerar o 1º turno');
    await tester.tap(find.text('Sortear'));
    await tester.pumpAndSettle();

    final d = gestao.temporada.dados;
    expect(d.demonstracao, isFalse);
    expect(d.partidas, hasLength(45));
    expect(find.text('Rodada 1'), findsOneWidget);
  });

  testWidgets('lançar e encerrar súmula com placar', (tester) async {
    final dados = _real();
    final jogo = dados.partidas.first;
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/jogos/${jogo.id}/sumula',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    for (final botao in [
      find.byTooltip('Mais um gol').first,
      find.byTooltip('Mais um gol').first,
      find.byTooltip('Mais um gol').last,
    ]) {
      await tester.tap(botao);
      await tester.pumpAndSettle();
    }
    await acionar(tester, 'Encerrar súmula');

    final salvo = gestao.temporada.dados.partidas.firstWhere((p) => p.id == jogo.id);
    expect(salvo.sumula?.golsMandante, 2);
    expect(salvo.sumula?.golsVisitante, 1);
    expect(find.text('Encerrada'), findsOneWidget);
  });

  testWidgets('W.O. registra 6 x 0 para o time presente', (tester) async {
    final dados = _real();
    final jogo = dados.partidas.first;
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/jogos/${jogo.id}/sumula',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    final sigla = dados.times.firstWhere((t) => t.id == jogo.visitanteId).sigla;
    await tester.tap(find.text('W.O.: $sigla faltou'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vale 6 x 0'), findsOneWidget);
    await acionar(tester, 'Encerrar súmula');
    final salvo = gestao.temporada.dados.partidas.firstWhere((p) => p.id == jogo.id);
    expect(salvo.sumula?.ausenteWo, jogo.visitanteId);
  });

  testWidgets('Disciplina: cartão gera pendência e a Organização marca como quitada', (
    tester,
  ) async {
    late Partida jogo;
    final dados = _real(
      ajustar: (ps) {
        jogo = ps.first;
        final atleta = montarTemporadaExemplo().pessoas.firstWhere(
          (p) => p.timeId == jogo.mandanteId && p.funcao == Funcao.atleta,
        );
        return [
          jogo.comSumula(
            Sumula(
              golsMandante: 1,
              cartoes: [
                CartaoAplicado(
                  pessoaId: atleta.id,
                  timeId: atleta.timeId,
                  tipo: TipoCartao.amarelo,
                ),
              ],
            ),
          ),
          ...ps.skip(1),
        ];
      },
    );
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/disciplina',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    expect(find.text('Em aberto (1)'), findsOneWidget);
    expect(find.text('R\$ 30,00'), findsOneWidget);
    await acionar(tester, 'Marcar como quitada');

    expect(gestao.temporada.dados.pagamentos, hasLength(1));
    expect(find.text('Em aberto (0)'), findsOneWidget);
    expect(find.text('Quitadas (1)'), findsOneWidget);
  });
}
