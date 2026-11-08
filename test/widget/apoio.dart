import 'package:calcio_firenze/app/app.dart';
import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/montar_painel.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta o app com dados de exemplo e login em memória, em tela de celular.
Future<void> abrirApp(
  WidgetTester tester, {
  String inicio = '/',
  Sessao? sessao,
  Map<String, Usuario>? usuarios,
}) async {
  tester.view.physicalSize = const Size(414 * 3, 896 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  DateTime agora() => TemporadaExemploRepository.agora;
  await tester.pumpWidget(
    CalcioApp(
      temporada: TemporadaExemploRepository(),
      auth: MemoriaAuthRepository(sessao: sessao),
      usuarios: MemoriaUsuarioRepository(usuarios),
      montarPainel: MontarPainel(agora: agora),
      montarSituacao: MontarSituacao(agora: agora),
      initialLocation: inicio,
    ),
  );
  if (inicio == '/') await tester.pump(const Duration(milliseconds: 1300)); // Splash
  await tester.pumpAndSettle();
}
