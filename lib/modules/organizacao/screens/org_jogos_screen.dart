import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';

/// O9 · Organização · Jogos: calendário do turno e acesso à súmula.
class OrgJogosScreen extends StatelessWidget {
  const OrgJogosScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(builder: (context, o) => _Jogos(o: o));
}

class _Jogos extends StatefulWidget {
  final OrgPronta o;
  const _Jogos({required this.o});

  @override
  State<_Jogos> createState() => _JogosState();
}

class _JogosState extends State<_Jogos> {
  int _turno = 1;
  int? _rodada;
  bool _gerando = false;

  List<Partida> get _doTurno => widget.o.dados.demonstracao
      ? const []
      : (widget.o.dados.partidas.where((p) => p.turno == _turno).toList()
          ..sort((a, b) => a.inicio.compareTo(b.inicio)));

  Future<void> _gerar({required bool refazer}) async {
    final demo = widget.o.dados.demonstracao;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(refazer ? 'Refazer o sorteio?' : 'Sortear o $_turnoº turno?'),
        content: Text(
          [
            'O app sorteia os confrontos (todos contra todos, 9 rodadas, 45 jogos) e '
                'ocupa os horários oficiais do calendário do Master, na Arena Gugu. '
                'Depois dá para mudar data, hora e local de cada jogo.',
            if (refazer) 'Os confrontos atuais deste turno serão substituídos.',
            if (demo) 'Os jogos e cartões de exemplo saem do app.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sortear')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _gerando = true);
    try {
      await context.read<OrganizacaoController>().gerarTurno(_turno);
      if (mounted) {
        setState(() => _rodada = 1);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Calendário do $_turnoº turno gerado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is StateError ? e.message : 'Não foi possível gerar. Tente de novo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final jogos = _doTurno;
    final rodadas = {
      for (final p in jogos)
        if (p.rodada != null) p.rodada!,
    }.toList()..sort();
    final pendente = jogos.where((p) => !p.encerrada).firstOrNull?.rodada;
    final rodada = _rodada != null && rodadas.contains(_rodada)
        ? _rodada!
        : (pendente ?? (rodadas.isEmpty ? 1 : rodadas.last));
    final daRodada = jogos.where((p) => p.rodada == rodada).toList();
    final algumaSumula = jogos.any((p) => p.encerrada);

    return ListView(
      padding: AppSpacing.tela,
      children: [
        const CabecalhoTela('Jogos', subtitulo: 'Calendário e súmulas'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final t in const [1, 2]) ...[
              ChipFiltro(
                '$tº Turno',
                ativo: t == _turno,
                onTap: () => setState(() {
                  _turno = t;
                  _rodada = null;
                }),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (jogos.isEmpty) ...[
          ListaVazia(
            titulo: 'Calendário ainda não gerado',
            texto: o.dados.demonstracao
                ? 'O app está mostrando a temporada de exemplo. Ao sortear o turno, '
                      'os jogos reais entram no lugar.'
                : 'Sorteie os confrontos do $_turnoº turno para montar as 9 rodadas.',
          ),
          FilledButton(
            onPressed: _gerando ? null : () => _gerar(refazer: false),
            child: Text(_gerando ? 'Gerando…' : 'Sortear e gerar o $_turnoº turno'),
          ),
        ] else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final r in rodadas) ...[
                  ChipFiltro('R$r', ativo: r == rodada, onTap: () => setState(() => _rodada = r)),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
          TituloSecao('Rodada $rodada'),
          for (final p in daRodada) ...[
            CardJogo(
              partida: p,
              mandante: o.time(p.mandanteId)!,
              visitante: o.time(p.visitanteId)!,
              local: p.local ?? o.dados.local,
              onTap: () => context.go('/organizacao/jogos/${p.id}'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!algumaSumula)
            TextButton(
              onPressed: _gerando ? null : () => _gerar(refazer: true),
              child: const Text('Refazer o sorteio deste turno'),
            ),
          if (algumaSumula)
            const Text(
              'O sorteio fica travado depois da primeira súmula encerrada.',
              style: AppTextStyles.pequeno,
            ),
        ],
        if (o.dados.demonstracao)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Dica: importe os elencos antes ou depois. O sorteio usa os 10 times da temporada.',
              style: TextStyle(fontFamily: 'OpenSans', fontSize: 11, color: AppColors.dica),
            ),
          ),
      ],
    );
  }
}
