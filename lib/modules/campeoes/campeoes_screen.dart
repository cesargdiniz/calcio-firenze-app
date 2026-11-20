import 'package:material_ui/material_ui.dart';

import '../../domain/entities/campeoes.dart';
import '../../domain/entities/categoria.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';

/// Botão de troféu do Início: abre os campeões da categoria. Some nas
/// categorias sem histórico.
class BotaoCampeoes extends StatelessWidget {
  final Categoria categoria;
  const BotaoCampeoes({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    if (campeoesDe(categoria).isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Campeões',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CampeoesScreen(categoria: categoria)),
      ),
      icon: const Icon(Icons.emoji_events_outlined, color: AppColors.amareloEscuro),
    );
  }
}

/// Campeões e vices de cada temporada da categoria.
class CampeoesScreen extends StatelessWidget {
  final Categoria categoria;
  const CampeoesScreen({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.fundo,
    appBar: AppBar(backgroundColor: AppColors.fundo, surfaceTintColor: AppColors.fundo),
    body: ListView(
      padding: AppSpacing.tela,
      children: [
        CabecalhoTela('Campeões', subtitulo: 'Calcio Firenze · ${categoria.nome}'),
        const SizedBox(height: AppSpacing.md),
        for (final t in campeoesDe(categoria)) ...[
          _CartaoTemporada(t),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ),
  );
}

class _CartaoTemporada extends StatelessWidget {
  final TituloTemporada t;
  const _CartaoTemporada(this.t);

  @override
  Widget build(BuildContext context) => Semantics(
    label: t.emAndamento
        ? '${t.ano}, em andamento'
        : '${t.ano}, campeão ${t.campeao}, vice ${t.vice}',
    excludeSemantics: true,
    child: Cartao(
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text('${t.ano}', style: AppTextStyles.tituloSecao.copyWith(fontSize: 18)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: t.emAndamento
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Etiqueta(
                      'Em andamento',
                      cor: AppColors.texto2,
                      fundo: AppColors.cinzaSuave,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Linha(
                        icone: Icons.emoji_events_rounded,
                        cor: AppColors.amarelo,
                        rotulo: 'Campeão',
                        time: t.campeao!,
                        destaque: true,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Linha(
                        icone: Icons.military_tech_rounded,
                        cor: AppColors.dica,
                        rotulo: 'Vice',
                        time: t.vice ?? '—',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String rotulo;
  final String time;
  final bool destaque;
  const _Linha({
    required this.icone,
    required this.cor,
    required this.rotulo,
    required this.time,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icone, color: cor, size: 20),
      const SizedBox(width: AppSpacing.sm),
      SizedBox(width: 64, child: Text(rotulo, style: AppTextStyles.pequeno)),
      Expanded(
        child: Text(
          time,
          style: destaque ? AppTextStyles.nome : AppTextStyles.corpo,
        ),
      ),
    ],
  );
}
