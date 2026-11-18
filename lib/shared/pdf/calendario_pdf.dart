import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/categoria.dart';
import '../../domain/usecases/calendario_geral.dart';

// Cores do app (lib/shared/theme/app_colors.dart).
const _verde = PdfColor.fromInt(0xFF008E44);
const _verdeSuave = PdfColor.fromInt(0xFFE6F4EC);
const _oliva = PdfColor.fromInt(0xFF6C8A26);
const _tinta = PdfColor.fromInt(0xFF292B23);
const _texto2 = PdfColor.fromInt(0xFF585954);
const _dica = PdfColor.fromInt(0xFF9A9B94);
const _linha = PdfColor.fromInt(0xFFE2E3DE);
const _fundo = PdfColor.fromInt(0xFFFAFAF8);
const _vermelho = PdfColor.fromInt(0xFFCE2B37);
const _vermelhoSuave = PdfColor.fromInt(0xFFFCE9EA);
const _draft = PdfColor.fromInt(0xFFB0247A);

/// Cor de cada competição (as mesmas da tela Calendário).
PdfColor _cor(Competicao c) => switch (c) {
  Competicao.master => _verde,
  Competicao.superMaster => const PdfColor.fromInt(0xFFC98600),
  Competicao.livre => const PdfColor.fromInt(0xFF1B5CC1),
  Competicao.copaMaster => const PdfColor.fromInt(0xFF6A3FA0),
};

int _equipes(Competicao c) => switch (c) {
  Competicao.master => Categoria.master.times,
  Competicao.superMaster => Categoria.superMaster.times,
  Competicao.livre => Categoria.livre.times,
  Competicao.copaMaster => Categoria.master.times,
};

const _meses = [
  'JANEIRO', 'FEVEREIRO', 'MARÇO', 'ABRIL', 'MAIO', 'JUNHO', //
  'JULHO', 'AGOSTO', 'SETEMBRO', 'OUTUBRO', 'NOVEMBRO', 'DEZEMBRO',
];
const _semana = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
const _diasExtenso = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];

String _dd(int n) => n.toString().padLeft(2, '0');
String _diaMes(DateTime d) => '${_dd(d.day)}/${_dd(d.month)}';
DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Fontes e logo do app, carregados dos assets.
class RecursosCalendarioPdf {
  final pw.Font titulo;
  final pw.Font texto;
  final pw.Font textoNegrito;
  final pw.MemoryImage logo;
  const RecursosCalendarioPdf({
    required this.titulo,
    required this.texto,
    required this.textoNegrito,
    required this.logo,
  });

  static Future<RecursosCalendarioPdf> carregar() async => RecursosCalendarioPdf(
    titulo: pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-ExtraBold.ttf')),
    texto: pw.Font.ttf(await rootBundle.load('assets/fonts/OpenSans-Regular.ttf')),
    textoNegrito: pw.Font.ttf(await rootBundle.load('assets/fonts/OpenSans-SemiBold.ttf')),
    logo: pw.MemoryImage((await rootBundle.load('assets/images/logo.png')).buffer.asUint8List()),
  );
}

