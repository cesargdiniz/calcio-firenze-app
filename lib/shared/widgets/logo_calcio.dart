import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// Logo do Calcio, em tamanho fixo em todas as telas internas (38 × 56).
/// A abertura tem a própria arte (`assets/splash`).
class LogoCalcio extends StatelessWidget {
  final Size tamanho;

  const LogoCalcio({super.key}) : tamanho = AppSpacing.logo;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo.png',
    width: tamanho.width,
    height: tamanho.height,
    fit: BoxFit.contain,
    semanticLabel: 'Calcio Firenze',
  );
}
