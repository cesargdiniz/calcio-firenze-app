import 'dart:math';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/shared/widgets/basicos.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

/// Temporada "real": elencos de exemplo e o 1º turno sorteado.
DadosTemporada _real({
  List<Partida> Function(List<Partida>)? ajustar,
  Parametros parametros = Parametros.master2027,
}) {
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
    parametros: parametros,
  );
}

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
  group('Regulamento e parâmetros', () {
    testWidgets('alterar o valor do cartão amarelo', (tester) async {
      final gestao = await abrirApp(
        tester,
        inicio: '/organizacao/gestao/parametros',
        sessao: _org,
        organizacao: {'org1'},
      );
      final campo = find.widgetWithText(TextField, 'Cartão amarelo (R\$)');
      await tester.scrollUntilVisible(campo, 200, scrollable: find.byType(Scrollable).first);
      await tester.enterText(campo, '40');
      await tester.pumpAndSettle();
      await acionar(tester, 'Salvar parâmetros');

      final salvos = gestao.temporada.dados.parametros;
      expect(salvos.valorAmarelo, 4000);
      expect(salvos.valorVermelho, 5000);
      expect(salvos.pontosVitoria, 3);
      expect(salvos.prazoQuitacao, const Duration(hours: 24));
    });

    testWidgets('patrocinador dá nome à competição na súmula', (tester) async {
      final gestao = await abrirApp(
        tester,
        inicio: '/organizacao/gestao/parametros',
        sessao: _org,
        organizacao: {'org1'},
      );
      await tester.enterText(find.widgetWithText(TextField, 'Patrocinador'), 'CASA ASSIS');
      await tester.pumpAndSettle();
      expect(find.text('Na súmula: CF CASA ASSIS 2027'), findsOneWidget);
      await acionar(tester, 'Salvar parâmetros');
      expect(gestao.temporada.dados.patrocinador, 'CASA ASSIS');
    });

    testWidgets('datas do Draft-1 e do Draft-2', (tester) async {
      final gestao = await abrirApp(
        tester,
        inicio: '/organizacao/gestao/parametros',
        sessao: _org,
        organizacao: {'org1'},
      );
      expect(find.text('Sem data'), findsNWidgets(2));
      await tester.tap(find.text('Definir').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(gestao.temporada.dados.drafts, {1: DateTime(2027, 1, 1)});
      expect(find.text('01/01/2027'), findsOneWidget);

      await tester.tap(find.byTooltip('Apagar a data do Draft-1'));
      await tester.pumpAndSettle();
      expect(gestao.temporada.dados.drafts, isEmpty);
    });

    testWidgets('valor inválido bloqueia o salvamento', (tester) async {
      await abrirApp(
        tester,
        inicio: '/organizacao/gestao/parametros',
        sessao: _org,
        organizacao: {'org1'},
      );
      final pontos = find.widgetWithText(TextField, 'Pontos por vitória');
      await tester.scrollUntilVisible(pontos, 200, scrollable: find.byType(Scrollable).first);
      await tester.enterText(pontos, 'x');
      await tester.pumpAndSettle();
      expect(find.text('Informe um número válido.'), findsOneWidget);

      final lista = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Salvar parâmetros'), 200, scrollable: lista);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar parâmetros'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a Disciplina cobra o valor configurado', (tester) async {
      final dados = _real(
        parametros: const Parametros(valorAmarelo: 4000),
        ajustar: (ps) {
          final jogo = ps.first;
          final atleta = montarTemporadaExemplo().pessoas.firstWhere(
            (p) => p.timeId == jogo.mandanteId && p.funcao == Funcao.atleta,
          );
          return [
            jogo.comSumula(
              Sumula(
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
      await abrirApp(
        tester,
        inicio: '/organizacao/disciplina',
        sessao: _org,
        organizacao: {'org1'},
        dados: dados,
      );
      expect(find.text('R\$ 40,00'), findsOneWidget);
    });
  });

  group('Movimentações', () {
    testWidgets('registrar demissão tira o atleta do elenco; desfazer devolve', (tester) async {
      final dados = _real();
      final atleta = dados.pessoas.firstWhere(
        (p) => p.funcao == Funcao.atleta && !p.dirigente && !p.goleiro,
      );
      final sigla = dados.times.firstWhere((t) => t.id == atleta.timeId).sigla;
      final gestao = await abrirApp(
        tester,
        inicio: '/organizacao/gestao/movimentacoes/nova',
        sessao: _org,
        organizacao: {'org1'},
        dados: dados,
      );
      Pessoa atual() => gestao.temporada.dados.pessoas.firstWhere((p) => p.id == atleta.id);

      await _escolher<ChipFiltro>(tester, sigla, (c) => c.onTap);
      await _escolher<ListTile>(tester, atleta.nome.toUpperCase(), (l) => l.onTap);
      await acionar(tester, 'Registrar movimentação');

      expect(atual().ativo, isFalse);
      expect(gestao.movimentacoes.single.tipo, TipoMovimentacao.demissao);
      expect(find.text('1 movimentação registrada'), findsOneWidget);

      await acionar(tester, 'Desfazer');
      await tester.tap(find.text('Sim, desfazer'));
      await tester.pumpAndSettle();

      expect(atual().ativo, isTrue);
      expect(gestao.movimentacoes, isEmpty);
      expect(find.text('Nenhuma movimentação'), findsOneWidget);
    });

    testWidgets('troca de goleiro inscreve o substituto', (tester) async {
      final dados = _real();
      final goleiro = dados.pessoas.firstWhere((p) => p.goleiro);
      final sigla = dados.times.firstWhere((t) => t.id == goleiro.timeId).sigla;
      final gestao = await abrirApp(
        tester,
        inicio: '/organizacao/gestao/movimentacoes/nova',
        sessao: _org,
        organizacao: {'org1'},
        dados: dados,
      );

      await _escolher<ChipFiltro>(tester, 'Troca de goleiro', (c) => c.onTap);
      await _escolher<ChipFiltro>(tester, sigla, (c) => c.onTap);
      await _escolher<ListTile>(tester, goleiro.nome.toUpperCase(), (l) => l.onTap);
      await _escolher<ChipFiltro>(tester, 'Mudança de município', (c) => c.onTap);
      final campo = find.widgetWithText(TextField, 'Nome do novo goleiro');
      await tester.scrollUntilVisible(campo, 200, scrollable: find.byType(Scrollable).first);
      await tester.enterText(campo, 'Paulo Reserva');
      await tester.pumpAndSettle();
      await acionar(tester, 'Registrar movimentação');

      final pessoas = gestao.temporada.dados.pessoas;
      expect(pessoas.firstWhere((p) => p.id == goleiro.id).ativo, isFalse);
      final novo = pessoas.firstWhere((p) => p.nome == 'Paulo Reserva');
      expect(novo.goleiro, isTrue);
      expect(novo.timeId, goleiro.timeId);
      expect(novo.numero, goleiro.numero);
      expect(gestao.movimentacoes.single.substitutoId, novo.id);
    });

    testWidgets('lesão sem laudo não pode ser registrada', (tester) async {
      final dados = _real();
      final atleta = dados.pessoas.firstWhere((p) => p.funcao == Funcao.atleta && !p.goleiro);
      final sigla = dados.times.firstWhere((t) => t.id == atleta.timeId).sigla;
      final gestao = await abrirApp(
        tester,
        inicio: '/organizacao/gestao/movimentacoes/nova',
        sessao: _org,
        organizacao: {'org1'},
        dados: dados,
      );
      await _escolher<ChipFiltro>(tester, 'Lesão', (c) => c.onTap);
      await _escolher<ChipFiltro>(tester, sigla, (c) => c.onTap);
      await _escolher<ListTile>(tester, atleta.nome.toUpperCase(), (l) => l.onTap);

      final lista = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Registrar movimentação'), 200, scrollable: lista);
      expect(find.textContaining('precisa ser comprovada'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Registrar movimentação'))
            .onPressed,
        isNull,
      );
      expect(gestao.movimentacoes, isEmpty);
    });
  });
}
