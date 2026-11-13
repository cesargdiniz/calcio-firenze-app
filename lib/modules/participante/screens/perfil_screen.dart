import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../avisos.dart';
import '../participante_controller.dart';
import 'participante_inicio_screen.dart';

/// P3 · Participante · Perfil
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _excluir(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Seu login e o pedido de vínculo serão apagados. Súmulas e cartões do '
          'campeonato continuam registrados, como manda o regulamento.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.vermelho)),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      await context.read<ParticipanteController>().excluirConta();
      if (context.mounted) context.go('/entrar');
    } on FalhaLogin catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ComParticipante(
    builder: (context, p) {
      final s = p.pessoal;
      final avisos = montarAvisos(s, p.time, veTime: p.papel.veTime).length;
      final iniciais = s.pessoa.nome
          .split(' ')
          .where((x) => x.isNotEmpty)
          .take(2)
          .map((x) => x[0])
          .join();

      Widget item(String texto, IconData icone, VoidCallback onTap, {Color? cor}) => ListTile(
        leading: Icon(icone, color: cor ?? AppColors.texto2),
        title: Text(texto, style: AppTextStyles.rotulo.copyWith(color: cor)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
        onTap: onTap,
      );

      return ListView(
        padding: AppSpacing.tela,
        children: [
          const CabecalhoTela('Perfil'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.verdeSuave,
                child: Text(
                  iniciais,
                  style: AppTextStyles.tituloSecao.copyWith(color: AppColors.verde),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.pessoa.nome, style: AppTextStyles.tituloSecao),
                    Text('${p.papel.rotulo} · ${s.time.nome}', style: AppTextStyles.subtitulo),
                    Text(p.usuario.email, style: AppTextStyles.pequeno),
                  ],
                ),
              ),
            ],
          ),
          const TituloSecao('Avisos'),
          Cartao(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: item(
              avisos == 0 ? 'Pendências e suspensões' : 'Pendências e suspensões ($avisos)',
              Icons.notifications_none_rounded,
              () => context.go('/participante/avisos'),
            ),
          ),
          const TituloSecao('Conta'),
          Cartao(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                item('Trocar de perfil', Icons.swap_horiz_rounded, () => context.go('/entrar')),
                item('Sair', Icons.logout_rounded, () async {
                  await context.read<ParticipanteController>().sair();
                  if (context.mounted) context.go('/entrar');
                }),
                item(
                  'Excluir conta',
                  Icons.delete_outline_rounded,
                  () => _excluir(context),
                  cor: AppColors.vermelho,
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
