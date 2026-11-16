import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../torcedor_controller.dart';

/// Aviso fixo no topo enquanto a categoria mostra a temporada de exemplo, para
/// ninguém tomar times e jogos fictícios por reais.
class FaixaExemplo extends StatelessWidget {
  const FaixaExemplo({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<TorcedorController, TorcedorStatus>(
    builder: (context, s) => switch (s) {
      TorcedorPronto(:final painel) when painel.demonstracao => Container(
        key: const Key('faixa-exemplo'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.amareloSuave,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Dados de exemplo: a temporada ainda não foi cadastrada. Times, jogos e '
          'resultados são fictícios.',
          style: AppTextStyles.pequeno,
        ),
      ),
      _ => const SizedBox.shrink(),
    },
  );
}
