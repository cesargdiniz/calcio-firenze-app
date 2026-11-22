import 'package:material_ui/material_ui.dart';

import '../../../domain/entities/temporada.dart';
import '../../../domain/entities/etapa.dart';
import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/compartilhar/compartilhar_imagem.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../widgets/com_painel.dart';
import '../../../shared/layout/tela_larga.dart';

/// T4 · Torcedor · Suspensos. Mostra quem NÃO joga a próxima rodada.
class SuspensosScreen extends StatelessWidget {
  const SuspensosScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ComPainel(builder: (context, painel) => _Suspensos(painel: painel));
}

class _Suspensos extends StatefulWidget {
  final Painel painel;
  const _Suspensos({required this.painel});

  @override
  State<_Suspensos> createState() => _SuspensosState();
}

class _SuspensosState extends State<_Suspensos> {
  bool _verPendurados = false;

  /// Suspensos e pendurados da próxima etapa, como imagem.
  void _compartilhar(Painel p) {
    final etapa = p.proximaEtapa;
    compartilharComoImagem(
      context,
      titulo: 'Suspensos e pendurados',
      subtitulo: '${p.categoria.nome} 2027${etapa == null ? '' : ' · ${etapa.rotulo}'}',
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSecao('Suspensos'),
          if (p.suspensos.isEmpty) const Text('Ninguém suspenso.', style: AppTextStyles.corpo),
          for (final s in p.suspensos)
            _Linha(
              pessoa: s.pessoa,
              time: s.time,
              detalhe: s.motivo,
              lateral: s.retorno ?? '',
              corLateral: AppColors.vermelho,
            ),
          const TituloSecao('Pendurados'),
          if (p.pendurados.isEmpty) const Text('Ninguém pendurado.', style: AppTextStyles.corpo),
          for (final x in p.pendurados)
            _Linha(
              pessoa: x.pessoa,
              time: x.time,
              detalhe: '${x.amarelos} amarelos',
              lateral: 'Pendurado',
              corLateral: AppColors.amareloEscuro,
            ),
        ],
      ),
      nomeArquivo: 'calcio-${p.categoria.name}-suspensos.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.painel;
    final etapa = p.proximaEtapa;
    return ListView(
      padding: TelaLarga.margens(context),
      children: [
        CabecalhoTela(
          'Suspensos',
          acao: BotaoCompartilhar(onPressed: () => _compartilhar(p)),
          subtitulo: switch (etapa) {
            null => 'Sem jogos marcados',
            Etapa(turno: 0) => 'Para a ${etapa.rotulo}',
            _ => 'Para ${etapa.rotulo} · ${etapa.turno}º Turno',
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChipFiltro(
              'Suspensos (${p.suspensos.length})',
              ativo: !_verPendurados,
              onTap: () => setState(() => _verPendurados = false),
            ),
            ChipFiltro(
              'Pendurados (${p.pendurados.length})',
              ativo: _verPendurados,
              onTap: () => setState(() => _verPendurados = true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!_verPendurados && p.suspensos.isEmpty)
          const ListaVazia(
            titulo: 'Ninguém suspenso',
            texto:
                'Todos os atletas podem jogar a próxima rodada. '
                'A lista aparece aqui quando houver suspensões.',
          ),
        if (_verPendurados && p.pendurados.isEmpty)
          const ListaVazia(
            titulo: 'Ninguém pendurado',
            texto: 'Nenhum atleta está a um amarelo da suspensão.',
          ),
        if (!_verPendurados)
          for (final s in p.suspensos)
            _Linha(
              pessoa: s.pessoa,
              time: s.time,
              detalhe: s.motivo,
              lateral: s.retorno ?? '',
              corLateral: AppColors.vermelho,
            ),
        if (_verPendurados)
          for (final x in p.pendurados)
            _Linha(
              pessoa: x.pessoa,
              time: x.time,
              detalhe: '${x.amarelos} amarelos',
              lateral: 'Pendurado',
              corLateral: AppColors.amareloEscuro,
            ),
      ],
    );
  }
}

/// Componente "Lista/Suspenso" do Figma.
class _Linha extends StatelessWidget {
  final Pessoa pessoa;
  final Time time;
  final String detalhe;
  final String lateral;
  final Color corLateral;

  const _Linha({
    required this.pessoa,
    required this.time,
    required this.detalhe,
    required this.lateral,
    required this.corLateral,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Cartao(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Escudo(time),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pessoa.nome.toUpperCase(), style: AppTextStyles.nome),
                Text('${time.nome} · $detalhe', style: AppTextStyles.pequeno),
              ],
            ),
          ),
          Text(lateral, style: AppTextStyles.rotulo.copyWith(fontSize: 11, color: corLateral)),
        ],
      ),
    ),
  );
}
