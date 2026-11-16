import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/widgets/logo_calcio.dart';
import '../../domain/entities/categoria.dart';
import '../categoria/categoria_controller.dart';
import '../categoria/seletor_categoria.dart';
import '../login/login_screen.dart';
import 'organizacao_controller.dart';

/// Entrega o estado "pronto" às telas da Organização.
class ComOrg extends StatelessWidget {
  final Widget Function(BuildContext context, OrgPronta o) builder;
  const ComOrg({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => BlocBuilder<OrganizacaoController, OrgStatus>(
    builder: (context, s) => s is OrgPronta ? builder(context, s) : const SizedBox.shrink(),
  );
}

/// Porta de entrada da Organização (componente "Nav/Organização").
class OrganizacaoShell extends StatelessWidget {
  final StatefulNavigationShell navegacao;
  const OrganizacaoShell({super.key, required this.navegacao});

  @override
  Widget build(BuildContext context) => BlocBuilder<OrganizacaoController, OrgStatus>(
    builder: (context, status) => switch (status) {
      OrgCarregando() => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.verde)),
      ),
      OrgSemLogin() => const LoginScreen(
        titulo: 'Entrar como Organização',
        subtitulo: 'Acesso restrito a quem organiza o campeonato.',
      ),
      OrgSemAcesso(:final sessao) => _SemAcesso(uid: sessao.uid, email: sessao.email),
      OrgSemCategoria(:final sessao) => _InformarCategoria(email: sessao.email),
      OrgFalha(:final mensagem) => Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.tela,
            child: Text(mensagem, style: AppTextStyles.corpo, textAlign: TextAlign.center),
          ),
        ),
      ),
      OrgPronta(:final categoria, :final categorias) => _AlinharCategoria(
        categoria: categoria,
        child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BarraCategoria(
                atual: categoria,
                opcoes: categorias,
                onEscolher: context.read<OrganizacaoController>().escolherCategoria,
              ),
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
            NavigationDestination(icon: Icon(Icons.style_outlined), label: 'Disciplina'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Tabela'),
            NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Gestão'),
          ],
        ),
      ),
      ),
    },
  );
}

/// Primeiro acesso da conta da Organização: informar a categoria que organiza.
/// A escolha limita tudo o que a conta altera; trocar depois só pelo console.
/// Na área da Organização, o resto do app (Tabela, que vem do Torcedor)
/// segue a categoria que a conta organiza.
class _AlinharCategoria extends StatelessWidget {
  final Categoria categoria;
  final Widget child;
  const _AlinharCategoria({required this.categoria, required this.child});

  @override
  Widget build(BuildContext context) {
    final escolha = context.read<CategoriaController>();
    if (escolha.atual != categoria) {
      WidgetsBinding.instance.addPostFrameCallback((_) => escolha.escolher(categoria));
    }
    return child;
  }
}

class _InformarCategoria extends StatefulWidget {
  final String email;
  const _InformarCategoria({required this.email});

  @override
  State<_InformarCategoria> createState() => _InformarCategoriaState();
}

class _InformarCategoriaState extends State<_InformarCategoria> {
  bool _gravando = false;

  Future<void> _escolher(Categoria c) async {
    final controller = context.read<OrganizacaoController>();
    final avisos = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Organizar a categoria ${c.nome}?'),
        content: Text(
          'Esta conta vai alterar só a ${c.nome}: calendário, súmulas, elencos, disciplina e '
          'pedidos de vínculo. Para trocar depois, fale com quem administra o Firebase.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _gravando = true);
    try {
      await controller.definirMinhaCategoria(c);
    } catch (_) {
      avisos.showSnackBar(const SnackBar(content: Text('Não foi possível gravar. Tente de novo.')));
    } finally {
      if (mounted) setState(() => _gravando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSpacing.tela,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
          const SizedBox(height: AppSpacing.xl),
          const Text('Qual categoria você organiza?', style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Você entrou como ${widget.email}. Cada categoria tem a sua Organização: esta conta '
            'só vai poder alterar a categoria escolhida.',
            style: AppTextStyles.corpo,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final c in Categoria.values) ...[
            Cartao(
              onTap: _gravando ? null : () => _escolher(c),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nome, style: AppTextStyles.tituloSecao),
                        const SizedBox(height: AppSpacing.xs),
                        Text('${c.times} times', style: AppTextStyles.pequeno),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextButton(
            onPressed: () async {
              await context.read<OrganizacaoController>().sair();
              if (context.mounted) context.go('/entrar');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    ),
  );
}

class _SemAcesso extends StatelessWidget {
  final String uid;
  final String email;
  const _SemAcesso({required this.uid, required this.email});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSpacing.tela,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.lock_outline_rounded, size: 44, color: AppColors.texto2),
          const SizedBox(height: AppSpacing.md),
          const Text('Esta conta não é da Organização', style: AppTextStyles.tituloTela),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Você entrou como $email. Para liberar o acesso, quem já é da Organização '
            'adiciona o código abaixo na lista "organizacao" do Firebase.',
            style: AppTextStyles.corpo,
          ),
          const SizedBox(height: AppSpacing.md),
          Cartao(
            child: Row(
              children: [
                Expanded(child: SelectableText(uid, style: AppTextStyles.rotulo)),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy_rounded, color: AppColors.verde),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: uid));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Código copiado.')));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: () => context.go('/participante'),
            child: const Text('Entrar como Participante'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<OrganizacaoController>().sair();
              if (context.mounted) context.go('/entrar');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    ),
  );
}

/// Abas que ainda não existem (Disciplina chega com a súmula).
class EmBreveScreen extends StatelessWidget {
  final String titulo;
  final String texto;
  const EmBreveScreen({super.key, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.tela,
    children: [
      CabecalhoTela(titulo),
      const SizedBox(height: AppSpacing.lg),
      Text(texto, style: AppTextStyles.corpo),
    ],
  );
}
