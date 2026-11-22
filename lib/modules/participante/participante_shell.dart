import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/menu_lateral.dart';
import '../../shared/layout/tela_larga.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/coluna_larga.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../login/login_screen.dart';
import '../categoria/seletor_categoria.dart';
import 'participante_controller.dart';
import 'screens/aguardando_screen.dart';
import 'screens/vincular_screen.dart';

/// Porta de entrada do Participante: mostra login, vínculo, espera ou as
/// abas (componente "Nav/Participante"), conforme a situação da conta.
class ParticipanteShell extends StatelessWidget {
  final StatefulNavigationShell navegacao;
  const ParticipanteShell({super.key, required this.navegacao});

  static const _itens = [
    ItemMenu(Icons.home_outlined, 'Início'),
    ItemMenu(Icons.shield_outlined, 'Meu time'),
    ItemMenu(Icons.calendar_month_outlined, 'Jogos'),
    ItemMenu(Icons.bar_chart_rounded, 'Tabela'),
    ItemMenu(Icons.person_outline_rounded, 'Perfil'),
  ];

  void _ir(int i) => navegacao.goBranch(i, initialLocation: i == navegacao.currentIndex);

  @override
  Widget build(BuildContext context) => ComCategoria(
    child: BlocBuilder<ParticipanteController, ParticipanteStatus>(
      builder: (context, status) => switch (status) {
        ParticipantePronto() when TelaLarga.menuLateral(context) => ComMenuLateral(
          menu: MenuLateral(
            itens: _itens,
            selecionado: navegacao.currentIndex,
            onSelecionar: _ir,
            categoria: const BarraCategoriaDoApp(noMenu: true),
            perfil: 'Participante',
            onSair: context.read<ParticipanteController>().sair,
          ),
          conteudo: navegacao,
        ),
        ParticipanteCarregando() => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.verde)),
        ),
        ParticipanteSemLogin() => const ColunaCentral(child: LoginScreen()),
        ParticipanteSemVinculo(:final dados, :final comVinculo) => _comBarra(
          VincularScreen(dados: dados, comVinculo: comVinculo),
        ),
        ParticipanteRecusado(:final dados) => _comBarra(VincularScreen(dados: dados, recusado: true)),
        ParticipanteAguardando(:final usuario, :final vinculo, :final pessoa, :final time) =>
          _comBarra(
            AguardandoScreen(usuario: usuario, vinculo: vinculo, pessoa: pessoa, time: time),
          ),
        ParticipanteFalha(:final mensagem, :final detalhe) => Scaffold(
          body: Center(
            child: Padding(
              padding: AppSpacing.tela,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mensagem, style: AppTextStyles.corpo, textAlign: TextAlign.center),
                  if (detalhe != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      detalhe,
                      style: AppTextStyles.pequeno,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: context.read<ParticipanteController>().tentarDeNovo,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ParticipantePronto() => Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const BarraCategoriaDoApp(),
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
        ),
      },
    ),
  );

  /// Telas de vínculo com a categoria no topo, para pedir vínculo em outra.
  static Widget _comBarra(Widget tela) => ColunaCentral(
    child: Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const BarraCategoriaDoApp(),
          Expanded(child: tela),
        ],
      ),
    ),
    ),
  );
}
