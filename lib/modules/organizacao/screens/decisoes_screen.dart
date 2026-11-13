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

const _rotaLista = '/organizacao/gestao/decisoes';

/// Id usado na rota para abrir o formulário em branco.
const _nova = 'nova';

MotorDisciplinar _motor(DadosTemporada d, {Iterable<DecisaoDisciplinar>? decisoes}) =>
    MotorDisciplinar(
      partidas: d.partidas,
      pagamentos: d.pagamentos,
      decisoes: decisoes ?? d.decisoes,
      agora: d.relogio ?? DateTime.now(),
      params: d.parametros,
    );

/// "MON x SAM"
String _confronto(OrgPronta o, Partida p) =>
    '${o.time(p.mandanteId)?.sigla ?? p.mandanteId} x ${o.time(p.visitanteId)?.sigla ?? p.visitanteId}';

/// "Rodada 3 · MON x SAM · Sex 19/02 · 20:30"
String _rotuloJogo(OrgPronta o, Partida p) => [
  if (p.rodada != null) 'Rodada ${p.rodada}',
  _confronto(o, p),
  dataHoraJogo(p.inicio),
].join(' · ');

String _jogos(int n) => n == 1 ? '1 jogo' : '$n jogos';

Suspensao? _suspensaoDa(MotorDisciplinar m, DecisaoDisciplinar d) => m.suspensoes
    .where(
      (s) =>
          s.motivo == MotivoSuspensao.decisao &&
          s.pessoaId == d.pessoaId &&
          s.partidaOrigemId == d.partidaOrigemId &&
          s.jogos == d.jogosSuspensao,
    )
    .firstOrNull;

Pendencia? _multaDa(MotorDisciplinar m, DecisaoDisciplinar d) =>
    m.pendencias.where((p) => p.id == idPendenciaDaDecisao(d.id)).firstOrNull;

/// Jogos em que a suspensão é cumprida, por extenso.
String _cumprimento(OrgPronta o, Suspensao s) {
  final porId = {for (final p in o.dados.partidas) p.id: p};
  final partes = [
    for (final id in s.partidasACumprir)
      if (porId[id] case final p?) '${_confronto(o, p)} (${dataHoraJogo(p.inicio)})',
  ];
  if (s.semData > 0) partes.add('${_jogos(s.semData)} ainda sem data');
  return partes.join(', ');
}

/// O9 · Gestão · Decisões e punições (arts. 87 e 88).
class DecisoesScreen extends StatelessWidget {
  const DecisoesScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final d = o.dados;
      final motor = _motor(d);
      final inicio = {for (final p in d.partidas) p.id: p.inicio};
      final antigo = DateTime(2000);
      final decisoes = [...d.decisoes]
        ..sort(
          (a, b) => (inicio[b.partidaOrigemId] ?? antigo).compareTo(
            inicio[a.partidaOrigemId] ?? antigo,
          ),
        );

      return ListView(
        padding: AppSpacing.tela,
        children: [
          const VoltarGestao(),
          CabecalhoTela(
            'Decisões e punições',
            subtitulo: decisoes.isEmpty
                ? 'Nenhuma registrada'
                : decisoes.length == 1
                ? '1 decisão registrada'
                : '${decisoes.length} decisões registradas',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            d.demonstracao
                ? 'Temporada de exemplo: o registro de decisões é liberado depois que os '
                      'jogos reais forem gerados.'
                : 'Suspensões e multas decididas pela Organização e pela arbitragem, '
                      'inclusive por vídeo. Entram na lista de suspensos e na Disciplina.',
            style: AppTextStyles.pequeno,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: d.demonstracao ? null : () => context.go('$_rotaLista/$_nova'),
            child: const Text('Nova decisão'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (decisoes.isEmpty)
            const ListaVazia(
              titulo: 'Nenhuma decisão',
              texto: 'As punições decididas fora da súmula aparecem aqui.',
            ),
          for (final x in decisoes)
            _CartaoDecisao(
              o: o,
              decisao: x,
              suspensao: x.jogosSuspensao > 0 ? _suspensaoDa(motor, x) : null,
              multa: _multaDa(motor, x),
              onTap: d.demonstracao ? null : () => context.go('$_rotaLista/${x.id}'),
            ),
        ],
      );
    },
  );
}

