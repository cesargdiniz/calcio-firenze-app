import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';

/// Jogo na visão da Organização: agenda (data, hora, local) e súmula.
class JogoOrgScreen extends StatelessWidget {
  final String partidaId;
  const JogoOrgScreen({super.key, required this.partidaId});

  Future<void> _editarAgenda(BuildContext context, Partida p) async {
    final c = context.read<OrganizacaoController>();
    final data = await showDatePicker(
      context: context,
      initialDate: p.inicio,
      firstDate: DateTime(p.inicio.year - 1),
      lastDate: DateTime(p.inicio.year + 1, 12, 31),
      helpText: 'Data do jogo',
    );
    if (data == null || !context.mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(p.inicio),
      helpText: 'Horário do jogo',
    );
    if (hora == null || !context.mounted) return;
    final localCtrl = TextEditingController(text: p.local ?? 'Arena Gugu');
    final local = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Local do jogo'),
        content: TextField(controller: localCtrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(d, localCtrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    localCtrl.dispose();
    if (local == null || local.isEmpty) return;
    await c.salvarPartida(
      p.comAgenda(
        inicio: DateTime(data.year, data.month, data.day, hora.hour, hora.minute),
        local: local,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agenda salva.')));
    }
  }

  Future<void> _reabrir(BuildContext context, Partida p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Reabrir a súmula?'),
        content: const Text(
          'O resultado sai da tabela e os cartões deixam de contar até você encerrar de novo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Reabrir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final c = context.read<OrganizacaoController>();
      final rascunho = p.sumula;
      await c.salvarPartida(p.comSumula(null));
      if (context.mounted) {
        context.go('/organizacao/jogos/${p.id}/sumula', extra: rascunho);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final p = o.dados.partidas.where((x) => x.id == partidaId).firstOrNull;
      if (p == null) return const Center(child: Text('Jogo não encontrado.'));
      final s = p.sumula;
      final nomes = {for (final x in o.dados.pessoas) x.id: x.nome};

      return ListView(
        padding: AppSpacing.tela,
        children: [
          const VoltarGestao(rotulo: 'Jogos', rota: '/organizacao/jogos'),
          CardJogo(
            partida: p,
            mandante: o.time(p.mandanteId)!,
            visitante: o.time(p.visitanteId)!,
            local: p.local ?? o.dados.local,
          ),
          const TituloSecao('Agenda'),
          Cartao(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dataHoraJogo(p.inicio), style: AppTextStyles.nome),
                      Text(p.local ?? o.dados.local, style: AppTextStyles.pequeno),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: s != null ? null : () => _editarAgenda(context, p),
                  child: const Text('Alterar'),
                ),
              ],
            ),
          ),
          const TituloSecao('Súmula'),
          if (s == null) ...[
            const Text(
              'Lance depois do jogo, a partir da súmula de papel ou da transmissão.',
              style: AppTextStyles.corpo,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/organizacao/jogos/${p.id}/sumula'),
              child: const Text('Lançar súmula'),
            ),
          ] else ...[
            Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Text('Encerrada', style: AppTextStyles.nome)),
                      Etiqueta.verde('Publicada'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (s.ausenteWo != null)
                    Text(
                      'W.O.: ${o.time(s.ausenteWo!)?.nome} não compareceu.',
                      style: AppTextStyles.corpo,
                    ),
                  for (final g in s.gols)
                    Text(
                      '⚽ ${nomes[g.autorId] ?? 'Gol'}${g.contra ? ' (contra)' : ''} · '
                      '${o.time(g.timeId)?.sigla} · ${g.tempo}º tempo',
                      style: AppTextStyles.corpo,
                    ),
                  for (final c in s.cartoes)
                    Text(
                      '${c.tipo == TipoCartao.amarelo ? '🟨' : '🟥'} ${nomes[c.pessoaId] ?? c.pessoaId} · '
                      '${o.time(c.timeId)?.sigla}${c.funcao == Funcao.tecnico ? ' (técnico)' : ''}',
                      style: AppTextStyles.corpo,
                    ),
                  if (s.timesSemPontos.isNotEmpty)
                    Text(
                      'Perdeu os pontos: ${s.timesSemPontos.map((t) => o.time(t)?.nome).join(', ')}',
                      style: AppTextStyles.corpo.copyWith(color: AppColors.vermelho),
                    ),
                  if ((s.observacoes ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text('Observações: ${s.observacoes}', style: AppTextStyles.pequeno),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => _reabrir(context, p),
              child: const Text('Reabrir para corrigir'),
            ),
          ],
        ],
      );
    },
  );
}
