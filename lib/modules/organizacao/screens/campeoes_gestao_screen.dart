import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/entities/campeoes.dart';
import '../../../domain/entities/categoria.dart';
import '../../../shared/layout/tela_larga.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../campeoes/campeoes_controller.dart';
import '../../campeoes/escalacao_campeao.dart';
import '../organizacao_shell.dart';

const _rotaLista = '/organizacao/gestao/campeoes';

/// Gestão › Campeões: os títulos da categoria que esta conta organiza.
class CampeoesGestaoScreen extends StatelessWidget {
  const CampeoesGestaoScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final titulos = context.select((CampeoesController c) => c.de(o.categoria));
      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          const BotaoVoltar(rotulo: 'Gestão', rota: '/organizacao/gestao'),
          CabecalhoTela(
            'Campeões',
            subtitulo: '${o.categoria.nome} · elencos, titulares e premiações',
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'O que for salvo aqui aparece em Campeões no site e nos apps, para todos.',
            style: AppTextStyles.pequeno,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const Key('novo-campeao'),
            onPressed: () => context.go('$_rotaLista/novo'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo campeão'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (titulos.isEmpty)
            const ListaVazia(
              titulo: 'Nenhum campeão cadastrado',
              texto: 'Cadastre o primeiro título da categoria.',
            ),
          for (final t in titulos) ...[
            Cartao(
              onTap: () => context.go('$_rotaLista/${t.ano}'),
              child: Row(
                children: [
                  _Camisa(cor: t.cor, numero: t.corNumero, tamanho: 34),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.ano} · ${t.campeao}', style: AppTextStyles.nome),
                        Text(_resumo(t), style: AppTextStyles.pequeno),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    },
  );

  static String _resumo(TituloTemporada t) {
    if (t.elenco.isEmpty) return 'Sem elenco cadastrado';
    final partes = [
      '${t.elenco.length} no elenco',
      if (t.titulares.isNotEmpty) '${t.titulares.length} titulares' else 'sem titulares',
      if (t.premios.isNotEmpty) '${t.premios.length} ${t.premios.length == 1 ? 'prêmio' : 'prêmios'}',
    ];
    return partes.join(' · ');
  }
}

/// Cadastro ou edição de um título ([ano] nulo: novo).
class EditarCampeaoScreen extends StatelessWidget {
  final int? ano;
  const EditarCampeaoScreen({super.key, this.ano});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final titulos = context.read<CampeoesController>().de(o.categoria);
      final original = titulos.where((t) => t.ano == ano).firstOrNull;
      final cores = <int>{for (final t in o.dados.times) t.cor};
      return _Editor(
        key: ValueKey('${o.categoria.name}-$ano'),
        categoria: o.categoria,
        original: original,
        outrosAnos: [for (final t in titulos) if (t.ano != original?.ano) t.ano],
        times: [for (final t in o.dados.times) (nome: t.nome, cor: t.cor)],
        coresDosTimes: cores.toList(),
      );
    },
  );
}

class _JogadorEditavel {
  final TextEditingController nome;
  final TextEditingController numero;
  final TextEditingController curto;
  PosicaoCampeao? posicao;
  bool titular;

  _JogadorEditavel({String nome = '', int? numero, String? curto, this.posicao, this.titular = false})
    : nome = TextEditingController(text: nome),
      numero = TextEditingController(text: numero?.toString() ?? ''),
      curto = TextEditingController(text: curto ?? '');

  factory _JogadorEditavel.de(JogadorCampeao j) => _JogadorEditavel(
    nome: j.nome,
    numero: j.numero,
    curto: j.curto,
    posicao: j.posicao,
    titular: j.titular,
  );

  JogadorCampeao paraJogador() {
    final c = curto.text.trim();
    return JogadorCampeao(
      nome.text.trim(),
      posicao,
      titular: titular,
      numero: int.tryParse(numero.text.trim()),
      curto: c.isEmpty ? null : c,
    );
  }

  void dispose() {
    nome.dispose();
    numero.dispose();
    curto.dispose();
  }
}

class _PremioEditavel {
  final TextEditingController premio;
  final TextEditingController nome;
  final TextEditingController time;

