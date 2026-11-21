import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/usecases/montar_painel.dart';
import '../../categoria/categoria_controller.dart';
import '../../../domain/usecases/perfil_do_time.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';

/// Abre a tela do time (toque no escudo).
void abrirTime(BuildContext context, Painel painel, String timeId) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => TimeScreen(painel: painel, timeId: timeId)),
);

/// Escudo que abre a tela do time ao ser tocado.
class EscudoClicavel extends StatelessWidget {
  final Painel painel;
  final String timeId;
  final double tamanho;

  const EscudoClicavel({super.key, required this.painel, required this.timeId, this.tamanho = 36});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ver ${painel.time(timeId).nome}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => abrirTime(context, painel, timeId),
      child: Escudo(painel.time(timeId), tamanho: tamanho),
    ),
  );
}

/// Dirigente, títulos, campanha e destaques do time na temporada.
class TimeScreen extends StatelessWidget {
  final Painel painel;
  final String timeId;
  const TimeScreen({super.key, required this.painel, required this.timeId});

  @override
  Widget build(BuildContext context) {
    final p = perfilDoTime(painel, timeId);
    final c = p.campanha;
    String juntos(List<String> nomes) => nomes.join(' · ');
    // Trocou a categoria no seletor do topo: este time não é mais dela.
    return BlocListener<CategoriaController, CategoriaStatus>(
      listener: (context, status) {
        if (status is CategoriaEscolhida && status.categoria != painel.categoria) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(backgroundColor: AppColors.fundo, surfaceTintColor: AppColors.fundo),
      body: ListView(
        padding: AppSpacing.tela,
        children: [
          Center(child: Escudo(p.time, tamanho: 96)),
          const SizedBox(height: AppSpacing.md),
          Text(p.time.nome, textAlign: TextAlign.center, style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.xs),
          Text(
            painel.nomeTemporada,
            textAlign: TextAlign.center,
            style: AppTextStyles.pequeno,
          ),
          const SizedBox(height: AppSpacing.lg),
          Cartao(
            child: Column(
              children: [
                _Linha(
                  icone: Icons.badge_outlined,
                  rotulo: p.dirigentes.length > 1 ? 'Dirigentes' : 'Dirigente',
                  valor: p.dirigentes.isEmpty ? 'A definir' : juntos(p.dirigentes),
                ),
                if (p.tecnico != null)
                  _Linha(icone: Icons.sports_outlined, rotulo: 'Técnico', valor: p.tecnico!),
                _Linha(
                  icone: Icons.emoji_events_rounded,
                  cor: AppColors.amarelo,
                  rotulo: 'Títulos',
                  valor: p.titulos.isEmpty
                      ? 'Ainda não foi campeão'
                      : '${p.titulos.length}× campeão (${p.titulos.join(', ')})',
                ),
                if (c != null && c.jogos > 0)
                  _Linha(
                    icone: Icons.leaderboard_outlined,
                    rotulo: painel.turno == Painel.geral ? 'Campanha' : 'Campanha · ${painel.turno}º turno',
                    valor:
                        '${p.posicao}º lugar · ${c.pontos} pts · ${c.vitorias}V ${c.empates}E ${c.derrotas}D',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TituloSecao('Destaques da temporada'),
          Cartao(
            child: Column(
              children: [
                _Linha(
                  icone: Icons.sports_soccer,
                  rotulo: 'Artilheiro',
                  valor: p.artilheiro == null
                      ? 'Ninguém marcou ainda'
                      : '${juntos(p.artilheiro!.nomes)} · ${p.artilheiro!.valor} '
                            '${p.artilheiro!.valor == 1 ? 'gol' : 'gols'}',
                ),
                _Linha(
                  icone: Icons.star_rounded,
                  cor: AppColors.amarelo,
                  rotulo: 'Mais vezes melhor da partida',
                  valor: p.melhorDaPartida == null
                      ? 'Ainda sem escolhas'
                      : '${juntos(p.melhorDaPartida!.nomes)} · ${p.melhorDaPartida!.valor}×',
                ),
                _Linha(
                  icone: Icons.style_outlined,
                  cor: AppColors.vermelho,
                  rotulo: 'Mais indisciplinado',
                  valor: p.indisciplinado == null
                      ? 'Nenhum cartão'
                      : '${juntos(p.indisciplinado!.nomes)} · '
                            '${p.amarelosDoLider} amarelo${p.amarelosDoLider == 1 ? '' : 's'}'
                            '${p.vermelhosDoLider > 0 ? ', ${p.vermelhosDoLider} vermelho${p.vermelhosDoLider == 1 ? '' : 's'}' : ''}',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String rotulo;
  final String valor;
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.cor = AppColors.verde,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: cor, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: AppTextStyles.pequeno),
              const SizedBox(height: 2),
              Text(valor, style: AppTextStyles.nome),
            ],
          ),
        ),
      ],
    ),
  );
}
