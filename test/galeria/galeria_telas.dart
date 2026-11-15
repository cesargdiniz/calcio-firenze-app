// Gera uma imagem de cada tela do app, com os dados de exemplo.
//
// Não roda no `flutter test` comum (o nome não termina em _test). Para gerar:
//
//   flutter test test/galeria/galeria_telas.dart --update-goldens
//
// As imagens saem em test/galeria/telas/.
import 'dart:io';

import 'package:calcio_firenze/app/app.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:calcio_firenze/domain/usecases/montar_sumula_impressa.dart';
import 'package:calcio_firenze/shared/pdf/sumula_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tamanho da tela capturada. O padrão é um celular comum, a 2x. Para as
/// capturas da App Store (iPhone de 6,9", 1320 × 2868):
///
///   flutter test test/galeria/galeria_telas.dart --update-goldens \
///     --dart-define=TELA_LARGURA=440 --dart-define=TELA_ALTURA=956 --dart-define=TELA_DENSIDADE=3
const double _largura = int.fromEnvironment('TELA_LARGURA', defaultValue: 414) + 0.0;
const double _altura = int.fromEnvironment('TELA_ALTURA', defaultValue: 896) + 0.0;
const double _densidade = int.fromEnvironment('TELA_DENSIDADE', defaultValue: 2) + 0.0;

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');
const _rafael = Sessao(uid: 'u1', email: 'rafael@exemplo.com');

Usuario _usuario(StatusVinculo status, {String uid = 'u1'}) => Usuario(
  uid: uid,
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

/// A temporada de exemplo como se fosse a real (elencos importados, três
/// rodadas jogadas), para mostrar as telas da Organização liberadas.
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
    patrocinador: 'CASA ASSIS',
  );
}

Future<void> _carregarFontes() async {
  Future<void> familia(String nome, List<String> arquivos) async {
    final fontes = FontLoader(nome);
    for (final caminho in arquivos) {
      fontes.addFont(
        File(caminho).readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
      );
    }
    await fontes.load();
  }

  await familia('Montserrat', [
    'assets/fonts/Montserrat-SemiBold.ttf',
    'assets/fonts/Montserrat-Bold.ttf',
    'assets/fonts/Montserrat-ExtraBold.ttf',
  ]);
  await familia('OpenSans', [
    'assets/fonts/OpenSans-Regular.ttf',
    'assets/fonts/OpenSans-SemiBold.ttf',
  ]);

  // Ícones do Material: ficam dentro do SDK do Flutter.
  const relativo = 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  final candidatos = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final raiz?) '$raiz/$relativo',
  ];
  var pasta = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    candidatos.add('${pasta.path}/$relativo');
    pasta = pasta.parent;
  }
  final icones = candidatos.where((c) => File(c).existsSync()).firstOrNull;
  if (icones != null) await familia('MaterialIcons', [icones]);
}

Future<MemoriaGestaoRepository> _abrir(
  WidgetTester tester,
  String rota, {
  Sessao? sessao,
  Map<String, Usuario>? usuarios,
  Set<String> organizacao = const {},
  DadosTemporada? dados,
  bool assentar = true,
}) async {
  tester.view.physicalSize = Size(_largura * _densidade, _altura * _densidade);
  tester.view.devicePixelRatio = _densidade;
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
      organizacao: MemoriaOrganizacaoRepository(organizacao),
      gestao: gestao,
      montarPainel: MontarPainel(agora: agora),
      montarSituacao: MontarSituacao(agora: agora),
      initialLocation: rota,
    ),
  );
  if (assentar) await tester.pumpAndSettle();
  return gestao;
}

Future<void> _capturar(WidgetTester tester, String nome) async {
  // Imagens (logo, arte da abertura) só aparecem na captura depois de
  // decodificadas, o que precisa de tempo real e não do relógio do teste.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate().toList()) {
      await precacheImage((e.widget as Image).image, e);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  await expectLater(find.byType(CalcioApp), matchesGoldenFile('telas/$nome.png'));
}

/// Rola a lista principal para mostrar a continuação de uma tela longa.
Future<void> _rolar(WidgetTester tester, [double distancia = 640]) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, -distancia));
  await tester.pumpAndSettle();
}

/// Aciona o chip, botão ou linha que contém o texto.
Future<void> _tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).first;
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo, warnIfMissed: false);
  await tester.pumpAndSettle();
}

