import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../torcedor_controller.dart';

/// Resolve carregando / falha uma vez só e entrega o [Painel] pronto às telas.
class ComPainel extends StatelessWidget {
  final Widget Function(BuildContext context, Painel painel) builder;
  const ComPainel({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => BlocBuilder<TorcedorController, TorcedorStatus>(
    builder: (context, status) => switch (status) {
      TorcedorCarregando() => const Center(
        child: CircularProgressIndicator(color: AppColors.verde),
      ),
      TorcedorFalha(:final mensagem) => Center(
        child: Padding(
          padding: AppSpacing.tela,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensagem, style: AppTextStyles.corpo, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => context.read<TorcedorController>().tentarDeNovo(),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
      TorcedorPronto(:final painel) => builder(context, painel),
    },
  );
}
