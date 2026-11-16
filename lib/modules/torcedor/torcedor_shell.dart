import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../categoria/seletor_categoria.dart';
import 'widgets/faixa_exemplo.dart';

/// Barra de baixo do Torcedor (componente "Nav/Torcedor") e a categoria no
/// topo. Na primeira abertura, pede a categoria antes.
class TorcedorShell extends StatelessWidget {
  final StatefulNavigationShell navegacao;
  const TorcedorShell({super.key, required this.navegacao});

  @override
  Widget build(BuildContext context) => ComCategoria(child: _abas());

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
      onDestinationSelected: (i) =>
          navegacao.goBranch(i, initialLocation: i == navegacao.currentIndex),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Jogos'),
        NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Tabela'),
        NavigationDestination(icon: Icon(Icons.block_rounded), label: 'Suspensos'),
      ],
    ),
  );
}
