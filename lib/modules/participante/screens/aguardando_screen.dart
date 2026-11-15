import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/temporada.dart';
import '../../../domain/entities/usuario.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../../../shared/widgets/logo_calcio.dart';
import '../participante_controller.dart';

/// Pedido de vínculo enviado, aguardando a Organização.
class AguardandoScreen extends StatelessWidget {
  final Usuario usuario;
  final Pessoa pessoa;
  final Time time;

  const AguardandoScreen({
    super.key,
    required this.usuario,
    required this.pessoa,
    required this.time,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSpacing.tela,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.hourglass_top_rounded, size: 44, color: AppColors.amareloEscuro),
          const SizedBox(height: AppSpacing.md),
          const Text('Pedido enviado', style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'A Organização vai confirmar que esta conta é sua. '
            'Assim que aprovar, sua situação e a do seu time aparecem aqui.',
            style: AppTextStyles.corpo,
          ),
          const SizedBox(height: AppSpacing.lg),
          Cartao(
            child: Row(
              children: [
                Escudo(time),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pessoa.nome.toUpperCase(), style: AppTextStyles.nome),
                      Text(
                        '${usuario.vinculo?.papel.rotulo ?? ''} · ${time.nome}',
                        style: AppTextStyles.pequeno,
                      ),
                    ],
                  ),
                ),
                const Etiqueta(
                  'Pendente',
                  cor: AppColors.amareloEscuro,
                  fundo: AppColors.amareloSuave,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: () => context.go('/torcedor'),
            child: const Text('Enquanto isso, ver como Torcedor'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ParticipanteController>().sair();
              if (context.mounted) context.go('/entrar');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    ),
  );
}