class _CartaoDecisao extends StatelessWidget {
  final OrgPronta o;
  final DecisaoDisciplinar decisao;
  final Suspensao? suspensao;
  final Pendencia? multa;
  final VoidCallback? onTap;

  const _CartaoDecisao({
    required this.o,
    required this.decisao,
    required this.suspensao,
    required this.multa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final x = decisao;
    final time = o.time(x.timeId);
    final origem = o.dados.partidas.where((p) => p.id == x.partidaOrigemId).firstOrNull;
    final detalhes = [
      if (origem != null) 'Ocorrido em: ${_rotuloJogo(o, origem)}',
      if (suspensao != null) 'Cumpre em: ${_cumprimento(o, suspensao!)}',
      if (x.fundamento != null) 'Enquadramento: ${x.fundamento}',
      if (x.votacao != null) 'Votação: ${x.votacao}',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Cartao(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (time != null) ...[
                  Escudo(time, tamanho: 28),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (o.pessoa(x.pessoaId)?.nome ?? x.pessoaId).toUpperCase(),
                        style: AppTextStyles.nome,
                      ),
                      Text(x.motivo, style: AppTextStyles.pequeno),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (x.jogosSuspensao > 0)
                  Etiqueta(
                    'Suspensão · ${_jogos(x.jogosSuspensao)}',
                    cor: AppColors.vermelho,
                    fundo: AppColors.vermelhoSuave,
                  ),
                if (x.multa > 0)
                  multa?.pagoEm != null
                      ? Etiqueta.verde('Multa ${reais(x.multa)} · quitada')
                      : Etiqueta(
                          'Multa ${reais(x.multa)}',
                          cor: AppColors.amareloEscuro,
                          fundo: AppColors.amareloSuave,
                        ),
              ],
            ),
            for (final linha in detalhes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(linha, style: AppTextStyles.pequeno),
              ),
          ],
        ),
      ),
    );
  }
}

/// O10 · Gestão · Nova decisão / Editar decisão
class EditarDecisaoScreen extends StatelessWidget {
  final String decisaoId;
  const EditarDecisaoScreen({super.key, required this.decisaoId});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final inicial = o.dados.decisoes.where((x) => x.id == decisaoId).firstOrNull;
      final indisponivel = o.dados.demonstracao
          ? 'O registro de decisões é liberado depois que os jogos reais forem gerados.'
          : decisaoId != _nova && inicial == null
          ? 'Decisão não encontrada.'
          : null;
      if (indisponivel != null) {
        return ListView(
          padding: AppSpacing.tela,
          children: [
            const VoltarGestao(rotulo: 'Decisões e punições', rota: _rotaLista),
            Text(indisponivel, style: AppTextStyles.corpo),
          ],
        );
      }
      return _Formulario(o: o, inicial: inicial, key: ValueKey(decisaoId));
    },
  );
}

/// Punições com valor fixo no regulamento.
const _atalhos = [
  (
    rotulo: 'Prejudicar a própria equipe',
    jogos: 1,
    multa: 10000,
    motivo: 'Atuou deliberadamente contra a própria equipe',
    fundamento: 'Art. 88',
  ),
  (
    rotulo: 'Ofensa à arbitragem (torcedor)',
    jogos: 0,
    multa: 25000,
    motivo: 'Desrespeito à arbitragem na condição de torcedor',
    fundamento: 'Atitudes antidesportivas direcionadas à arbitragem',
  ),
];

