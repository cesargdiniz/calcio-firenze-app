import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/importar_elencos.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';

/// G1 · Gestão · Importar elencos (colando as linhas da planilha).
class ImportarElencosScreen extends StatelessWidget {
  const ImportarElencosScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(builder: (context, o) => _Importar(o: o));
}

class _Importar extends StatefulWidget {
  final OrgPronta o;
  const _Importar({required this.o});

  @override
  State<_Importar> createState() => _ImportarState();
}

class _ImportarState extends State<_Importar> {
  final _texto = TextEditingController();
  ResultadoImportacao? _resultado;
  bool _importando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _conferir() =>
      setState(() => _resultado = ImportarElencos()(_texto.text, widget.o.dados.times));

  Future<void> _importar() async {
    final prontos = _resultado!.prontos;
    setState(() => _importando = true);
    try {
      await context.read<OrganizacaoController>().importarElencos({
        for (final t in prontos) t.time.id: t.pessoas,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            prontos.length == 1
                ? 'Elenco importado: ${prontos.single.time.nome}.'
                : 'Elencos importados: ${prontos.length} times.',
          ),
        ),
      );
      setState(() {
        _resultado = null;
        _texto.clear();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Não foi possível importar. Tente de novo.')));
      }
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    final prontos = r?.prontos.length ?? 0;
    return ListView(
      padding: AppSpacing.tela,
      children: [
        const VoltarGestao(),
        const CabecalhoTela('Importar elencos', subtitulo: 'Master · Temporada 2027'),
        const TituloSecao('1. Copie da planilha'),
        const Text(
          'Uma linha por pessoa, com as colunas nesta ordem:\n'
          'Time · Número · Nome · Posição · Função\n\n'
          '• Time: sigla (SAM) ou nome (Sampdoria)\n'
          '• Posição: Goleiro ou Linha\n'
          '• Função: Atleta, Técnico ou Dirigente (dirigente com número também é atleta)\n\n'
          'Selecione as linhas no Excel ou no Google Planilhas, copie e cole abaixo. '
          'Pode colar vários times de uma vez. Importar de novo substitui o elenco do time.',
          style: AppTextStyles.corpo,
        ),
        const TituloSecao('2. Cole aqui'),
        TextField(
          controller: _texto,
          minLines: 8,
          maxLines: 16,
          style: const TextStyle(fontFamily: 'OpenSans', fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'SAM\t1\tBruno Alves\tGoleiro\tAtleta\nSAM\t7\tRafael Souza\tLinha\tAtleta',
            border: OutlineInputBorder(borderRadius: AppRadius.botao),
          ),
          onChanged: (_) {
            if (_resultado != null) setState(() => _resultado = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: _conferir, child: const Text('Conferir')),
        if (r != null) ...[
          const TituloSecao('3. Conferência'),
          if (r.times.isEmpty) const Text('Nenhuma linha reconhecida.', style: AppTextStyles.corpo),
          for (final t in r.times) _CartaoConferencia(t),
          if (r.linhasIgnoradas.isNotEmpty)
            _Caixa(
              cor: AppColors.cinzaSuave,
              texto:
                  'Linhas ignoradas:\n${[for (final e in r.linhasIgnoradas.entries) 'Linha ${e.key}: ${e.value}'].join('\n')}',
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: prontos == 0 || _importando ? null : _importar,
            child: Text(
              _importando
                  ? 'Importando…'
                  : prontos == 1
                  ? 'Importar 1 time'
                  : 'Importar $prontos times',
            ),
          ),
          if (r.times.length > prontos)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Times com erro ficam de fora. Corrija na planilha e confira de novo.',
                style: AppTextStyles.pequeno,
              ),
            ),
        ],
      ],
    );
  }
}

class _CartaoConferencia extends StatelessWidget {
  final ConferenciaTime t;
  const _CartaoConferencia(this.t);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Cartao(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Escudo(t.time, tamanho: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(t.time.nome, style: AppTextStyles.nome)),
              t.ok
                  ? const Etiqueta.verde('Pronto')
                  : const Etiqueta(
                      'Com erro',
                      cor: AppColors.vermelho,
                      fundo: AppColors.vermelhoSuave,
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${t.atletas} atletas · ${t.pessoas.length} pessoas', style: AppTextStyles.pequeno),
          for (final e in t.erros) _Caixa(cor: AppColors.vermelhoSuave, texto: e),
          for (final a in t.avisos) _Caixa(cor: AppColors.amareloSuave, texto: a),
        ],
      ),
    ),
  );
}

class _Caixa extends StatelessWidget {
  final Color cor;
  final String texto;
  const _Caixa({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(color: cor, borderRadius: AppRadius.botao),
    child: Text(texto, style: AppTextStyles.corpo.copyWith(color: AppColors.tinta, fontSize: 12)),
  );
}
