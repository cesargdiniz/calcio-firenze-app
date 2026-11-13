import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:calcio_firenze/shared/seletor_imagem.dart';
import 'package:flutter_test/flutter_test.dart';

/// PNG de [largura] x [altura] pintado de verde.
Future<Uint8List> _png(int largura, int altura) async {
  final gravador = ui.PictureRecorder();
  ui.Canvas(gravador).drawRect(
    ui.Rect.fromLTWH(0, 0, largura.toDouble(), altura.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF008E44),
  );
  final imagem = await gravador.endRecording().toImage(largura, altura);
  final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
  return dados!.buffer.asUint8List();
}

Future<(int, int)> _medidas(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final quadro = await codec.getNextFrame();
  return (quadro.image.width, quadro.image.height);
}

void main() {
  testWidgets('imagem grande é reduzida para caber em 256 px, mantendo a proporção', (
    tester,
  ) async {
    final medidas = await tester.runAsync(() async {
      final reduzida = await reduzirParaEscudo(await _png(600, 300));
      return _medidas(reduzida);
    });
    expect(medidas, (256, 128));
  });

  testWidgets('imagem pequena não é ampliada', (tester) async {
    final medidas = await tester.runAsync(() async {
      final reduzida = await reduzirParaEscudo(await _png(100, 80));
      return _medidas(reduzida);
    });
    expect(medidas, (100, 80));
  });

  testWidgets('arquivo que não é imagem é recusado', (tester) async {
    final falhou = await tester.runAsync(() async {
      try {
        await reduzirParaEscudo(Uint8List.fromList([1, 2, 3, 4]));
        return false;
      } catch (_) {
        return true;
      }
    });
    expect(falhou, isTrue);
  });
}