class _Formulario extends StatefulWidget {
  final OrgPronta o;
  final DecisaoDisciplinar? inicial;
  const _Formulario({super.key, required this.o, required this.inicial});

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late String? _time = widget.inicial?.timeId;
  late String? _pessoa = widget.inicial?.pessoaId;
  late Funcao _funcao = widget.o.pessoa(widget.inicial?.pessoaId ?? '')?.funcao ?? Funcao.atleta;
  late String? _origem = widget.inicial?.partidaOrigemId;
  late int _suspensao = widget.inicial?.jogosSuspensao ?? 0;
  late final _multa = TextEditingController(text: valorParaCampo(widget.inicial?.multa ?? 0));
  late final _motivo = TextEditingController(text: widget.inicial?.motivo ?? '');
  late final _fundamento = TextEditingController(text: widget.inicial?.fundamento ?? '');
  late final _votacao = TextEditingController(text: widget.inicial?.votacao ?? '');
  bool _salvando = false;

  @override
  void dispose() {
    _multa.dispose();
    _motivo.dispose();
    _fundamento.dispose();
    _votacao.dispose();
    super.dispose();
  }

  DadosTemporada get _dados => widget.o.dados;

  /// Jogos do time com súmula encerrada, do mais recente para o mais antigo.
  /// O jogo já escolhido continua na lista mesmo se a súmula foi reaberta.
  List<Partida> _jogosDoTime(String timeId) =>
      _dados.partidas
          .where(
            (p) => p.envolve(timeId) && (p.encerrada || p.id == widget.inicial?.partidaOrigemId),
          )
          .toList()
        ..sort((a, b) => b.inicio.compareTo(a.inicio));

  List<Pessoa> _elenco(String timeId) =>
      _dados.pessoas.where((x) => x.timeId == timeId && x.funcao == _funcao).toList()
        ..sort((a, b) => (a.numero ?? 999).compareTo(b.numero ?? 999));

  void _escolherTime(String id) => setState(() {
    _time = id;
    _pessoa = null;
    _origem = _jogosDoTime(id).firstOrNull?.id;
  });

  int? get _centavos => centavosDe(_multa.text);

  /// O que ainda falta para poder salvar; nulo quando está tudo preenchido.
  String? get _falta {
    if (_time == null) return 'Escolha o time.';
    if (_pessoa == null) return 'Escolha quem foi punido.';
    if (_origem == null) return 'Escolha o jogo em que ocorreu.';
    final multa = _centavos;
    if (multa == null) return 'Valor da multa inválido.';
    if (_suspensao == 0 && multa == 0) return 'Informe a suspensão, a multa ou as duas.';
    if (_motivo.text.trim().isEmpty) return 'Descreva o motivo.';
    return null;
  }

