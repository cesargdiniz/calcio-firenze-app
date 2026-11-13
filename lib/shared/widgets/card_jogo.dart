import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/temporada.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'basicos.dart';
import 'escudo.dart';

/// Componente "Card/Jogo" do Figma.
class CardJogo extends StatelessWidget {
  final Partida partida;
  final Time mandante;
  final Time visitante;
  final String local;
  final VoidCallback? onTap;

  const CardJogo({
    super.key,
    required this.partida,
    required this.mandante,
    required this.visitante,
    required this.local,
    this.onTap,
  });

  String get _info {
    final fase = switch (partida.fase) {
      Fase.classificatoria => 'Rodada ${partida.rodada}',
      Fase.quartas => 'Quartas',
      Fase.semifinal => 'Semifinal',
      Fase.finalTurno => 'Final',
      Fase.grandeFinal => 'Grande final',
    };
    return '$fase · ${dataHoraJogo(partida.inicio)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = partida.sumula;
    final placar = s == null
        ? '×'
        : s.ausenteWo != null
        ? (s.ausenteWo == partida.mandanteId ? '0 : 6' : '6 : 0')
        : '${s.golsMandante} : ${s.golsVisitante}';

    return Cartao(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(_info, style: AppTextStyles.info)),
              s == null
                  ? const Etiqueta.neutra('Agendado')
                  : Etiqueta.verde(s.ausenteWo != null ? 'W.O.' : 'Encerrado'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Escudo(mandante),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  mandante.nome,
                  style: AppTextStyles.nome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: s == null ? Colors.transparent : AppColors.cinzaSuave,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(placar, style: AppTextStyles.placar),
              ),
              Expanded(
                child: Text(
                  visitante.nome,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.nome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Escudo(visitante),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(partida.local ?? local, style: AppTextStyles.pequeno),
        ],
      ),
    );
  }
}
