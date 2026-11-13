// Gera uma imagem de cada tela do app, com os dados de exemplo.
//
//   flutter test tool/telas/telas_test.dart --update-goldens
//
// As imagens saem em tool/telas/saida/. Fica fora de test/ para não rodar
// junto com os testes: aqui nada é conferido, só desenhado.
import 'dart:io';

import 'package:calcio_firenze/app/app.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _largura = 414.0;
const _densidade = 2.0;

const _contaOrg = Sessao(uid: 'org1', email: 'cesar@exemplo.com');
const _contaRafael = Sessao(uid: 'u1', email: 'rafael@exemplo.com');

Usuario _rafael(StatusVinculo status) => Usuario(
  uid: 'u1',
  email: 'rafael@exemplo.com',
  nome: 'Rafael Souza',
  vinculo: Vinculo(
    temporadaId: 'master-2027',
    pessoaId: 'rafael-souza',
    timeId: 'SAM',
    papel: Papel.atleta,
    status: status,
  ),
);

/// A temporada de exemplo como se fosse a real (fora do modo demonstração),
/// para as telas da Organização que só liberam o registro com dados reais.
DadosTemporada _real() {
  final e = montarTemporadaExemplo();
  return DadosTemporada(
    id: e.id,
    nome: e.nome,
    local: e.local,
    times: e.times,
    pessoas: e.pessoas,
    partidas: e.partidas,
    decisoes: e.decisoes,
    relogio: e.relogio,
  );
}

Future<void> _carregarFonte(String familia, List<String> arquivos) async {
  final fonte = FontLoader(familia);
  for (final caminho in arquivos) {
    fonte.addFont(
      File(caminho).readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
    );
  }
  await fonte.load();
}

Future<MemoriaGestaoRepository> _abrir(
  WidgetTester tester,
  String rota, {
  Sessao? sessao,
  Map<String, Usuario>? usuarios,
  bool organizacao = false,
  DadosTemporada? dados,
  bool assentar = true,
}) async {
  tester.view.devicePixelRatio = _densidade;
  tester.view.physicalSize = const Size(_largura * _densidade, 896 * _densidade);
  addTearDown(tester.view.reset);

  final repoUsuarios = MemoriaUsuarioRepository(usuarios);
  final temporada = MemoriaTemporadaRepository(dados ?? montarTemporadaExemplo());
  final gestao = MemoriaGestaoRepository(repoUsuarios, temporada);
  DateTime agora() => TemporadaExemploRepository.agora;

  await tester.pumpWidget(
    CalcioApp(
      temporada: temporada,
      auth: MemoriaAuthRepository(sessao: sessao),
      usuarios: repoUsuarios,
      organizacao: MemoriaOrganizacaoRepository(organizacao ? {'org1'} : const {}),
      gestao: gestao,
      montarPainel: MontarPainel(agora: agora),
      montarSituacao: MontarSituacao(agora: agora),
      initialLocation: rota,
    ),
  );
  if (assentar) await tester.pumpAndSettle();
  return gestao;
}

Future<void> _capturar(WidgetTester tester, String nome, double altura) async {
  tester.view.physicalSize = Size(_largura * _densidade, altura * _densidade);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // Imagens (o logo) só são decodificadas fora do relógio simulado.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await expectLater(find.byType(CalcioApp), matchesGoldenFile('saida/$nome.png'));
}

/// Declara uma tela: abre com [abrir] e grava `saida/<nome>.png`.
void _tela(
  String nome,
  Future<void> Function(WidgetTester tester) abrir, {
  double altura = 896,
  Future<void> Function(WidgetTester tester)? depois,
}) => testWidgets(nome, (tester) async {
  debugDisableShadows = false;
  try {
    await abrir(tester);
    await _capturar(tester, nome, altura);
    await depois?.call(tester);
  } finally {
    debugDisableShadows = true;
  }
});

