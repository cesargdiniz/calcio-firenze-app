import 'package:calcio_firenze/app/app.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:calcio_firenze/shared/pdf/saida_pdf.dart';
import 'package:calcio_firenze/shared/seletor_imagem.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta o app com dados de exemplo e repositórios em memória, em tela de
/// celular. A [categoria] simula a escolha já feita (nula: primeira
/// abertura). Devolve a gestão para os testes inspecionarem o que foi gravado.
Future<MemoriaGestaoRepository> abrirApp(
  WidgetTester tester, {
  String inicio = '/',
  Sessao? sessao,
  Map<String, Usuario>? usuarios,
  Set<String> organizacao = const {},
  DadosTemporada? dados,
  SaidaPdf? saidaPdf,
  SeletorImagem? seletorImagem,
  String? categoria = 'master-2027',
  Map<String, List<Categoria>>? organizacaoPorCategoria,
  List<DadosTemporada> outrasTemporadas = const [],
}) async {
  tester.view.physicalSize = const Size(414 * 3, 896 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repoUsuarios = MemoriaUsuarioRepository(usuarios);
  final temporada = MemoriaTemporadaRepository(
    dados ?? montarTemporadaExemplo(),
    outrasTemporadas,
  );
  final gestao = MemoriaGestaoRepository(repoUsuarios, temporada);

  DateTime agora() => TemporadaExemploRepository.agora;
  await tester.pumpWidget(
    CalcioApp(
      temporada: temporada,
      auth: MemoriaAuthRepository(sessao: sessao),
      usuarios: repoUsuarios,
      organizacao: MemoriaOrganizacaoRepository(organizacao, organizacaoPorCategoria),
      gestao: gestao,
      montarPainel: MontarPainel(agora: agora),
      montarSituacao: MontarSituacao(agora: agora),
      preferencias: MemoriaPreferencias(categoria),
      saidaPdf: saidaPdf ?? const SaidaPdfDoAparelho(),
      seletorImagem: seletorImagem ?? const SeletorImagemDoAparelho(),
      initialLocation: inicio,
    ),
  );
  // A abertura segue sozinha para a escolha do perfil ao fim da animação.
  await tester.pumpAndSettle();
  return gestao;
}

/// Rola até o botão com [texto] e aciona direto (evita toques que caem
/// atrás da barra de abas em telas longas).
Future<void> acionar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto);
  await tester.scrollUntilVisible(alvo, 200, scrollable: find.byType(Scrollable).first);
  final botao = find.ancestor(
    of: alvo,
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  (tester.widget(botao.first) as ButtonStyleButton).onPressed!();
  await tester.pumpAndSettle();
}
