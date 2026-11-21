import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/etapa.dart';
import '../../../domain/usecases/gerar_calendario.dart';
import '../../../domain/usecases/mata_mata.dart';
import '../../../shared/format.dart';
import '../../calendario/calendario_screen.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/widgets/datas_copa.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';

/// O9 · Organização · Jogos: calendário do turno e acesso à súmula.
class OrgJogosScreen extends StatelessWidget {
  const OrgJogosScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ComOrg(builder: (context, o) => _Jogos(key: ValueKey(o.dados.id), o: o));
}

class _Jogos extends StatefulWidget {
  final OrgPronta o;
  const _Jogos({super.key, required this.o});

  @override
  State<_Jogos> createState() => _JogosState();
}

class _JogosState extends State<_Jogos> {
  int _turno = 1;

  /// Abas "Eliminatórias": o mata-mata do turno (no 2º, com a grande final).
  bool _elim = false;
  Etapa? _etapa;
  bool _gerando = false;

  /// Jogos da aba: a fase classificatória do turno ou o mata-mata dele (no
  /// 2º turno, também a grande final).
  List<Partida> get _daAba => widget.o.dados.demonstracao
      ? const []
      : (widget.o.dados.partidas
                .where(
                  (p) =>
                      (p.turno == _turno || (_turno == 2 && p.fase == Fase.grandeFinal)) &&
                      p.fase.eliminatoria == _elim,
                )
                .toList()
            ..sort((a, b) => a.inicio.compareTo(b.inicio)));

  /// Algum jogo da fase classificatória do turno já sorteado?
  bool get _turnoSorteado => widget.o.dados.partidas.any(
    (p) => p.turno == _turno && p.fase == Fase.classificatoria,
  );

