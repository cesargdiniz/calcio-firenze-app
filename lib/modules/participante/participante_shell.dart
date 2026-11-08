import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../login/login_screen.dart';
import 'participante_controller.dart';
import 'screens/aguardando_screen.dart';
import 'screens/vincular_screen.dart';

/// Porta de entrada do Participante: mostra login, vínculo, espera ou as
/// abas (componente "Nav/Participante"), conforme a situação da conta.
class ParticipanteShell extends StatelessWidget {
  final StatefulNavigationShell navegacao;
  const ParticipanteShell({super.key, required this.navegacao});

  @override
  Widget build(BuildContext context) => BlocBuilder<ParticipanteController, ParticipanteStatus>(
    builder: (context, status) => switch (status) {
      ParticipanteCarregando() => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.verde)),
      ),
      ParticipanteSemLogin() => const LoginScreen(),
      ParticipanteSemVinculo(:final dados) => VincularScreen(dados: dados),
      ParticipanteRecusado(:final dados) => VincularScreen(dados: dados, recusado: true),
      ParticipanteAguardando(:final usuario, :final pessoa, :final time) => AguardandoScreen(
        usuario: usuario,
        pessoa: pessoa,
        time: time,
      ),
      ParticipanteFalha(:final mensagem) => Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.tela,
            child: Text(mensagem, style: AppTextStyles.corpo, textAlign: TextAlign.center),
          ),
        ),
      ),
      ParticipantePronto() => Scaffold(
        body: SafeArea(bottom: false, child: navegacao),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navegacao.currentIndex,
          onDestinationSelected: (i) =>
              navegacao.goBranch(i, initialLocation: i == navegacao.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
            NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Meu time'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Jogos'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Tabela'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
          ],
        ),
      ),
    },
  );
}
