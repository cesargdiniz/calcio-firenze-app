import 'package:material_ui/material_ui.dart';

import '../../domain/entities/campeoes.dart';
import '../../domain/entities/categoria.dart';
import '../../shared/layout/folha.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';

/// Abre o campinho com a escalação do time campeão: folha de baixo no
/// celular, painel pela direita no computador.
Future<void> abrirEscalacao(BuildContext context, Categoria categoria, TituloTemporada t) =>
    abrirFolha<void>(context, (_) => EscalacaoCampeao(categoria: categoria, titulo: t));

/// Titulares no campo (goleiro e 2-2-1) e reservas por posição.
class EscalacaoCampeao extends StatelessWidget {
  final Categoria categoria;
  final TituloTemporada titulo;
  const EscalacaoCampeao({super.key, required this.categoria, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final lateral = FolhaLateral.ativa(context);
    final reservas = titulo.reservas;
    return SafeArea(
      top: lateral,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, lateral ? 24 : 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.emoji_events_rounded, color: AppColors.amarelo, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo.campeao, style: AppTextStyles.tituloTela.copyWith(fontSize: 24)),
                      Text(
                        'Campeão ${categoria.nome} ${titulo.ano}',
                        style: AppTextStyles.subtitulo,
                      ),
                    ],
                  ),
                ),
                if (lateral)
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _Campo(titulo: titulo),
              ),
            ),
            if (reservas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const Text('Reservas', style: AppTextStyles.tituloSecao),
              const SizedBox(height: AppSpacing.sm),
              for (final p in PosicaoCampeao.values)
                if (reservas.where((j) => j.posicao == p).toList() case final daPosicao
                    when daPosicao.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            daPosicao.length == 1 ? p.nome : p.plural,
                            style: AppTextStyles.rotulo.copyWith(color: AppColors.texto2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            daPosicao.map((j) => j.nome).join(', '),
                            style: AppTextStyles.nome,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Meio campo visto de cima, ataque no alto: atacante, 2 meias, 2 zagueiros
/// e o goleiro.
class _Campo extends StatelessWidget {
  final TituloTemporada titulo;
  const _Campo({required this.titulo});

  /// Lugar de cada titular, em frações da largura e da altura do campo.
  static const _lugares = {
    PosicaoCampeao.ataque: [Offset(0.5, 0.17)],
    PosicaoCampeao.meia: [Offset(0.27, 0.41), Offset(0.73, 0.41)],
    PosicaoCampeao.zagueiro: [Offset(0.27, 0.65), Offset(0.73, 0.65)],
    PosicaoCampeao.goleiro: [Offset(0.5, 0.87)],
  };

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 0.72,
    child: LayoutBuilder(
      builder: (context, box) {
        final jogadores = <Widget>[];
        for (final MapEntry(key: posicao, value: lugares) in _lugares.entries) {
          final nomes = titulo.titularesDe(posicao);
          for (final (i, j) in nomes.indexed) {
            if (i >= lugares.length) break;
            final l = nomes.length == 1 && lugares.length > 1 ? const Offset(0.5, 0) : lugares[i];
            final y = lugares[i].dy;
            jogadores.add(
              Positioned(
                left: l.dx * box.maxWidth - 55,
                top: y * box.maxHeight - 22,
                width: 110,
                child: _Jogador(j),
              ),
            );
          }
        }
        return Semantics(
          label: 'Titulares: ${titulo.titulares.map((j) => '${j.nome}, ${j.posicao.nome}').join('; ')}',
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: AppRadius.cartao,
            child: CustomPaint(
              painter: const _LinhasDoCampo(),
              child: Stack(children: jogadores),
            ),
          ),
        );
      },
    ),
  );
}

class _Jogador extends StatelessWidget {
  final JogadorCampeao j;
  const _Jogador(this.j);

  @override
  Widget build(BuildContext context) {
    final partes = j.nome.split(' ');
    final iniciais = partes.length > 1
        ? '${partes.first[0]}${partes.last[0]}'
        : j.nome.substring(0, j.nome.length < 2 ? j.nome.length : 2);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: j.posicao == PosicaoCampeao.goleiro ? AppColors.amarelo : Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Text(
            iniciais.toUpperCase(),
            style: AppTextStyles.nome.copyWith(fontSize: 13, color: AppColors.tinta),
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0x99000000),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              j.nome,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.rotulo.copyWith(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gramado listrado com as linhas de meio campo, grande área e gol.
class _LinhasDoCampo extends CustomPainter {
  const _LinhasDoCampo();

  @override
  void paint(Canvas canvas, Size s) {
    const claro = Color(0xFF2E9E57);
    const escuro = Color(0xFF278C4C);
    const faixas = 8;
    for (var i = 0; i < faixas; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, s.height * i / faixas, s.width, s.height / faixas + 1),
        Paint()..color = i.isEven ? claro : escuro,
      );
    }
    final linha = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const m = 10.0;
    canvas.drawRect(Rect.fromLTWH(m, m, s.width - 2 * m, s.height - 2 * m), linha);
    // Linha e círculo do meio campo, no alto.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s.width / 2, m), radius: s.width * 0.16),
      0,
      3.1416,
      false,
      linha,
    );
    // Grande área, pequena área e gol, embaixo.
    final area = s.width * 0.62;
    canvas.drawRect(
      Rect.fromLTWH((s.width - area) / 2, s.height - m - s.height * 0.2, area, s.height * 0.2),
      linha,
    );
    final pequena = s.width * 0.3;
    canvas.drawRect(
      Rect.fromLTWH((s.width - pequena) / 2, s.height - m - s.height * 0.08, pequena, s.height * 0.08),
      linha,
    );
  }

  @override
  bool shouldRepaint(_LinhasDoCampo oldDelegate) => false;
}
