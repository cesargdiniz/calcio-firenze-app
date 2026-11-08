import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Barra de baixo do Torcedor (componente "Nav/Torcedor").
class TorcedorShell extends StatelessWidget {
  final StatefulNavigationShell navegacao;
  const TorcedorShell({super.key, required this.navegacao});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(bottom: false, child: navegacao),
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
