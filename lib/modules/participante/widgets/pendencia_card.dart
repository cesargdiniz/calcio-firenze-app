import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';

import '../../../domain/usecases/montar_situacao.dart';
import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';

/// Componente "Card/Pendência" do Figma.
class PendenciaCard extends StatelessWidget {
  final ItemPendencia pendencia;

  /// Nome de quem deve (na lista do time, para dirigente e técnico).
  final String? nome;

  const PendenciaCard(this.pendencia, {super.key, this.nome});

  @override
  Widget build(BuildContext context) {
    final p = pendencia;
    final (rotulo, cor, fundo) = switch (p.status) {
      StatusPendencia.quitada => ('Quitada', AppColors.verde, AppColors.verdeSuave),
      StatusPendencia.vencida => ('Vencida', AppColors.vermelho, AppColors.vermelhoSuave),
      StatusPendencia.aVencer => (
        'Até ${dataHoraJogo(p.prazo!)}',
        AppColors.amareloEscuro,
        AppColors.amareloSuave,
      ),
      StatusPendencia.semPrazo => ('Sem prazo ainda', AppColors.texto2, AppColors.cinzaSuave),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Cartao(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 14,
              decoration: BoxDecoration(
                color: p.titulo.contains('amarelo') && !p.titulo.contains('Dois')
                    ? AppColors.amarelo
                    : AppColors.vermelho,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome == null ? p.titulo : '${nome!.toUpperCase()} · ${p.titulo}',
                    style: AppTextStyles.nome,
                  ),
                  Text(p.origem, style: AppTextStyles.pequeno),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(reais(p.valor), style: AppTextStyles.nome),
                const SizedBox(height: 2),
                Etiqueta(rotulo, cor: cor, fundo: fundo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
