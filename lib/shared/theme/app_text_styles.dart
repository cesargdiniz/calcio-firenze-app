import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Montserrat nos títulos, Open Sans no texto (identidade do Figma).
/// As fontes vão dentro do app (assets/fonts), sem depender de internet.
abstract final class AppTextStyles {
  static const _m = 'Montserrat';
  static const _o = 'OpenSans';

  static const tituloTela = TextStyle(
    fontFamily: _m,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.tinta,
  );
  static const tituloSecao = TextStyle(
    fontFamily: _m,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.tinta,
  );
  static const subtitulo = TextStyle(
    fontFamily: _m,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.oliva,
  );
  static const rotulo = TextStyle(
    fontFamily: _m,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.tinta,
  );
  static const nome = TextStyle(
    fontFamily: _m,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.tinta,
  );
  static const placar = TextStyle(
    fontFamily: _m,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.tinta,
  );
  static const info = TextStyle(
    fontFamily: _m,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.oliva,
  );
  static const botao = TextStyle(fontFamily: _m, fontSize: 15, fontWeight: FontWeight.w700);

  static const corpo = TextStyle(fontFamily: _o, fontSize: 13, color: AppColors.texto2);
  static const pequeno = TextStyle(fontFamily: _o, fontSize: 11, color: AppColors.dica);
}
