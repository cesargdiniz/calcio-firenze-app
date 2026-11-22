import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../calendario/calendario_screen.dart';
import '../../campeoes/campeoes_screen.dart';
import '../../../domain/entities/etapa.dart';
import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/layout/tela_larga.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/widgets/logo_calcio.dart';
import '../widgets/com_painel.dart';
import '../widgets/tabela.dart';
import 'time_screen.dart';

/// T1 · Torcedor · Início
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) {
      if (TelaLarga.de(context)) return _InicioLargo(painel: painel);
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

/// Início no computador: próximos jogos e classificação lado a lado com os
/// suspensos e o calendário.
class _InicioLargo extends StatelessWidget {
  final Painel painel;
  const _InicioLargo({required this.painel});

  @override
  Widget build(BuildContext context) {
    final etapa = painel.proximaEtapa;
    final suspensos = painel.suspensos.length;
    return PaginaLarga(
      titulo: 'Início',
      subtitulo: painel.nomeTemporada,
      acao: BotaoCampeoes(categoria: painel.categoria),
      principal: [
        if (painel.partidas.isEmpty)
          const ListaVazia(
            icone: Icons.event_outlined,
            titulo: 'Confrontos ainda não sorteados',
            texto: 'As datas de todas as categorias já estão no calendário completo. Jogos, '
                'tabela e suspensos aparecem aqui quando a Organização sortear os confrontos.',
          ),
        if (etapa != null && suspensos > 0)
          _AvisoSuspensos(
            texto: suspensos == 1
                ? '1 suspenso para ${_para(etapa)}'
                : '$suspensos suspensos para ${_para(etapa)}',
            onTap: () => context.go('/torcedor/suspensos'),
          ),
        if (etapa != null)
          BlocoLargo(
            titulo: 'Próximos jogos · ${etapa.rotulo}',
            acao: 'Ver todos',
            onAcao: () => context.go('/torcedor/jogos'),
            child: GradeLarga(
              children: [
                for (final p in painel.proximosJogos)
                  CardJogo(
                    onTapTime: (id) => abrirTime(context, painel, id),
                    partida: p,
                    mandante: painel.time(p.mandanteId),
                    visitante: painel.time(p.visitanteId),
                    local: painel.local,
                    onTap: () => context.go('/torcedor/jogos/${p.id}'),
                  ),
              ],
            ),
          ),
        if (painel.partidas.isNotEmpty)
          BlocoLargo(
            titulo: painel.turno == Painel.geral
                ? 'Classificação geral'
                : 'Classificação · ${painel.turno}º Turno',
            acao: 'Ver tabela',
            onAcao: () => context.go('/torcedor/tabela'),
            child: TabelaClassificacao(painel: painel, linhas: painel.tabela),
          ),
      ],
      lateral: [
        BlocoLargo(
          titulo: 'Suspensos',
          acao: 'Ver lista',
          onAcao: () => context.go('/torcedor/suspensos'),
          child: Text(
            switch ((etapa, suspensos)) {
              (null, _) => 'Sem jogos marcados.',
              (_, 0) => 'Ninguém suspenso para ${_para(etapa!)}.',
              (_, 1) => '1 atleta fora d${_para(etapa!)}.',
              _ => '$suspensos atletas fora d${_para(etapa!)}.',
            },
            style: AppTextStyles.corpo,
          ),
        ),
        const AtalhoCalendario(),
      ],
    );
  }
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
