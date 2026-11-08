import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/widgets/logo_calcio.dart';

/// 02 · Como você quer entrar
class EntradaScreen extends StatelessWidget {
  const EntradaScreen({super.key});

  void _emBreve(BuildContext context, String perfil) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('O acesso de $perfil chega na próxima versão.')));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSpacing.tela,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
          const SizedBox(height: AppSpacing.xl),
          Text('Como você quer entrar?', style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.sm),
          Text('Escolha o seu perfil. Dá para trocar depois.', style: AppTextStyles.corpo),
          const SizedBox(height: AppSpacing.xl),
          _Opcao(
            titulo: 'Torcedor',
            tag: 'Sem login',
            descricao: 'Jogos, tabela e suspensos da temporada.',
            onTap: () => context.go('/torcedor'),
          ),
          _Opcao(
            titulo: 'Participante',
            tag: 'Com login',
            descricao: 'Atletas, técnicos e dirigentes: sua situação e a do seu time.',
            onTap: () => context.go('/participante'),
          ),
          _Opcao(
            titulo: 'Organização',
            tag: 'Acesso restrito',
            descricao: 'Súmulas, disciplina e gestão da temporada.',
            onTap: () => _emBreve(context, 'Organização'),
          ),
        ],
      ),
    ),
  );
}

/// Componente "Card/Opção de entrada" do Figma.
class _Opcao extends StatelessWidget {
  final String titulo;
  final String tag;
  final String descricao;
  final VoidCallback onTap;

  const _Opcao({
    required this.titulo,
    required this.tag,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Cartao(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(titulo, style: AppTextStyles.tituloSecao),
                    Etiqueta.verde(tag),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(descricao, style: AppTextStyles.corpo),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.oliva),
        ],
      ),
    ),
  );
}
