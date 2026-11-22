import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/temporada.dart';
import '../../../domain/usecases/movimentacoes.dart';
import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';
import '../../../shared/layout/tela_larga.dart';

const _rotaLista = '/organizacao/gestao/movimentacoes';

/// O12 · Gestão · Movimentações (arts. 82 a 83.2)
class MovimentacoesScreen extends StatelessWidget {
  const MovimentacoesScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final demo = o.dados.demonstracao;
      final lista = [...o.movimentacoes]..sort((a, b) => b.data.compareTo(a.data));
      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          const VoltarGestao(),
          CabecalhoTela(
            'Movimentações',
            subtitulo: lista.isEmpty
                ? 'Nenhuma registrada'
                : lista.length == 1
                ? '1 movimentação registrada'
                : '${lista.length} movimentações registradas',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            demo
                ? 'Temporada de exemplo: o registro de movimentações é liberado depois que os '
                      'elencos reais forem importados.'
                : 'Demissões, desligamentos, lesões e trocas de goleiro. Quem sai deixa de '
                      'aparecer no elenco e na súmula dos jogos seguintes.',
            style: AppTextStyles.pequeno,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: demo ? null : () => context.go('$_rotaLista/nova'),
            child: const Text('Nova movimentação'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (lista.isEmpty)
            const ListaVazia(
              titulo: 'Nenhuma movimentação',
              texto: 'As saídas de elenco registradas aparecem aqui.',
            ),
          for (final m in lista) _CartaoMovimentacao(o: o, movimentacao: m, key: ValueKey(m.id)),
        ],
      );
    },
  );
}

class _CartaoMovimentacao extends StatefulWidget {
  final OrgPronta o;
  final Movimentacao movimentacao;
  const _CartaoMovimentacao({super.key, required this.o, required this.movimentacao});

  @override
  State<_CartaoMovimentacao> createState() => _CartaoMovimentacaoState();
}

class _CartaoMovimentacaoState extends State<_CartaoMovimentacao> {
  bool _desfazendo = false;

  Future<void> _desfazer() async {
    final m = widget.movimentacao;
    final controller = context.read<OrganizacaoController>();
    // Guardado antes: o cartão some da lista assim que a gravação começa.
    final avisos = ScaffoldMessenger.of(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Desfazer movimentação?'),
        content: Text(
          m.substitutoNome == null
              ? '${m.nome} volta ao elenco.'
              : '${m.nome} volta ao elenco e ${m.substitutoNome} é retirado dele.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Sim, desfazer'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _desfazendo = true);
    String aviso;
    try {
      await controller.desfazerMovimentacao(m);
      aviso = 'Movimentação desfeita.';
    } on MovimentacaoEmUso {
      aviso = 'O substituto já aparece em súmula ou decisão; não dá mais para desfazer.';
    } catch (_) {
      aviso = 'Não foi possível desfazer. Tente de novo.';
    }
    avisos.showSnackBar(SnackBar(content: Text(aviso)));
    if (mounted) setState(() => _desfazendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movimentacao;
    final time = widget.o.time(m.timeId);
    final detalhes = [
      if (m.motivoTroca != null) 'Motivo: ${m.motivoTroca!.rotulo}',
      if (m.substitutoNome != null) 'Novo goleiro: ${m.substitutoNome}',
      if (m.laudo) 'Exame ou laudo apresentado',
      if (m.observacoes != null) m.observacoes!,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Cartao(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 4),
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
                      Text(m.nome.toUpperCase(), style: AppTextStyles.nome),
                      Text('Saiu em ${dataCompleta(m.data)}', style: AppTextStyles.pequeno),
                    ],
                  ),
                ),
                Etiqueta.neutra(m.tipo.rotulo),
              ],
            ),
            for (final linha in detalhes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(linha, style: AppTextStyles.pequeno),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _desfazendo ? null : _desfazer,
                child: const Text('Desfazer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O13 · Gestão · Nova movimentação
class NovaMovimentacaoScreen extends StatelessWidget {
  const NovaMovimentacaoScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) => o.dados.demonstracao
        ? ListView(
            padding: TelaLarga.margens(context),
            children: const [
              VoltarGestao(rotulo: 'Movimentações', rota: _rotaLista),
              Text(
                'O registro de movimentações é liberado depois que os elencos reais forem '
                'importados.',
                style: AppTextStyles.corpo,
              ),
            ],
          )
        : _Formulario(o: o),
  );
}

