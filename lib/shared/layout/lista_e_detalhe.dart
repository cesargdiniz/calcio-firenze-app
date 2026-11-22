import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'tela_larga.dart';

/// No computador, uma lista à esquerda e o item aberto à direita (jogos e
/// súmula, gestão). No celular mostra só [detalhe], que é a tela da rota.
class ListaEDetalhe extends StatelessWidget {
  final Widget lista;
  final Widget detalhe;
  final double larguraLista;

  const ListaEDetalhe({
    super.key,
    required this.lista,
    required this.detalhe,
    this.larguraLista = 400,
  });

  /// A rota está sendo mostrada no lado direito (lista visível à esquerda).
  static bool noDetalhe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NoDetalhe>() != null;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (!TelaLarga.de(context) || mq.size.width < larguraLista + 480) return detalhe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: larguraLista,
          // A lista se monta como no celular, na largura da coluna.
          child: MediaQuery(
            data: mq.copyWith(size: Size(larguraLista, mq.size.height)),
            child: lista,
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: AppColors.linha),
        Expanded(
          child: MediaQuery(
            data: mq.copyWith(size: Size(mq.size.width - larguraLista - 1, mq.size.height)),
            child: _NoDetalhe(child: detalhe),
          ),
        ),
      ],
    );
  }
}

/// Lado direito vazio, antes de escolher um item da lista.
class DetalheVazio extends StatelessWidget {
  final IconData icone;
  final String texto;
  const DetalheVazio({super.key, required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: AppColors.dica),
          const SizedBox(height: AppSpacing.md),
          Text(texto, textAlign: TextAlign.center, style: AppTextStyles.corpo),
        ],
      ),
    ),
  );
}

class _NoDetalhe extends InheritedWidget {
  const _NoDetalhe({required super.child});

  @override
  bool updateShouldNotify(_NoDetalhe oldWidget) => false;
}
