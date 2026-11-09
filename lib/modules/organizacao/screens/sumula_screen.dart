import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/temporada.dart';
import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';

/// O3/O4 · Súmula: lançamento depois do jogo e encerramento.
class SumulaScreen extends StatelessWidget {
  final String partidaId;

  /// Súmula reaberta para correção (preenche o formulário).
  final Sumula? inicial;

  const SumulaScreen({super.key, required this.partidaId, this.inicial});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final p = o.dados.partidas.where((x) => x.id == partidaId).firstOrNull;
      if (p == null) return const Center(child: Text('Jogo não encontrado.'));
      return _Sumula(key: ValueKey(p.id), partida: p, dados: o.dados, inicial: inicial ?? p.sumula);
    },
  );
}

class _Sumula extends StatefulWidget {
  final Partida partida;
  final DadosTemporada dados;
  final Sumula? inicial;

  const _Sumula({super.key, required this.partida, required this.dados, this.inicial});

  @override
  State<_Sumula> createState() => _SumulaState();
}

class _SumulaState extends State<_Sumula> {
  late int _golsM = widget.inicial?.golsMandante ?? 0;
  late int _golsV = widget.inicial?.golsVisitante ?? 0;
  late String? _ausente = widget.inicial?.ausenteWo;
  late final List<Gol> _gols = [...?widget.inicial?.gols];
  late final List<CartaoAplicado> _cartoes = [...?widget.inicial?.cartoes];
  late final Set<String> _semPontos = {...?widget.inicial?.timesSemPontos};
  late int _penM = widget.inicial?.penaltis?.mandante ?? 0;
  late int _penV = widget.inicial?.penaltis?.visitante ?? 0;
  late final _youtube = TextEditingController(text: widget.inicial?.youtubeUrl ?? '');
  late final _obs = TextEditingController(text: widget.inicial?.observacoes ?? '');
  bool _salvando = false;

  Partida get p => widget.partida;
  Time time(String id) => widget.dados.times.firstWhere((t) => t.id == id);
  String nome(String? id) =>
      widget.dados.pessoas.where((x) => x.id == id).firstOrNull?.nome ?? (id ?? 'Gol');

  @override
  void dispose() {
    _youtube.dispose();
    _obs.dispose();
    super.dispose();
  }

  bool get _precisaPenaltis => p.fase.eliminatoria && _ausente == null && _golsM == _golsV;

  String? get _problema {
    if (_ausente != null) return null;
    final doM = _gols.where((g) => g.timeId == p.mandanteId).length;
    final doV = _gols.where((g) => g.timeId == p.visitanteId).length;
    if (doM > _golsM || doV > _golsV) {
      return 'Há mais gols na lista do que no placar.';
    }
    return null;
  }

