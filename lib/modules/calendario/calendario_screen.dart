import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/repositories/calendario_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/calendario_geral.dart';
import '../../domain/usecases/gerar_calendario.dart';
import '../../domain/usecases/verificar_calendario.dart';
import '../../shared/format.dart';
import '../../shared/pdf/saida_pdf.dart';
import '../../shared/layout/tela_larga.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/widgets/escudo.dart';
import 'calendario_controller.dart';
import 'consistencia_calendario.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', //
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Cor de cada competição nas etiquetas do calendário.
Color corDa(Competicao c) => switch (c) {
  Competicao.master => AppColors.verde,
  Competicao.superMaster => AppColors.amareloEscuro,
  Competicao.livre => const Color(0xFF1B5CC1),
  Competicao.copaMaster => const Color(0xFF6A3FA0),
};

/// Calendário completo do Calcio: todas as categorias e a Copa, com filtro.
class CalendarioScreen extends StatelessWidget {
  /// Para onde volta se a tela foi aberta direto.
  final String voltarPara;

  /// Gestão (superconta): arrastar as etiquetas muda os jogos de dia.
  final bool editavel;
  const CalendarioScreen({super.key, this.voltarPara = '/torcedor/jogos', this.editavel = false});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (c) => CalendarioController(c.read<TemporadaRepository>())..iniciar(),
    child: Scaffold(
      body: SafeArea(
        child: BlocBuilder<CalendarioController, CalendarioStatus>(
          builder: (context, s) => switch (s) {
            CalendarioCarregando() => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: BotaoVoltar(rotulo: 'Voltar', rota: voltarPara),
                ),
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.verde)),
                ),
              ],
            ),
            CalendarioPronto(:final jogos) => editavel
                ? _CalendarioLargo(
                    jogos: jogos,
                    filtro: null,
                    onFiltro: (_) {},
                    voltarPara: voltarPara,
                    editavel: true,
                  )
                : _Calendario(jogos: jogos, voltarPara: voltarPara),
          },
        ),
      ),
    ),
  );
}

class _Calendario extends StatefulWidget {
  final List<JogoDoCalendario> jogos;
  final String voltarPara;
  const _Calendario({required this.jogos, required this.voltarPara});

  @override
  State<_Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<_Calendario> {
  /// Nulo: todas as competições.
  Competicao? _filtro;

  /// Mostrar também os jogos que já passaram.
  bool _anteriores = false;

  @override
  Widget build(BuildContext context) {
    if (TelaLarga.de(context)) {
      return _CalendarioLargo(
        jogos: widget.jogos,
        filtro: _filtro,
        onFiltro: (c) => setState(() => _filtro = c),
        voltarPara: widget.voltarPara,
      );
    }
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final daCompeticao = [
      for (final j in widget.jogos)
        if (_filtro == null || j.competicao == _filtro) j,
    ];
    final passados = daCompeticao.where((j) => j.inicio.isBefore(inicioHoje)).length;
    final jogos = _anteriores
        ? daCompeticao
        : daCompeticao.where((j) => !j.inicio.isBefore(inicioHoje)).toList();

    // Lista plana: mês, dia e jogos, para montar só o que aparece na tela.
    final linhas = <Widget>[];
    DateTime? dia;
    for (final j in jogos) {
      final d = DateTime(j.inicio.year, j.inicio.month, j.inicio.day);
      if (dia == null || d.month != dia.month || d.year != dia.year) {
        linhas.add(_Mes('${_meses[d.month - 1]} ${d.year}'));
      }
      if (dia != d) linhas.add(_Dia(dataCurta(d)));
      dia = d;
      linhas.add(_LinhaJogo(j));
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          sliver: SliverList.list(
            children: [
              BotaoVoltar(rotulo: 'Voltar', rota: widget.voltarPara),
              const CabecalhoTela(
                'Calendário',
                subtitulo: 'Todos os jogos do Calcio Firenze 2027',
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => abrirCalendarioPdf(context, widget.jogos),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Baixar calendário anual (PDF)'),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChipFiltro('Todas', ativo: _filtro == null, onTap: () => setState(() => _filtro = null)),
                  for (final c in Competicao.values)
                    ChipFiltro(c.nome, ativo: _filtro == c, onTap: () => setState(() => _filtro = c)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${jogos.where((j) => !j.ehDraft).length} jogos'
                '${_anteriores ? '' : ' a partir de hoje'}',
                style: AppTextStyles.pequeno,
              ),
              if (passados > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _anteriores = !_anteriores),
                    child: Text(
                      _anteriores ? 'Esconder jogos que já passaram' : 'Ver também os $passados que já passaram',
                    ),
                  ),
                ),
              if (jogos.isEmpty)
                const ListaVazia(
                  icone: Icons.event_outlined,
                  titulo: 'Nenhum jogo',
                  texto: 'Não há jogos marcados para esta seleção.',
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverList.builder(itemCount: linhas.length, itemBuilder: (_, i) => linhas[i]),
        ),
      ],
    );
  }
}

class _Mes extends StatelessWidget {
  final String texto;
  const _Mes(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: Text(texto, style: AppTextStyles.tituloSecao),
  );
}

class _Dia extends StatelessWidget {
  final String texto;
  const _Dia(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(texto.toUpperCase(), style: AppTextStyles.rotulo.copyWith(color: AppColors.dica)),
  );
}

class _LinhaJogo extends StatelessWidget {
  final JogoDoCalendario jogo;
  const _LinhaJogo(this.jogo);

