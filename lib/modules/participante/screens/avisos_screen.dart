import 'package:material_ui/material_ui.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../avisos.dart';
import 'participante_inicio_screen.dart';
import '../../../shared/layout/tela_larga.dart';

/// P5 · Participante · Avisos de pendência e suspensão
class AvisosScreen extends StatelessWidget {
  const AvisosScreen({super.key});

  @override
  Widget build(BuildContext context) => ComParticipante(
    builder: (context, p) {
      final avisos = avisosDoParticipante(p);
      final meus = avisos.where((a) => !a.doTime).toList();
      final doTime = avisos.where((a) => a.doTime).toList();
      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          const BotaoVoltar(rotulo: 'Início', rota: '/participante'),
          CabecalhoTela(
            'Avisos',
            subtitulo: avisos.isEmpty
                ? 'Nenhum aviso'
                : avisos.length == 1
                ? '1 aviso'
                : '${avisos.length} avisos',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Pendências de cartão e suspensões. Cada aviso some quando a situação é resolvida.',
            style: AppTextStyles.pequeno,
          ),
          if (avisos.isEmpty)
            const ListaVazia(
              titulo: 'Tudo em dia',
              texto: 'Sem pendência de cartão nem suspensão no momento.',
            ),
          if (meus.isNotEmpty) ...[
            if (doTime.isNotEmpty) const TituloSecao('Para você') else const SizedBox(height: 12),
            for (final a in meus) _CartaoAviso(a),
          ],
          if (doTime.isNotEmpty) ...[
            TituloSecao('Do ${p.time.time.nome}'),
            for (final a in doTime) _CartaoAviso(a),
          ],
        ],
      );
    },
  );
}

class _CartaoAviso extends StatelessWidget {
  final Aviso aviso;
  const _CartaoAviso(this.aviso);

  @override
  Widget build(BuildContext context) {
    final (icone, cor, fundo) = switch (aviso.gravidade) {
      GravidadeAviso.critico => (
        Icons.block_rounded,
        AppColors.vermelho,
        AppColors.vermelhoSuave,
      ),
      GravidadeAviso.atencao => (
        Icons.schedule_rounded,
        AppColors.amareloEscuro,
        AppColors.amareloSuave,
      ),
      GravidadeAviso.informativo => (
        Icons.info_outline_rounded,
        AppColors.texto2,
        AppColors.cinzaSuave,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Cartao(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
              child: Icon(icone, color: cor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aviso.titulo, style: AppTextStyles.nome),
                  const SizedBox(height: 2),
                  Text(aviso.texto, style: AppTextStyles.corpo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