  Future<void> _gerar({required bool refazer}) async {
    final demo = widget.o.dados.demonstracao;
    final cat = widget.o.categoria;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(refazer ? 'Refazer o sorteio?' : 'Sortear o $_turnoº turno?'),
        content: Text(
          [
            'O app sorteia os confrontos (todos contra todos, ${cat.rodadas} rodadas, '
                '${cat.rodadas * cat.times ~/ 2} jogos) e ocupa os horários oficiais do '
                'calendário ${cat.nome}, na Arena Gugu. Depois dá para mudar data, hora e '
                'local de cada jogo.',
            if (refazer) 'Os confrontos atuais deste turno serão substituídos.',
            if (demo) 'Os jogos e cartões de exemplo saem do app.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sortear')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _gerando = true);
    try {
      await context.read<OrganizacaoController>().gerarTurno(_turno);
      if (mounted) {
        setState(() => _etapa = Etapa(_turno, Fase.classificatoria, 1));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Calendário do $_turnoº turno gerado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is StateError ? e.message : 'Não foi possível gerar. Tente de novo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  /// Etapas do mata-mata do turno (e a grande final, no 2º) já criadas.
  Set<Fase> _criadas(OrgPronta o) => {
    for (final p in o.dados.partidas)
      if (p.fase.eliminatoria && (p.turno == _turno || (_turno == 2 && p.turno == 0))) p.fase,
  };

  bool _mataMataPendente(OrgPronta o) {
    final criadas = _criadas(o);
    return datasMataMata(o.categoria, _turno).any((d) => !criadas.contains(d.fase));
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final jogos = _daAba;
    final etapas = etapasDe(jogos);
    final pendente = jogos.where((p) => !p.encerrada).firstOrNull;
    final etapa = etapas.contains(_etapa)
        ? _etapa
        : (pendente != null ? Etapa.de(pendente) : etapas.lastOrNull);
    final daEtapa = etapa == null ? const <Partida>[] : jogos.where(etapa.contem).toList();
    final algumaSumula = o.dados.partidas.any(
      (p) => p.turno == _turno && p.encerrada && p.fase == Fase.classificatoria,
    );

    return ListView(
      padding: AppSpacing.tela,
      children: [
        const CabecalhoTela('Jogos', subtitulo: 'Calendário e súmulas'),
        const SizedBox(height: AppSpacing.md),
        const AtalhoCalendario(),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (t, elim) in const [(1, false), (1, true), (2, false), (2, true)])
              ChipFiltro(
                elim ? 'Eliminatórias T$t' : '$tº Turno',
                ativo: _turno == t && _elim == elim,
                onTap: () => setState(() {
                  _turno = t;
                  _elim = elim;
                  _etapa = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_elim && jogos.isEmpty) ...[
          ListaVazia(
            titulo: 'Calendário ainda não gerado',
            texto: o.dados.demonstracao
                ? 'O app está mostrando a temporada de exemplo. Ao sortear o turno, '
                      'os jogos reais entram no lugar.'
                : 'Sorteie os confrontos do $_turnoº turno para montar as '
                      '${o.categoria.rodadas} rodadas.',
          ),
          FilledButton(
            onPressed: _gerando ? null : () => _gerar(refazer: false),
            child: Text(_gerando ? 'Gerando…' : 'Sortear e gerar o $_turnoº turno'),
          ),
        ] else ...[
          if (etapas.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in etapas) ...[
                    ChipFiltro(e.curto, ativo: e == etapa, onTap: () => setState(() => _etapa = e)),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          if (etapa != null) TituloSecao(etapa.rotulo),
          for (final p in daEtapa) ...[
            CardJogo(
              partida: p,
              mandante: o.time(p.mandanteId)!,
              visitante: o.time(p.visitanteId)!,
              local: p.local ?? o.dados.local,
              onTap: () => context.go('/organizacao/jogos/${p.id}'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_elim) ...[
            if (!_turnoSorteado)
              Text(
                'O mata-mata do $_turnoº turno sai da classificação: sorteie o turno primeiro.',
                style: AppTextStyles.corpo,
              )
            else ...[
              _PainelMataMata(
                o: o,
                turno: _turno,
                onCriado: (e) => setState(() => _etapa = e),
              ),
              if (_turno == 2)
                _PainelMataMata(o: o, turno: 0, onCriado: (e) => setState(() => _etapa = e)),
            ],
          ] else if (!algumaSumula)
            TextButton(
              onPressed: _gerando ? null : () => _gerar(refazer: true),
              child: const Text('Refazer o sorteio deste turno'),
            )
          else
            const Text(
              'O sorteio fica travado depois da primeira súmula encerrada.',
              style: AppTextStyles.pequeno,
            ),
        ],
        if (_elim && _mataMataPendente(o)) ...[
          const SizedBox(height: AppSpacing.md),
          DatasMataMata(categoria: o.categoria, turno: _turno, criadas: _criadas(o)),
        ],
        if (!_elim && o.categoria == Categoria.master && _turno == 1) ...[
          const SizedBox(height: AppSpacing.md),
          const DatasCopa(),
        ],
        if (o.dados.demonstracao)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Dica: importe os elencos antes ou depois. O sorteio usa os times da temporada.',
              style: TextStyle(fontFamily: 'OpenSans', fontSize: 11, color: AppColors.dica),
            ),
          ),
      ],
    );
  }
}

/// Situação do mata-mata do turno (ou da grande final, com [turno] 0): cria a
/// próxima etapa, mostra o campeão ou desfaz a última etapa sem súmula.
class _PainelMataMata extends StatefulWidget {
  final OrgPronta o;
  final int turno;
  final ValueChanged<Etapa> onCriado;
  const _PainelMataMata({required this.o, required this.turno, required this.onCriado});

  @override
  State<_PainelMataMata> createState() => _PainelMataMataState();
}

class _PainelMataMataState extends State<_PainelMataMata> {
  bool _gravando = false;

  bool get _grandeFinal => widget.turno == 0;

  SituacaoMataMata get _situacao => _grandeFinal
      ? const MataMata().grandeFinal(widget.o.dados)
      : const MataMata().turno(widget.o.dados, widget.turno);

  String _nome(String id) => widget.o.time(id)?.nome ?? id;

  static String _etapa(Fase f) => switch (f) {
    Fase.quartas => 'quartas de final',
    Fase.semifinal => 'semifinais',
    Fase.finalTurno => 'final do turno',
    Fase.grandeFinal => 'grande final',
    Fase.classificatoria => 'fase classificatória',
  };

  Future<void> _executar(Future<void> Function() acao, String feito) async {
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _gravando = true);
    try {
      await acao();
      avisos.showSnackBar(SnackBar(content: Text(feito)));
    } catch (_) {
      avisos.showSnackBar(const SnackBar(content: Text('Não foi possível gravar. Tente de novo.')));
    } finally {
      if (mounted) setState(() => _gravando = false);
    }
  }

  Future<void> _criar(SituacaoMataMata s) async {
    final controller = context.read<OrganizacaoController>();
    final etapa = Etapa.de(s.propostos.first);
    await _executar(
      () => controller.criarEtapa(s.propostos),
      'Jogos criados: ${_etapa(s.proxima!)}.',
    );
    if (mounted) widget.onCriado(etapa);
  }

  Future<void> _desfazer(SituacaoMataMata s) async {
    final controller = context.read<OrganizacaoController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Desfazer ${_etapa(s.desfazivel!)}?'),
        content: const Text(
          'Os jogos desta etapa saem do calendário. Dá para criar de novo depois.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Desfazer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _executar(() => controller.desfazerEtapa(s.idsDesfaziveis), 'Etapa desfeita.');
  }

  @override
  Widget build(BuildContext context) {
    final s = _situacao;
    final filhos = <Widget>[];

    if (s.campeao case final c? when s.proxima == null) {
      filhos.add(
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.amarelo),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _grandeFinal ? 'Campeão do Calcio Firenze: ${_nome(c)}' : 'Campeão do ${widget.turno}º turno: ${_nome(c)}',
                style: AppTextStyles.nome,
              ),
            ),
          ],
        ),
      );
    }
    if (s.aguardando case final texto?) {
      filhos.add(Text(texto, style: AppTextStyles.corpo));
    }
    if (s.proxima case final fase?) {
      filhos.add(Text('Próxima etapa: ${_etapa(fase)}', style: AppTextStyles.nome));
      for (final p in s.propostos) {
        final vantagem = s.vantagem[p.mandanteId];
        filhos.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              [
                '${_nome(p.mandanteId)} x ${_nome(p.visitanteId)}',
                dataHoraJogo(p.inicio),
                if (vantagem != null) 'empate classifica ${_nome(vantagem)}',
              ].join(' · '),
              style: AppTextStyles.corpo,
            ),
          ),
        );
      }
      if (s.dataProvisoria) {
        filhos.add(
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Data provisória: o calendário oficial ainda não tem horário para esta etapa. '
              'Ajuste data e hora em cada jogo depois de criar.',
              style: AppTextStyles.pequeno,
            ),
          ),
        );
      }
      filhos
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(
          FilledButton(
            onPressed: _gravando ? null : () => _criar(s),
            child: Text('Criar ${_etapa(fase)}'),
          ),
        );
    }
    if (s.desfazivel case final f?) {
      filhos.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _gravando ? null : () => _desfazer(s),
            child: Text('Desfazer ${_etapa(f)}'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSecao(_grandeFinal ? 'Grande final' : 'Mata-mata do ${widget.turno}º turno'),
        Cartao(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: filhos),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
