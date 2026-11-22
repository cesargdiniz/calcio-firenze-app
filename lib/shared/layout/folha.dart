import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'tela_larga.dart';

/// Abre um formulário curto: no celular, folha que sobe de baixo; no
/// computador, painel que entra pela direita.
Future<T?> abrirFolha<T>(BuildContext context, WidgetBuilder builder) {
  if (!TelaLarga.computador(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: builder,
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: const Color(0x73292B23),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.cartao,
        elevation: 12,
        child: SizedBox(
          width: 480,
          height: double.infinity,
          child: SafeArea(child: FolhaLateral(child: Builder(builder: builder))),
        ),
      ),
    ),
    transitionBuilder: (context, animacao, _, filho) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animacao),
      child: filho,
    ),
  );
}

/// Marca o conteúdo aberto no painel lateral do computador.
class FolhaLateral extends InheritedWidget {
  const FolhaLateral({super.key, required super.child});

  static bool ativa(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FolhaLateral>() != null;

  @override
  bool updateShouldNotify(FolhaLateral oldWidget) => false;
}
