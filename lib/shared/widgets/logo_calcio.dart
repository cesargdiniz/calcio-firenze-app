import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Logo do Calcio. Tamanho fixo em todas as telas internas (38 × 56);
/// só a Splash usa [LogoCalcio.grande].
class LogoCalcio extends StatelessWidget {
  final Size tamanho;

  const LogoCalcio({super.key}) : tamanho = AppSpacing.logo;
  const LogoCalcio.grande({super.key}) : tamanho = const Size(152, 224);

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo.png',
    width: tamanho.width,
    height: tamanho.height,
    fit: BoxFit.contain,
    semanticLabel: 'Calcio Firenze',
  );
}
