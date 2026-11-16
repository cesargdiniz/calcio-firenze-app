import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Título de tela com subtítulo em oliva.
class CabecalhoTela extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  /// Botão à direita do título (ex.: compartilhar).
  final Widget? acao;
  const CabecalhoTela(this.titulo, {super.key, this.subtitulo, this.acao});

  @override
  Widget build(BuildContext context) {
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTextStyles.tituloTela),
        if (subtitulo != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitulo!, style: AppTextStyles.subtitulo),
        ],
      ],
    );
    if (acao == null) return textos;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: textos), acao!],
    );
  }
}

/// Título de seção com ação opcional à direita ("Ver todos").
class TituloSecao extends StatelessWidget {
  final String titulo;
  final String? acao;
  final VoidCallback? onAcao;
  const TituloSecao(this.titulo, {super.key, this.acao, this.onAcao});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Text(titulo, style: AppTextStyles.tituloSecao)),
        if (acao != null)
          InkWell(
            onTap: onAcao,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Text(acao!, style: AppTextStyles.subtitulo),
            ),
          ),
      ],
    ),
  );
}

/// Cartão branco com sombra suave (padrão do Figma).
class Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const Cartao({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.cartao,
      borderRadius: AppRadius.cartao,
      boxShadow: AppShadow.suave,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadius.cartao,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Etiqueta pequena (ex.: "Encerrado", "Agendado").
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;
  const Etiqueta(this.texto, {super.key, required this.cor, required this.fundo});

  const Etiqueta.verde(this.texto, {super.key})
    : cor = AppColors.verde,
      fundo = AppColors.verdeSuave;

  const Etiqueta.neutra(this.texto, {super.key})
    : cor = AppColors.texto2,
      fundo = AppColors.cinzaSuave;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: fundo, borderRadius: AppRadius.chip),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(texto, style: AppTextStyles.info.copyWith(fontSize: 9, color: cor)),
    ),
  );
}

/// Chip de filtro (turno, rodada, aba).
class ChipFiltro extends StatelessWidget {
  final String texto;
  final bool ativo;
  final VoidCallback? onTap;
  const ChipFiltro(this.texto, {super.key, required this.ativo, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    selected: ativo,
    button: true,
    child: Material(
      color: ativo ? AppColors.verde : AppColors.cartao,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.chip,
        side: ativo ? BorderSide.none : const BorderSide(color: AppColors.linha),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            texto,
            style: AppTextStyles.rotulo.copyWith(color: ativo ? Colors.white : AppColors.tinta),
          ),
        ),
      ),
    ),
  );
}

/// Estado de lista vazia (tela E1 do Figma).
class ListaVazia extends StatelessWidget {
  final String titulo;
  final String texto;
  final IconData icone;
  const ListaVazia({
    super.key,
    required this.titulo,
    required this.texto,
    this.icone = Icons.check_rounded,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
          child: Icon(icone, color: AppColors.verde, size: 36),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(titulo, style: AppTextStyles.tituloSecao.copyWith(fontSize: 18)),
        const SizedBox(height: AppSpacing.sm),
        Text(texto, style: AppTextStyles.corpo, textAlign: TextAlign.center),
      ],
    ),
  );
}
