import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Layout de computador: só no navegador, com a janela larga. No iPhone, no
/// Android e no navegador do celular o app continua igual.
abstract final class TelaLarga {
  /// Janela a partir da qual entra o menu lateral.
  static const larguraJanela = 1024.0;

  /// Área de conteúdo a partir da qual as telas usam colunas.
  static const larguraConteudo = 760.0;

  /// Largura máxima do conteúdo das telas.
  static const maxima = 1180.0;

  /// Liga o layout fora do navegador (testes e galeria de telas).
  static bool? forcar;

  static bool get _ligado => forcar ?? kIsWeb;

  /// Menu lateral no lugar da barra de baixo (decidido pela janela inteira).
  static bool menuLateral(BuildContext context) =>
      _ligado && MediaQuery.sizeOf(context).width >= larguraJanela;

  /// A tela tem espaço para o layout em colunas. Dentro das áreas com menu
  /// lateral, a largura vista é a do conteúdo, sem o menu.
  static bool de(BuildContext context) =>
      _ligado && MediaQuery.sizeOf(context).width >= larguraConteudo;

  /// Margens de uma tela em lista: no computador, o texto fica numa coluna
  /// central de leitura em vez de esticar até as bordas.
  static EdgeInsets margens(BuildContext context, {double leitura = 760}) {
    if (!de(context)) return AppSpacing.tela;
    final largura = MediaQuery.sizeOf(context).width;
    final lado = math.max(40.0, (largura - leitura) / 2);
    return EdgeInsets.fromLTRB(lado, 32, lado, 48);
  }
}

/// Uma tela no computador: título grande, conteúdo até [TelaLarga.maxima] px
/// e, se houver, uma coluna lateral. Sem espaço para as duas colunas, a
/// lateral desce para baixo do conteúdo principal.
class PaginaLarga extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  /// Filtros e seletores logo abaixo do título, na largura toda.
  final List<Widget> topo;
  final List<Widget> principal;
  final List<Widget> lateral;
  final double larguraLateral;

  const PaginaLarga({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
    this.topo = const [],
    required this.principal,
    this.lateral = const [],
    this.larguraLateral = 340,
  });

  static List<Widget> _espacados(List<Widget> filhos, double espaco) => [
    for (final (i, f) in filhos.indexed) ...[if (i > 0) SizedBox(height: espaco), f],
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const margem = 40.0;
      final util = math.min(box.maxWidth - 2 * margem, TelaLarga.maxima);
      final colunas = lateral.isNotEmpty && util >= 640 + larguraLateral;
      final principal = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _espacados(this.principal, AppSpacing.xl),
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(margem, 32, margem, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: TelaLarga.maxima),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CabecalhoLargo(titulo, subtitulo: subtitulo, acao: acao),
                for (final t in topo) ...[const SizedBox(height: AppSpacing.lg), t],
                const SizedBox(height: AppSpacing.xl),
                if (colunas)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: principal),
                      const SizedBox(width: AppSpacing.xl),
                      SizedBox(
                        width: larguraLateral,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _espacados(lateral, AppSpacing.xl),
                        ),
                      ),
                    ],
                  )
                else ...[
                  principal,
                  if (lateral.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    ..._espacados(lateral, AppSpacing.xl),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Título de tela no tamanho do computador.
class CabecalhoLargo extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  const CabecalhoLargo(this.titulo, {super.key, this.subtitulo, this.acao});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: AppTextStyles.tituloTela.copyWith(fontSize: 34, height: 1.1)),
            if (subtitulo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitulo!, style: AppTextStyles.subtitulo.copyWith(fontSize: 15)),
            ],
          ],
        ),
      ),
      ?acao,
    ],
  );
}

/// Cartão branco com título, usado nas colunas do computador.
class BlocoLargo extends StatelessWidget {
  final String titulo;
  final String? acao;
  final VoidCallback? onAcao;
  final Widget child;
  const BlocoLargo({super.key, required this.titulo, this.acao, this.onAcao, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.cartao,
      borderRadius: AppRadius.cartao,
      border: Border.all(color: AppColors.linha),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: AppTextStyles.tituloSecao)),
              if (acao != null)
                TextButton(onPressed: onAcao, child: Text(acao!)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}
