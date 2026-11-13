import 'package:flutter/material.dart';
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

      Widget item(String texto, {String? rota, String? detalhe}) => ListTile(
        title: Text(
          texto,
          style: AppTextStyles.rotulo.copyWith(color: rota == null ? AppColors.dica : null),
        ),
        subtitle: detalhe == null ? null : Text(detalhe, style: AppTextStyles.pequeno),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: rota == null ? AppColors.linha : AppColors.dica,
        ),
        onTap: rota == null ? null : () => context.go(rota),
      );

      return ListView(
        padding: AppSpacing.tela,
        children: [
          const CabecalhoTela('Gestão', subtitulo: 'Master · Temporada 2027'),
          grupo('Temporada', [
            item('Times da temporada', rota: '/organizacao/gestao/times'),
            item('Regulamento e parâmetros', detalhe: 'Em breve'),
            item('Calendário e jogos', rota: '/organizacao/jogos'),
          ]),
          grupo('Elencos', [
            item('Importar elencos do turno', rota: '/organizacao/gestao/elencos'),
            item('Movimentações', detalhe: 'Em breve'),
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
