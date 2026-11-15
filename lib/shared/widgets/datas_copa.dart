import 'package:material_ui/material_ui.dart';

import '../../domain/usecases/gerar_calendario.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'basicos.dart';

/// Datas reservadas da Copa Master. Os confrontos aparecem quando a
/// Organização definir quem joga.
class DatasCopa extends StatelessWidget {
  const DatasCopa({super.key});

  static String _horas(List<DateTime> h) {
    String hora(DateTime d) => dataHoraJogo(d).split(' · ').last;
    return h.map(hora).join(' e ');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const TituloSecao('Copa Master · datas reservadas'),
      const Text(
        'Mata-mata entre os times do Master. Os confrontos são definidos depois; as datas já '
        'estão reservadas na Arena Gugu.',
        style: AppTextStyles.corpo,
      ),
      const SizedBox(height: AppSpacing.md),
      Cartao(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            for (final d in datasCopaMaster2027)
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: AppColors.verde),
                title: Text(d.etapa, style: AppTextStyles.nome),
                subtitle: Text(
                  '${dataCurta(d.horarios.first)} · ${_horas(d.horarios)} · '
                  '${d.horarios.length == 1 ? '1 jogo' : '${d.horarios.length} jogos'}',
                  style: AppTextStyles.pequeno,
                ),
                trailing: const Etiqueta(
                  'A definir',
                  cor: AppColors.texto2,
                  fundo: AppColors.cinzaSuave,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
