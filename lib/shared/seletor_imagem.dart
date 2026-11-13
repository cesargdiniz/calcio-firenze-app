import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

/// Lado máximo, em pixels, do escudo guardado no cadastro do time.
const ladoEscudo = 256;

/// O escudo fica dentro do documento do time no Firestore (limite de 1 MB por
/// documento), então a imagem reduzida não pode passar disto.
const tamanhoMaximoEscudo = 300 * 1024;

/// A imagem, mesmo reduzida, passou de [tamanhoMaximoEscudo].
class ImagemGrandeDemais implements Exception {
  const ImagemGrandeDemais();
}

/// Escolha de imagens no aparelho (trocada por uma versão fixa nos testes).
abstract interface class SeletorImagem {
  /// Abre a galeria ou o seletor de arquivos e devolve o escudo já reduzido,
  /// em PNG. Nulo se a pessoa desistiu.
  Future<Uint8List?> escolherEscudo();
}

class SeletorImagemDoAparelho implements SeletorImagem {
  const SeletorImagemDoAparelho();

  @override
  Future<Uint8List?> escolherEscudo() async {
    final arquivo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (arquivo == null) return null;
    return reduzirParaEscudo(await arquivo.readAsBytes());
  }
}

/// Reduz a imagem para caber em [lado] x [lado], mantendo a proporção e a
/// transparência, e devolve em PNG. Falha se os bytes não forem uma imagem.
Future<Uint8List> reduzirParaEscudo(Uint8List original, {int lado = ladoEscudo}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(original);
  final descritor = await ui.ImageDescriptor.encoded(buffer);
  final escala = min(1.0, lado / max(descritor.width, descritor.height));
  final codec = await descritor.instantiateCodec(
    targetWidth: max(1, (descritor.width * escala).round()),
    targetHeight: max(1, (descritor.height * escala).round()),
  );
  final quadro = await codec.getNextFrame();
  final dados = await quadro.image.toByteData(format: ui.ImageByteFormat.png);
  quadro.image.dispose();
  codec.dispose();
  descritor.dispose();
  buffer.dispose();
  if (dados == null) throw const FormatException('Imagem ilegível.');
  final png = dados.buffer.asUint8List();
  if (png.lengthInBytes > tamanhoMaximoEscudo) throw const ImagemGrandeDemais();
  return png;
}
