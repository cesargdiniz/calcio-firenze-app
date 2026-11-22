import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../calendario/calendario_screen.dart';
import '../../campeoes/campeoes_screen.dart';
import '../../../domain/entities/etapa.dart';
import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/widgets/logo_calcio.dart';
import '../widgets/com_painel.dart';
import '../widgets/tabela.dart';
import 'time_screen.dart';
import '../../../shared/layout/tela_larga.dart';

/// T1 · Torcedor · Início
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) {
      final suspensos = painel.suspensos.length;
      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          Row(
            children: [
              const LogoCalcio(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calcio Firenze', style: AppTextStyles.tituloSecao.copyWith(fontSize: 20)),
                    Text(painel.nomeTemporada, style: AppTextStyles.subtitulo),
                  ],
                ),
              ),
              BotaoCampeoes(categoria: painel.categoria),
              // Atleta ou Organização que entrou como Torcedor volta à escolha.
              IconButton(
                tooltip: 'Trocar de perfil',
                onPressed: () => context.push('/entrar'),
                icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.texto2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (painel.partidas.isEmpty) ...[
            const ListaVazia(
              icone: Icons.event_outlined,
              titulo: 'Confrontos ainda não sorteados',
              texto: 'As datas de todas as categorias já estão no calendário completo. Jogos, '
                  'tabela e suspensos aparecem aqui quando a Organização sortear os confrontos.',
            ),
            const AtalhoCalendario(),
          ],
          if (painel.proximaEtapa != null && suspensos > 0)
            _AvisoSuspensos(
              texto: suspensos == 1
                  ? '1 suspenso para ${_para(painel.proximaEtapa!)}'
                  : '$suspensos suspensos para ${_para(painel.proximaEtapa!)}',
              onTap: () => context.go('/torcedor/suspensos'),
            ),
          if (painel.proximaEtapa != null) ...[
            TituloSecao(
              'Próximos jogos · ${painel.proximaEtapa!.rotulo}',
              acao: 'Ver todos',
              onAcao: () => context.go('/torcedor/jogos'),
            ),
            for (final p in painel.proximosJogos.take(2)) ...[
              CardJogo(
              onTapTime: (id) => abrirTime(context, painel, id),
                partida: p,
                mandante: painel.time(p.mandanteId),
                visitante: painel.time(p.visitanteId),
                local: painel.local,
                onTap: () => context.go('/torcedor/jogos/${p.id}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
          if (painel.partidas.isNotEmpty) ...[
            TituloSecao(
              painel.turno == Painel.geral
                  ? 'Classificação geral'
                  : 'Classificação · ${painel.turno}º Turno',
              acao: 'Ver tabela',
              onAcao: () => context.go('/torcedor/tabela'),
            ),
            TabelaClassificacao(
              painel: painel,
              linhas: painel.tabela.take(4).toList(),
              compacta: true,
            ),
          ],
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

/// "a Rodada 4", "as Quartas de final", "a Final do 1º turno".
String _para(Etapa e) => switch (e.fase) {
  Fase.quartas || Fase.semifinal => 'as ${e.rotulo}',
  _ => 'a ${e.rotulo}',
};
