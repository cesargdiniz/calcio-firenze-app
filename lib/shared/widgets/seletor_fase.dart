import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Parte da temporada mostrada na tela de Jogos: a fase classificatória de um
/// turno ou as eliminatórias dele.
typedef FaseDosJogos = ({int turno, bool eliminatorias});

String rotuloFase(FaseDosJogos f) =>
    f.eliminatorias ? 'Eliminatórias T${f.turno}' : '${f.turno}º Turno';

const fasesDosJogos = <FaseDosJogos>[
  (turno: 1, eliminatorias: false),
  (turno: 1, eliminatorias: true),
  (turno: 2, eliminatorias: false),
  (turno: 2, eliminatorias: true),
];

/// Menu suspenso com as quatro partes: 1º Turno, Eliminatórias T1,
/// 2º Turno e Eliminatórias T2.
class SeletorFase extends StatelessWidget {
  final FaseDosJogos atual;
  final ValueChanged<FaseDosJogos> onEscolher;

  const SeletorFase({super.key, required this.atual, required this.onEscolher});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${rotuloFase(atual)}. Toque para trocar.',
    excludeSemantics: true,
    child: PopupMenuButton<FaseDosJogos>(
      key: const Key('seletor-fase'),
      initialValue: atual,
      position: PopupMenuPosition.under,
      tooltip: 'Trocar turno ou eliminatórias',
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onEscolher,
      itemBuilder: (_) => [
        for (final f in fasesDosJogos)
          PopupMenuItem(
            value: f,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rotuloFase(f),
                    style: AppTextStyles.nome.copyWith(
                      color: f == atual ? AppColors.verde : null,
                    ),
                  ),
                ),
                if (f == atual) const Icon(Icons.check_rounded, color: AppColors.verde, size: 20),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.verde,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rotuloFase(atual), style: AppTextStyles.nome.copyWith(color: Colors.white)),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.expand_more_rounded, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}
