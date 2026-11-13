import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/usecases/montar_sumula_impressa.dart';
import '../format.dart';

const _linha = 0.8;
const _fina = 0.4;
const _alturaJogador = 17.5;

/// Linhas da lista de jogadores: o elenco e ao menos uma em branco, para
/// inscrição à mão.
const _linhasMinimas = 15;

/// Desenha a súmula de papel em uma página A4, no modelo usado pelo Calcio:
/// cabeçalho do jogo e, para cada time, a lista de jogadores com faltas e
/// cartões, faltas acumuladas, pedidos de tempo, gols e substituições.
Future<Uint8List> gerarSumulaPdf(
  SumulaImpressa s, {
  required ByteData fonte,
  required ByteData fonteNegrito,
}) {
  final normal = pw.Font.ttf(fonte);
  final negrito = pw.Font.ttf(fonteNegrito);
  final doc = pw.Document(
    title: 'Súmula ${s.mandante.nome} x ${s.visitante.nome}',
    author: 'Calcio Firenze',
    theme: pw.ThemeData.withFont(base: normal, bold: negrito).copyWith(
      defaultTextStyle: pw.TextStyle(font: normal, fontBold: negrito, fontSize: 8.5),
    ),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _cabecalho(s),
          pw.SizedBox(height: 6),
          _agenda(s),
          pw.SizedBox(height: 8),
          _time(s.mandante),
          pw.SizedBox(height: 12),
          _time(s.visitante),
          pw.SizedBox(height: 6),
          pw.Text(
            'Nome riscado: suspenso ou impedido por pendência nesta partida.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

final _negrito = pw.TextStyle(fontWeight: pw.FontWeight.bold);

pw.BoxDecoration _borda([double largura = _linha]) =>
    pw.BoxDecoration(border: pw.Border.all(width: largura));

/// "Rótulo: valor", com o rótulo em negrito.
pw.Widget _campo(String rotulo, String valor) => pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(text: '$rotulo ', style: _negrito),
      pw.TextSpan(text: valor),
    ],
  ),
);

pw.Widget _celula(
  pw.Widget child, {
  double altura = 14,
  pw.Alignment alinhamento = pw.Alignment.centerLeft,
}) => pw.Container(
  height: altura,
  alignment: alinhamento,
  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
  child: child,
);

pw.Widget _titulo(String texto) => pw.Container(
  height: 12,
  alignment: pw.Alignment.center,
  decoration: _borda(),
  child: pw.Text(texto, style: _negrito),
);

pw.Widget _cabecalho(SumulaImpressa s) {
  pw.Widget placar(int? gols) => pw.Container(
    width: 50,
    height: 14,
    alignment: pw.Alignment.center,
    decoration: _borda(),
    child: pw.Text(gols == null ? '' : '$gols', style: _negrito),
  );
  pw.Widget nome(String texto) => pw.Expanded(
    child: pw.Container(
      height: 14,
      alignment: pw.Alignment.center,
      decoration: _borda(),
      child: pw.Text(texto, style: _negrito),
    ),
  );
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              decoration: _borda(),
              child: _celula(_campo('Competição:', s.competicao)),
            ),
          ),
          pw.Container(
            width: 130,
            decoration: _borda(),
            child: _celula(_campo('Jogo Nº:', '')),
          ),
        ],
      ),
      pw.Container(
        decoration: _borda(),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 5, child: _celula(_campo('Categoria:', s.categoria))),
            pw.Expanded(flex: 2, child: _celula(_campo('Fase:', s.fase))),
            pw.Expanded(flex: 2, child: _celula(_campo('Rodada:', s.rodada ?? ''))),
          ],
        ),
      ),
      pw.Row(
        children: [
          nome(s.mandante.nome),
          placar(s.mandante.gols),
          pw.Container(
            width: 32,
            height: 14,
            alignment: pw.Alignment.center,
            decoration: _borda(),
            child: pw.Text('X', style: _negrito),
          ),
          placar(s.visitante.gols),
          nome(s.visitante.nome),
        ],
      ),
    ],
  );
}

