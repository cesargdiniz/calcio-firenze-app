import 'package:calcio_regras/calcio_regras.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/entities/etapa.dart';
import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../widgets/com_painel.dart';

/// T2 · Torcedor · Jogos
class JogosScreen extends StatelessWidget {
  /// Rota da lista, para abrir o detalhe dentro da navegação certa
  /// (Torcedor ou Participante).
  final String rotaBase;
  const JogosScreen({super.key, this.rotaBase = '/torcedor/jogos'});

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) => _Jogos(painel: painel, rotaBase: rotaBase),
  );
}

class _Jogos extends StatefulWidget {
  final Painel painel;
  final String rotaBase;
  const _Jogos({required this.painel, required this.rotaBase});

  @override
  State<_Jogos> createState() => _JogosState();
}

class _JogosState extends State<_Jogos> {
  late Etapa? _etapa = _etapaInicial();

  /// Abre na última etapa com jogo encerrado, como no Figma.
  Etapa? _etapaInicial() {
    final encerradas = widget.painel.partidas.where((p) => p.encerrada);
    if (encerradas.isNotEmpty) return Etapa.de(encerradas.last);
    return widget.painel.etapas.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final painel = widget.painel;
    final etapas = painel.etapas;
    final doisTurnos = etapas.any((e) => e.turno == 2);
    final etapa = etapas.contains(_etapa) ? _etapa : etapas.firstOrNull;
    final jogos = etapa == null ? const <Partida>[] : painel.jogosDa(etapa);
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
              for (final e in etapas) ...[
                ChipFiltro(
                  doisTurnos && e.turno > 0 ? '${e.turno}ºT ${e.curto}' : e.curto,
                  ativo: e == etapa,
                  onTap: () => setState(() => _etapa = e),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        if (etapa != null) TituloSecao(etapa.rotulo),
        for (final p in jogos) ...[
          CardJogo(
            partida: p,
            mandante: painel.time(p.mandanteId),
            visitante: painel.time(p.visitanteId),
            local: painel.local,
            onTap: () => context.go('${widget.rotaBase}/${p.id}'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
