import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/widgets/logo_calcio.dart';
import '../widgets/com_painel.dart';
import '../widgets/tabela.dart';

/// T1 · Torcedor · Início
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) {
      final suspensos = painel.suspensos.length;
      return ListView(
        padding: AppSpacing.tela,
        children: [
          Row(
            children: [
              const LogoCalcio(),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calcio Firenze', style: AppTextStyles.tituloSecao.copyWith(fontSize: 20)),
                  Text(painel.nomeTemporada, style: AppTextStyles.subtitulo),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (painel.proximaRodada != null && suspensos > 0)
            _AvisoSuspensos(
              texto: suspensos == 1
                  ? '1 suspenso para a Rodada ${painel.proximaRodada}'
                  : '$suspensos suspensos para a Rodada ${painel.proximaRodada}',
              onTap: () => context.go('/torcedor/suspensos'),
            ),
          if (painel.proximaRodada != null) ...[
            TituloSecao(
              'Próximos jogos · Rodada ${painel.proximaRodada}',
              acao: 'Ver todos',
              onAcao: () => context.go('/torcedor/jogos'),
            ),
            for (final p in painel.proximosJogos.take(2)) ...[
              CardJogo(
                partida: p,
                mandante: painel.time(p.mandanteId),
                visitante: painel.time(p.visitanteId),
                local: painel.local,
                onTap: () => context.go('/torcedor/jogos/${p.id}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
          TituloSecao(
            'Classificação · 1º Turno',
            acao: 'Ver tabela',
            onAcao: () => context.go('/torcedor/tabela'),
          ),
          TabelaClassificacao(
            painel: painel,
            linhas: painel.tabela.take(4).toList(),
            compacta: true,
          ),
        ],
      );
    },
  );
}

class _AvisoSuspensos extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _AvisoSuspensos({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.vermelhoSuave,
    borderRadius: AppRadius.botao,
    child: InkWell(
      borderRadius: AppRadius.botao,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, color: AppColors.vermelho, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto, style: AppTextStyles.nome),
                  Text(
                    'Veja quem não joga e quem está pendurado',
                    style: AppTextStyles.pequeno.copyWith(color: AppColors.texto2),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.vermelho),
          ],
        ),
      ),
    ),
  );
}
