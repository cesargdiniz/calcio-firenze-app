import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';

import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../widgets/com_painel.dart';
import '../widgets/tabela.dart';

/// T3 · Torcedor · Classificação e artilharia
class ClassificacaoScreen extends StatefulWidget {
  const ClassificacaoScreen({super.key});

  @override
  State<ClassificacaoScreen> createState() => _ClassificacaoScreenState();
}

class _ClassificacaoScreenState extends State<ClassificacaoScreen> {
  bool _artilharia = false;

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) => ListView(
      padding: AppSpacing.tela,
      children: [
        CabecalhoTela(
          _artilharia ? 'Artilharia' : 'Classificação',
          subtitulo: _artilharia ? '1º Turno' : 'Fase classificatória · 1º Turno',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChipFiltro(
              'Classificação',
              ativo: !_artilharia,
              onTap: () => setState(() => _artilharia = false),
            ),
            ChipFiltro(
              'Artilharia',
              ativo: _artilharia,
              onTap: () => setState(() => _artilharia = true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_artilharia)
          _Artilharia(painel: painel)
        else ...[
          TabelaClassificacao(painel: painel, linhas: painel.tabela),
          const SizedBox(height: AppSpacing.md),
          const _Legenda(AppColors.verde, '1º e 2º vão direto às semifinais'),
          const _Legenda(AppColors.oliva, '3º ao 6º jogam as quartas de final'),
          if (painel.tabela.any((l) => l.aguardaSorteio))
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '* Empate em todos os critérios: decidido por sorteio (art. 42).',
                style: AppTextStyles.pequeno,
              ),
            ),
        ],
      ],
    ),
  );
}

class _Artilharia extends StatelessWidget {
  final Painel painel;
  const _Artilharia({required this.painel});

  @override
  Widget build(BuildContext context) {
    final lista = painel.artilharia;
    if (lista.isEmpty) {
      return const ListaVazia(
        titulo: 'Ainda sem artilheiros',
        texto: 'A artilharia aparece quando a Organização lança os autores dos gols na súmula.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (final (i, a) in lista.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.linha),
                _LinhaArtilheiro(painel: painel, artilheiro: a),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Só contam gols com autor lançado na súmula. Gols contra e os gols de W.O. ficam de '
          'fora.',
          style: AppTextStyles.pequeno.copyWith(color: AppColors.texto2),
        ),
      ],
    );
  }
}

class _LinhaArtilheiro extends StatelessWidget {
  final Painel painel;
  final Artilheiro artilheiro;
  const _LinhaArtilheiro({required this.painel, required this.artilheiro});

  @override
  Widget build(BuildContext context) {
    final a = artilheiro;
    final time = painel.times[a.timeId];
    final lider = a.posicao == 1;
    return Semantics(
      label:
          '${a.posicao}º, ${painel.nomes[a.pessoaId] ?? a.pessoaId}, ${time?.nome ?? a.timeId}, '
          '${a.gols == 1 ? '1 gol' : '${a.gols} gols'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${a.posicao}º',
                  style: AppTextStyles.rotulo.copyWith(
                    color: lider ? AppColors.verde : AppColors.texto2,
                  ),
                ),
              ),
              if (time != null) ...[
                Escudo(time, tamanho: 28),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (painel.nomes[a.pessoaId] ?? a.pessoaId).toUpperCase(),
                      style: AppTextStyles.nome,
                    ),
                    Text(time?.nome ?? a.timeId, style: AppTextStyles.pequeno),
                  ],
                ),
              ),
              Text('${a.gols}', style: AppTextStyles.placar),
              const SizedBox(width: 4),
              Text(a.gols == 1 ? 'gol' : 'gols', style: AppTextStyles.pequeno),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;
  const _Legenda(this.cor, this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      children: [
        Container(width: 10, height: 10, color: cor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(texto, style: AppTextStyles.pequeno.copyWith(color: AppColors.texto2)),
        ),
      ],
    ),
  );
}
