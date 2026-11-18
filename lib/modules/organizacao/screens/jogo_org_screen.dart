import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/etapa.dart';
import '../../../domain/repositories/temporada_repository.dart';
import '../../calendario/calendario_controller.dart';
import '../../calendario/consistencia_calendario.dart';
import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/pdf/saida_pdf.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';

/// Jogo na visão da Organização: agenda (data, hora, local) e súmula.
class JogoOrgScreen extends StatelessWidget {
  final String partidaId;
  const JogoOrgScreen({super.key, required this.partidaId});

  Future<void> _editarAgenda(BuildContext context, Partida p) async {
    final c = context.read<OrganizacaoController>();
    // Calendário de todas as categorias, para avisar se a nova data fere
    // alguma regra.
    final calendario = CalendarioController(context.read<TemporadaRepository>())..iniciar();
    final nova = await showModalBottomSheet<Partida>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(value: calendario, child: _FormAgenda(partida: p)),
    );
    await calendario.close();
    if (nova == null || !context.mounted) return;
    await c.salvarPartida(nova);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agenda salva.')));
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
          OutlinedButton.icon(
            onPressed: () => abrirSumulaPdf(context, o.dados, p.id),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(s == null ? 'Súmula para imprimir (PDF)' : 'Súmula em PDF'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (s == null) ...[
            const Text(
              'Lance depois do jogo, a partir da súmula de papel ou da transmissão.',
              style: AppTextStyles.corpo,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.go('/organizacao/jogos/${p.id}/sumula'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Lançar placar e súmula'),
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
                  if (resultadoMataMata(p, (id) => o.time(id)?.nome ?? id) case final texto?)
                    Text(texto, style: AppTextStyles.nome),
                  if (s.ausenteWo != null)
                    Text(
                      'W.O.: ${o.time(s.ausenteWo!)?.nome} não compareceu. Os gols contam na '
                      'classificação, mas não têm autor e ficam fora da artilharia.',
                      style: AppTextStyles.corpo,
                    ),
                  for (final g in s.gols)
                    Text(
                      '⚽ ${nomes[g.autorId] ?? 'Gol'}${g.contra ? ' (contra)' : ''} · '
                      '${o.time(g.timeId)?.sigla} · ${g.tempo}º tempo',
                      style: AppTextStyles.corpo,
                    ),
                  if (s.melhorDaPartida case final m?)
                    Text(
                      '⭐ Melhor da partida: ${nomes[m.pessoaId] ?? m.pessoaId} · '
                      '${o.time(m.timeId)?.sigla}',
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
            // A súmula abre preenchida; a publicada continua valendo até salvar
            // a corrigida.
            FilledButton.icon(
              onPressed: () => context.go('/organizacao/jogos/${p.id}/sumula'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar placar e súmula'),
            ),
          ],
        ],
      );
    },
  );
}

/// Data, hora e local do jogo num formulário só.
class _FormAgenda extends StatefulWidget {
  final Partida partida;
  const _FormAgenda({required this.partida});

  @override
  State<_FormAgenda> createState() => _FormAgendaState();
}

class _FormAgendaState extends State<_FormAgenda> {
  late DateTime _inicio = widget.partida.inicio;
  late final _local = TextEditingController(text: widget.partida.local ?? 'Arena Gugu');

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _inicio,
      firstDate: DateTime(_inicio.year - 1),
      lastDate: DateTime(_inicio.year + 1, 12, 31),
      helpText: 'Data do jogo',
    );
    if (d != null) {
      setState(() => _inicio = DateTime(d.year, d.month, d.day, _inicio.hour, _inicio.minute));
    }
  }

  Future<void> _escolherHora() async {
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio),
      helpText: 'Horário do jogo',
    );
    if (h != null) {
      setState(() => _inicio = DateTime(_inicio.year, _inicio.month, _inicio.day, h.hour, h.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final partes = dataHoraJogo(_inicio).split(' · ');
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Agenda do jogo', style: AppTextStyles.tituloSecao),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolherData,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(partes.first),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolherHora,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(partes.last),
                ),
              ),
            ],
          ),
          AvisoNovaData(partidaId: widget.partida.id, inicio: _inicio),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _local,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Local',
              border: OutlineInputBorder(borderRadius: AppRadius.botao),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _local.text.trim().isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    widget.partida.comAgenda(inicio: _inicio, local: _local.text.trim()),
                  ),
            child: const Text('Salvar agenda'),
          ),
        ],
      ),
    );
  }
}
