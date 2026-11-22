import 'package:material_ui/material_ui.dart';

import '../../../domain/entities/temporada.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/escudo.dart';

/// Posição de cada time rodada a rodada (como o "gráfico conectado" do
/// Brasileirão): uma coluna por rodada, uma linha por posição; o time em
/// destaque na cor dele, os outros em cinza. Os escudos ficam à esquerda, na
/// posição da 1ª rodada.
class GraficoEvolucao extends StatelessWidget {
  /// `posicoes[rodada - 1][timeId]`.
  final List<Map<String, int>> posicoes;
  final List<Time> times;
  final String destaque;
  final int rodadas;

  const GraficoEvolucao({
    super.key,
    required this.posicoes,
    required this.times,
    required this.destaque,
    required this.rodadas,
  });

  static const _linha = 30.0;
  static const _escudos = 34.0;
  static const _posicao = 26.0;
  static const _cabecalho = 26.0;

  @override
  Widget build(BuildContext context) {
    final n = times.length;
    final altura = _cabecalho + n * _linha;
    final porId = {for (final t in times) t.id: t};
    final primeira = posicoes.isEmpty ? const <String, int>{} : posicoes.first;
    return Semantics(
      label: _descricao(porId),
      excludeSemantics: true,
      child: SizedBox(
        height: altura,
        child: LayoutBuilder(
          builder: (context, c) {
            final largura = c.maxWidth - _escudos - _posicao;
            final coluna = largura / rodadas;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Pintor(
                      posicoes: posicoes,
                      times: times,
                      destaque: destaque,
                      rodadas: rodadas,
                      esquerda: _escudos,
                      coluna: coluna,
                      topo: _cabecalho,
                      linha: _linha,
                    ),
                  ),
                ),
                // Rodadas no topo.
                for (var r = 0; r < rodadas; r++)
                  Positioned(
                    left: _escudos + coluna * r,
                    width: coluna,
                    top: 0,
                    child: Text(
                      'R${r + 1}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pequeno.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                // Posições à direita.
                for (var i = 1; i <= n; i++)
                  Positioned(
                    right: 0,
                    width: _posicao,
                    top: _cabecalho + (i - 1) * _linha + 7,
                    child: Text(
                      '$iº',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.pequeno.copyWith(
                        color: AppColors.vermelho,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                // Escudos na posição da 1ª rodada (o destacado por cima).
                for (final t in [
                  for (final t in times)
                    if (t.id != destaque) t,
                  ?porId[destaque],
                ])
                  if (primeira[t.id] != null)
                    Positioned(
                      left: 0,
                      top: _cabecalho + (primeira[t.id]! - 1) * _linha + 2,
                      child: Opacity(
                        opacity: t.id == destaque ? 1 : 0.45,
                        child: Escudo(t, tamanho: 26),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _descricao(Map<String, Time> porId) {
    final nome = porId[destaque]?.nome ?? '';
    final caminho = [
      for (final (i, p) in posicoes.indexed)
        if (p[destaque] != null) 'rodada ${i + 1}: ${p[destaque]}º',
    ];
    return 'Evolução de $nome na tabela. ${caminho.join(', ')}.';
  }
}

class _Pintor extends CustomPainter {
  final List<Map<String, int>> posicoes;
  final List<Time> times;
  final String destaque;
  final int rodadas;
  final double esquerda;
  final double coluna;
  final double topo;
  final double linha;

  _Pintor({
    required this.posicoes,
    required this.times,
    required this.destaque,
    required this.rodadas,
    required this.esquerda,
    required this.coluna,
    required this.topo,
    required this.linha,
  });

  Offset _ponto(int rodada, int posicao) =>
      Offset(esquerda + coluna * rodada + coluna / 2, topo + (posicao - 1) * linha + linha / 2);

  @override
  void paint(Canvas canvas, Size size) {
    // Faixas alternadas, como na tabela.
    final faixa = Paint()..color = const Color(0xFFF2F2EE);
    for (var i = 0; i < times.length; i += 2) {
      canvas.drawRect(Rect.fromLTWH(esquerda, topo + i * linha, size.width - esquerda, linha), faixa);
    }
    void desenhar(Time t, {required bool forte}) {
      final cor = forte ? Color(t.cor) : const Color(0xFFBDBDB6);
      final traco = Paint()
        ..color = cor
        ..strokeWidth = forte ? 3 : 1.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final pontos = [
        for (final (r, p) in posicoes.indexed)
          if (p[t.id] != null) _ponto(r, p[t.id]!),
      ];
      if (pontos.isEmpty) return;
      canvas.drawPath(
        Path()..addPolygon(pontos, false),
        traco,
      );
      final bolinha = Paint()..color = cor;
      for (final o in pontos) {
        canvas.drawCircle(o, forte ? 6 : 3, bolinha);
      }
    }

    for (final t in times) {
      if (t.id != destaque) desenhar(t, forte: false);
    }
    for (final t in times) {
      if (t.id == destaque) desenhar(t, forte: true);
    }
  }

  @override
  bool shouldRepaint(_Pintor old) => old.posicoes != posicoes || old.destaque != destaque;
}
