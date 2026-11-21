import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/organizacao_repository.dart';
import '../domain/repositories/preferencias_repository.dart';
import '../domain/repositories/push_repository.dart';
import '../domain/repositories/temporada_repository.dart';
import '../domain/repositories/usuario_repository.dart';
import '../domain/usecases/montar_painel.dart';
import '../domain/usecases/montar_situacao.dart';
import '../modules/categoria/categoria_controller.dart';
import '../modules/organizacao/organizacao_controller.dart';
import '../modules/participante/participante_controller.dart';
import '../modules/push/sincronizador_push.dart';
import '../modules/torcedor/torcedor_controller.dart';
import '../shared/compartilhar/saida_imagem.dart';
import '../shared/pdf/saida_pdf.dart';
import '../shared/seletor_imagem.dart';
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
  final PreferenciasRepository preferencias;
  final SaidaPdf saidaPdf;
  final SaidaImagem saidaImagem;
  final SeletorImagem seletorImagem;
  final PushRepository push;
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
    required this.preferencias,
    this.saidaImagem = const SaidaImagemDoAparelho(),
    this.saidaPdf = const SaidaPdfDoAparelho(),
    this.seletorImagem = const SeletorImagemDoAparelho(),
    this.push = const PushDesligado(),
    this.initialLocation = '/',
  });

  @override
  State<CalcioApp> createState() => _CalcioAppState();
}

class _CalcioAppState extends State<CalcioApp> {
  late final GoRouter _router = criarRouter(initialLocation: widget.initialLocation);
  late final CategoriaController _categoria = CategoriaController(widget.preferencias)..iniciar();
  late final SincronizadorPush _sincronizador = SincronizadorPush(
    widget.push,
    widget.auth,
    widget.usuarios,
    _categoria.observar(),
  );
  StreamSubscription<String>? _rotas;

  @override
  void initState() {
    super.initState();
    _sincronizador.iniciar();
    // Toque na notificação abre o jogo ou a tela do aviso.
    _rotas = widget.push.rotasAbertas.listen(_router.go);
  }

  @override
  void dispose() {
    _rotas?.cancel();
    _sincronizador.encerrar();
    _router.dispose();
    _categoria.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<TemporadaRepository>.value(value: widget.temporada),
      RepositoryProvider<AuthRepository>.value(value: widget.auth),
      RepositoryProvider<UsuarioRepository>.value(value: widget.usuarios),
      RepositoryProvider<PreferenciasRepository>.value(value: widget.preferencias),
      RepositoryProvider<SaidaPdf>.value(value: widget.saidaPdf),
      RepositoryProvider<SaidaImagem>.value(value: widget.saidaImagem),
      RepositoryProvider<SeletorImagem>.value(value: widget.seletorImagem),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _categoria),
        BlocProvider(
          create: (_) =>
              TorcedorController(widget.temporada, widget.montarPainel, _categoria)..iniciar(),
        ),
        BlocProvider(
          create: (_) => ParticipanteController(
            widget.auth,
            widget.usuarios,
            widget.temporada,
            widget.montarSituacao,
            _categoria,
            widget.gestao,
          )..iniciar(),
        ),
        BlocProvider(
          create: (_) => OrganizacaoController(
            widget.auth,
            widget.organizacao,
            widget.gestao,
            widget.temporada,
            _categoria,
          )..iniciar(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Calcio Firenze',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(),
        // Calendários, botões e textos do sistema em português.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    ),
  );
}