class _Formulario extends StatefulWidget {
  final OrgPronta o;
  const _Formulario({required this.o});

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  TipoMovimentacao _tipo = TipoMovimentacao.demissao;
  String? _time;
  String? _pessoa;
  DateTime _data = DateUtils.dateOnly(DateTime.now());
  bool _laudo = false;
  MotivoTroca _motivoTroca = MotivoTroca.lesao;
  final _substituto = TextEditingController();
  final _numero = TextEditingController();
  final _observacoes = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _substituto.dispose();
    _numero.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  bool get _troca => _tipo == TipoMovimentacao.trocaGoleiro;

  /// A saída precisa de exame ou laudo?
  bool get _exigeLaudo =>
      _tipo == TipoMovimentacao.lesao || (_troca && _motivoTroca == MotivoTroca.lesao);

  Pessoa? get _escolhida => _pessoa == null ? null : widget.o.pessoa(_pessoa!);

  /// Atletas que ainda estão no elenco do time.
  List<Pessoa> _elenco(String timeId) =>
      widget.o.dados.pessoas
          .where((x) => x.timeId == timeId && x.funcao == Funcao.atleta && x.ativo)
          .toList()
        ..sort((a, b) => (a.numero ?? 999).compareTo(b.numero ?? 999));

  /// Número digitado para o novo goleiro; `(false, null)` se for inválido.
  (bool valido, int? numero) get _numeroDigitado {
    final texto = _numero.text.trim();
    if (texto.isEmpty) return (true, null);
    final n = int.tryParse(texto);
    return (n != null && n > 0, n);
  }

