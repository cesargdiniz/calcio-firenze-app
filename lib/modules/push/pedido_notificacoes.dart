import 'package:material_ui/material_ui.dart';

import '../../domain/repositories/push_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';

/// Antes do pedido do sistema, o app explica para que servem as
/// notificações. Aparece uma vez, por cima do app, depois que a pessoa
/// escolhe a categoria ([pronto]).
class PedidoNotificacoes extends StatefulWidget {
  final PushRepository push;
  final bool pronto;
  final Widget child;

  const PedidoNotificacoes({
    super.key,
    required this.push,
    required this.pronto,
    required this.child,
  });

  @override
  State<PedidoNotificacoes> createState() => _PedidoNotificacoesState();
}

class _PedidoNotificacoesState extends State<PedidoNotificacoes> {
  bool _mostrar = false;
  bool _conferido = false;

  @override
  void initState() {
    super.initState();
    _conferir();
  }

  @override
  void didUpdateWidget(PedidoNotificacoes old) {
    super.didUpdateWidget(old);
    _conferir();
  }

  Future<void> _conferir() async {
    if (_conferido || !widget.pronto) return;
    _conferido = true;
    final precisa = await widget.push.precisaPerguntar();
    if (mounted && precisa) setState(() => _mostrar = true);
  }

  Future<void> _responder({required bool sim}) async {
    setState(() => _mostrar = false);
    sim ? await widget.push.autorizar() : await widget.push.recusar();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_mostrar)
        Positioned.fill(
          child: TelaPedidoNotificacoes(
            onAutorizar: () => _responder(sim: true),
            onAgoraNao: () => _responder(sim: false),
          ),
        ),
    ],
  );
}

/// Tela do pedido: texto da Administração e as duas respostas.
class TelaPedidoNotificacoes extends StatelessWidget {
  final VoidCallback onAutorizar;
  final VoidCallback onAgoraNao;

  const TelaPedidoNotificacoes({super.key, required this.onAutorizar, required this.onAgoraNao});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.fundo,
    child: SafeArea(
      child: Padding(
        padding: AppSpacing.tela,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 44,
                  color: AppColors.verde,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Notificações',
              textAlign: TextAlign.center,
              style: AppTextStyles.tituloTela,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'O Calcio Firenze precisa da sua autorização para enviar notificações de '
              'resultados dos jogos, suspensões, multas e outras comunicações do seu interesse.',
              textAlign: TextAlign.center,
              style: AppTextStyles.corpo.copyWith(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Você autoriza o recebimento de mensagens da Administração do Calcio Firenze?',
              textAlign: TextAlign.center,
              style: AppTextStyles.nome.copyWith(fontSize: 15, height: 1.4),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onAutorizar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.verde,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Sim, autorizo', style: AppTextStyles.botao),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAgoraNao,
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(
                'Agora não',
                style: AppTextStyles.botao.copyWith(color: AppColors.texto2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Você pode mudar isso depois nos ajustes do celular.',
              textAlign: TextAlign.center,
              style: AppTextStyles.pequeno,
            ),
          ],
        ),
      ),
    ),
  );
}
