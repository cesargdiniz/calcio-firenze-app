import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/calendario_geral.dart';
import '../../domain/usecases/verificar_calendario.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import 'calendario_controller.dart';

/// Situação do calendário de todas as categorias frente às cinco regras
/// (Gestão da Organização).
class ConsistenciaCalendario extends StatelessWidget {
  const ConsistenciaCalendario({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (c) => CalendarioController(c.read<TemporadaRepository>())..iniciar(),
    child: BlocBuilder<CalendarioController, CalendarioStatus>(
      builder: (context, s) => switch (s) {
        CalendarioCarregando() => const SizedBox.shrink(),
        CalendarioPronto(:final jogos) => QuadroInconsistencias(verificarCalendario(jogos)),
      },
    ),
  );
}

/// Lista das regras violadas, ou um aviso de calendário em ordem.
class QuadroInconsistencias extends StatelessWidget {
  final List<Inconsistencia> inconsistencias;

  /// Título quando há problema.
  final String? titulo;
  const QuadroInconsistencias(this.inconsistencias, {super.key, this.titulo});

  @override
  Widget build(BuildContext context) {
    if (inconsistencias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.verdeSuave, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.event_available_rounded, color: AppColors.verde),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Calendário sem inconsistências: as datas de todas as categorias seguem as regras.',
                style: AppTextStyles.corpo,
              ),
            ),
          ],
        ),
      );
    }
    final porRegra = <RegraCalendario, List<Inconsistencia>>{};
    for (final i in inconsistencias) {
      porRegra.putIfAbsent(i.regra, () => []).add(i);
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.vermelhoSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vermelho.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.vermelho),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  titulo ??
                      (inconsistencias.length == 1
                          ? 'Inconsistência no calendário'
                          : '${inconsistencias.length} inconsistências no calendário'),
                  style: AppTextStyles.nome.copyWith(color: AppColors.vermelho),
                ),
              ),
            ],
          ),
          for (final MapEntry(key: regra, value: itens) in porRegra.entries) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Regra ${regra.numero} · ${regra.texto}',
              style: AppTextStyles.corpo.copyWith(
                color: AppColors.tinta,
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final i in itens)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: AppSpacing.sm),
                child: Text('• ${i.detalhe}', style: AppTextStyles.corpo),
              ),
          ],
        ],
      ),
    );
  }
}

/// Regras que a nova data de uma partida viola (formulário de agenda). Usa o
/// [CalendarioController] de quem abriu o formulário.
class AvisoNovaData extends StatelessWidget {
  final String partidaId;
  final DateTime inicio;
  const AvisoNovaData({super.key, required this.partidaId, required this.inicio});

  /// Inconsistências que envolvem a partida, com ela na nova data.
  static List<Inconsistencia> simular(
    List<JogoDoCalendario> eventos,
    String partidaId,
    DateTime inicio,
  ) {
    final i = eventos.indexWhere((e) => e.partida?.id == partidaId);
    if (i < 0) return const [];
    final movido = eventos[i].em(inicio);
    final simulado = [...eventos]..[i] = movido;
    return [
      for (final x in verificarCalendario(simulado))
        if (x.jogos.contains(movido)) x,
    ];
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CalendarioController, CalendarioStatus>(
    builder: (context, s) {
      if (s is! CalendarioPronto) return const SizedBox.shrink();
      final problemas = simular(s.jogos, partidaId, inicio);
      if (problemas.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: QuadroInconsistencias(problemas, titulo: 'Esta data deixa o calendário inconsistente'),
      );
    },
  );
}
