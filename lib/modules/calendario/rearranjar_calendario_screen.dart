import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/superconta.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/basicos.dart';
import 'calendario_screen.dart';

/// Gestão › Rearranjar calendário: só para as supercontas, que mudam de dia
/// os jogos de todas as categorias e da Copa arrastando as etiquetas.
class RearranjarCalendarioScreen extends StatelessWidget {
  const RearranjarCalendarioScreen({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<Sessao?>(
    stream: context.read<AuthRepository>().observarSessao(),
    builder: (context, s) {
      if (!s.hasData && s.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.verde)),
        );
      }
      if (!ehSuperconta(s.data?.email)) {
        return const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BotaoVoltar(rotulo: 'Voltar', rota: '/organizacao/gestao'),
                  ListaVazia(
                    icone: Icons.lock_outline_rounded,
                    titulo: 'Acesso restrito',
                    texto: 'Só as supercontas rearranjam o calendário de todas as categorias.',
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const CalendarioScreen(editavel: true, voltarPara: '/organizacao/gestao');
    },
  );
}