  _PremioEditavel({String premio = '', String nome = '', String? time})
    : premio = TextEditingController(text: premio),
      nome = TextEditingController(text: nome),
      time = TextEditingController(text: time ?? '');

  PremioTemporada paraPremio() {
    final t = time.text.trim();
    return PremioTemporada(premio.text.trim(), nome.text.trim(), time: t.isEmpty ? null : t);
  }

  void dispose() {
    premio.dispose();
    nome.dispose();
    time.dispose();
  }
}

class _Editor extends StatefulWidget {
  final Categoria categoria;
  final TituloTemporada? original;
  final List<int> outrosAnos;
  final List<({String nome, int cor})> times;
  final List<int> coresDosTimes;

  const _Editor({
    super.key,
    required this.categoria,
    required this.original,
    required this.outrosAnos,
    required this.times,
    required this.coresDosTimes,
  });

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  /// Cores para times que não estão na tabela atual (Brasil, Roma, Napoli...).
  static const _coresExtras = [
    0xFFFFDF00, // amarelo
    0xFF12A0D7, // azul-claro
    0xFF8E1F2F, // grená
    0xFF00A752, // verde
    0xFFF27F1B, // laranja
    0xFFFFFFFF, // branco
    0xFF111111, // preto
  ];
  static const _coresNumero = [0xFFFFFFFF, 0xFF111111, 0xFFF4B43A, 0xFF009C3B];
  static const _premiosSugeridos = ['Melhor jogador', 'Artilheiro', 'Melhor goleiro'];

  late final _ano = TextEditingController(text: widget.original?.ano.toString() ?? '');
  late final _campeao = TextEditingController(text: widget.original?.campeao ?? '');
  late int? _cor = widget.original?.cor;
  late int? _corNumero = widget.original?.corNumero;
  late final _elenco = [
    for (final j in widget.original?.elenco ?? const <JogadorCampeao>[]) _JogadorEditavel.de(j),
  ];
  late final _premios = [
    for (final p in widget.original?.premios ?? const <PremioTemporada>[])
      _PremioEditavel(premio: p.premio, nome: p.nome, time: p.time),
  ];
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _ano.dispose();
    _campeao.dispose();
    for (final j in _elenco) {
      j.dispose();
    }
    for (final p in _premios) {
      p.dispose();
    }
    super.dispose();
  }

  TituloTemporada _montar() => TituloTemporada(
    int.tryParse(_ano.text.trim()) ?? 0,
    _campeao.text.trim(),
    cor: _cor,
    corNumero: _corNumero,
    elenco: [for (final j in _elenco) j.paraJogador()],
    premios: [for (final p in _premios) p.paraPremio()],
  );