  @override
  Widget build(BuildContext context) {
    final hora = jogo.ehDraft && jogo.inicio.hour == 0 && jogo.inicio.minute == 0
        ? '—'
        : dataHoraJogo(jogo.inicio).split(' · ').last;
    final cor = corDa(jogo.competicao);
    final s = jogo.partida?.sumula;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Cartao(
        child: Row(
          children: [
            SizedBox(width: 48, child: Text(hora, style: AppTextStyles.nome)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          jogo.competicao.nome,
                          style: AppTextStyles.pequeno.copyWith(color: cor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          jogo.etapa,
                          style: AppTextStyles.pequeno,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (jogo.ehDraft)
                    Text('Escolha dos elencos', style: AppTextStyles.nome)
                  else if (jogo.aDefinir || jogo.mandante == null || jogo.visitante == null)
                    Text('Confronto a definir', style: AppTextStyles.corpo.copyWith(color: AppColors.dica))
                  else
                    Row(
                      children: [
                        Escudo(jogo.mandante!, tamanho: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s == null
                                ? '${jogo.mandante!.nome} x ${jogo.visitante!.nome}'
                                : '${jogo.mandante!.nome} ${s.golsMandante} x ${s.golsVisitante} '
                                      '${jogo.visitante!.nome}',
                            style: AppTextStyles.nome,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Escudo(jogo.visitante!, tamanho: 20),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atalho para o calendário de todas as categorias (fica no topo de Jogos).
class AtalhoCalendario extends StatelessWidget {
  const AtalhoCalendario({super.key});

  @override
  Widget build(BuildContext context) => Cartao(
    onTap: () => context.push('/calendario'),
    child: const Row(
      children: [
        Icon(Icons.calendar_month_rounded, color: AppColors.verde),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendário completo', style: AppTextStyles.nome),
              Text('Jogos de todas as categorias e da Copa', style: AppTextStyles.pequeno),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: AppColors.dica),
      ],
    ),
  );
}


/// Calendário no computador: dois meses em grade, lado a lado, com o número
/// de jogos de cada competição por dia e os feriados.
class _CalendarioLargo extends StatefulWidget {
  final List<JogoDoCalendario> jogos;
  final Competicao? filtro;
  final ValueChanged<Competicao?> onFiltro;
  final String voltarPara;
  final bool editavel;

  const _CalendarioLargo({
    required this.jogos,
    required this.filtro,
    required this.onFiltro,
    required this.voltarPara,
    this.editavel = false,
  });

  @override
  State<_CalendarioLargo> createState() => _CalendarioLargoState();
}

class _CalendarioLargoState extends State<_CalendarioLargo> {
  static const _ano = 2027;

  /// Primeiro mês do par em exibição (1, 3, 5 ... 11).
  late int _mes = _parInicial();

  /// Passa o mês quando uma etiqueta fica parada sobre a seta.
  Timer? _virar;

  @override
  void dispose() {
    _virar?.cancel();
    super.dispose();
  }

  /// Filtro próprio no modo de edição (lá a tela não guarda o filtro).
  Competicao? _filtroEdicao;
  Competicao? get _filtro => widget.editavel ? _filtroEdicao : widget.filtro;
  void _filtrar(Competicao? c) =>
      widget.editavel ? setState(() => _filtroEdicao = c) : widget.onFiltro(c);

  /// Leva os jogos de uma etiqueta para [destino], depois dos que já estão
  /// lá, e oferece desfazer.
  Future<void> _mover(_Arraste a, DateTime destino) async {
    final repo = context.read<CalendarioRepository>();
    final aviso = ScaffoldMessenger.of(context);
    final jaNoDia = widget.jogos
        .where((j) => !j.ehDraft && _mesmoDia(j.inicio, destino) && !a.jogos.contains(j))
        .length;
    final novos = horariosNoDia(destino, jaNoDia, a.jogos.length);
    final antes = {for (final j in a.jogos) j: j.inicio};
    try {
      await _aplicar(repo, {for (final (i, j) in a.jogos.indexed) j: novos[i]});
      aviso
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${a.competicao.sigla}: ${a.jogos.length} '
              '${a.jogos.length == 1 ? 'jogo' : 'jogos'} de ${dataCurta(a.dia)} para ${dataCurta(destino)}.',
            ),
            action: SnackBarAction(label: 'Desfazer', onPressed: () => _aplicar(repo, antes)),
          ),
        );
    } catch (e) {
      aviso.showSnackBar(SnackBar(content: Text('Não foi possível mudar o dia: $e')));
    }
  }

  /// Grava os novos horários: jogos já sorteados mudam no banco da categoria;
  /// datas ainda a definir (e da Copa) viram ajustes do calendário oficial.
  static Future<void> _aplicar(CalendarioRepository repo, Map<JogoDoCalendario, DateTime> destinos) async {
    final ajustes = {...AjustesCalendario.atual};
    var mudouAjuste = false;
    final porTemporada = <String, Map<String, DateTime>>{};
    for (final MapEntry(key: j, value: h) in destinos.entries) {
      final categoria = j.competicao.categoria;
      if (j.partida case final p? when categoria != null) {
        (porTemporada[categoria.temporadaId] ??= {})[p.id] = h;
      } else if (j.oficial case final o?) {
        mudouAjuste = true;
        if (h == o) {
          ajustes.remove(o);
        } else {
          ajustes[o] = h;
        }
      }
    }
    for (final MapEntry(key: t, value: inicios) in porTemporada.entries) {
      await repo.moverPartidas(t, inicios);
    }
    if (mudouAjuste) await repo.salvarAjustes(ajustes);
  }

  static int _parInicial() {
    final hoje = DateTime.now();
    if (hoje.year != _ano) return 1;
    return hoje.month.isOdd ? hoje.month : hoje.month - 1;
  }

  @override
  Widget build(BuildContext context) {
    final porDia = <DateTime, Map<Competicao, List<JogoDoCalendario>>>{};
    for (final j in widget.jogos) {
      if (j.ehDraft || (_filtro != null && j.competicao != _filtro)) continue;
      final d = DateTime(j.inicio.year, j.inicio.month, j.inicio.day);
      (porDia.putIfAbsent(d, () => {})[j.competicao] ??= []).add(j);
    }
    final feriados = {
      for (final f in feriados2027) DateTime(f.data.year, f.data.month, f.data.day): f,
    };
    Widget seta(IconData icone, String rotulo, int? destino) {
      final botao = IconButton.outlined(
        tooltip: rotulo,
        onPressed: destino == null ? null : () => setState(() => _mes = destino),
        icon: Icon(icone),
      );
      if (!widget.editavel || destino == null) return botao;
      // Arrastando uma etiqueta: parar sobre a seta passa o mês.
      return DragTarget<_Arraste>(
        onWillAcceptWithDetails: (_) {
          _virar?.cancel();
          _virar = Timer(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _mes = destino);
          });
          return false;
        },
        onLeave: (_) => _virar?.cancel(),
        builder: (_, _, _) => botao,
      );
    }

    // Na edição o mês anda de um em um, para levar jogos de um mês ao seguinte.
    final passo = widget.editavel ? 1 : 2;
    return PaginaLarga(
      antes: context.canPop() || widget.editavel
          ? BotaoVoltar(rotulo: 'Voltar', rota: widget.voltarPara)
          : null,
      titulo: widget.editavel ? 'Rearranjar calendário' : 'Calendário completo',
      subtitulo: widget.editavel
          ? 'Arraste uma etiqueta (ex.: M 2) para outro dia: os jogos dela vão juntos, nos '
                'horários do dia. Vale para todas as categorias e a Copa.'
          : 'Todas as categorias e a Copa · temporada $_ano',
      acao: OutlinedButton.icon(
        onPressed: () => abrirCalendarioPdf(context, widget.jogos),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Baixar PDF do ano'),
      ),
      topo: [
        if (widget.editavel) QuadroInconsistencias(verificarCalendario(widget.jogos)),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChipFiltro('Todas', ativo: _filtro == null, onTap: () => _filtrar(null)),
            for (final c in Competicao.values)
              ChipFiltro(c.nome, ativo: _filtro == c, onTap: () => _filtrar(c)),
          ],
        ),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in Competicao.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Selo(c, c.sigla),
                  const SizedBox(width: AppSpacing.xs),
                  Text(c.nome, style: AppTextStyles.corpo),
                ],
              ),
            DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.cinzaSuave, borderRadius: AppRadius.botao),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Como ler: ', style: AppTextStyles.corpo.copyWith(fontWeight: FontWeight.w700)),
                    const _Selo(Competicao.master, 'M 3'),
                    Text(' = 3 jogos do Master nesse dia', style: AppTextStyles.corpo),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            seta(
              Icons.chevron_left_rounded,
              widget.editavel ? 'Mês anterior' : 'Meses anteriores',
              _mes > 1 ? (_mes - passo).clamp(1, 11) : null,
            ),
            SizedBox(
              width: 260,
              child: Text(
                '${_meses[_mes - 1]} e ${_meses[_mes]} de $_ano',
                textAlign: TextAlign.center,
                style: AppTextStyles.tituloSecao,
              ),
            ),
            seta(
              Icons.chevron_right_rounded,
              widget.editavel ? 'Próximo mês' : 'Próximos meses',
              _mes < 11 ? (_mes + passo).clamp(1, 11) : null,
            ),
            const Spacer(),
            const _LegendaFeriado(),
          ],
        ),
      ],
      principal: [
        GradeLarga(
          minimo: 460,
          espaco: AppSpacing.xl,
          children: [
            for (final m in [_mes, _mes + 1])
              _GradeMes(
                ano: _ano,
                mes: m,
                porDia: porDia,
                feriados: feriados,
                onMover: widget.editavel ? _mover : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Selo extends StatelessWidget {
  final Competicao competicao;
  final String texto;
  const _Selo(this.competicao, this.texto);

  @override
  Widget build(BuildContext context) {
    final cor = corDa(competicao);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          texto,
          style: AppTextStyles.rotulo.copyWith(fontSize: 11, color: cor, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _LegendaFeriado extends StatelessWidget {
  const _LegendaFeriado();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.vermelho, width: 1.5),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      const Text('Feriado oficial', style: AppTextStyles.corpo),
      const SizedBox(width: AppSpacing.lg),
      Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: AppColors.vermelhoSuave,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      const Text('Facultativo ou a confirmar', style: AppTextStyles.corpo),
    ],
  );
}

class _GradeMes extends StatelessWidget {
  final int ano;
  final int mes;
  final Map<DateTime, Map<Competicao, List<JogoDoCalendario>>> porDia;
  final Map<DateTime, Feriado> feriados;

  /// Modo de edição: recebe a etiqueta solta num dia.
  final void Function(_Arraste arraste, DateTime destino)? onMover;

  const _GradeMes({
    required this.ano,
    required this.mes,
    required this.porDia,
    required this.feriados,
    this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    final primeiro = DateTime(ano, mes);
    final dias = DateTime(ano, mes + 1, 0).day;
    final vazios = primeiro.weekday - 1; // a semana começa na segunda
    final celulas = <Widget>[
      for (final d in const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'])
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(d, style: AppTextStyles.rotulo.copyWith(color: AppColors.texto2)),
          ),
        ),
      for (var i = 0; i < vazios; i++) const SizedBox.shrink(),
      for (var d = 1; d <= dias; d++) _celula(context, DateTime(ano, mes, d)),
    ];
    final linhas = <TableRow>[];
    for (var i = 0; i < celulas.length; i += 7) {
      final fim = i + 7 > celulas.length ? celulas.length : i + 7;
      linhas.add(
        TableRow(
          children: [
            for (var k = i; k < fim; k++) Padding(padding: const EdgeInsets.all(3), child: celulas[k]),
            for (var k = fim; k < i + 7; k++) const SizedBox.shrink(),
          ],
        ),
      );
    }
    return BlocoLargo(
      titulo: '${_meses[mes - 1]} $ano',
      child: Table(children: linhas),
    );
  }

  Widget _celula(BuildContext context, DateTime dia) {
    final mover = onMover;
    if (mover == null) return _conteudo(context, dia, destacar: false);
    return DragTarget<_Arraste>(
      onWillAcceptWithDetails: (d) => !_mesmoDia(d.data.dia, dia),
      onAcceptWithDetails: (d) => mover(d.data, dia),
      builder: (context, candidatos, _) =>
          _conteudo(context, dia, destacar: candidatos.isNotEmpty),
    );
  }

  Widget _conteudo(BuildContext context, DateTime dia, {required bool destacar}) {
    final feriado = feriados[dia];
    final jogos = porDia[dia] ?? const {};
    final domingo = dia.weekday == DateTime.sunday;
    final rotulo = [
      if (feriado != null) feriado.nome,
      for (final MapEntry(key: c, value: l) in jogos.entries)
        '${l.length} ${l.length == 1 ? 'jogo' : 'jogos'} ${c == Competicao.copaMaster ? 'da' : 'do'} ${c.nome}',
    ];
    return Semantics(
      label: '${dia.day}${rotulo.isEmpty ? '' : ': ${rotulo.join(', ')}'}',
      excludeSemantics: onMover == null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: feriado != null && !feriado.oficial ? AppColors.vermelhoSuave : AppColors.cartao,
          borderRadius: AppRadius.botao,
          border: Border.all(
            color: destacar
                ? AppColors.verde
                : (feriado != null && feriado.oficial ? AppColors.vermelho : AppColors.linha),
            width: destacar ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dia.day}',
              style: AppTextStyles.nome.copyWith(
                fontSize: 13,
                color: feriado != null
                    ? AppColors.vermelho
                    : (domingo ? AppColors.dica : AppColors.tinta),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final MapEntry(key: c, value: l) in jogos.entries)
                  if (onMover == null)
                    _Selo(c, '${c.sigla} ${l.length}')
                  else
                    _SeloArrastavel(_Arraste(c, dia, l)),
              ],
            ),
            if (feriado != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  feriado.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pequeno.copyWith(color: AppColors.vermelho, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Jogos de uma competição num dia, levados juntos ao arrastar a etiqueta.
class _Arraste {
  final Competicao competicao;
  final DateTime dia;
  final List<JogoDoCalendario> jogos;
  const _Arraste(this.competicao, this.dia, this.jogos);
}

/// Etiqueta que se arrasta para outro dia (no celular, segurando).
class _SeloArrastavel extends StatelessWidget {
  final _Arraste arraste;
  const _SeloArrastavel(this.arraste);

  @override
  Widget build(BuildContext context) {
    final selo = _Selo(arraste.competicao, '${arraste.competicao.sigla} ${arraste.jogos.length}');
    final etapas = {for (final j in arraste.jogos) j.etapa}.join(', ');
    final rotulo = '${arraste.competicao.nome}, ${arraste.jogos.length} '
        '${arraste.jogos.length == 1 ? 'jogo' : 'jogos'} ($etapas). Arraste para outro dia.';
    final arrastando = Material(color: Colors.transparent, child: Transform.scale(scale: 1.15, child: selo));
    final noLugar = Opacity(opacity: 0.35, child: selo);
    final alvo = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Tooltip(message: rotulo, child: selo),
    );
    return Semantics(
      label: rotulo,
      child: TelaLarga.computador(context)
          ? Draggable<_Arraste>(
              data: arraste,
              feedback: arrastando,
              childWhenDragging: noLugar,
              child: alvo,
            )
          : LongPressDraggable<_Arraste>(
              data: arraste,
              feedback: arrastando,
              childWhenDragging: noLugar,
              child: alvo,
            ),
    );
  }
}
