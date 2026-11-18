import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/temporada.dart';
import '../../domain/usecases/montar_sumula_impressa.dart';
import 'sumula_pdf.dart';

/// Entrega um PDF pronto a quem está usando o app (trocada por uma versão
/// que só guarda o arquivo nos testes).
abstract interface class SaidaPdf {
  Future<void> abrir(Uint8List bytes, String nomeArquivo);
}

/// No navegador, baixa o arquivo; no celular, abre o compartilhamento
/// (imprimir, salvar, enviar).
class SaidaPdfDoAparelho implements SaidaPdf {
  const SaidaPdfDoAparelho();

  @override
  Future<void> abrir(Uint8List bytes, String nomeArquivo) =>
      Printing.sharePdf(bytes: bytes, filename: nomeArquivo);
}

/// Gera a súmula de papel da partida e entrega o PDF.
Future<void> abrirSumulaPdf(BuildContext context, DadosTemporada dados, String partidaId) async {
  final saida = context.read<SaidaPdf>();
  final avisos = ScaffoldMessenger.of(context);
  try {
    final sumula = MontarSumulaImpressa()(dados, partidaId);
    final bytes = await gerarSumulaPdf(
      sumula,
      fonte: await rootBundle.load('assets/fonts/OpenSans-Regular.ttf'),
      fonteNegrito: await rootBundle.load('assets/fonts/OpenSans-SemiBold.ttf'),
    );
    await saida.abrir(bytes, sumula.nomeArquivo);
  } catch (_) {
    avisos.showSnackBar(const SnackBar(content: Text('Não foi possível gerar o PDF da súmula.')));
  }
}

/// Arte oficial do calendário anual (todas as categorias), enviada pela
/// Organização. Para atualizar, troque o arquivo e gere um build novo.
const arteCalendario2027 = 'assets/calendario/calendario-2027.png';

/// PDF de uma página com a arte do calendário anual, para baixar ou enviar.
Future<Uint8List> gerarCalendarioPdf(Uint8List arte) async {
  final imagem = pw.MemoryImage(arte);
  final largura = PdfPageFormat.a4.width;
  final altura = largura * imagem.height! / imagem.width!;
  final doc = pw.Document(title: 'Calcio Firenze 2027 · Calendário anual de jogos');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(largura, altura),
      build: (_) => pw.Image(imagem, fit: pw.BoxFit.contain),
    ),
  );
  return doc.save();
}

/// Entrega o PDF do calendário anual.
Future<void> abrirCalendarioPdf(BuildContext context) async {
  final saida = context.read<SaidaPdf>();
  final avisos = ScaffoldMessenger.of(context);
  try {
    final arte = await rootBundle.load(arteCalendario2027);
    final bytes = await gerarCalendarioPdf(arte.buffer.asUint8List());
    await saida.abrir(bytes, 'Calcio_Firenze_2027_Calendario.pdf');
  } catch (_) {
    avisos.showSnackBar(const SnackBar(content: Text('Não foi possível gerar o PDF do calendário.')));
  }
}