pw.Widget _agenda(SumulaImpressa s) {
  String dois(int n) => n.toString().padLeft(2, '0');
  final horario = '${dois(s.inicio.hour)}:${dois(s.inicio.minute)}';
  pw.TableRow linha(String rotulo) => pw.TableRow(
    children: [
      _celula(pw.Text(rotulo, style: _negrito), altura: 16),
      pw.SizedBox(height: 16),
      pw.SizedBox(height: 16),
    ],
  );
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 5,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              decoration: _borda(),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: _celula(_campo('Local:', s.local), altura: 16)),
                  pw.Expanded(
                    flex: 2,
                    child: _celula(_campo('Data:', dataCompleta(s.inicio)), altura: 16),
                  ),
                  pw.Expanded(flex: 2, child: _celula(_campo('Horário:', horario), altura: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 44,
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.topLeft,
              decoration: _borda(),
              child: pw.Text('Arbitragem:', style: _negrito),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Expanded(
        flex: 2,
        child: pw.Table(
          border: pw.TableBorder.all(width: _linha),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.SizedBox(height: 16),
                _celula(
                  pw.Text('Início', style: _negrito),
                  altura: 16,
                  alinhamento: pw.Alignment.center,
                ),
                _celula(
                  pw.Text('Fim', style: _negrito),
                  altura: 16,
                  alinhamento: pw.Alignment.center,
                ),
              ],
            ),
            linha('1º Tempo'),
            linha('2º Tempo'),
            linha('Acréscimos'),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _time(TimeSumulaImpresso t) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Expanded(flex: 2, child: _jogadores(t)),
    pw.SizedBox(width: 6),
    pw.Expanded(flex: 1, child: _quadros(t)),
  ],
);

pw.Widget _jogadores(TimeSumulaImpresso t) {
  final emBranco = t.jogadores.length >= _linhasMinimas
      ? 1
      : _linhasMinimas - t.jogadores.length;
  final linhas = [...t.jogadores, for (var i = 0; i < emBranco; i++) null];
  // Elenco maior que o modelo: as linhas encolhem para caber na página.
  final altura = linhas.length <= _linhasMinimas
      ? _alturaJogador
      : _alturaJogador * _linhasMinimas / linhas.length;
  final cinza = pw.TextStyle(color: PdfColors.grey500, fontSize: 7);

  pw.Widget centro(pw.Widget child) =>
      _celula(child, altura: altura, alinhamento: pw.Alignment.center);
  pw.Widget cabeca(String texto) => _celula(
    pw.Text(texto, style: _negrito),
    altura: 13,
    alinhamento: texto == 'Jogadores' ? pw.Alignment.centerLeft : pw.Alignment.center,
  );

  pw.TableRow jogador(LinhaSumulaImpressa? j) => pw.TableRow(
    children: [
      _celula(
        pw.Text(
          j?.nome.toUpperCase() ?? '',
          maxLines: 1,
          style: j != null && j.fora
              ? const pw.TextStyle(
                  decoration: pw.TextDecoration.lineThrough,
                  color: PdfColors.grey700,
                )
              : null,
        ),
        altura: altura,
      ),
      centro(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [for (var i = 0; i < 4; i++) pw.Text('|', style: cinza)],
        ),
      ),
      centro(pw.Text(j?.numero == null ? '' : '${j!.numero}', style: const pw.TextStyle(fontSize: 9.5))),
      centro(
        j != null && j.amarelos > 0
            ? pw.Text('X' * j.amarelos, style: _negrito)
            // Divisão entre o 1º e o 2º amarelo.
            : pw.Container(width: _linha, height: altura * 0.5, color: PdfColors.black),
      ),
      centro(pw.Text(j != null && j.vermelho ? 'X' : '', style: _negrito)),
    ],
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(
        height: 12,
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
        decoration: _borda(),
        child: pw.Text(t.nome, style: _negrito),
      ),
      pw.Table(
        border: pw.TableBorder.all(width: _linha),
        columnWidths: const {
          0: pw.FlexColumnWidth(8),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(1.3),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: [
              cabeca('Jogadores'),
              cabeca('Faltas'),
              cabeca('Nº'),
              cabeca('Ama'),
              cabeca('Ver'),
            ],
          ),
          for (final j in linhas) jogador(j),
        ],
      ),
    ],
  );
}

