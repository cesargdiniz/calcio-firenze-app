import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../torcedor_controller.dart';
import '../widgets/com_painel.dart';
import '../widgets/tabela.dart';

/// Categorias da seção Estatísticas, na ordem dos botões.
enum _Categoria {
  artilharia('Artilharia'),
  melhorDaPartida('Melhor da partida'),
  ataque('Melhor ataque'),
  defesa('Melhor defesa'),
  amarelos('Cartão amarelo'),
  vermelhos('Cartão vermelho'),
  cartoes('Todos os cartões');

  final String rotulo;
  const _Categoria(this.rotulo);
}

/// T3 · Torcedor · Classificação e estatísticas do turno
class ClassificacaoScreen extends StatefulWidget {
  const ClassificacaoScreen({super.key});

  @override
  State<ClassificacaoScreen> createState() => _ClassificacaoScreenState();
}

class _ClassificacaoScreenState extends State<ClassificacaoScreen> {
  bool _estatisticas = false;
  _Categoria _categoria = _Categoria.artilharia;

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) => ListView(
      padding: AppSpacing.tela,
      children: [
        CabecalhoTela(
          _estatisticas ? 'Estatísticas' : 'Classificação',
          subtitulo: painel.turno == Painel.geral
              ? (_estatisticas ? 'Temporada inteira' : 'Geral · os dois turnos somados')
              : (_estatisticas
                    ? '${painel.turno}º Turno'
                    : 'Fase classificatória · ${painel.turno}º Turno'),
        ),
        const SizedBox(height: AppSpacing.md),
        SeletorTurno(painel: painel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChipFiltro(
              'Classificação',
              ativo: !_estatisticas,
              onTap: () => setState(() => _estatisticas = false),
            ),
            ChipFiltro(
              'Estatísticas',
              ativo: _estatisticas,
              onTap: () => setState(() => _estatisticas = true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_estatisticas) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in _Categoria.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChipFiltro(
                      c.rotulo,
                      ativo: c == _categoria,
                      onTap: () => setState(() => _categoria = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Estatistica(painel: painel, categoria: _categoria),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          TabelaClassificacao(painel: painel, linhas: painel.tabela),
          const SizedBox(height: AppSpacing.md),
          if (painel.turno == Painel.geral)
            _Legenda(
              AppColors.vermelho,
              painel.rebaixados.isEmpty
                  ? 'Os últimos da geral são rebaixados ao fim da temporada (art. 89)'
                  : 'Rebaixados (art. 89)',
            )
          else if (painel.categoria.temQuartas) ...[
            const _Legenda(AppColors.verde, '1º e 2º vão direto às semifinais'),
            _Legenda(
              AppColors.oliva,
              '3º ao ${painel.categoria.classificados}º jogam as quartas de final',
            ),
          ] else
            _Legenda(
              AppColors.verde,
              '1º ao ${painel.categoria.classificados}º vão às semifinais',
            ),
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

/// Uma linha de ranking: posição, escudo, nome, detalhe e o valor à direita.
class _Item {
  final int posicao;
  final String timeId;
  final String titulo;
  final String subtitulo;
  final Widget valor;
  final String leitura;

  const _Item({
    required this.posicao,
    required this.timeId,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.leitura,
  });
}

class _Estatistica extends StatelessWidget {
  final Painel painel;
  final _Categoria categoria;
  const _Estatistica({required this.painel, required this.categoria});

  String _nome(String id) => (painel.nomes[id] ?? id).toUpperCase();
  String _time(String id) => painel.times[id]?.nome ?? id;
  static String _plural(int n, String um, String varios) => n == 1 ? '1 $um' : '$n $varios';

  _Item _pessoaCartoes(CartoesDaPessoa c, _Categoria cat) {
    final subtitulo = c.funcao == Funcao.tecnico ? '${_time(c.timeId)} · técnico' : _time(c.timeId);
    final leitura = [
      if (c.amarelos > 0) _plural(c.amarelos, 'amarelo', 'amarelos'),
      if (c.vermelhos > 0) _plural(c.vermelhos, 'vermelho', 'vermelhos'),
    ].join(' e ');
    final Widget valor = switch (cat) {
      _Categoria.amarelos => _Contagem(c.amarelos, cor: AppColors.amarelo),
      _Categoria.vermelhos => _Contagem(c.vermelhos, cor: AppColors.vermelho),
      _ => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.amarelos > 0) _Contagem(c.amarelos, cor: AppColors.amarelo),
          if (c.amarelos > 0 && c.vermelhos > 0) const SizedBox(width: AppSpacing.md),
          if (c.vermelhos > 0) _Contagem(c.vermelhos, cor: AppColors.vermelho),
        ],
      ),
    };
    return _Item(
      posicao: c.posicao,
      timeId: c.timeId,
      titulo: _nome(c.pessoaId),
      subtitulo: subtitulo,
      valor: valor,
      leitura: leitura,
    );
  }

  _Item _gols(GolsDoTime g, {required bool marcados}) => _Item(
    posicao: g.posicao,
    timeId: g.timeId,
    titulo: _time(g.timeId),
    subtitulo: _plural(g.jogos, 'jogo', 'jogos'),
    valor: _Numero(g.gols, g.gols == 1 ? 'gol' : 'gols'),
    leitura: '${_plural(g.gols, 'gol', 'gols')} ${marcados ? 'marcados' : 'sofridos'} em '
        '${_plural(g.jogos, 'jogo', 'jogos')}',
  );

  @override
  Widget build(BuildContext context) {
    final (itens, vazio, nota) = switch (categoria) {
      _Categoria.artilharia => (
        [
          for (final a in painel.artilharia)
            _Item(
              posicao: a.posicao,
              timeId: a.timeId,
              titulo: _nome(a.pessoaId),
              subtitulo: _time(a.timeId),
              valor: _Numero(a.gols, a.gols == 1 ? 'gol' : 'gols'),
              leitura: _plural(a.gols, 'gol', 'gols'),
            ),
        ],
        'A artilharia aparece quando a Organização lança os autores dos gols na súmula.',
        'Só contam gols com autor lançado na súmula. Gols contra e os gols de W.O. ficam de fora.',
      ),
      _Categoria.melhorDaPartida => (
        [
          for (final m in painel.melhoresDaPartida)
            _Item(
              posicao: m.posicao,
              timeId: m.timeId,
              titulo: _nome(m.pessoaId),
              subtitulo: _time(m.timeId),
              valor: _Numero(m.vezes, m.vezes == 1 ? 'vez' : 'vezes'),
              leitura: _plural(m.vezes, 'vez', 'vezes'),
            ),
        ],
        'Aparece quando a Organização escolhe o melhor da partida na súmula.',
        'Escolhido pela Organização em cada súmula. Jogo de W.O. não tem melhor da partida.',
      ),
      _Categoria.ataque => (
        [for (final g in painel.melhorAtaque) _gols(g, marcados: true)],
        'Aparece quando houver jogos encerrados.',
        'Gols marcados na fase classificatória, incluindo os de W.O. (art. 75).',
      ),
      _Categoria.defesa => (
        [for (final g in painel.melhorDefesa) _gols(g, marcados: false)],
        'Aparece quando houver jogos encerrados.',
        'Gols sofridos na fase classificatória, incluindo os de W.O. (art. 75). Menos gols, '
            'melhor defesa.',
      ),
      _Categoria.amarelos => (
        [for (final c in painel.amarelos) _pessoaCartoes(c, categoria)],
        'Nenhum cartão amarelo no turno.',
        'Inclui técnicos. O 2º amarelo no mesmo jogo conta como dois amarelos.',
      ),
      _Categoria.vermelhos => (
        [for (final c in painel.vermelhos) _pessoaCartoes(c, categoria)],
        'Nenhum cartão vermelho no turno.',
        'Inclui técnicos. O 2º amarelo no mesmo jogo conta como vermelho, porque gera expulsão.',
      ),
      _Categoria.cartoes => (
        [for (final c in painel.cartoes) _pessoaCartoes(c, categoria)],
        'Nenhum cartão no turno.',
        'Inclui técnicos. O 2º amarelo conta como dois amarelos e um vermelho. No empate, '
            'quem tem mais vermelhos fica à frente.',
      ),
    };

    if (itens.isEmpty) return ListaVazia(titulo: categoria.rotulo, texto: vazio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (final (i, item) in itens.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.linha),
                _Linha(painel: painel, item: item),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(nota, style: AppTextStyles.pequeno.copyWith(color: AppColors.texto2)),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  final Painel painel;
  final _Item item;
  const _Linha({required this.painel, required this.item});

  @override
  Widget build(BuildContext context) {
    final time = painel.times[item.timeId];
    final lider = item.posicao == 1;
    return Semantics(
      label: '${item.posicao}º, ${item.titulo}, ${item.subtitulo}, ${item.leitura}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${item.posicao}º',
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
                    Text(item.titulo, style: AppTextStyles.nome),
                    Text(item.subtitulo, style: AppTextStyles.pequeno),
                  ],
                ),
              ),
              item.valor,
            ],
          ),
        ),
      ),
    );
  }
}

/// Número grande com a unidade ao lado ("5 gols").
class _Numero extends StatelessWidget {
  final int valor;
  final String unidade;
  const _Numero(this.valor, this.unidade);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text('$valor', style: AppTextStyles.placar),
      const SizedBox(width: 4),
      Text(unidade, style: AppTextStyles.pequeno),
    ],
  );
}

/// Cartão desenhado com a quantidade ao lado.
class _Contagem extends StatelessWidget {
  final int valor;
  final Color cor;
  const _Contagem(this.valor, {required this.cor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 16,
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 6),
      Text('$valor', style: AppTextStyles.placar),
    ],
  );
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

/// Botões 1º Turno, 2º Turno e Geral da Tabela.
class SeletorTurno extends StatelessWidget {
  final Painel painel;
  const SeletorTurno({super.key, required this.painel});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TorcedorController>();
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final (t, rotulo) in [(1, '1º Turno'), (2, '2º Turno'), (Painel.geral, 'Geral')])
          ChipFiltro(
            rotulo,
            ativo: painel.turno == t,
            onTap: () => controller.escolherTurno(t),
          ),
      ],
    );
  }
}
