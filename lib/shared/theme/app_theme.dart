import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.verde,
      primary: AppColors.verde,
      secondary: AppColors.oliva,
      error: AppColors.vermelho,
      surface: AppColors.cartao,
    );

    Color corDaAba(Set<WidgetState> estados) =>
        estados.contains(WidgetState.selected) ? AppColors.verde : AppColors.dica;

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      fontFamily: 'OpenSans',
      scaffoldBackgroundColor: AppColors.fundo,
      cardTheme: const CardThemeData(
        color: AppColors.cartao,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cartao),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.botao),
          textStyle: AppTextStyles.botao,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verde,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.verde, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.botao),
          textStyle: AppTextStyles.botao,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cartao,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: corDaAba(estados),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(color: corDaAba(estados)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.linha, space: 1),
    );
  }
}
