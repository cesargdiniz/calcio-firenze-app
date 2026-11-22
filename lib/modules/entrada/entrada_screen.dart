import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/preferencias_repository.dart';
import '../../shared/layout/tela_larga.dart';
import '../../shared/links.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/widgets/logo_calcio.dart';

/// 02 · Como você quer entrar. A escolha fica guardada: nas próximas
/// aberturas o app vai direto para o perfil (troca pelo "Trocar de perfil").
class EntradaScreen extends StatelessWidget {
  const EntradaScreen({super.key});

  static void _entrar(BuildContext context, String rota) {
    context.read<PreferenciasRepository>().salvarPerfil(rota);
    context.go(rota);
  }

  static const _opcoes = [
    ('Torcedor', 'Sem login', 'Jogos, tabela e suspensos da temporada.', '/torcedor'),
    (
      'Participante',
      'Com login',
      'Atletas, técnicos e dirigentes: sua situação e a do seu time.',
      '/participante',
    ),
    ('Organização', 'Acesso restrito', 'Súmulas, disciplina e gestão da temporada.', '/organizacao'),
  ];

  @override
  Widget build(BuildContext context) =>
      TelaLarga.menuLateral(context) ? const _EntradaComputador() : _celular(context);

  Widget _celular(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSpacing.tela,
        children: [
          // Aberta pelo "Trocar de perfil": volta para onde estava.
          if (context.canPop())
            const BotaoVoltar(rotulo: 'Voltar', rota: '/torcedor')
          else
            const SizedBox(height: AppSpacing.xl),
          const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
          const SizedBox(height: AppSpacing.xl),
          const Text('Como você quer entrar?', style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.sm),
          const Text('Escolha o seu perfil. Dá para trocar depois.', style: AppTextStyles.corpo),
          const SizedBox(height: AppSpacing.xl),
          for (final (titulo, tag, descricao, rota) in _opcoes)
            _Opcao(
              titulo: titulo,
              tag: tag,
              descricao: descricao,
              onTap: () => _entrar(context, rota),
            ),
          const SizedBox(height: AppSpacing.md),
          const LinksLegais(),
        ],
      ),
    ),
  );
}

/// No computador: faixa verde com o logo à esquerda e os perfis lado a lado.
class _EntradaComputador extends StatelessWidget {
  const _EntradaComputador();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: ColoredBox(
            color: AppColors.verde,
            child: Padding(
              padding: const EdgeInsets.all(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 64, semanticLabel: 'Calcio Firenze'),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Calcio Firenze',
                        style: AppTextStyles.tituloSecao.copyWith(color: Colors.white, fontSize: 24),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'O maior campeonato de futebol condominial do Brasil',
                    style: AppTextStyles.tituloTela.copyWith(
                      color: Colors.white,
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Jogos, tabela, suspensos e súmulas do Master, Livre e Super Master. '
                    'Temporada 2027.',
                    style: AppTextStyles.corpo.copyWith(color: Colors.white, fontSize: 17, height: 1.6),
                  ),
                  const Spacer(),
                  Text(
                    'Também no iPhone e no Android.',
                    style: AppTextStyles.corpo.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.canPop()) const BotaoVoltar(rotulo: 'Voltar', rota: '/torcedor'),
                Text(
                  'Como você quer entrar?',
                  style: AppTextStyles.tituloTela.copyWith(fontSize: 32),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Escolha o seu perfil. Dá para trocar depois pelo menu.',
                  style: AppTextStyles.corpo,
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (final (titulo, tag, descricao, rota) in EntradaScreen._opcoes)
                      SizedBox(
                        width: 260,
                        child: _Opcao(
                          titulo: titulo,
                          tag: tag,
                          descricao: descricao,
                          onTap: () => EntradaScreen._entrar(context, rota),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const LinksLegais(),
              ],
            ),
          ),
        ),
      ],
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
