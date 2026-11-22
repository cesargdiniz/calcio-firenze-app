import 'package:material_ui/material_ui.dart';

/// Em telas largas (computador, tablet deitado), o app fica numa coluna
/// central de [largura] px, com fundo neutro dos lados, em vez de esticar
/// cartões e a barra de baixo pela tela inteira. No celular não muda nada.
class ColunaLarga extends StatelessWidget {
  static const largura = 700.0;
  static const _fundo = Color(0xFFECEBE6);

  final Widget child;
  const ColunaLarga({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= largura) return child;
    return ColoredBox(
      color: _fundo,
      child: Center(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24)],
          ),
          child: SizedBox(
            width: largura,
            // As telas (e menus, folhas e diálogos) enxergam só a coluna.
            child: MediaQuery(
              data: mq.copyWith(size: Size(largura, mq.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
