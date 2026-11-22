import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/campeoes.dart';
import '../../domain/entities/categoria.dart';
import '../categoria/categoria_controller.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/layout/tela_larga.dart';
import 'escalacao_campeao.dart';

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

/// Campeões de cada temporada da categoria.
class CampeoesScreen extends StatelessWidget {
  final Categoria categoria;
  const CampeoesScreen({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.fundo,
    appBar: AppBar(backgroundColor: AppColors.fundo, surfaceTintColor: AppColors.fundo),
    // Acompanha a troca de categoria no seletor do topo.
    body: BlocBuilder<CategoriaController, CategoriaStatus>(
      builder: (context, status) {
        final atual = status is CategoriaEscolhida ? status.categoria : categoria;
        if (TelaLarga.de(context)) {
          // No computador, as três categorias lado a lado.
          return PaginaLarga(
            titulo: 'Campeões',
            subtitulo: 'Calcio Firenze · todas as categorias',
            principal: [
              GradeLarga(
                minimo: 280,
                children: [
                  for (final c in Categoria.values)
                    if (campeoesDe(c).isNotEmpty)
                      BlocoLargo(
                        titulo: c == atual ? '${c.nome} · em exibição' : c.nome,
                        child: ListaCampeoes(categoria: c),
                      ),
                ],
              ),
            ],
          );
        }
        return ListView(
          padding: TelaLarga.margens(context),
          children: [
            CabecalhoTela('Campeões', subtitulo: 'Calcio Firenze · ${atual.nome}'),
            const SizedBox(height: AppSpacing.md),
            if (campeoesDe(atual).isEmpty)
              const Text('Ainda sem campeões registrados.', style: AppTextStyles.corpo)
            else
              ListaCampeoes(categoria: atual),
          ],
        );
      },
    ),
  );
}

/// Os campeões da categoria, do mais recente ao mais antigo.
class ListaCampeoes extends StatelessWidget {
  final Categoria categoria;
  const ListaCampeoes({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final t in campeoesDe(categoria)) ...[
        _CartaoTemporada(t, categoria),
        const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}

class _CartaoTemporada extends StatelessWidget {
  final TituloTemporada t;
  final Categoria categoria;
  const _CartaoTemporada(this.t, this.categoria);

  @override
  Widget build(BuildContext context) {
    final temElenco = t.elenco.isNotEmpty;
    return Semantics(
      button: temElenco,
      label: '${t.ano}, campeão ${t.campeao}${temElenco ? '. Ver escalação' : ''}',
      excludeSemantics: true,
      child: Cartao(
        onTap: temElenco ? () => abrirEscalacao(context, categoria, t) : null,
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.amarelo, size: 26),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 52,
              child: Text('${t.ano}', style: AppTextStyles.tituloSecao.copyWith(fontSize: 18)),
            ),
            Expanded(child: Text(t.campeao, style: AppTextStyles.nome)),
            if (temElenco) ...[
              const Text('Escalação', style: AppTextStyles.subtitulo),
              const Icon(Icons.chevron_right_rounded, color: AppColors.oliva),
            ],
          ],
        ),
      ),
    );
  }
}
