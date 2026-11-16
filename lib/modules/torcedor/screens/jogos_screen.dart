import 'package:calcio_regras/calcio_regras.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/etapa.dart';
import '../../../domain/usecases/montar_painel.dart';
import '../../../shared/compartilhar/compartilhar_imagem.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/widgets/datas_copa.dart';
import '../widgets/com_painel.dart';

/// T2 · Torcedor · Jogos
class JogosScreen extends StatelessWidget {
  /// Rota da lista, para abrir o detalhe dentro da navegação certa
  /// (Torcedor ou Participante).
  final String rotaBase;
  const JogosScreen({super.key, this.rotaBase = '/torcedor/jogos'});

  @override
  Widget build(BuildContext context) => ComPainel(
    builder: (context, painel) => _Jogos(painel: painel, rotaBase: rotaBase),
  );
}

class _Jogos extends StatefulWidget {
  final Painel painel;
  final String rotaBase;
  const _Jogos({required this.painel, required this.rotaBase});

  @override
  State<_Jogos> createState() => _JogosState();
}

class _JogosState extends State<_Jogos> {
  late Etapa? _etapa = _etapaInicial();

  /// Turno dos botões de etapa (o 2º inclui a grande final).
  late int _turno = _etapa == null ? widget.painel.turnoAtual : _turnoDa(_etapa!);

  /// Mostrando as datas reservadas da Copa (só no Master).
  bool _copa = false;

  static int _turnoDa(Etapa e) => e.turno == 0 ? 2 : e.turno;

  /// Jogos e resultados da etapa escolhida (ou as datas da Copa), como imagem.
  void _compartilhar(Painel painel, Etapa? etapa, List<Partida> jogos) {
    final competicao = '${painel.categoria.nome} 2027';
    if (_copa) {
      compartilharComoImagem(
        context,
        titulo: 'Copa Master',
        subtitulo: 'Datas reservadas',
        conteudo: const DatasCopa(),
        nomeArquivo: 'calcio-copa-master-datas.png',
      );
      return;
    }
    compartilharComoImagem(
      context,
      titulo: etapa!.rotulo,
      subtitulo: etapa.turno == 0 ? competicao : '$competicao · ${etapa.turno}º Turno',
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in jogos) ...[
            CardJogo(
              partida: p,
              mandante: painel.time(p.mandanteId),
              visitante: painel.time(p.visitanteId),
              local: painel.local,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      nomeArquivo: 'calcio-${painel.categoria.name}-t${etapa.turno}-${etapa.curto.toLowerCase().replaceAll(' ', '-')}.png',
    );
  }

  /// Abre na última etapa com jogo encerrado, como no Figma.
  Etapa? _etapaInicial() {
    final encerradas = widget.painel.partidas.where((p) => p.encerrada);
    if (encerradas.isNotEmpty) return Etapa.de(encerradas.last);
    return widget.painel.etapas.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final painel = widget.painel;
    final etapas = [
      for (final e in painel.etapas)
        if (_turnoDa(e) == _turno) e,
    ];
    final etapa = etapas.contains(_etapa) ? _etapa : etapas.firstOrNull;
    final jogos = etapa == null || _copa ? const <Partida>[] : painel.jogosDa(etapa);
    final temCopa = painel.categoria == Categoria.master && _turno == 1;
    return ListView(
      padding: AppSpacing.tela,
      children: [
        CabecalhoTela(
          'Jogos',
          acao: _copa || etapa != null
              ? BotaoCompartilhar(onPressed: () => _compartilhar(painel, etapa, jogos))
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final t in [1, 2])
              ChipFiltro(
                '$tº Turno',
                ativo: _turno == t,
                onTap: () => setState(() {
                  _turno = t;
                  _etapa = null;
                  _copa = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final e in etapas) ...[
                ChipFiltro(
                  e.curto,
                  ativo: !_copa && e == etapa,
                  onTap: () => setState(() {
                    _etapa = e;
                    _copa = false;
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (temCopa)
                ChipFiltro('Copa', ativo: _copa, onTap: () => setState(() => _copa = true)),
            ],
          ),
        ),
        if (_copa)
          const DatasCopa()
        else if (etapa != null)
          TituloSecao(etapa.rotulo)
        else
          ListaVazia(
            icone: Icons.event_outlined,
            titulo: 'Sem jogos no $_turnoº turno',
            texto: 'Os jogos aparecem aqui quando a Organização sortear o calendário do turno.',
          ),
        for (final p in jogos) ...[
          CardJogo(
            partida: p,
            mandante: painel.time(p.mandanteId),
            visitante: painel.time(p.visitanteId),
            local: painel.local,
            onTap: () => context.go('${widget.rotaBase}/${p.id}'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