pw.Widget _quadros(TimeSumulaImpresso t) {
  pw.Widget rotulo(String texto, {double altura = 13}) => _celula(
    pw.Text(texto, style: _negrito),
    altura: altura,
    alinhamento: pw.Alignment.center,
  );
  pw.TableRow periodo(String texto) => pw.TableRow(
    children: [
      rotulo(texto, altura: 16),
      for (var i = 0; i < 5; i++) pw.SizedBox(height: 16),
    ],
  );
  pw.TableRow substituicao(String texto) => pw.TableRow(
    children: [
      _celula(pw.Text(texto, style: _negrito), altura: 13),
      for (var i = 0; i < 9; i++) pw.SizedBox(height: 13),
    ],
  );
  pw.TableRow assinatura(String texto, String valor) => pw.TableRow(
    children: [
      _celula(pw.Text(texto, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)), altura: 13),
      _celula(pw.Text(valor, maxLines: 1, style: const pw.TextStyle(fontSize: 7)), altura: 13),
    ],
  );
  pw.Widget gol(int numero) => pw.Expanded(
    child: pw.Container(
      height: 18,
      decoration: _borda(_fina),
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 1.5,
            top: 0.5,
            child: pw.Text(
              '$numero',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5.5),
            ),
          ),
          pw.Center(child: pw.Text(':')),
        ],
      ),
    ),
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _titulo('Faltas acumuladas'),
      pw.Table(
        border: pw.TableBorder.all(width: _linha),
        columnWidths: const {0: pw.FlexColumnWidth(5)},
        defaultColumnWidth: const pw.FlexColumnWidth(1),
        children: [periodo('Período 1'), periodo('Período 2')],
      ),
      pw.SizedBox(height: 5),
      _titulo('Pedidos de tempo'),
      pw.Table(
        border: pw.TableBorder.all(width: _linha),
        children: [
          pw.TableRow(
            children: [rotulo('Período 1', altura: 12), rotulo('Período 2', altura: 12)],
          ),
          pw.TableRow(
            children: [
              _celula(pw.Text('X'), altura: 12, alinhamento: pw.Alignment.center),
              _celula(pw.Text('X'), altura: 12, alinhamento: pw.Alignment.center),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      _titulo('GOLS'),
      pw.Container(
        decoration: _borda(),
        child: pw.Column(
          children: [
            for (var fila = 0; fila < 4; fila++)
              pw.Row(children: [for (var i = 1; i <= 7; i++) gol(fila * 7 + i)]),
          ],
        ),
      ),
      pw.SizedBox(height: 5),
      _titulo('Substituições'),
      pw.Table(
        border: pw.TableBorder.all(width: _linha),
        columnWidths: const {0: pw.FlexColumnWidth(4.5)},
        defaultColumnWidth: const pw.FlexColumnWidth(1),
        children: [
          pw.TableRow(
            children: [
              pw.SizedBox(height: 13),
              for (var i = 1; i <= 9; i++)
                _celula(pw.Text('$i'), altura: 13, alinhamento: pw.Alignment.center),
            ],
          ),
          substituicao('Entrou'),
          substituicao('Saiu'),
        ],
      ),
      pw.SizedBox(height: 5),
      pw.Table(
        border: pw.TableBorder.all(width: _linha),
        columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(4)},
        children: [
          assinatura('Técnico', t.tecnico ?? ''),
          assinatura('Capitão', ''),
          assinatura('', ''),
          assinatura('', ''),
        ],
      ),
    ],
  );
}
