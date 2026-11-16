import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../organizacao_shell.dart';

/// O6 · Organização · Gestão
class GestaoScreen extends StatelessWidget {
  const GestaoScreen({super.key});

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
        title: Text(texto, style: AppTextStyles.rotulo),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
        onTap: () => context.go(rota),
      );

      return ListView(
        padding: AppSpacing.tela,
        children: [
          CabecalhoTela('Gestão', subtitulo: o.dados.nome),
          const SizedBox(height: AppSpacing.md),
          Text(
            o.categorias.length == 1
                ? 'Esta conta organiza a categoria ${o.categoria.nome} e só altera os dados dela.'
                : 'Esta conta organiza: ${o.categorias.map((c) => c.nome).join(', ')}.',
            style: AppTextStyles.pequeno,
          ),
          grupo('Temporada', [
            item('Times da temporada', rota: '/organizacao/gestao/times'),
            item('Regulamento e parâmetros', rota: '/organizacao/gestao/parametros'),
            item('Calendário e jogos', rota: '/organizacao/jogos'),
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
        ],
      );
    },
  );
}