/// Calendário anual em uma folha A3, no padrão visual do app: cabeçalho
/// verde com o logo, um quadro por mês com as partidas de cada competição
/// por dia (M2 = 2 jogos do Master), drafts, feriados, destaques do mês e o
/// resumo da temporada. Sai sempre dos dados do app.
Future<Uint8List> gerarCalendarioPdf(
  List<JogoDoCalendario> eventos,
  RecursosCalendarioPdf r,
) async {
  final jogos = [for (final e in eventos) if (!e.ehDraft) e];
  final drafts = [for (final e in eventos) if (e.ehDraft) e];
  final feriados = {for (final f in feriados2027) _dia(f.data): f};

  // Do mês do primeiro evento (o Draft-1 pode cair no ano anterior) a dezembro.
  final inicio = eventos.isEmpty
      ? DateTime(2027)
      : eventos.map((e) => e.inicio).reduce((a, b) => a.isBefore(b) ? a : b);
  final primeiroMes = DateTime(inicio.year, inicio.month);
  final meses = <DateTime>[
    for (var m = primeiroMes; !m.isAfter(DateTime(2027, 12)); m = DateTime(m.year, m.month + 1)) m,
  ];

  // Altura das casas para caber tudo numa folha: meses + 2 quadros, 3 por linha.
  final linhasDaGrade = (meses.length + 2 + 2) ~/ 3;
  // Sobra ~1040 pt para a grade; cada quadro gasta ~54 pt fora as casas.
  final alturaCasa = (((940 - 6 * (linhasDaGrade - 1)) / linhasDaGrade - 54) / 6).clamp(13.0, 26.0);

  final porDia = <DateTime, List<JogoDoCalendario>>{};
  for (final e in eventos) {
    porDia.putIfAbsent(_dia(e.inicio), () => []).add(e);
  }

  pw.TextStyle t(double tamanho, {bool negrito = false, PdfColor cor = _tinta}) => pw.TextStyle(
    font: negrito ? r.textoNegrito : r.texto,
    fontSize: tamanho,
    color: cor,
  );
  pw.TextStyle tt(double tamanho, {PdfColor cor = _tinta}) =>
      pw.TextStyle(font: r.titulo, fontSize: tamanho, color: cor);

  pw.Widget selo(String texto, PdfColor cor) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 0.8),
    padding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.6),
    decoration: pw.BoxDecoration(color: cor, borderRadius: pw.BorderRadius.circular(2)),
    child: pw.Text(texto, style: t(5.6, negrito: true, cor: PdfColors.white)),
  );

  pw.Widget celula(DateTime d) {
    final doDia = porDia[d] ?? const <JogoDoCalendario>[];
    final contagem = <Competicao, int>{};
    for (final e in doDia) {
      if (!e.ehDraft) contagem[e.competicao] = (contagem[e.competicao] ?? 0) + 1;
    }
    final feriado = feriados[d];
    final domingo = d.weekday == DateTime.sunday;
    final numero = pw.Text(
      '${d.day}',
      style: t(7, negrito: true, cor: feriado != null ? _vermelho : (domingo ? _dica : _tinta)),
    );
    return pw.Container(
      height: alturaCasa,
      alignment: pw.Alignment.topCenter,
      padding: const pw.EdgeInsets.only(top: 1),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _linha, width: 0.4)),
      ),
      child: pw.Column(
        children: [
          if (feriado == null)
            numero
          else
            pw.Container(
              width: 10,
              height: 10,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: feriado.oficial ? null : _vermelhoSuave,
                border: feriado.oficial ? pw.Border.all(color: _vermelho, width: 0.8) : null,
              ),
              child: numero,
            ),
          // Selos lado a lado, para caber mais de uma competição no dia.
          pw.Wrap(
            alignment: pw.WrapAlignment.center,
            spacing: 1.5,
            children: [
              for (final c in Competicao.values)
                if (contagem[c] case final n?) selo('${c.sigla}$n', _cor(c)),
              for (final e in doDia)
                if (e.ehDraft) selo('D${e.draft} ${e.competicao.sigla}', _draft),
            ],
          ),
        ],
      ),
    );
  }

  /// Destaques do mês: aberturas de turno, mata-mata, finais, Copa e drafts.
  String destaques(DateTime mes) {
    final vistos = <String>{};
    final linhas = <String>[];
    for (final e in eventos) {
      if (e.inicio.year != mes.year || e.inicio.month != mes.month) continue;
      final String texto;
      if (e.ehDraft) {
        texto = 'Draft-${e.draft} ${e.competicao.nome}';
      } else if (e.etapa == 'Rodada 1') {
        texto = 'Abertura ${e.competicao.nome} · ${e.turno}º turno';
      } else if (e.etapa.startsWith('Rodada')) {
        continue;
      } else {
        texto = '${e.etapa} ${e.competicao.nome}';
      }
      if (vistos.add(texto)) linhas.add('${_diaMes(e.inicio)} $texto');
    }
    return linhas.join('  •  ');
  }

  pw.Widget quadroDoMes(DateTime mes) {
    final primeiro = DateTime(mes.year, mes.month);
    final vazios = primeiro.weekday - 1;
    final dias = DateTime(mes.year, mes.month + 1, 0).day;
    final casas = <DateTime?>[
      for (var i = 0; i < vazios; i++) null,
      for (var d = 1; d <= dias; d++) DateTime(mes.year, mes.month, d),
    ];
    // Sempre seis semanas, para os quadros de uma linha terem a mesma altura.
    while (casas.length < 42) {
      casas.add(null);
    }
    final notas = destaques(mes);
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _linha, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: const pw.BoxDecoration(
              color: _verde,
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text('${_meses[mes.month - 1]} ${mes.year}', style: tt(10, cor: PdfColors.white)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: pw.Column(
              children: [
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    for (final s in _semana)
                      pw.Expanded(
                        child: pw.Center(child: pw.Text(s, style: t(5.5, negrito: true, cor: _dica))),
                      ),
                  ],
                ),
                for (var i = 0; i < casas.length; i += 7)
                  pw.Row(
                    children: [
                      for (final d in casas.sublist(i, i + 7))
                        pw.Expanded(child: d == null ? pw.SizedBox(height: alturaCasa) : celula(d)),
                    ],
                  ),
              ],
            ),
          ),
          pw.Container(
            height: 22,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const pw.BoxDecoration(
              color: _fundo,
              border: pw.Border(top: pw.BorderSide(color: _linha, width: 0.4)),
            ),
            child: pw.Text(notas, style: t(5.6, cor: _texto2), maxLines: 2),
          ),
        ],
      ),
    );
  }

  pw.Widget legenda(String sigla, String nome, PdfColor cor) => pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        decoration: pw.BoxDecoration(color: cor, borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Text(sigla, style: t(7, negrito: true, cor: PdfColors.white)),
      ),
      pw.SizedBox(width: 4),
      pw.Text(nome, style: t(8, negrito: true)),
      pw.SizedBox(width: 14),
    ],
  );

  pw.Widget caixa(String titulo, List<pw.Widget> filhos) => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: _linha, width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [pw.Text(titulo, style: tt(10, cor: _verde)), pw.SizedBox(height: 5), ...filhos],
    ),
  );

  final grandesFinais = [
    for (final e in jogos)
      if (e.etapa == 'Grande final') e,
  ];
  final resumo = caixa('RESUMO DA TEMPORADA', [
    for (final c in Competicao.values)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2.5),
        child: pw.Row(
          children: [
            pw.Container(width: 6, height: 6, color: _cor(c)),
            pw.SizedBox(width: 5),
            pw.SizedBox(width: 70, child: pw.Text(c.nome, style: t(7.5, negrito: true))),
            pw.Text(
              '${_equipes(c)} equipes  •  ${jogos.where((e) => e.competicao == c).length} partidas',
              style: t(7.5, cor: _texto2),
            ),
          ],
        ),
      ),
    pw.Divider(color: _linha, thickness: 0.5),
    pw.Text('${jogos.length} PARTIDAS PREVISTAS', style: tt(9)),
    pw.SizedBox(height: 4),
    for (final g in grandesFinais)
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 2),
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: pw.BoxDecoration(color: _verdeSuave, borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Text(
          '${g.competicao.nome.toUpperCase()} · GRANDE FINAL ${_diaMes(g.inicio)}/${g.inicio.year} '
          '(${_diasExtenso[g.inicio.weekday - 1]})',
          style: t(6.8, negrito: true, cor: _oliva),
        ),
      ),
    for (final d in drafts)
      pw.Text(
        'Draft-${d.draft} ${d.competicao.nome}: ${_diaMes(d.inicio)}/${d.inicio.year}',
        style: t(6.8, cor: _texto2),
      ),
  ]);

  final listaFeriados = caixa('FERIADOS E DATAS', [
    for (final f in feriados2027)
      if (f.data.year == 2027 || meses.any((m) => m.year == f.data.year && m.month == f.data.month))
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1.8),
          child: pw.Row(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: f.oficial ? null : _vermelhoSuave,
                  border: f.oficial ? pw.Border.all(color: _vermelho, width: 0.8) : null,
                ),
              ),
              pw.SizedBox(width: 5),
              pw.SizedBox(
                width: 50,
                child: pw.Text(
                  f.data.year == 2027 ? _diaMes(f.data) : '${_diaMes(f.data)}/${f.data.year % 100}',
                  style: t(7, negrito: true),
                ),
              ),
              pw.Expanded(child: pw.Text(f.nome, style: t(7, cor: _texto2))),
            ],
          ),
        ),
    pw.SizedBox(height: 3),
    pw.Text(
      'Círculo vermelho: feriado oficial  •  fundo rosado: facultativo ou a confirmar',
      style: t(6, cor: _dica),
    ),
  ]);

  final quadros = <pw.Widget>[...meses.map(quadroDoMes), resumo, listaFeriados];
  final linhasGrade = <pw.Widget>[];
  for (var i = 0; i < quadros.length; i += 3) {
    final trio = quadros.sublist(i, (i + 3).clamp(0, quadros.length));
    linhasGrade.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < 3; j++) ...[
              if (j > 0) pw.SizedBox(width: 8),
              pw.Expanded(child: j < trio.length ? trio[j] : pw.SizedBox()),
            ],
          ],
        ),
      ),
    );
  }

  final doc = pw.Document(
    title: 'Calcio Firenze 2027 · Calendário anual de jogos',
    author: 'Calcio Firenze',
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a3.copyWith(
        marginLeft: 22,
        marginRight: 22,
        marginTop: 20,
        marginBottom: 16,
      ),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(color: _verde, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 40,
                  height: 40,
                  padding: const pw.EdgeInsets.all(3),
                  decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
                  child: pw.Image(r.logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CALCIO FIRENZE 2027', style: tt(22, cor: PdfColors.white)),
                    pw.Text('CALENDÁRIO ANUAL DE JOGOS', style: t(9, negrito: true, cor: _verdeSuave)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _linha, width: 0.6),
            ),
            child: pw.Row(
              children: [
                for (final c in Competicao.values) legenda(c.sigla, c.nome.toUpperCase(), _cor(c)),
                legenda('D', 'DRAFT', _draft),
                pw.Spacer(),
                pw.Text('Número no selo = partidas no dia', style: t(7, cor: _dica)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          ...linhasGrade,
          pw.Spacer(),
          pw.Text(
            'Gerado pelo app Calcio Firenze. Horários e confrontos atualizados no app.',
            style: t(6.5, cor: _dica),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
