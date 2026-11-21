import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';

import '../screens/time_screen.dart';
import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';

/// Zona da posição: no turno, quem vai ao mata-mata (art. 16); na
/// classificação geral, os rebaixados (art. 89).
Color? corDaZona(Painel painel, LinhaClassificacao l) {
  if (painel.turno == Painel.geral) {
    return painel.rebaixados.contains(l.timeId) ? AppColors.vermelho : null;
  }
  final c = painel.categoria;
  if (!c.temQuartas) return l.posicao <= c.classificados ? AppColors.verde : null;
  if (l.posicao <= 2) return AppColors.verde; // direto às semifinais
  if (l.posicao <= c.classificados) return AppColors.oliva; // quartas de final
  return null;
}

/// Componente "Tabela/Linha" do Figma, com cabeçalho.
class TabelaClassificacao extends StatelessWidget {
  final Painel painel;
  final List<LinhaClassificacao> linhas;
  final bool compacta;

  const TabelaClassificacao({
    super.key,
    required this.painel,
    required this.linhas,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    final colunas = compacta
        ? const ['J', 'V', 'SG', 'PTS']
        : const ['J', 'V', 'E', 'D', 'SG', 'PTS'];

    Widget celula(String t, {bool forte = false}) => SizedBox(
      width: 30,
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: forte ? AppTextStyles.nome : AppTextStyles.corpo.copyWith(fontSize: 12),
      ),
    );

    List<String> valores(LinhaClassificacao l) => compacta
        ? ['${l.jogos}', '${l.vitorias}', '${l.saldo}', '${l.pontos}']
        : [
            '${l.jogos}',
            '${l.vitorias}',
            '${l.empates}',
            '${l.derrotas}',
            '${l.saldo}',
            '${l.pontos}',
          ];

    return Cartao(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 26),
                const Expanded(child: Text('Clube', style: AppTextStyles.pequeno)),
                for (final c in colunas)
                  SizedBox(
                    width: 30,
                    child: Text(c, textAlign: TextAlign.center, style: AppTextStyles.pequeno),
                  ),
              ],
            ),
          ),
          for (final l in linhas)
            Semantics(
              label: '${l.posicao}º ${painel.time(l.timeId).nome}, ${l.pontos} pontos',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 24,
                      color: corDaZona(painel, l) ?? Colors.transparent,
                    ),
                    SizedBox(
                      width: 23,
                      child: Text(
                        '${l.posicao}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.rotulo,
                      ),
                    ),
                    EscudoClicavel(painel: painel, timeId: l.timeId, tamanho: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        painel.time(l.timeId).nome + (l.aguardaSorteio ? ' *' : ''),
                        style: AppTextStyles.nome.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final (i, v) in valores(l).indexed)
                      celula(v, forte: i == colunas.length - 1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
