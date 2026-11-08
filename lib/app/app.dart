import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/repositories/temporada_repository.dart';
import '../domain/usecases/montar_painel.dart';
import '../modules/torcedor/torcedor_controller.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

class CalcioApp extends StatefulWidget {
  final TemporadaRepository repository;
  final MontarPainel montarPainel;

  const CalcioApp({super.key, required this.repository, required this.montarPainel});

  @override
  State<CalcioApp> createState() => _CalcioAppState();
}

class _CalcioAppState extends State<CalcioApp> {
  late final GoRouter _router = criarRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: widget.repository,
    child: BlocProvider(
      create: (_) => TorcedorController(widget.repository, widget.montarPainel)..iniciar(),
      child: MaterialApp.router(
        title: 'Calcio Firenze',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(),
        routerConfig: _router,
      ),
    ),
  );
}
