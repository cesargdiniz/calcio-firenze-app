import 'package:calcio_firenze/app/app.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta o app com dados de exemplo e repositórios em memória, em tela de
/// celular. Devolve a gestão para os testes inspecionarem o que foi gravado.
Future<MemoriaGestaoRepository> abrirApp(
  WidgetTester tester, {
  String inicio = '/',
  Sessao? sessao,
  Map<String, Usuario>? usuarios,
  Set<String> organizacao = const {},
}) async {
  tester.view.physicalSize = const Size(414 * 3, 896 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repoUsuarios = MemoriaUsuarioRepository(usuarios);
  final temporada = MemoriaTemporadaRepository(montarTemporadaExemplo());
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
      initialLocation: inicio,
    ),
  );
  if (inicio == '/') await tester.pump(const Duration(milliseconds: 1300)); // Splash
  await tester.pumpAndSettle();
  return gestao;
}
