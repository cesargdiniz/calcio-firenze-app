import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/logo_calcio.dart';
import '../organizacao_shell.dart';

/// O1 · Organização · Início
class OrgInicioScreen extends StatelessWidget {
  const OrgInicioScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final d = o.dados;
      final atletas = d.demonstracao ? 0 : d.pessoas.where((p) => p.funcao == Funcao.atleta).length;
      final elencos = d.demonstracao ? 0 : d.pessoas.map((p) => p.timeId).toSet().length;

      return ListView(
        padding: AppSpacing.tela,
        children: [
          Row(
            children: [
              const LogoCalcio(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Organização', style: AppTextStyles.tituloSecao),
                    Text(d.nome, style: AppTextStyles.subtitulo),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _Indicador('${o.pedidos.length}', 'Pedidos de vínculo')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Indicador('$elencos/${d.times.length}', 'Elencos importados')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _Indicador('$atletas', 'Atletas inscritos')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Indicador(
                  d.demonstracao ? '0' : '${d.partidas.length}',
                  'Jogos no calendário',
                ),
              ),
            ],
          ),
          const TituloSecao('Atenção'),
          if (o.pedidos.isNotEmpty)
            _Atencao(
              icone: Icons.how_to_reg_outlined,
              texto: o.pedidos.length == 1
                  ? '1 pedido de vínculo aguardando'
                  : '${o.pedidos.length} pedidos de vínculo aguardando',
              onTap: () => context.go('/organizacao/gestao/pedidos'),
            ),
          if (d.demonstracao)
            _Atencao(
              icone: Icons.upload_file_outlined,
              texto: 'Elencos ainda não importados: o app está mostrando a temporada de exemplo.',
              onTap: () => context.go('/organizacao/gestao/elencos'),
            ),
          if (o.pedidos.isEmpty && !d.demonstracao)
            const Text('Nada pendente por aqui.', style: AppTextStyles.corpo),
        ],
      );
    },
  );
}

class _Indicador extends StatelessWidget {
  final String valor;
  final String rotulo;
  const _Indicador(this.valor, this.rotulo);

  @override
  Widget build(BuildContext context) => Cartao(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(valor, style: AppTextStyles.tituloTela.copyWith(fontSize: 24)),
        Text(rotulo, style: AppTextStyles.pequeno),
      ],
    ),
  );
}

class _Atencao extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  const _Atencao({required this.icone, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Cartao(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icone, color: AppColors.amareloEscuro),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(texto, style: AppTextStyles.rotulo)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
        ],
      ),
    ),
  );
}
