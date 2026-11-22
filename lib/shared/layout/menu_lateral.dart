import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Um destino do menu.
class ItemMenu {
  final IconData icone;
  final String rotulo;
  const ItemMenu(this.icone, this.rotulo);
}

/// Atalho do menu que abre uma tela por cima (Campeões, Calendário).
class AtalhoMenu {
  final IconData icone;
  final String rotulo;
  final void Function(BuildContext context) abrir;
  final bool ativo;
  const AtalhoMenu(this.icone, this.rotulo, this.abrir, {this.ativo = false});
}

/// Menu da esquerda no computador, no lugar da barra de baixo do celular:
/// logo, categoria, destinos e, no rodapé, a troca de perfil.
class MenuLateral extends StatelessWidget {
  static const largura = 260.0;

  final List<ItemMenu> itens;
  final int selecionado;
  final ValueChanged<int> onSelecionar;
  final List<AtalhoMenu> atalhos;

  /// Seletor de categoria (o mesmo do celular).
  final Widget? categoria;

  /// Ex.: "Torcedor · sem login".
  final String perfil;

  const MenuLateral({
    super.key,
    required this.itens,
    required this.selecionado,
    required this.onSelecionar,
    required this.perfil,
    this.atalhos = const [],
    this.categoria,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cartao,
    child: Container(
      width: largura,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.linha)),
      ),
      child: SafeArea(
        right: false,
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 36,
                            height: 48,
                            fit: BoxFit.contain,
                            semanticLabel: 'Calcio Firenze',
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calcio Firenze',
                                  style: AppTextStyles.tituloSecao.copyWith(fontSize: 17),
                                ),
                                const Text('Temporada 2027', style: AppTextStyles.subtitulo),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (categoria != null) ...[const SizedBox(height: AppSpacing.xl), categoria!],
                    const SizedBox(height: AppSpacing.xl),
                    for (final (i, item) in itens.indexed)
                      _Linha(
                        icone: item.icone,
                        rotulo: item.rotulo,
                        ativo: i == selecionado,
                        onTap: () => onSelecionar(i),
                      ),
                    for (final a in atalhos)
                      _Linha(
                        icone: a.icone,
                        rotulo: a.rotulo,
                        ativo: a.ativo,
                        onTap: () => a.abrir(context),
                      ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1, color: AppColors.linha),
                    const SizedBox(height: AppSpacing.md),
                    _Linha(
                      icone: Icons.swap_horiz_rounded,
                      rotulo: 'Trocar perfil',
                      discreto: true,
                      onTap: () => context.push('/entrar'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                      child: Text(perfil, style: AppTextStyles.pequeno),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final bool discreto;
  final VoidCallback onTap;

  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.onTap,
    this.ativo = false,
    this.discreto = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? AppColors.verde : (discreto ? AppColors.texto2 : AppColors.tinta);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        selected: ativo,
        button: true,
        child: Material(
          color: ativo ? AppColors.verdeSuave : Colors.transparent,
          borderRadius: AppRadius.botao,
          child: InkWell(
            borderRadius: AppRadius.botao,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(icone, size: 20, color: ativo ? AppColors.verde : AppColors.texto2),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        rotulo,
                        style: AppTextStyles.nome.copyWith(
                          fontSize: discreto ? 14 : 15,
                          color: cor,
                          fontWeight: ativo ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Área de conteúdo ao lado do menu: as telas enxergam só a largura dela,
/// para decidirem o próprio layout.
class ComMenuLateral extends StatelessWidget {
  final Widget menu;
  final Widget conteudo;
  const ComMenuLateral({super.key, required this.menu, required this.conteudo});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final largura = mq.size.width - MenuLateral.largura;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          menu,
          Expanded(
            child: MediaQuery(
              data: mq.copyWith(size: Size(largura, mq.size.height)),
              child: conteudo,
            ),
          ),
        ],
      ),
    );
  }
}
