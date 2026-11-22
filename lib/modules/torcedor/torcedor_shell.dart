import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/menu_lateral.dart';
import '../../shared/layout/tela_larga.dart';
import '../categoria/seletor_categoria.dart';
import 'widgets/faixa_exemplo.dart';

/// Barra de baixo do Torcedor (componente "Nav/Torcedor") e a categoria no
/// topo. Na primeira abertura, pede a categoria antes. No computador, menu
/// lateral.
class TorcedorShell extends StatelessWidget {
  final StatefulNavigationShell navegacao;

  /// Rota aberta, para marcar no menu lateral os atalhos (Campeões, Calendário).
  final String rota;
  const TorcedorShell({super.key, required this.navegacao, this.rota = ''});

  static const _itens = [
    ItemMenu(Icons.home_outlined, 'Início'),
    ItemMenu(Icons.calendar_month_outlined, 'Jogos'),
    ItemMenu(Icons.bar_chart_rounded, 'Tabela'),
    ItemMenu(Icons.block_rounded, 'Suspensos'),
  ];

  void _ir(int i) => navegacao.goBranch(i, initialLocation: i == navegacao.currentIndex);

  @override
  Widget build(BuildContext context) =>
      ComCategoria(child: TelaLarga.menuLateral(context) ? _computador() : _abas());

  Widget _computador() {
    final atalho = rota.startsWith('/torcedor/campeoes')
        ? 0
        : (rota.startsWith('/torcedor/calendario') ? 1 : -1);
    return ComMenuLateral(
      menu: MenuLateral(
        itens: _itens,
        selecionado: atalho >= 0 ? -1 : navegacao.currentIndex,
        onSelecionar: _ir,
        categoria: const BarraCategoriaDoApp(noMenu: true),
        perfil: 'Torcedor · sem login',
        atalhos: [
          AtalhoMenu(
            Icons.emoji_events_outlined,
            'Campeões',
            (c) => c.go('/torcedor/campeoes'),
            ativo: atalho == 0,
          ),
          AtalhoMenu(
            Icons.event_note_outlined,
            'Calendário completo',
            (c) => c.go('/torcedor/calendario'),
            ativo: atalho == 1,
          ),
        ],
      ),
      conteudo: Column(
        children: [
          const FaixaExemplo(),
          Expanded(child: navegacao),
        ],
      ),
    );
  }

  Widget _abas() => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const BarraCategoriaDoApp(),
          const FaixaExemplo(),
          Expanded(child: navegacao),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: navegacao.currentIndex,
      onDestinationSelected: _ir,
      destinations: [
        for (final i in _itens) NavigationDestination(icon: Icon(i.icone), label: i.rotulo),
      ],
    ),
  );
}