  /// O que ainda falta para poder registrar; nulo quando está tudo certo.
  String? get _falta {
    if (_time == null) return 'Escolha o time.';
    final pessoa = _escolhida;
    if (pessoa == null) return 'Escolha o atleta.';
    final impedimento = impedimentoMovimentacao(_tipo, pessoa);
    if (impedimento != null) return impedimento;
    if (_exigeLaudo && !_laudo) {
      return 'A lesão precisa ser comprovada com exame ou laudo (arts. 83 e 83.2).';
    }
    if (_troca) {
      if (_substituto.text.trim().isEmpty) return 'Informe o nome do novo goleiro.';
      if (!_numeroDigitado.$1) return 'Número da camisa inválido.';
    }
    return null;
  }

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _escolherData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 1, 12, 31),
    );
    if (escolhida != null && mounted) setState(() => _data = escolhida);
  }

  Future<void> _salvar() async {
    final pessoa = _escolhida;
    if (_falta != null || pessoa == null) return;
    final marca = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final observacoes = _observacoes.text.trim();
    final substituto = _troca
        ? Pessoa(
            id: '${pessoa.timeId.toLowerCase()}-gol-$marca',
            nome: _substituto.text.trim(),
            timeId: pessoa.timeId,
            numero: _numeroDigitado.$2 ?? pessoa.numero,
            goleiro: true,
          )
        : null;
    final movimentacao = Movimentacao(
      id: 'mov-$marca',
      tipo: _tipo,
      pessoaId: pessoa.id,
      timeId: pessoa.timeId,
      nome: pessoa.nome,
      data: _data,
      laudo: _exigeLaudo && _laudo,
      motivoTroca: _troca ? _motivoTroca : null,
      substitutoId: substituto?.id,
      substitutoNome: substituto?.nome,
      observacoes: observacoes.isEmpty ? null : observacoes,
    );
    final controller = context.read<OrganizacaoController>();
    setState(() => _salvando = true);
    try {
      await controller.registrarMovimentacao(movimentacao, substituto: substituto);
      if (mounted) {
        _avisar('Movimentação registrada.');
        context.go(_rotaLista);
      }
    } catch (_) {
      if (mounted) _avisar('Não foi possível salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  InputDecoration _campo(String rotulo, {String? dica}) => InputDecoration(
    labelText: rotulo,
    hintText: dica,
    border: const OutlineInputBorder(borderRadius: AppRadius.botao),
  );

  @override
  Widget build(BuildContext context) {
    final times = [...widget.o.dados.times]..sort((a, b) => a.sigla.compareTo(b.sigla));
    final time = _time;
    final escolhida = _escolhida;
    final falta = _falta;

    final filhos = <Widget>[
      const VoltarGestao(rotulo: 'Movimentações', rota: _rotaLista),
      const CabecalhoTela('Nova movimentação'),
    ];

    void rotulo(String texto) => filhos
      ..add(const SizedBox(height: AppSpacing.lg))
      ..add(Text(texto, style: AppTextStyles.rotulo))
      ..add(const SizedBox(height: AppSpacing.sm));

    rotulo('Tipo');
    filhos
      ..add(
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final t in TipoMovimentacao.values)
              ChipFiltro(t.rotulo, ativo: t == _tipo, onTap: () => setState(() => _tipo = t)),
          ],
        ),
      )
      ..add(
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.amareloSuave,
            borderRadius: AppRadius.botao,
          ),
          child: Text(
            consequenciaMovimentacao(_tipo),
            style: AppTextStyles.corpo.copyWith(color: AppColors.tinta),
          ),
        ),
      );

    rotulo('Time');
    filhos.add(
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final t in times)
            ChipFiltro(
              t.sigla,
              ativo: t.id == time,
              onTap: () => setState(() {
                _time = t.id;
                _pessoa = null;
              }),
            ),
        ],
      ),
    );

    if (time != null) {
      rotulo(_troca ? 'Goleiro que sai' : 'Atleta');
      if (escolhida != null) {
        filhos.add(
          Cartao(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 4, 4),
            child: Row(
              children: [
                Expanded(child: Text(escolhida.nome.toUpperCase(), style: AppTextStyles.nome)),
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
        if (elenco.isEmpty) {
          filhos.add(
            const Text(
              'Nenhum atleta neste elenco. Importe em Gestão → Importar elencos.',
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
              subtitle: x.goleiro || x.dirigente
                  ? Text(
                      [if (x.goleiro) 'Goleiro', if (x.dirigente) 'Dirigente'].join(' · '),
                      style: AppTextStyles.pequeno,
                    )
                  : null,
              onTap: () => setState(() => _pessoa = x.id),
            ),
          );
        }
      }
    }

    rotulo('Data da saída');
    filhos.add(
      Cartao(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 4, 4),
        child: Row(
          children: [
            Expanded(child: Text(dataCompleta(_data), style: AppTextStyles.nome)),
            TextButton(onPressed: _escolherData, child: const Text('Alterar data')),
          ],
        ),
      ),
    );

    if (_troca) {
      rotulo('Motivo da troca');
      filhos
        ..add(
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final m in MotivoTroca.values)
                ChipFiltro(
                  m.rotulo,
                  ativo: m == _motivoTroca,
                  onTap: () => setState(() => _motivoTroca = m),
                ),
            ],
          ),
        )
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(
          TextField(
            controller: _substituto,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: _campo('Nome do novo goleiro'),
          ),
        )
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(
          TextField(
            controller: _numero,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: _campo(
              'Número da camisa (opcional)',
              dica: 'Em branco, fica com o número de quem saiu',
            ),
          ),
        );
    }

    if (_exigeLaudo) {
      filhos
        ..add(const SizedBox(height: AppSpacing.sm))
        ..add(
          CheckboxListTile(
            value: _laudo,
            onChanged: (v) => setState(() => _laudo = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.verde,
            title: const Text('Exame ou laudo apresentado', style: AppTextStyles.rotulo),
          ),
        );
    }

    filhos
      ..add(const SizedBox(height: AppSpacing.md))
      ..add(
        TextField(
          controller: _observacoes,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          decoration: _campo('Observações (opcional)'),
        ),
      )
      ..add(const SizedBox(height: AppSpacing.md));
    if (falta != null) filhos.add(Text(falta, style: AppTextStyles.pequeno));
    filhos
      ..add(const SizedBox(height: AppSpacing.lg))
      ..add(
        FilledButton(
          onPressed: _salvando || falta != null ? null : _salvar,
          child: Text(_salvando ? 'Salvando…' : 'Registrar movimentação'),
        ),
      );

    return ListView(padding: TelaLarga.margens(context), children: filhos);
  }
}
