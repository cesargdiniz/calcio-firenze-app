import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../calendario/consistencia_calendario.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import '../../../shared/layout/tela_larga.dart';

/// O6 · Organização · Gestão
class GestaoScreen extends StatelessWidget {
  /// Rota aberta ao lado (computador), para marcar a seção.
  final String? rotaAtual;
  const GestaoScreen({super.key, this.rotaAtual});

  bool _aberta(String rota) {
    final atual = rotaAtual;
    if (atual == null) return false;
    // Na raiz, o computador mostra os times.
    if (atual == '/organizacao/gestao') return rota.endsWith('/times');
    return atual.startsWith(rota);
  }

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      Widget grupo(String titulo, List<Widget> itens) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloSecao(titulo),
          Cartao(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(children: itens),
          ),
        ],
      );

      Widget item(String texto, {required String rota}) => ListTile(
        selected: _aberta(rota),
        selectedTileColor: AppColors.verdeSuave,
        selectedColor: AppColors.verde,
        title: Text(texto, style: AppTextStyles.rotulo),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
        onTap: () => context.go(rota),
      );

      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          CabecalhoTela('Gestão', subtitulo: o.dados.nome),
          const SizedBox(height: AppSpacing.md),
          Text(
            o.categorias.length == 1
                ? 'Esta conta organiza a categoria ${o.categoria.nome} e só altera os dados dela.'
                : 'Esta conta organiza: ${o.categorias.map((c) => c.nome).join(', ')}.',
            style: AppTextStyles.pequeno,
          ),
          const SizedBox(height: AppSpacing.md),
          const ConsistenciaCalendario(),
          grupo('Temporada', [
            item('Times da temporada', rota: '/organizacao/gestao/times'),
            item('Regulamento e parâmetros', rota: '/organizacao/gestao/parametros'),
          ]),
          grupo('Elencos', [
            item('Importar elencos do turno', rota: '/organizacao/gestao/elencos'),
            item(
              o.movimentacoes.isEmpty ? 'Movimentações' : 'Movimentações (${o.movimentacoes.length})',
              rota: '/organizacao/gestao/movimentacoes',
            ),
          ]),
          grupo('Acessos', [
            item(
              o.pedidos.isEmpty ? 'Pedidos de vínculo' : 'Pedidos de vínculo (${o.pedidos.length})',
              rota: '/organizacao/gestao/pedidos',
            ),
          ]),
          grupo('Governança', [
            item(
              o.dados.decisoes.isEmpty || o.dados.demonstracao
                  ? 'Decisões e punições'
                  : 'Decisões e punições (${o.dados.decisoes.length})',
              rota: '/organizacao/gestao/decisoes',
            ),
          ]),
          grupo('Conta', [
            ListTile(
              title: Text('Entrou como ${o.sessao.email}', style: AppTextStyles.pequeno),
            ),
            ListTile(
              title: const Text('Trocar de perfil', style: AppTextStyles.rotulo),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
              onTap: () => context.push('/entrar'),
            ),
            ListTile(
              title: const Text('Sair da conta', style: AppTextStyles.rotulo),
              trailing: const Icon(Icons.logout_rounded, color: AppColors.dica),
              onTap: () async {
                await context.read<OrganizacaoController>().sair();
                if (context.mounted) context.go('/entrar');
              },
            ),
          ]),
        ],
      );
    },
  );
}