void _tela(String nome, Future<void> Function(WidgetTester tester) corpo) {
  testWidgets(nome, (tester) async {
    // Por padrão os testes trocam as sombras por contornos pretos.
    debugDisableShadows = false;
    try {
      await corpo(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  setUpAll(_carregarFontes);

  final exemplo = montarTemporadaExemplo();
  final encerrado = exemplo.partidas.where((p) => p.encerrada).last;
  final agendado = exemplo.partidas.where((p) => !p.encerrada).first;
  final comCartoes = exemplo.partidas.where((p) => (p.sumula?.cartoes.length ?? 0) > 1).first;

  testWidgets('súmula em PDF (em branco e encerrada)', (t) async {
    await t.runAsync(() async {
      ByteData fonte(String nome) =>
          ByteData.sublistView(File('assets/fonts/$nome.ttf').readAsBytesSync());
      final montar = MontarSumulaImpressa(agora: () => TemporadaExemploRepository.agora);
      final proximoDoMonza = exemplo.partidas.firstWhere((p) => !p.encerrada && p.envolve('MON'));
      for (final (nome, partida) in [
        ('sumula_em_branco', proximoDoMonza),
        ('sumula_encerrada', comCartoes),
      ]) {
        final bytes = await gerarSumulaPdf(
          montar(_real(), partida.id),
          fonte: fonte('OpenSans-Regular'),
          fonteNegrito: fonte('OpenSans-SemiBold'),
        );
        File('test/galeria/telas/$nome.pdf')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
      }
    });
  });

  group('Entrada', () {
    _tela('01 splash', (t) async {
      await _abrir(t, '/', assentar: false);
      // No meio da entrada das faixas e depois com tudo no lugar.
      await t.pump();
      await t.pump(const Duration(milliseconds: 450));
      await _capturar(t, '01_splash_entrando');
      await t.pump(const Duration(milliseconds: 1250));
      await _capturar(t, '01_splash');
      await t.pumpAndSettle();
    });
    _tela('02 como você quer entrar', (t) async {
      await _abrir(t, '/entrar');
      await _capturar(t, '02_entrar');
    });
  });

  group('Torcedor', () {
    _tela('03 início', (t) async {
      await _abrir(t, '/torcedor');
      await _capturar(t, '03_torcedor_inicio');
    });
    _tela('05 jogos', (t) async {
      await _abrir(t, '/torcedor/jogos');
      await _capturar(t, '05_torcedor_jogos');
    });
    _tela('06 detalhe do jogo', (t) async {
      await _abrir(t, '/torcedor/jogos/${comCartoes.id}');
      await _capturar(t, '06_torcedor_jogo_encerrado');
    });
    _tela('07 jogo agendado', (t) async {
      await _abrir(t, '/torcedor/jogos/${agendado.id}');
      await _capturar(t, '07_torcedor_jogo_agendado');
    });
    _tela('08 classificação', (t) async {
      await _abrir(t, '/torcedor/tabela');
      await _capturar(t, '08_torcedor_classificacao');
    });
    _tela('09 suspensos', (t) async {
      await _abrir(t, '/torcedor/suspensos');
      await _capturar(t, '09_torcedor_suspensos');
    });
  });

  group('Participante', () {
    _tela('10 login', (t) async {
      await _abrir(t, '/participante');
      await _capturar(t, '10_login');
    });
    _tela('11 vincular ao elenco', (t) async {
      await _abrir(t, '/participante', sessao: _rafael);
      await _capturar(t, '11_participante_vincular');
    });
    _tela('12 aguardando aprovação', (t) async {
      await _abrir(
        t,
        '/participante',
        sessao: _rafael,
        usuarios: {'u1': _usuario(StatusVinculo.pendente)},
      );
      await _capturar(t, '12_participante_aguardando');
    });
    final aprovado = {'u1': _usuario(StatusVinculo.aprovado)};
    _tela('13 início', (t) async {
      await _abrir(t, '/participante', sessao: _rafael, usuarios: aprovado);
      await _capturar(t, '13_participante_inicio');
    });
    _tela('14 meu time', (t) async {
      await _abrir(t, '/participante/time', sessao: _rafael, usuarios: aprovado);
      await _capturar(t, '14_participante_meu_time');
    });
    _tela('16a avisos do atleta', (t) async {
      await _abrir(t, '/participante/avisos', sessao: _rafael, usuarios: aprovado);
      await _capturar(t, '16a_participante_avisos');
    });
    _tela('16b avisos do técnico', (t) async {
      await _abrir(
        t,
        '/participante/avisos',
        sessao: _rafael,
        usuarios: {
          'u1': const Usuario(
            uid: 'u1',
            email: 'helio@exemplo.com',
            nome: 'Hélio Ramos',
            vinculo: Vinculo(
              temporadaId: 'master-2027',
              pessoaId: 'helio-ramos',
              timeId: 'SAM',
              papel: Papel.tecnico,
              status: StatusVinculo.aprovado,
            ),
          ),
        },
      );
      await _capturar(t, '16b_participante_avisos_tecnico');
    });
    _tela('16 perfil', (t) async {
      await _abrir(t, '/participante/perfil', sessao: _rafael, usuarios: aprovado);
      await _capturar(t, '16_participante_perfil');
    });
  });

  group('Organização', () {
    Future<MemoriaGestaoRepository> org(
      WidgetTester t,
      String rota, {
      Map<String, Usuario>? usuarios,
    }) => _abrir(
      t,
      rota,
      sessao: _org,
      organizacao: {'org1'},
      dados: _real(),
      usuarios: usuarios,
    );
    final pedido = {'u1': _usuario(StatusVinculo.pendente)};

    _tela('17 conta sem acesso', (t) async {
      await _abrir(t, '/organizacao', sessao: _org);
      await _capturar(t, '17_org_sem_acesso');
    });
    _tela('18 início', (t) async {
      await org(t, '/organizacao', usuarios: pedido);
      await _capturar(t, '18_org_inicio');
    });
    _tela('19 jogos', (t) async {
      await org(t, '/organizacao/jogos');
      await _capturar(t, '19_org_jogos');
    });
    _tela('20 jogo', (t) async {
      await org(t, '/organizacao/jogos/${agendado.id}');
      await _capturar(t, '20_org_jogo_agendado');
    });
    _tela('21 jogo encerrado', (t) async {
      await org(t, '/organizacao/jogos/${encerrado.id}');
      await _capturar(t, '21_org_jogo_encerrado');
    });
    _tela('22 súmula', (t) async {
      await org(t, '/organizacao/jogos/${agendado.id}/sumula');
      await _capturar(t, '22_org_sumula');
      await _rolar(t);
      await _capturar(t, '23_org_sumula_continuacao');
    });
    _tela('24 disciplina', (t) async {
      await org(t, '/organizacao/disciplina');
      await _capturar(t, '24_org_disciplina');
    });
    _tela('25 gestão', (t) async {
      await org(t, '/organizacao/gestao', usuarios: pedido);
      await _capturar(t, '25_org_gestao');
    });
    _tela('26 times', (t) async {
      await org(t, '/organizacao/gestao/times');
      await _capturar(t, '26_org_times');
    });
    _tela('27 editar time', (t) async {
      await org(t, '/organizacao/gestao/times/SAM');
      await _capturar(t, '27_org_editar_time');
    });
    _tela('28 parâmetros', (t) async {
      await org(t, '/organizacao/gestao/parametros');
      await _capturar(t, '28_org_parametros');
      await _rolar(t, 700);
      await _capturar(t, '29_org_parametros_continuacao');
    });
    _tela('30 importar elencos', (t) async {
      await org(t, '/organizacao/gestao/elencos');
      await _capturar(t, '30_org_importar_elencos');
    });
    _tela('31 movimentações', (t) async {
      final gestao = await org(t, '/organizacao/gestao/movimentacoes');
      final saiu = gestao.temporada.dados.pessoas.firstWhere((p) => p.id == 'marcos-lima');
      await gestao.registrarMovimentacao(
        'master-2027',
        Movimentacao(
          id: 'mov-1',
          tipo: TipoMovimentacao.lesao,
          pessoaId: saiu.id,
          timeId: saiu.timeId,
          nome: saiu.nome,
          data: DateTime(2027, 2, 27),
          laudo: true,
        ),
      );
      await t.pumpAndSettle();
      await _capturar(t, '31_org_movimentacoes');
    });
    _tela('32 nova movimentação', (t) async {
      await org(t, '/organizacao/gestao/movimentacoes/nova');
      await _tocar(t, 'Troca de goleiro');
      await _tocar(t, 'SAM');
      await _capturar(t, '32_org_nova_movimentacao');
      await _rolar(t);
      await _capturar(t, '33_org_nova_movimentacao_continuacao');
    });
    _tela('34 pedidos de vínculo', (t) async {
      await org(t, '/organizacao/gestao/pedidos', usuarios: pedido);
      await _capturar(t, '34_org_pedidos');
    });
    _tela('35 decisões', (t) async {
      await org(t, '/organizacao/gestao/decisoes');
      await _capturar(t, '35_org_decisoes');
    });
    _tela('36 nova decisão', (t) async {
      await org(t, '/organizacao/gestao/decisoes/nova');
      await _tocar(t, 'MON');
      await _capturar(t, '36_org_nova_decisao');
      await _rolar(t);
      await _capturar(t, '37_org_nova_decisao_continuacao');
    });
    _tela('38 editar decisão', (t) async {
      await org(t, '/organizacao/gestao/decisoes/dec-1');
      await _rolar(t, 500);
      await _capturar(t, '38_org_editar_decisao');
    });
  });
}
