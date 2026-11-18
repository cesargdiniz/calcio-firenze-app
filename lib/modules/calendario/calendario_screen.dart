import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/calendario_geral.dart';
import '../../shared/format.dart';
import '../../shared/pdf/saida_pdf.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/basicos.dart';
import '../../shared/widgets/escudo.dart';
import 'calendario_controller.dart';

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
  const CalendarioScreen({super.key, this.voltarPara = '/torcedor/jogos'});

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
            CalendarioPronto(:final jogos) => _Calendario(jogos: jogos, voltarPara: voltarPara),
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
                onPressed: () => abrirCalendarioPdf(context),
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
                '${jogos.length} jogos${_anteriores ? '' : ' a partir de hoje'}',
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
    final hora = dataHoraJogo(jogo.inicio).split(' · ').last;
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
                  if (jogo.aDefinir || jogo.mandante == null || jogo.visitante == null)
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
