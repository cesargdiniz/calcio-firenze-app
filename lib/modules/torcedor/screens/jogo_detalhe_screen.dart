import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../widgets/com_painel.dart';

/// S3 · Jogo · Detalhe
class JogoDetalheScreen extends StatelessWidget {
  final String partidaId;
  final String voltarPara;
  const JogoDetalheScreen({
    super.key,
    required this.partidaId,
    this.voltarPara = '/torcedor/jogos',
  });

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) {
      final p = painel.partida(partidaId);
      final s = p.sumula;
      final mandante = painel.time(p.mandanteId);
      final visitante = painel.time(p.visitanteId);
      final nomes = painel.nomes;

      return ListView(
        padding: AppSpacing.tela,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.canPop() ? context.pop() : context.go(voltarPara),
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.oliva),
              label: Text('Jogos', style: AppTextStyles.subtitulo.copyWith(fontSize: 14)),
            ),
          ),
          Cartao(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${p.rodada != null ? 'Rodada ${p.rodada} · ' : ''}'
                        '${dataHoraJogo(p.inicio)} · ${painel.local}',
                        style: AppTextStyles.info,
                      ),
                    ),
                    s == null
                        ? const Etiqueta.neutra('Agendado')
                        : const Etiqueta.verde('Encerrado'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _Time(escudo: Escudo(mandante, tamanho: 48), nome: mandante.nome),
                    ),
                    Text(
                      s == null ? '×' : _placar(p),
                      style: AppTextStyles.placar.copyWith(fontSize: 36),
                    ),
                    Expanded(
                      child: _Time(escudo: Escudo(visitante, tamanho: 48), nome: visitante.nome),
                    ),
                  ],
                ),
                if (s?.penaltis != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pênaltis: ${s!.penaltis!.mandante} × ${s.penaltis!.visitante}',
                    style: AppTextStyles.corpo,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (s != null)
            OutlinedButton(
              onPressed: () => _emBreve(context, 'O vídeo do jogo'),
              child: const Text('Ver no YouTube'),
            ),
          if (s != null && s.ausenteWo != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'W.O.: ${painel.time(s.ausenteWo!).nome} não compareceu (art. 75). Os gols do '
                'W.O. contam na classificação, mas não têm autor e ficam fora da artilharia.',
                style: AppTextStyles.corpo,
              ),
            ),
          if (s != null && s.ausenteWo == null) ...[
            const TituloSecao('Gols'),
            s.gols.isEmpty
                ? const Text('Autores dos gols ainda não lançados.', style: AppTextStyles.pequeno)
                : _Lista([
                    for (final g in s.gols)
                      (
                        const Icon(Icons.circle, size: 12, color: AppColors.verde),
                        '${g.autorId == null ? 'Gol' : (nomes[g.autorId] ?? g.autorId!).toUpperCase()}'
                            '${g.contra ? ' (contra)' : ''} · ${painel.time(g.timeId).sigla}',
                        '${g.tempo}º tempo',
                      ),
                  ]),
            if (s.melhorDaPartida case final m?) ...[
              const TituloSecao('Melhor da partida'),
              _Lista([
                (
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.amarelo),
                  '${(nomes[m.pessoaId] ?? m.pessoaId).toUpperCase()} · ${painel.time(m.timeId).sigla}',
                  '',
                ),
              ]),
            ],
            const TituloSecao('Cartões'),
            s.cartoes.isEmpty
                ? const Text('Nenhum cartão.', style: AppTextStyles.pequeno)
                : _Lista([
                    for (final c in s.cartoes)
                      (
                        Container(
                          width: 10,
                          height: 14,
                          decoration: BoxDecoration(
                            color: c.tipo == TipoCartao.amarelo
                                ? AppColors.amarelo
                                : AppColors.vermelho,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        '${(nomes[c.pessoaId] ?? c.pessoaId).toUpperCase()} · ${painel.time(c.timeId).sigla}',
                        switch (c.tipo) {
                          TipoCartao.amarelo => c.funcao == Funcao.tecnico ? 'Técnico' : '',
                          TipoCartao.segundoAmarelo => '2º amarelo',
                          TipoCartao.vermelho => 'Vermelho',
                        },
                      ),
                  ]),
          ],
        ],
      );
    },
  );

  static String _placar(Partida p) {
    final s = p.sumula!;
    if (s.ausenteWo != null) return s.ausenteWo == p.mandanteId ? '0 : 6' : '6 : 0';
    return '${s.golsMandante} : ${s.golsVisitante}';
  }

  static void _emBreve(BuildContext context, String o) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$o aparece aqui quando a súmula for publicada.')));
}

class _Time extends StatelessWidget {
  final Widget escudo;
  final String nome;
  const _Time({required this.escudo, required this.nome});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      escudo,
      const SizedBox(height: AppSpacing.sm),
      Text(nome, style: AppTextStyles.nome, textAlign: TextAlign.center),
    ],
  );
}

class _Lista extends StatelessWidget {
  final List<(Widget, String, String)> itens;
  const _Lista(this.itens);

  @override
  Widget build(BuildContext context) => Cartao(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    child: Column(
      children: [
        for (final (icone, texto, lateral) in itens)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 16, child: Center(child: icone)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(texto, style: AppTextStyles.rotulo)),
                Text(lateral, style: AppTextStyles.pequeno),
              ],
            ),
          ),
      ],
    ),
  );
}
