import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/categoria.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/widgets/coluna_larga.dart';
import '../../shared/widgets/logo_calcio.dart';
import 'categoria_controller.dart';

/// Barra do topo com a categoria em exibição. Com mais de uma opção, um toque
/// abre a lista para trocar.
class BarraCategoria extends StatelessWidget {
  final Categoria atual;
  final List<Categoria> opcoes;
  final ValueChanged<Categoria> onEscolher;

  /// No menu lateral do computador: ocupa a largura do menu e abre a lista
  /// logo abaixo do botão.
  final bool noMenu;

  const BarraCategoria({
    super.key,
    required this.atual,
    required this.onEscolher,
    this.opcoes = Categoria.values,
    this.noMenu = false,
  });

  bool get _podeTrocar => opcoes.length > 1;

  Future<void> _abrirNoMenu(BuildContext context) async {
    final caixa = context.findRenderObject()! as RenderBox;
    final canto = caixa.localToGlobal(Offset.zero);
    final tela = MediaQuery.sizeOf(context);
    final c = await showMenu<Categoria>(
      context: context,
      position: RelativeRect.fromLTRB(
        canto.dx,
        canto.dy + caixa.size.height + 6,
        tela.width - canto.dx - caixa.size.width,
        0,
      ),
      constraints: BoxConstraints.tightFor(width: caixa.size.width),
      color: AppColors.cartao,
      items: [
        for (final o in opcoes)
          PopupMenuItem(
            value: o,
            child: Row(
              children: [
                Expanded(child: Text(o.nome, style: AppTextStyles.nome)),
                if (o == atual) const Icon(Icons.check_rounded, color: AppColors.verde, size: 20),
              ],
            ),
          ),
      ],
    );
    if (c != null && c != atual) onEscolher(c);
  }

  Future<void> _abrir(BuildContext context) async {
    if (noMenu) return _abrirNoMenu(context);
    final c = await showModalBottomSheet<Categoria>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Categoria', style: AppTextStyles.tituloSecao),
            ),
            for (final o in opcoes)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(o.nome, style: AppTextStyles.nome),
                subtitle: Text('${o.times} times', style: AppTextStyles.pequeno),
                trailing: o == atual
                    ? const Icon(Icons.check_rounded, color: AppColors.verde)
                    : null,
                onTap: () => Navigator.pop(c, o),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (c != null && c != atual) onEscolher(c);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: noMenu ? EdgeInsets.zero : const EdgeInsets.fromLTRB(24, 8, 24, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: _podeTrocar,
        label: _podeTrocar ? 'Categoria ${atual.nome}. Toque para trocar.' : 'Categoria ${atual.nome}',
        excludeSemantics: true,
        child: Material(
          color: AppColors.verdeSuave,
          borderRadius: AppRadius.chip,
          child: InkWell(
            key: const Key('seletor-categoria'),
            borderRadius: AppRadius.chip,
            onTap: _podeTrocar ? () => _abrir(context) : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: noMenu ? 44 : 36,
                minWidth: noMenu ? double.infinity : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: noMenu ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Text(
                      atual.nome.toUpperCase(),
                      style: AppTextStyles.rotulo.copyWith(color: AppColors.verde, letterSpacing: 0.6),
                    ),
                    if (noMenu) const Spacer(),
                    if (_podeTrocar) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.verde),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// [BarraCategoria] ligada à escolha do app (Torcedor e Participante).
class BarraCategoriaDoApp extends StatelessWidget {
  final bool noMenu;
  const BarraCategoriaDoApp({super.key, this.noMenu = false});

  @override
  Widget build(BuildContext context) => BlocBuilder<CategoriaController, CategoriaStatus>(
    builder: (context, s) => switch (s) {
      CategoriaEscolhida(:final categoria) => BarraCategoria(
        atual: categoria,
        noMenu: noMenu,
        onEscolher: context.read<CategoriaController>().escolher,
      ),
      _ => const SizedBox.shrink(),
    },
  );
}

/// Mostra [child] depois que há uma categoria escolhida; na primeira abertura,
/// pede a escolha.
class ComCategoria extends StatelessWidget {
  final Widget child;
  const ComCategoria({super.key, required this.child});

  @override
  Widget build(BuildContext context) => BlocBuilder<CategoriaController, CategoriaStatus>(
    builder: (context, s) => switch (s) {
      CategoriaCarregando() => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.verde)),
      ),
      CategoriaPendente() => const ColunaCentral(child: EscolherCategoriaScreen()),
      CategoriaEscolhida() => child,
    },
  );
}

/// Primeira abertura: qual categoria acompanhar. Dá para trocar depois pela
/// barra do topo.
class EscolherCategoriaScreen extends StatelessWidget {
  const EscolherCategoriaScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSpacing.tela,
        children: [
          const BotaoVoltar(rotulo: 'Voltar', rota: '/entrar'),
          const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
          const SizedBox(height: AppSpacing.xl),
          const Text('Qual categoria você quer acompanhar?', style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Dá para trocar a qualquer momento pelo botão no topo da tela.',
            style: AppTextStyles.corpo,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final c in Categoria.values) ...[
            _OpcaoCategoria(c),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    ),
  );
}

class _OpcaoCategoria extends StatelessWidget {
  final Categoria categoria;
  const _OpcaoCategoria(this.categoria);

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cartao,
    borderRadius: AppRadius.cartao,
    child: InkWell(
      borderRadius: AppRadius.cartao,
      onTap: () => context.read<CategoriaController>().escolher(categoria),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.cartao,
          border: Border.all(color: AppColors.linha),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoria.nome, style: AppTextStyles.tituloSecao),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${categoria.times} times · temporada 2027',
                    style: AppTextStyles.pequeno,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
          ],
        ),
      ),
    ),
  );
}
