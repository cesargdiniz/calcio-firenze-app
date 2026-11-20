import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/categoria.dart';
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

  @override
  Widget build(BuildContext context) => DatasReservadas(
    titulo: 'Copa Master · datas reservadas',
    texto: 'Mata-mata entre os times do Master. Os confrontos são definidos depois; as datas já '
        'estão reservadas na Arena Gugu.',
    dias: datasCopaMaster2027,
  );
}

/// Datas reservadas do mata-mata de um turno: os confrontos dependem da
/// classificação, mas os participantes já podem se programar.
class DatasMataMata extends StatelessWidget {
  final Categoria categoria;
  final int turno;

  /// Etapas que já têm jogos criados (saem da lista).
  final Set<Fase> criadas;

  const DatasMataMata({
    super.key,
    required this.categoria,
    required this.turno,
    this.criadas = const {},
  });

  List<DiaReservado> get dias => [
    for (final d in datasMataMata(categoria, turno))
      if (!criadas.contains(d.fase)) d,
  ];

  @override
  Widget build(BuildContext context) => DatasReservadas(
    titulo: 'Eliminatórias do $turnoº turno · datas reservadas',
    texto: 'Os confrontos saem da classificação, mas as datas já estão definidas na Arena '
        'Gugu. Programe-se para estar no condomínio nesses dias.',
    dias: dias,
  );
}

class DatasReservadas extends StatelessWidget {
  final String titulo;
  final String texto;
  final List<DiaReservado> dias;

  const DatasReservadas({
    super.key,
    required this.titulo,
    required this.texto,
    required this.dias,
  });

  static String _horas(List<DateTime> h) {
    String hora(DateTime d) => dataHoraJogo(d).split(' · ').last;
    return h.map(hora).join(' e ');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TituloSecao(titulo),
      Text(texto, style: AppTextStyles.corpo),
      const SizedBox(height: AppSpacing.md),
      Cartao(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            for (final d in dias)
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
