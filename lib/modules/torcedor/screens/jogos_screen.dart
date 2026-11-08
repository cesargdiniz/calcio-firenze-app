import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../widgets/com_painel.dart';

/// T2 · Torcedor · Jogos
class JogosScreen extends StatelessWidget {
  const JogosScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ComPainel(builder: (context, painel) => _Jogos(painel: painel));
}

class _Jogos extends StatefulWidget {
  final Painel painel;
  const _Jogos({required this.painel});

  @override
  State<_Jogos> createState() => _JogosState();
}

class _JogosState extends State<_Jogos> {
  late int _rodada = _rodadaInicial();

  /// Abre na última rodada com jogo encerrado, como no Figma.
  int _rodadaInicial() {
    final encerradas = widget.painel.partidas.where((p) => p.encerrada && p.rodada != null);
    if (encerradas.isNotEmpty) return encerradas.last.rodada!;
    return widget.painel.rodadas.isEmpty ? 1 : widget.painel.rodadas.first;
  }

  @override
  Widget build(BuildContext context) {
    final painel = widget.painel;
    final jogos = painel.jogosDaRodada(_rodada);
    return ListView(
      padding: AppSpacing.tela,
      children: [
        const CabecalhoTela('Jogos'),
        const SizedBox(height: AppSpacing.md),
        const Row(children: [ChipFiltro('1º Turno', ativo: true)]),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in painel.rodadas) ...[
                ChipFiltro('R$r', ativo: r == _rodada, onTap: () => setState(() => _rodada = r)),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        TituloSecao('Rodada $_rodada'),
        for (final p in jogos) ...[
          CardJogo(
            partida: p,
            mandante: painel.time(p.mandanteId),
            visitante: painel.time(p.visitanteId),
            local: painel.local,
            onTap: () => context.go('/torcedor/jogos/${p.id}'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