  Future<void> _salvar() async {
    final titulo = _montar();
    final problema = problemaDoTitulo(titulo, outrosAnos: widget.outrosAnos);
    setState(() => _erro = problema);
    if (problema != null) return;
    setState(() => _salvando = true);
    try {
      await context.read<CampeoesController>().salvar(
        widget.categoria,
        titulo,
        anoOriginal: widget.original?.ano,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campeão salvo.')));
      context.go(_rotaLista);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final original = widget.original;
    if (original == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir campeão?'),
        content: Text(
          'O título de ${original.ano} (${original.campeao}) sai de Campeões, com elenco e '
          'premiações. Não dá para desfazer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.vermelho)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _salvando = true);
    try {
      await context.read<CampeoesController>().excluir(widget.categoria, original.ano);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campeão excluído.')));
      context.go(_rotaLista);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível excluir: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// Cola uma lista de nomes (um por linha) no elenco.
  Future<void> _colarLista() async {
    final campo = TextEditingController();
    final nomes = await showDialog<List<String>>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Colar elenco'),
        content: SizedBox(
          width: 420,
          child: TextField(
            key: const Key('colar-elenco'),
            controller: campo,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Um nome por linha.\nEx.: "Goleiro - Toupeira" já marca a posição.',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(
              c,
              [for (final l in campo.text.split('\n')) if (l.trim().isNotEmpty) l.trim()],
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    campo.dispose();
    if (nomes == null || nomes.isEmpty || !mounted) return;
    setState(() {
      for (final linha in nomes) {
        final (posicao, nome) = _lerLinha(linha);
        _elenco.add(_JogadorEditavel(nome: nome, posicao: posicao));
      }
    });
  }

  /// "Zagueiro - Cesar" ou "Zagueiro: Cesar" vira posição e nome.
  static (PosicaoCampeao?, String) _lerLinha(String linha) {
    final partes = linha.split(RegExp(r'\s*[-:–]\s*'));
    if (partes.length >= 2) {
      final p = _posicaoDe(partes.first);
      if (p != null) return (p, partes.sublist(1).join(' - ').trim());
    }
    return (null, linha);
  }

  static PosicaoCampeao? _posicaoDe(String t) {
    final s = t.toLowerCase().trim();
    if (s.startsWith('gol')) return PosicaoCampeao.goleiro;
    if (s.startsWith('zag')) return PosicaoCampeao.zagueiro;
    if (s.startsWith('mei') || s.startsWith('meio')) return PosicaoCampeao.meia;
    if (s.startsWith('ata')) return PosicaoCampeao.ataque;
    return null;
  }

  String _contagemTitulares() {
    final t = _montar();
    if (t.titulares.isEmpty) return 'Nenhum titular marcado: o painel mostra só a lista do elenco.';
    final partes = [
      for (final MapEntry(key: p, value: n) in titularesPorPosicao.entries)
        '${t.titularesDe(p).length}/$n ${n == 1 ? p.nome.toLowerCase() : p.plural.toLowerCase()}',
    ];
    return 'Titulares: ${partes.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.original == null;
    return ListView(
      padding: TelaLarga.margens(context),
      children: [
        const BotaoVoltar(rotulo: 'Campeões', rota: _rotaLista),
        CabecalhoTela(
          novo ? 'Novo campeão' : 'Editar campeão',
          subtitulo: widget.categoria.nome,
        ),
        const SizedBox(height: AppSpacing.lg),
        const TituloSecao('Título'),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('campeao-ano'),
                controller: _ano,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Ano', counterText: ''),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                key: const Key('campeao-time'),
                controller: _campeao,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Time campeão'),
              ),
            ),
          ],
        ),
        if (widget.times.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in widget.times)
                ActionChip(
                  avatar: _Camisa(cor: t.cor, tamanho: 18),
                  label: Text(t.nome),
                  onPressed: () => setState(() {
                    _campeao.text = t.nome;
                    _cor = t.cor;
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Text('Cor da camisa no campinho', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        _Cores(
          cores: [...widget.coresDosTimes, ..._coresExtras.where((c) => !widget.coresDosTimes.contains(c))],
          atual: _cor,
          onEscolher: (c) => setState(() => _cor = c),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Cor do número', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        _Cores(
          cores: _coresNumero,
          atual: _corNumero ?? 0xFFFFFFFF,
          onEscolher: (c) => setState(() => _corNumero = c == 0xFFFFFFFF ? null : c),
        ),
        const SizedBox(height: AppSpacing.xl),
        TituloSecao('Elenco (${_elenco.length})'),
        Text(_contagemTitulares(), style: AppTextStyles.pequeno),
        const SizedBox(height: AppSpacing.md),
        for (final (i, j) in _elenco.indexed) ...[
          _LinhaJogador(
            key: ObjectKey(j),
            jogador: j,
            onMudou: () => setState(() {}),
            onRemover: () => setState(() => _elenco.removeAt(i).dispose()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            TextButton.icon(
              key: const Key('adicionar-jogador'),
              onPressed: () => setState(() => _elenco.add(_JogadorEditavel())),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Adicionar jogador'),
            ),
            TextButton.icon(
              onPressed: _colarLista,
              icon: const Icon(Icons.content_paste_rounded),
              label: const Text('Colar lista de nomes'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const TituloSecao('Premiações da temporada'),
        for (final (i, p) in _premios.indexed) ...[
          _LinhaPremio(
            key: ObjectKey(p),
            premio: p,
            onRemover: () => setState(() => _premios.removeAt(i).dispose()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in _premiosSugeridos)
              if (!_premios.any((p) => p.premio.text.trim() == s))
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text(s),
                  onPressed: () => setState(() => _premios.add(_PremioEditavel(premio: s))),
                ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Outro prêmio'),
              onPressed: () => setState(() => _premios.add(_PremioEditavel())),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_erro != null) ...[
          Text(_erro!, style: AppTextStyles.corpo.copyWith(color: AppColors.vermelho)),
          const SizedBox(height: AppSpacing.md),
        ],
        OutlinedButton.icon(
          onPressed: _campeao.text.trim().isEmpty
              ? null
              : () => abrirEscalacao(context, widget.categoria, _montar()),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Ver como fica'),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('salvar-campeao'),
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando…' : 'Salvar'),
        ),
        if (!novo) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _salvando ? null : _excluir,
            child: const Text('Excluir este campeão', style: TextStyle(color: AppColors.vermelho)),
          ),
        ],
      ],
    );
  }
}

class _LinhaJogador extends StatelessWidget {
  final _JogadorEditavel jogador;
  final VoidCallback onMudou;
  final VoidCallback onRemover;

  const _LinhaJogador({super.key, required this.jogador, required this.onMudou, required this.onRemover});

  @override
  Widget build(BuildContext context) => Cartao(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: jogador.nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
            ),
            IconButton(
              tooltip: 'Remover do elenco',
              onPressed: onRemover,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.texto2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<PosicaoCampeao?>(
              value: jogador.posicao,
              hint: const Text('Posição'),
              onChanged: (p) {
                jogador.posicao = p;
                onMudou();
              },
              items: [
                const DropdownMenuItem(child: Text('Sem posição')),
                for (final p in PosicaoCampeao.values) DropdownMenuItem(value: p, child: Text(p.nome)),
              ],
            ),
            FilterChip(
              label: const Text('Titular'),
              selected: jogador.titular,
              onSelected: (v) {
                jogador.titular = v;
                onMudou();
              },
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: jogador.numero,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                decoration: const InputDecoration(labelText: 'Nº', counterText: ''),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: jogador.curto,
                decoration: const InputDecoration(labelText: 'Nome no campo'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LinhaPremio extends StatelessWidget {
  final _PremioEditavel premio;
  final VoidCallback onRemover;

  const _LinhaPremio({super.key, required this.premio, required this.onRemover});

  @override
  Widget build(BuildContext context) => Cartao(
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: premio.premio,
                decoration: const InputDecoration(labelText: 'Prêmio'),
              ),
            ),
            IconButton(
              tooltip: 'Remover prêmio',
              onPressed: onRemover,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.texto2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: premio.nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Quem ganhou'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: premio.time,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Time (se não for o campeão)',
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Cores extends StatelessWidget {
  final List<int> cores;
  final int? atual;
  final ValueChanged<int> onEscolher;

  const _Cores({required this.cores, required this.atual, required this.onEscolher});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final c in cores)
        Semantics(
          button: true,
          selected: c == atual,
          label: 'Cor ${c.toRadixString(16).substring(2).toUpperCase()}',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onEscolher(c),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: c == atual ? AppColors.verde : AppColors.linha,
                  width: c == atual ? 3 : 1,
                ),
              ),
              child: c == atual
                  ? Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Color(c).computeLuminance() > 0.5 ? AppColors.tinta : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
    ],
  );
}

/// Bolinha com a cor da camisa (e do número) do campeão.
class _Camisa extends StatelessWidget {
  final int? cor;
  final int? numero;
  final double tamanho;
  const _Camisa({required this.cor, this.numero, required this.tamanho});

  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(
      color: Color(cor ?? 0xFF008E44),
      shape: BoxShape.circle,
      border: Border.all(color: Color(numero ?? 0xFFFFFFFF), width: 2),
    ),
  );
}