void main() {
  setUpAll(() async {
    await _carregarFonte('Montserrat', [
      'assets/fonts/Montserrat-SemiBold.ttf',
      'assets/fonts/Montserrat-Bold.ttf',
      'assets/fonts/Montserrat-ExtraBold.ttf',
    ]);
    await _carregarFonte('OpenSans', [
      'assets/fonts/OpenSans-Regular.ttf',
      'assets/fonts/OpenSans-SemiBold.ttf',
    ]);
    final flutter = Platform.environment['FLUTTER_ROOT'];
    final icones = File('$flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (flutter != null && icones.existsSync()) {
      await _carregarFonte('MaterialIcons', [icones.path]);
    }
  });

  final exemplo = montarTemporadaExemplo();
  final encerrado = exemplo.partidas.firstWhere((p) => p.rodada == 3 && p.envolve('MON'));
  final aberto = exemplo.partidas.firstWhere((p) => !p.encerrada);

  Future<MemoriaGestaoRepository> org(WidgetTester t, String rota, {bool real = true}) => _abrir(
    t,
    rota,
    sessao: _contaOrg,
    organizacao: true,
    dados: real ? _real() : null,
    usuarios: {'u1': _rafael(StatusVinculo.pendente)},
  );

  Future<void> participante(WidgetTester t, String rota) => _abrir(
    t,
    rota,
    sessao: _contaRafael,
    usuarios: {'u1': _rafael(StatusVinculo.aprovado)},
  );

  Future<void> escolherTime(WidgetTester t, String sigla) async {
    await t.tap(find.text(sigla));
    await t.pumpAndSettle();
  }

  // ------------------------------------------------------------- Entrada
  _tela(
    '01-splash',
    (t) => _abrir(t, '/', assentar: false),
    depois: (t) async {
      await t.pump(const Duration(milliseconds: 1300));
      await t.pumpAndSettle();
    },
  );
  _tela('02-como-entrar', (t) => _abrir(t, '/entrar'));

  // ------------------------------------------------------------ Torcedor
  _tela('03-torcedor-inicio', (t) => _abrir(t, '/torcedor'), altura: 1400);
  _tela('04-torcedor-jogos', (t) => _abrir(t, '/torcedor/jogos'), altura: 1100);
  _tela('05-torcedor-jogo', (t) => _abrir(t, '/torcedor/jogos/${encerrado.id}'), altura: 1100);
  _tela('06-torcedor-classificacao', (t) => _abrir(t, '/torcedor/tabela'));
  _tela('07-torcedor-suspensos', (t) => _abrir(t, '/torcedor/suspensos'), altura: 1100);

  // -------------------------------------------------------- Participante
  _tela('08-participante-login', (t) => _abrir(t, '/participante'));
  _tela(
    '09-participante-vincular',
    (t) => _abrir(t, '/participante', sessao: _contaRafael),
    altura: 1100,
  );
  _tela(
    '10-participante-aguardando',
    (t) => _abrir(
      t,
      '/participante',
      sessao: _contaRafael,
      usuarios: {'u1': _rafael(StatusVinculo.pendente)},
    ),
  );
  _tela('11-participante-inicio', (t) => participante(t, '/participante'), altura: 1200);
  _tela('12-participante-meu-time', (t) => participante(t, '/participante/time'), altura: 1400);
  _tela('13-participante-perfil', (t) => participante(t, '/participante/perfil'));

  // --------------------------------------------------------- Organização
  _tela('14-org-sem-acesso', (t) => _abrir(t, '/organizacao', sessao: _contaOrg));
  _tela('15-org-inicio', (t) => org(t, '/organizacao'), altura: 1100);
  _tela('16-org-jogos-sem-calendario', (t) => org(t, '/organizacao/jogos', real: false));
  _tela('17-org-jogos', (t) => org(t, '/organizacao/jogos'), altura: 1300);
  _tela('18-org-jogo', (t) => org(t, '/organizacao/jogos/${aberto.id}'), altura: 1100);
  _tela('19-org-sumula', (t) => org(t, '/organizacao/jogos/${aberto.id}/sumula'), altura: 1500);
  _tela('20-org-disciplina', (t) => org(t, '/organizacao/disciplina'), altura: 1500);
  _tela('21-org-tabela', (t) => org(t, '/organizacao/tabela'));
  _tela('22-org-gestao', (t) => org(t, '/organizacao/gestao'));
  _tela('23-org-times', (t) => org(t, '/organizacao/gestao/times'), altura: 1000);
  _tela('24-org-editar-time', (t) => org(t, '/organizacao/gestao/times/SAM'));
  _tela('25-org-parametros', (t) => org(t, '/organizacao/gestao/parametros'), altura: 1750);
  _tela('26-org-importar-elencos', (t) => org(t, '/organizacao/gestao/elencos'), altura: 1100);
  _tela('27-org-pedidos', (t) => org(t, '/organizacao/gestao/pedidos'));
  _tela('28-org-decisoes', (t) => org(t, '/organizacao/gestao/decisoes'));
  _tela('29-org-nova-decisao', (t) async {
    await org(t, '/organizacao/gestao/decisoes/nova');
    await escolherTime(t, 'MON');
  }, altura: 1900);
  _tela('30-org-movimentacoes', (t) async {
    final gestao = await org(t, '/organizacao/gestao/movimentacoes');
    final goleiro = exemplo.pessoas.firstWhere((p) => p.timeId == 'SAS' && p.goleiro);
    final linha = exemplo.pessoas.firstWhere(
      (p) => p.timeId == 'ROM' && !p.goleiro && !p.dirigente && p.funcao == Funcao.atleta,
    );
    await gestao.registrarMovimentacao(
      'master-2027',
      Movimentacao(
        id: 'mov-1',
        tipo: TipoMovimentacao.demissao,
        pessoaId: linha.id,
        timeId: linha.timeId,
        nome: linha.nome,
        data: DateTime(2027, 2, 22),
      ),
    );
    await gestao.registrarMovimentacao(
      'master-2027',
      Movimentacao(
        id: 'mov-2',
        tipo: TipoMovimentacao.trocaGoleiro,
        pessoaId: goleiro.id,
        timeId: goleiro.timeId,
        nome: goleiro.nome,
        data: DateTime(2027, 2, 24),
        laudo: true,
        motivoTroca: MotivoTroca.lesao,
        substitutoId: 'sas-gol-novo',
        substitutoNome: 'Paulo Reserva',
      ),
      substituto: const Pessoa(
        id: 'sas-gol-novo',
        nome: 'Paulo Reserva',
        timeId: 'SAS',
        numero: 1,
        goleiro: true,
      ),
    );
    await t.pumpAndSettle();
  });
  _tela('31-org-nova-movimentacao', (t) async {
    await org(t, '/organizacao/gestao/movimentacoes/nova');
    await escolherTime(t, 'MON');
  }, altura: 1750);
}