  DecisaoDisciplinar _montar() {
    String? opcional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return DecisaoDisciplinar(
      id: widget.inicial?.id ?? 'dec-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      pessoaId: _pessoa!,
      timeId: _time!,
      partidaOrigemId: _origem!,
      jogosSuspensao: _suspensao,
      multa: _centavos!,
      motivo: _motivo.text.trim(),
      fundamento: opcional(_fundamento),
      votacao: opcional(_votacao),
    );
  }

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _salvar() async {
    if (_falta != null) return;
    final controller = context.read<OrganizacaoController>();
    setState(() => _salvando = true);
    try {
      await controller.salvarDecisao(_montar());
      if (mounted) {
        _avisar('Decisão registrada.');
        context.go(_rotaLista);
      }
    } catch (_) {
      if (mounted) _avisar('Não foi possível salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final controller = context.read<OrganizacaoController>();
    // Guardados antes: ao excluir, a decisão some da tela e este formulário
    // é desmontado antes de a gravação terminar.
    final rotas = GoRouter.of(context);
    final avisos = ScaffoldMessenger.of(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Excluir decisão?'),
        content: const Text(
          'A suspensão e a multa desta decisão deixam de valer, e a quitação da multa, '
          'se houver, é apagada.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _salvando = true);
    try {
      await controller.excluirDecisao(widget.inicial!.id);
      avisos.showSnackBar(const SnackBar(content: Text('Decisão excluída.')));
      rotas.go(_rotaLista);
    } catch (_) {
      avisos.showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir. Tente de novo.')),
      );
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// O que a decisão provoca, calculado pelas mesmas regras das outras telas.
  List<String> _previa() {
    if (_falta != null) return const [];
    final rascunho = _montar();
    final motor = _motor(
      _dados,
      decisoes: [..._dados.decisoes.where((x) => x.id != rascunho.id), rascunho],
    );
    final suspensao = _suspensaoDa(motor, rascunho);
    final multa = _multaDa(motor, rascunho);
    return [
      if (rascunho.jogosSuspensao > 0)
        suspensao == null || suspensao.partidasACumprir.isEmpty
            ? 'Suspensão de ${_jogos(rascunho.jogosSuspensao)}: o time ainda não tem jogo '
                  'marcado depois deste.'
            : 'Fica fora de: ${_cumprimento(widget.o, suspensao)}.',
      if (multa != null)
        multa.prazo == null
            ? 'Multa de ${reais(multa.valor)}, sem prazo enquanto o time não tiver próximo '
                  'jogo marcado.'
            : 'Multa de ${reais(multa.valor)}, a quitar até ${dataHoraJogo(multa.prazo!)}. '
                  'Depois disso, gera multa por atraso do mesmo valor.',
    ];
  }

  InputDecoration _campo(String rotulo, {String? dica, String? prefixo}) => InputDecoration(
    labelText: rotulo,
    hintText: dica,
    prefixText: prefixo,
    border: const OutlineInputBorder(borderRadius: AppRadius.botao),
  );

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final times = [..._dados.times]..sort((a, b) => a.sigla.compareTo(b.sigla));
    final time = _time;
    final jogos = time == null ? const <Partida>[] : _jogosDoTime(time);
    final escolhida = _pessoa == null ? null : o.pessoa(_pessoa!);
    final falta = _falta;
    final previa = _previa();

    void rotulo(List<Widget> filhos, String texto) => filhos
      ..add(const SizedBox(height: AppSpacing.lg))
      ..add(Text(texto, style: AppTextStyles.rotulo))
      ..add(const SizedBox(height: AppSpacing.sm));

    final filhos = <Widget>[
      const VoltarGestao(rotulo: 'Decisões e punições', rota: _rotaLista),
      CabecalhoTela(widget.inicial == null ? 'Nova decisão' : 'Editar decisão'),
    ];

    rotulo(filhos, 'Time');
    filhos.add(
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final t in times)
            ChipFiltro(t.sigla, ativo: t.id == time, onTap: () => _escolherTime(t.id)),
        ],
      ),
    );

    if (time != null) {
      rotulo(filhos, 'Quem foi punido');
      if (escolhida != null) {
        filhos.add(
          Cartao(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${escolhida.nome.toUpperCase()}'
                    '${escolhida.funcao == Funcao.tecnico ? ' · técnico' : ''}',
                    style: AppTextStyles.nome,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _pessoa = null),
                  child: const Text('Trocar'),
                ),
              ],
            ),
          ),
        );
      } else {
        final elenco = _elenco(time);
        filhos
          ..add(
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final (f, r) in const [(Funcao.atleta, 'Atleta'), (Funcao.tecnico, 'Técnico')])
                  ChipFiltro(r, ativo: f == _funcao, onTap: () => setState(() => _funcao = f)),
              ],
            ),
          )
          ..add(const SizedBox(height: AppSpacing.sm));
        if (elenco.isEmpty) {
          filhos.add(
            const Text(
              'Ninguém neste elenco. Importe em Gestão → Importar elencos.',
              style: AppTextStyles.pequeno,
            ),
          );
        }
        for (final x in elenco) {
          filhos.add(
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 28,
                child: Text(x.numero == null ? '' : '#${x.numero}', style: AppTextStyles.rotulo),
              ),
              title: Text(x.nome.toUpperCase(), style: AppTextStyles.nome.copyWith(fontSize: 12)),
              onTap: () => setState(() => _pessoa = x.id),
            ),
          );
        }
      }

      rotulo(filhos, 'Jogo em que ocorreu');
      if (jogos.isEmpty) {
        filhos.add(
          const Text(
            'Este time ainda não tem súmula encerrada. A suspensão conta a partir do jogo '
            'seguinte ao do ocorrido, então encerre a súmula antes de registrar a decisão.',
            style: AppTextStyles.pequeno,
          ),
        );
      } else {
        filhos.add(
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in jogos)
                ChipFiltro(
                  '${_confronto(o, p)} · ${dataCurta(p.inicio)}',
                  ativo: p.id == _origem,
                  onTap: () => setState(() => _origem = p.id),
                ),
            ],
          ),
        );
      }
    }

    rotulo(filhos, 'Punições com valor fixo no regulamento');
    filhos.add(
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final a in _atalhos)
            ChipFiltro(
              a.rotulo,
              ativo: false,
              onTap: () => setState(() {
                _suspensao = a.jogos;
                _multa.text = valorParaCampo(a.multa);
                _motivo.text = a.motivo;
                _fundamento.text = a.fundamento;
              }),
            ),
        ],
      ),
    );

    rotulo(filhos, 'Jogos de suspensão');
    filhos
      ..add(
        Row(
          children: [
            IconButton(
              tooltip: 'Menos um jogo',
              onPressed: _suspensao == 0 ? null : () => setState(() => _suspensao--),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$_suspensao',
                style: AppTextStyles.placar,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Mais um jogo',
              onPressed: _suspensao >= 99 ? null : () => setState(() => _suspensao++),
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.verde),
            ),
          ],
        ),
      )
      ..add(const SizedBox(height: AppSpacing.md))
      ..add(
        TextField(
          controller: _multa,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: _campo('Multa', dica: '0', prefixo: 'R\$ '),
        ),
      )
      ..add(const SizedBox(height: AppSpacing.md))
      ..add(
        TextField(
          controller: _motivo,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: _campo('Motivo', dica: 'Aparece para o atleta e na Disciplina'),
        ),
      )
      ..add(const SizedBox(height: AppSpacing.md))
      ..add(
        TextField(
          controller: _fundamento,
          decoration: _campo('Enquadramento (opcional)', dica: 'Ex.: Art. 87 · grau médio'),
        ),
      )
      ..add(const SizedBox(height: AppSpacing.md))
      ..add(
        TextField(
          controller: _votacao,
          decoration: _campo('Votação dos dirigentes (opcional)', dica: 'Ex.: 5 a 2'),
        ),
      )
      ..add(const SizedBox(height: AppSpacing.md));

    if (previa.isNotEmpty) {
      filhos.add(
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.amareloSuave,
            borderRadius: AppRadius.botao,
          ),
          child: Text(
            previa.join('\n'),
            style: AppTextStyles.corpo.copyWith(color: AppColors.tinta),
          ),
        ),
      );
    } else if (falta != null) {
      filhos.add(Text(falta, style: AppTextStyles.pequeno));
    }

    filhos
      ..add(const SizedBox(height: AppSpacing.lg))
      ..add(
        FilledButton(
          onPressed: _salvando || falta != null ? null : _salvar,
          child: Text(_salvando ? 'Salvando…' : 'Salvar decisão'),
        ),
      );
    if (widget.inicial != null) {
      filhos.add(
        TextButton(
          onPressed: _salvando ? null : _excluir,
          child: const Text('Excluir decisão', style: TextStyle(color: AppColors.vermelho)),
        ),
      );
    }

    return ListView(padding: AppSpacing.tela, children: filhos);
  }
}
