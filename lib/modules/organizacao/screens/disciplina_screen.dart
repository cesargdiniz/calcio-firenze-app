import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/temporada.dart';
import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import '../../../shared/layout/tela_larga.dart';

/// O5 · Organização · Disciplina: pendências calculadas das súmulas.
class DisciplinaScreen extends StatelessWidget {
  const DisciplinaScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(builder: (context, o) => _Disciplina(o: o));
}

class _Disciplina extends StatefulWidget {
  final OrgPronta o;
  const _Disciplina({required this.o});

  @override
  State<_Disciplina> createState() => _DisciplinaState();
}

class _DisciplinaState extends State<_Disciplina> {
  bool _quitadas = false;
  final Set<String> _salvando = {};

  Future<void> _alternar(Pendencia x) async {
    final c = context.read<OrganizacaoController>();
    setState(() => _salvando.add(x.id));
    try {
      x.pagoEm == null ? await c.registrarPagamento(x.id) : await c.desfazerPagamento(x.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não foi possível salvar. Tente de novo.')));
      }
    } finally {
      if (mounted) setState(() => _salvando.remove(x.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.o.dados;
    final agora = d.relogio ?? DateTime.now();
    final motor = MotorDisciplinar(
      partidas: d.partidas,
      pagamentos: d.pagamentos,
      decisoes: d.decisoes,
      agora: agora,
      params: d.parametros,
    );
    final nomes = {for (final p in d.pessoas) p.id: p.nome};
    final abertas = motor.pendenciasEmAberto()
      ..sort((a, b) {
        final va = a.status(agora) == StatusPendencia.vencida ? 0 : 1;
        final vb = b.status(agora) == StatusPendencia.vencida ? 0 : 1;
        return va != vb ? va.compareTo(vb) : a.origemEm.compareTo(b.origemEm);
      });
    final quitadas = motor.pendencias.where((p) => p.pagoEm != null).toList()
      ..sort((a, b) => b.pagoEm!.compareTo(a.pagoEm!));
    final lista = _quitadas ? quitadas : abertas;
    final total = abertas.fold(0, (s, p) => s + p.valor);

    if (TelaLarga.de(context)) {
      // Total em aberto por time, do maior para o menor.
      final porTime = <String, int>{};
      for (final x in abertas) {
        porTime[x.timeId] = (porTime[x.timeId] ?? 0) + x.valor;
      }
      final ordem = porTime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return PaginaLarga(
        titulo: 'Disciplina',
        subtitulo: abertas.isEmpty
            ? 'Nenhuma pendência em aberto'
            : '${abertas.length} em aberto · ${reais(total)}',
        topo: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChipFiltro(
                'Em aberto (${abertas.length})',
                ativo: !_quitadas,
                onTap: () => setState(() => _quitadas = false),
              ),
              ChipFiltro(
                'Quitadas (${quitadas.length})',
                ativo: _quitadas,
                onTap: () => setState(() => _quitadas = true),
              ),
            ],
          ),
          if (d.demonstracao)
            const Text(
              'Temporada de exemplo: as quitações só valem depois que os jogos reais forem gerados.',
              style: AppTextStyles.pequeno,
            ),
        ],
        principal: [
          if (lista.isEmpty)
            ListaVazia(
              titulo: _quitadas ? 'Nenhuma quitação' : 'Tudo em dia',
              texto: _quitadas
                  ? 'As pendências marcadas como pagas aparecem aqui.'
                  : 'Cartões das súmulas encerradas geram pendências aqui.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final x in lista)
                  _CartaoPendencia(
                    pendencia: x,
                    nome: nomes[x.pessoaId] ?? x.pessoaId,
                    time: widget.o.time(x.timeId),
                    agora: agora,
                    salvando: _salvando.contains(x.id),
                    onAlternar: d.demonstracao ? null : () => _alternar(x),
                  ),
              ],
            ),
        ],
        lateral: [
          BlocoLargo(
            titulo: 'Em aberto por time',
            child: ordem.isEmpty
                ? const Text('Todos os times em dia.', style: AppTextStyles.corpo)
                : Column(
                    children: [
                      for (final MapEntry(key: id, value: valor) in ordem)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              if (widget.o.time(id) case final t?) ...[
                                Escudo(t, tamanho: 24),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Expanded(
                                child: Text(widget.o.time(id)?.nome ?? id, style: AppTextStyles.nome),
                              ),
                              Text(reais(valor), style: AppTextStyles.corpo),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          BlocoLargo(
            titulo: 'Como funciona',
            child: Text(
              'Amarelo ${reais(d.parametros.valorAmarelo)} · vermelho ${reais(d.parametros.valorVermelho)}. '
              'A quitação vence antes do próximo jogo do time; quem não quitar fica impedido.',
              style: AppTextStyles.corpo,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: TelaLarga.margens(context),
      children: [
        CabecalhoTela(
          'Disciplina',
          subtitulo: abertas.isEmpty
              ? 'Nenhuma pendência em aberto'
              : '${abertas.length} em aberto · ${reais(total)}',
        ),
        if (d.demonstracao)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Temporada de exemplo: as quitações só valem depois que os jogos reais forem gerados.',
              style: AppTextStyles.pequeno,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChipFiltro(
              'Em aberto (${abertas.length})',
              ativo: !_quitadas,
              onTap: () => setState(() => _quitadas = false),
            ),
            ChipFiltro(
              'Quitadas (${quitadas.length})',
              ativo: _quitadas,
              onTap: () => setState(() => _quitadas = true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (lista.isEmpty)
          ListaVazia(
            titulo: _quitadas ? 'Nenhuma quitação' : 'Tudo em dia',
            texto: _quitadas
                ? 'As pendências marcadas como pagas aparecem aqui.'
                : 'Cartões das súmulas encerradas geram pendências aqui.',
          ),
        for (final x in lista)
          _CartaoPendencia(
            pendencia: x,
            nome: nomes[x.pessoaId] ?? x.pessoaId,
            time: widget.o.time(x.timeId),
            agora: agora,
            salvando: _salvando.contains(x.id),
            onAlternar: d.demonstracao ? null : () => _alternar(x),
          ),
      ],
    );
  }
}

class _CartaoPendencia extends StatelessWidget {
  final Pendencia pendencia;
  final String nome;
  final Time? time;
  final DateTime agora;
  final bool salvando;
  final VoidCallback? onAlternar;

  const _CartaoPendencia({
    required this.pendencia,
    required this.nome,
    required this.time,
    required this.agora,
    required this.salvando,
    required this.onAlternar,
  });

  @override
  Widget build(BuildContext context) {
    final x = pendencia;
    final (rotulo, cor, fundo) = switch (x.status(agora)) {
      StatusPendencia.quitada => (
        'Quitada ${dataHoraJogo(x.pagoEm!)}',
        AppColors.verde,
        AppColors.verdeSuave,
      ),
      StatusPendencia.vencida => ('Vencida', AppColors.vermelho, AppColors.vermelhoSuave),
      StatusPendencia.aVencer => (
        'Até ${dataHoraJogo(x.prazo!)}',
        AppColors.amareloEscuro,
        AppColors.amareloSuave,
      ),
      StatusPendencia.semPrazo => ('Sem prazo', AppColors.texto2, AppColors.cinzaSuave),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Cartao(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (time != null) ...[
                  Escudo(time!, tamanho: 28),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${nome.toUpperCase()}${x.funcao == Funcao.tecnico ? ' · técnico' : ''}',
                        style: AppTextStyles.nome,
                      ),
                      Text(x.descricao, style: AppTextStyles.pequeno),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(reais(x.valor), style: AppTextStyles.nome),
                    Etiqueta(rotulo, cor: cor, fundo: fundo),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: x.pagoEm == null
                  ? FilledButton.tonal(
                      onPressed: salvando ? null : onAlternar,
                      child: const Text('Marcar como quitada'),
                    )
                  : TextButton(
                      onPressed: salvando ? null : onAlternar,
                      child: const Text('Desfazer quitação'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
