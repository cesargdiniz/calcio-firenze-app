import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/usuario.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';

/// Voltar padrão das telas de Gestão.
class VoltarGestao extends StatelessWidget {
  final String rotulo;
  final String rota;
  const VoltarGestao({super.key, this.rotulo = 'Gestão', this.rota = '/organizacao/gestao'});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () => context.go(rota),
      icon: const Icon(Icons.chevron_left_rounded, color: AppColors.oliva),
      label: Text(rotulo, style: AppTextStyles.subtitulo.copyWith(fontSize: 14)),
    ),
  );
}

/// G3 · Gestão · Pedidos de vínculo
class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) => ListView(
      padding: AppSpacing.tela,
      children: [
        const VoltarGestao(),
        CabecalhoTela(
          'Pedidos de vínculo',
          subtitulo: o.pedidos.isEmpty
              ? 'Nenhum aguardando'
              : '${o.pedidos.length} aguardando aprovação',
        ),
        const SizedBox(height: AppSpacing.md),
        if (o.pedidos.isEmpty)
          const ListaVazia(
            titulo: 'Nenhum pedido',
            texto: 'Quando alguém pedir vínculo ao elenco, o pedido aparece aqui.',
          ),
        for (final u in o.pedidos) _Pedido(u, o),
      ],
    ),
  );
}

class _Pedido extends StatefulWidget {
  final Usuario usuario;
  final OrgPronta o;
  const _Pedido(this.usuario, this.o);

  @override
  State<_Pedido> createState() => _PedidoState();
}

class _PedidoState extends State<_Pedido> {
  bool _enviando = false;

  Future<void> _decidir(bool aprovar) async {
    final c = context.read<OrganizacaoController>();
    setState(() => _enviando = true);
    try {
      aprovar ? await c.aprovar(widget.usuario.uid) : await c.recusar(widget.usuario.uid);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não foi possível salvar. Tente de novo.')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final v = widget.o.vinculo(u)!;
    final pessoa = widget.o.pessoa(v.pessoaId);
    final time = widget.o.time(v.timeId);
    final conflito = widget.o.conflito(u);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Cartao(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (time != null) ...[Escudo(time), const SizedBox(width: AppSpacing.md)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((pessoa?.nome ?? u.nome).toUpperCase(), style: AppTextStyles.nome),
                      Text(
                        [
                          v.papel.rotulo,
                          time?.nome ?? v.timeId,
                          if (pessoa?.numero != null) '#${pessoa!.numero}',
                        ].join(' · '),
                        style: AppTextStyles.subtitulo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Conta: ${u.email}', style: AppTextStyles.pequeno),
            if (pessoa == null)
              _alerta('Essa pessoa não está mais no elenco. Recuse e peça um novo pedido.'),
            if (conflito != null)
              _alerta(
                'Esse nome já está vinculado à conta ${conflito.email}. Confira antes de aprovar.',
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enviando ? null : () => _decidir(false),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _enviando ? null : () => _decidir(true),
                    child: const Text('Aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _alerta(String texto) => Container(
    margin: const EdgeInsets.only(top: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(color: AppColors.amareloSuave, borderRadius: AppRadius.botao),
    child: Text(texto, style: AppTextStyles.corpo.copyWith(color: AppColors.tinta)),
  );
}
