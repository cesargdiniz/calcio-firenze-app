import 'package:material_ui/material_ui.dart';

import '../layout/tela_larga.dart';

/// Em telas largas que ainda não são de computador (tablet deitado, janela
/// estreita do navegador), o app fica numa coluna central de [largura] px,
/// com fundo neutro dos lados, em vez de esticar cartões e a barra de baixo
/// pela tela inteira. No celular não muda nada; no computador quem decide o
/// layout são as próprias telas (menu lateral).
class ColunaLarga extends StatelessWidget {
  static const largura = 700.0;

  final Widget child;
  const ColunaLarga({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= largura || TelaLarga.menuLateral(context)) return child;
    return _Coluna(largura: largura, child: child);
  }
}

/// No computador, telas de um passo só (entrar, pedir vínculo, escolher a
/// categoria) numa coluna central, com o mesmo visual do celular.
class ColunaCentral extends StatelessWidget {
  static const largura = 560.0;

  final Widget child;
  const ColunaCentral({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!TelaLarga.menuLateral(context)) return child;
    return _Coluna(largura: largura, child: child);
  }
}

class _Coluna extends StatelessWidget {
  static const _fundo = Color(0xFFECEBE6);

  final double largura;
  final Widget child;
  const _Coluna({required this.largura, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
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
