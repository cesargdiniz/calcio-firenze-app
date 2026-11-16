import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../organizacao_controller.dart';

/// Grupos de times empatados em todos os critérios do art. 42 na tabela do
/// painel, cada um na ordem atual da tabela.
List<List<String>> gruposEmpatados(Painel painel) {
  final vistos = <String>{};
  return [
    for (final l in painel.tabela)
      if (l.empatadosNoSorteio.length > 1 && vistos.add(l.empatadosNoSorteio.first))
        l.empatadosNoSorteio,
  ];
}

/// A fase classificatória da tabela já terminou (no turno, ou nos dois, para
/// a geral). Antes disso o empate ainda pode se desfazer em campo.
bool classificatoriaEncerrada(Painel painel) {
  final jogos = [
    for (final p in painel.partidas)
      if (p.fase == Fase.classificatoria &&
          (painel.turno == Painel.geral || p.turno == painel.turno))
        p,
  ];
  if (jogos.isEmpty || jogos.any((p) => !p.encerrada)) return false;
  return painel.turno != Painel.geral || {1, 2}.every((t) => jogos.any((p) => p.turno == t));
}

/// Organização: empates que só o sorteio resolve (art. 42). O sorteio é feito
/// fora do app (moeda, bingo); aqui só se registra a ordem que saiu.
class SorteiosDaTabela extends StatelessWidget {
  final Painel painel;
  const SorteiosDaTabela({super.key, required this.painel});

  @override
  Widget build(BuildContext context) {
    if (!classificatoriaEncerrada(painel)) return const SizedBox.shrink();
    final grupos = gruposEmpatados(painel);
    if (grupos.isEmpty) return const SizedBox.shrink();
    String nome(String id) => painel.time(id).nome;
    final linhas = {for (final l in painel.tabela) l.timeId: l};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in grupos)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.amareloSuave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Empate em todos os critérios (art. 42)', style: AppTextStyles.nome),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  linhas[g.first]!.aguardaSorteio
                      ? '${g.map(nome).join(', ')} empataram em tudo. Faça o sorteio (moeda, '
                            'bingo) e registre aqui a ordem que saiu.'
                      : 'Decidido por sorteio: ${g.map(nome).join(', ')}, nesta ordem.',
                  style: AppTextStyles.corpo,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _registrar(context, g, nome),
                    child: Text(
                      linhas[g.first]!.aguardaSorteio ? 'Registrar resultado do sorteio' : 'Corrigir',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _registrar(
    BuildContext context,
    List<String> grupo,
    String Function(String) nome,
  ) async {
    final controller = context.read<OrganizacaoController>();
    final avisos = ScaffoldMessenger.of(context);
    final ordem = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrdemSorteada(grupo: grupo, nome: nome),
    );
    if (ordem == null) return;
    try {
      await controller.registrarSorteio(painel.turno, ordem);
      avisos.showSnackBar(const SnackBar(content: Text('Sorteio registrado.')));
    } catch (_) {
      avisos.showSnackBar(const SnackBar(content: Text('Não foi possível gravar. Tente de novo.')));
    }
  }
}

/// Toca nos times na ordem sorteada: o primeiro toque é quem fica à frente.
class _OrdemSorteada extends StatefulWidget {
  final List<String> grupo;
  final String Function(String) nome;
  const _OrdemSorteada({required this.grupo, required this.nome});

  @override
  State<_OrdemSorteada> createState() => _OrdemSorteadaState();
}

class _OrdemSorteadaState extends State<_OrdemSorteada> {
  final _ordem = <String>[];

  void _tocar(String id) => setState(() {
    if (_ordem.contains(id)) return;
    _ordem.add(id);
    // O último não precisa de toque.
    final faltam = widget.grupo.where((t) => !_ordem.contains(t)).toList();
    if (faltam.length == 1) _ordem.add(faltam.single);
  });

  @override
  Widget build(BuildContext context) {
    final completo = _ordem.length == widget.grupo.length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Resultado do sorteio', style: AppTextStyles.tituloSecao),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Toque nos times na ordem que saiu no sorteio: primeiro quem fica à frente.',
              style: AppTextStyles.corpo,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final id in widget.grupo)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Cartao(
                  onTap: () => _tocar(id),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          _ordem.contains(id) ? '${_ordem.indexOf(id) + 1}º' : '–',
                          style: AppTextStyles.nome.copyWith(color: AppColors.verde),
                        ),
                      ),
                      Expanded(child: Text(widget.nome(id), style: AppTextStyles.nome)),
                    ],
                  ),
                ),
              ),
            if (_ordem.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(_ordem.clear),
                  child: const Text('Recomeçar'),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: completo ? () => Navigator.pop(context, [..._ordem]) : null,
              child: const Text('Confirmar ordem'),
            ),
          ],
        ),
      ),
    );
  }
}
