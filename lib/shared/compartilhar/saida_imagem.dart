import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Entrega uma imagem pronta a quem está usando o app (trocada por uma versão
/// que só guarda o arquivo nos testes).
abstract interface class SaidaImagem {
  Future<void> compartilhar(Uint8List png, {required String nomeArquivo, required String legenda});
}

/// No celular, abre o compartilhamento do sistema (WhatsApp, salvar, e-mail);
/// no navegador, compartilha quando dá e, se não der, baixa o arquivo.
class SaidaImagemDoAparelho implements SaidaImagem {
  const SaidaImagemDoAparelho();

  @override
  Future<void> compartilhar(
    Uint8List png, {
    required String nomeArquivo,
    required String legenda,
  }) => SharePlus.instance.share(
    ShareParams(
      text: legenda,
      files: [XFile.fromData(png, mimeType: 'image/png')],
      fileNameOverrides: [nomeArquivo],
    ),
  );
}
