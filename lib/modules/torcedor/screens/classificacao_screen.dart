import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../widgets/com_painel.dart';
import '../widgets/tabela.dart';

/// T3 · Torcedor · Classificação
class ClassificacaoScreen extends StatelessWidget {
  const ClassificacaoScreen({super.key});

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) => ListView(
      padding: AppSpacing.tela,
      children: [
        const CabecalhoTela('Classificação', subtitulo: 'Fase classificatória'),
        const SizedBox(height: AppSpacing.md),
        const Row(children: [ChipFiltro('1º Turno', ativo: true)]),
        const SizedBox(height: AppSpacing.lg),
        TabelaClassificacao(painel: painel, linhas: painel.tabela),
        const SizedBox(height: AppSpacing.md),
        const _Legenda(AppColors.verde, '1º e 2º vão direto às semifinais'),
        const _Legenda(AppColors.oliva, '3º ao 6º jogam as quartas de final'),
        if (painel.tabela.any((l) => l.aguardaSorteio))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '* Empate em todos os critérios: decidido por sorteio (art. 42).',
              style: AppTextStyles.pequeno,
            ),
          ),
      ],
    ),
  );
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;
  const _Legenda(this.cor, this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      children: [
        Container(width: 10, height: 10, color: cor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(texto, style: AppTextStyles.pequeno.copyWith(color: AppColors.texto2)),
        ),
      ],
    ),
  );
}
