import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
