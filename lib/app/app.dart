import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/organizacao_repository.dart';
import '../domain/repositories/temporada_repository.dart';
import '../domain/repositories/usuario_repository.dart';
import '../domain/usecases/montar_painel.dart';
import '../domain/usecases/montar_situacao.dart';
import '../modules/organizacao/organizacao_controller.dart';
import '../modules/participante/participante_controller.dart';
import '../modules/torcedor/torcedor_controller.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

/// Raiz do app. As dependências chegam prontas (Firebase em produção,
/// versões em memória nos testes).
class CalcioApp extends StatefulWidget {
  final TemporadaRepository temporada;
  final AuthRepository auth;
  final UsuarioRepository usuarios;
  final OrganizacaoRepository organizacao;
  final GestaoRepository gestao;
  final MontarPainel montarPainel;
  final MontarSituacao montarSituacao;
  final String initialLocation;

  const CalcioApp({
    super.key,
    required this.temporada,
    required this.auth,
    required this.usuarios,
    required this.organizacao,
    required this.gestao,
    required this.montarPainel,
    required this.montarSituacao,
    this.initialLocation = '/',
  });

  @override
  State<CalcioApp> createState() => _CalcioAppState();
}

class _CalcioAppState extends State<CalcioApp> {
  late final GoRouter _router = criarRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<TemporadaRepository>.value(value: widget.temporada),
      RepositoryProvider<AuthRepository>.value(value: widget.auth),
      RepositoryProvider<UsuarioRepository>.value(value: widget.usuarios),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TorcedorController(widget.temporada, widget.montarPainel)..iniciar(),
        ),
        BlocProvider(
          create: (_) => ParticipanteController(
            widget.auth,
            widget.usuarios,
            widget.temporada,
            widget.montarSituacao,
          )..iniciar(),
        ),
        BlocProvider(
          create: (_) => OrganizacaoController(
            widget.auth,
            widget.organizacao,
            widget.gestao,
            widget.temporada,
          )..iniciar(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Calcio Firenze',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(),
        routerConfig: _router,
      ),
    ),
  );
}