  Future<void> _encerrar() async {
    final c = context.read<OrganizacaoController>();
    setState(() => _salvando = true);
    try {
      await c.salvarPartida(
        p.comSumula(
          Sumula(
            golsMandante: _ausente == null ? _golsM : 0,
            golsVisitante: _ausente == null ? _golsV : 0,
            ausenteWo: _ausente,
            penaltis: _precisaPenaltis ? Penaltis(_penM, _penV) : null,
            gols: _ausente == null ? _gols : const [],
            cartoes: _cartoes,
            timesSemPontos: _semPontos,
            observacoes: _obs.text.trim().isEmpty ? null : _obs.text.trim(),
            youtubeUrl: _youtube.text.trim().isEmpty ? null : _youtube.text.trim(),
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Súmula encerrada. Tabela e disciplina atualizadas.')),
      );
      context.go('/organizacao/jogos/${p.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não foi possível salvar. Tente de novo.')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _adicionarGol() async {
    final g = await showModalBottomSheet<Gol>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormGol(partida: p, dados: widget.dados),
    );
    if (g != null) setState(() => _gols.add(g));
  }

  Future<void> _adicionarCartao() async {
    final c = await showModalBottomSheet<CartaoAplicado>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormCartao(partida: p, dados: widget.dados, jaLancados: _cartoes),
    );
    if (c != null) setState(() => _cartoes.add(c));
  }

  Widget _placar(Time t, int valor, ValueChanged<int> mudar) => Expanded(
    child: Column(
      children: [
        Escudo(t, tamanho: 44),
        const SizedBox(height: AppSpacing.xs),
        Text(t.nome, style: AppTextStyles.nome, textAlign: TextAlign.center),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Menos um gol',
              onPressed: valor == 0 ? null : () => mudar(valor - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$valor', style: AppTextStyles.placar.copyWith(fontSize: 32)),
            IconButton(
              tooltip: 'Mais um gol',
              onPressed: () => mudar(valor + 1),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.verde),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final m = time(p.mandanteId);
    final v = time(p.visitanteId);
    final problema = _problema;

    return ListView(
      padding: AppSpacing.tela,
      children: [
        VoltarGestao(rotulo: 'Jogo', rota: '/organizacao/jogos/${p.id}'),
        CabecalhoTela(
          '${m.nome} x ${v.nome}',
          subtitulo: '${p.rodada != null ? 'Rodada ${p.rodada} · ' : ''}${dataHoraJogo(p.inicio)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Lance a partir da súmula de papel ou da transmissão, depois do jogo.',
          style: AppTextStyles.pequeno,
        ),
        const TituloSecao('Resultado'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChipFiltro(
              'Jogo normal',
              ativo: _ausente == null,
              onTap: () => setState(() => _ausente = null),
            ),
            ChipFiltro(
              'W.O.: ${m.sigla} faltou',
              ativo: _ausente == m.id,
              onTap: () => setState(() => _ausente = m.id),
            ),
            ChipFiltro(
              'W.O.: ${v.sigla} faltou',
              ativo: _ausente == v.id,
              onTap: () => setState(() => _ausente = v.id),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_ausente != null)
          Cartao(
            child: Text(
              'Vale 6 x 0 para ${time(p.adversario(_ausente!)).nome}, e ${time(_ausente!).nome} '
              'perde 3 pontos (art. 75). Cartões registrados continuam valendo.',
              style: AppTextStyles.corpo,
            ),
          )
        else
          Cartao(
            child: Row(
              children: [
                _placar(m, _golsM, (x) => setState(() => _golsM = x)),
                const Text('×', style: AppTextStyles.placar),
                _placar(v, _golsV, (x) => setState(() => _golsV = x)),
              ],
            ),
          ),
        if (_precisaPenaltis) ...[
          const TituloSecao('Pênaltis'),
          Cartao(
            child: Row(
              children: [
                _placar(m, _penM, (x) => setState(() => _penM = x)),
                const Text('×', style: AppTextStyles.placar),
                _placar(v, _penV, (x) => setState(() => _penV = x)),
              ],
            ),
          ),
        ],
        if (_ausente == null) ...[
          TituloSecao('Gols (${_gols.length})', acao: '+ Adicionar', onAcao: _adicionarGol),
          if (_gols.isEmpty)
            const Text('Autores dos gols (opcional).', style: AppTextStyles.pequeno),
          for (final (i, g) in _gols.indexed)
            _Linha(
              icone: const Icon(Icons.sports_soccer, size: 18, color: AppColors.verde),
              texto: '${nome(g.autorId)}${g.contra ? ' (contra)' : ''} · ${time(g.timeId).sigla}',
              lateral: '${g.tempo}º tempo',
              onRemover: () => setState(() => _gols.removeAt(i)),
            ),
          if (problema != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(problema, style: AppTextStyles.corpo.copyWith(color: AppColors.vermelho)),
            ),
        ],
        TituloSecao('Cartões (${_cartoes.length})', acao: '+ Adicionar', onAcao: _adicionarCartao),
        if (_cartoes.isEmpty) const Text('Nenhum cartão.', style: AppTextStyles.pequeno),
        for (final (i, c) in _cartoes.indexed)
          _Linha(
            icone: Container(
              width: 10,
              height: 14,
              decoration: BoxDecoration(
                color: c.tipo == TipoCartao.amarelo ? AppColors.amarelo : AppColors.vermelho,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            texto:
                '${nome(c.pessoaId)} · ${time(c.timeId).sigla}${c.funcao == Funcao.tecnico ? ' (técnico)' : ''}',
            lateral: switch (c.tipo) {
              TipoCartao.amarelo => 'Amarelo',
              TipoCartao.segundoAmarelo => '2º amarelo',
              TipoCartao.vermelho => 'Vermelho',
            },
            onRemover: () => setState(() => _cartoes.removeAt(i)),
          ),
        const TituloSecao('Irregularidade'),
        for (final t in [m, v])
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _semPontos.contains(t.id),
            onChanged: (x) => setState(() {
              if (x == true) {
                _semPontos.add(t.id);
              } else {
                _semPontos.remove(t.id);
              }
            }),
            title: Text('${t.nome} perde os pontos', style: AppTextStyles.rotulo),
            subtitle: const Text(
              'Atleta que assinou e não jogou, débito em campo ou menos de 4 atletas (arts. 4, 43.1, 68).',
              style: AppTextStyles.pequeno,
            ),
          ),
        const TituloSecao('Fonte e observações'),
        TextField(
          controller: _youtube,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Link da transmissão (YouTube), se houver',
            border: OutlineInputBorder(borderRadius: AppRadius.botao),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _obs,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Observações da súmula',
            border: OutlineInputBorder(borderRadius: AppRadius.botao),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _salvando || problema != null ? null : _encerrar,
          child: Text(_salvando ? 'Salvando…' : 'Encerrar súmula'),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Ao encerrar, o resultado entra na tabela e os cartões geram pendências e suspensões.',
          style: AppTextStyles.pequeno,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  final Widget icone;
  final String texto;
  final String lateral;
  final VoidCallback onRemover;

  const _Linha({
    required this.icone,
    required this.texto,
    required this.lateral,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Cartao(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 4, 4),
      child: Row(
        children: [
          SizedBox(width: 20, child: Center(child: icone)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(texto, style: AppTextStyles.rotulo)),
          Text(lateral, style: AppTextStyles.pequeno),
          IconButton(
            tooltip: 'Remover',
            onPressed: onRemover,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.dica),
          ),
        ],
      ),
    ),
  );
}

/// Seletor de pessoa do elenco (lista simples, sem menus suspensos).
class _ListaPessoas extends StatelessWidget {
  final List<Pessoa> pessoas;
  final String? selecionada;
  final ValueChanged<String> onSelecionar;

  const _ListaPessoas({
    required this.pessoas,
    required this.selecionada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    if (pessoas.isEmpty) {
      return const Text(
        'Elenco ainda não importado. Importe em Gestão → Importar elencos.',
        style: AppTextStyles.pequeno,
      );
    }
    return Column(
      children: [
        for (final x in pessoas)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            selected: x.id == selecionada,
            selectedColor: AppColors.verde,
            leading: SizedBox(
              width: 28,
              child: Text(x.numero == null ? '' : '#${x.numero}', style: AppTextStyles.rotulo),
            ),
            title: Text(x.nome.toUpperCase(), style: AppTextStyles.nome.copyWith(fontSize: 12)),
            trailing: x.id == selecionada
                ? const Icon(Icons.check_circle_rounded, color: AppColors.verde)
                : null,
            onTap: () => onSelecionar(x.id),
          ),
      ],
    );
  }
}

List<Pessoa> _elenco(DadosTemporada d, String timeId, Funcao funcao) =>
    d.pessoas.where((x) => x.timeId == timeId && x.funcao == funcao).toList()
      ..sort((a, b) => (a.numero ?? 999).compareTo(b.numero ?? 999));

class _FormGol extends StatefulWidget {
  final Partida partida;
  final DadosTemporada dados;
  const _FormGol({required this.partida, required this.dados});

  @override
  State<_FormGol> createState() => _FormGolState();
}

class _FormGolState extends State<_FormGol> {
  late String _time = widget.partida.mandanteId;
  bool _contra = false;
  int _tempo = 1;
  String? _autor;

  @override
  Widget build(BuildContext context) {
    final p = widget.partida;
    String sigla(String id) => widget.dados.times.firstWhere((t) => t.id == id).nome;
    // Gol contra: o autor é do time adversário.
    final timeDoAutor = _contra ? p.adversario(_time) : _time;
    return _Folha(
      titulo: 'Adicionar gol',
      botao: 'Adicionar gol',
      pronto: _autor != null,
      onConfirmar: () => Navigator.pop(
        context,
        Gol(timeId: _time, autorId: _autor, contra: _contra, tempo: _tempo),
      ),
      children: [
        const Text('Time que marcou', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final t in [p.mandanteId, p.visitanteId])
              ChipFiltro(
                sigla(t),
                ativo: t == _time,
                onTap: () => setState(() {
                  _time = t;
                  _autor = null;
                }),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _contra,
          onChanged: (x) => setState(() {
            _contra = x;
            _autor = null;
          }),
          title: const Text('Gol contra', style: AppTextStyles.rotulo),
        ),
        const Text('Tempo', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final t in const [1, 2])
              ChipFiltro('$tº tempo', ativo: t == _tempo, onTap: () => setState(() => _tempo = t)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(_contra ? 'Quem fez contra' : 'Autor do gol', style: AppTextStyles.rotulo),
        _ListaPessoas(
          pessoas: _elenco(widget.dados, timeDoAutor, Funcao.atleta),
          selecionada: _autor,
          onSelecionar: (id) => setState(() => _autor = id),
        ),
      ],
    );
  }
}

class _FormCartao extends StatefulWidget {
  final Partida partida;
  final DadosTemporada dados;
  final List<CartaoAplicado> jaLancados;
  const _FormCartao({required this.partida, required this.dados, required this.jaLancados});

  @override
  State<_FormCartao> createState() => _FormCartaoState();
}

class _FormCartaoState extends State<_FormCartao> {
  late String _time = widget.partida.mandanteId;
  Funcao _funcao = Funcao.atleta;
  String? _pessoa;
  TipoCartao _tipo = TipoCartao.amarelo;

  String get _consequencia {
    final ehTecnico = _funcao == Funcao.tecnico;
    final temAmarelo = widget.jaLancados.any(
      (c) => c.pessoaId == _pessoa && c.tipo == TipoCartao.amarelo,
    );
    return switch (_tipo) {
      TipoCartao.amarelo => 'Gera pendência de R\$ 30,00.',
      TipoCartao.segundoAmarelo =>
        'Vira vermelho: pendência de R\$ 50,00 (o 1º amarelo não é cobrado)'
            '${ehTecnico ? '.' : ' e suspensão no próximo jogo.'}',
      TipoCartao.vermelho =>
        'Pendência de R\$ 50,00${temAmarelo ? ' (mais R\$ 30,00 do amarelo)' : ''}'
            '${ehTecnico ? '. Técnico não é suspenso.' : ' e suspensão no próximo jogo.'}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partida;
    String nomeTime(String id) => widget.dados.times.firstWhere((t) => t.id == id).nome;
    return _Folha(
      titulo: 'Adicionar cartão',
      botao: 'Adicionar cartão',
      pronto: _pessoa != null,
      onConfirmar: () => Navigator.pop(
        context,
        CartaoAplicado(pessoaId: _pessoa!, timeId: _time, tipo: _tipo, funcao: _funcao),
      ),
      children: [
        const Text('Time', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final t in [p.mandanteId, p.visitanteId])
              ChipFiltro(
                nomeTime(t),
                ativo: t == _time,
                onTap: () => setState(() {
                  _time = t;
                  _pessoa = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Quem recebeu', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final (f, r) in const [(Funcao.atleta, 'Atleta'), (Funcao.tecnico, 'Técnico')])
              ChipFiltro(
                r,
                ativo: f == _funcao,
                onTap: () => setState(() {
                  _funcao = f;
                  _pessoa = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Cartão', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (t, r) in const [
              (TipoCartao.amarelo, 'Amarelo'),
              (TipoCartao.segundoAmarelo, '2º amarelo'),
              (TipoCartao.vermelho, 'Vermelho'),
            ])
              ChipFiltro(r, ativo: t == _tipo, onTap: () => setState(() => _tipo = t)),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.amareloSuave,
            borderRadius: AppRadius.botao,
          ),
          child: Text(_consequencia, style: AppTextStyles.corpo.copyWith(color: AppColors.tinta)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(_funcao == Funcao.tecnico ? 'Técnico' : 'Atleta', style: AppTextStyles.rotulo),
        _ListaPessoas(
          pessoas: _elenco(widget.dados, _time, _funcao),
          selecionada: _pessoa,
          onSelecionar: (id) => setState(() => _pessoa = id),
        ),
      ],
    );
  }
}

/// Painel inferior (S1/S2 do Figma).
class _Folha extends StatelessWidget {
  final String titulo;
  final String botao;
  final bool pronto;
  final VoidCallback onConfirmar;
  final List<Widget> children;

  const _Folha({
    required this.titulo,
    required this.botao,
    required this.pronto,
    required this.onConfirmar,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (context, rolagem) => Column(
      children: [
        Expanded(
          child: ListView(
            controller: rolagem,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              Text(titulo, style: AppTextStyles.tituloSecao.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.md),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: FilledButton(onPressed: pronto ? onConfirmar : null, child: Text(botao)),
        ),
      ],
    ),
  );
}
