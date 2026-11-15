import 'package:material_ui/material_ui.dart';

/// Espaçamentos e raios do Figma.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;

  /// Margem lateral das telas.
  static const tela = EdgeInsets.fromLTRB(24, 16, 24, 24);

  /// Tamanho padrão do logo em todas as telas internas (só a Splash muda).
  static const logo = Size(38, 56);
}

abstract final class AppRadius {
  static const cartao = BorderRadius.all(Radius.circular(16));
  static const botao = BorderRadius.all(Radius.circular(12));
  static const chip = BorderRadius.all(Radius.circular(99));
}

abstract final class AppShadow {
  static const suave = [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 16)];
}
