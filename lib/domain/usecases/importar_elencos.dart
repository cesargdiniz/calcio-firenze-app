import 'package:calcio_regras/calcio_regras.dart';

import '../entities/temporada.dart';

/// Resultado da conferência de um time na importação.
class ConferenciaTime {
  final Time time;
  final List<Pessoa> pessoas;
  final List<String> erros;
  final List<String> avisos;

  const ConferenciaTime(this.time, this.pessoas, this.erros, this.avisos);

  int get atletas => pessoas.where((p) => p.funcao == Funcao.atleta).length;
  bool get ok => erros.isEmpty;
}

class ResultadoImportacao {
  final List<ConferenciaTime> times;

  /// Linhas que não deu para ler (número da linha → motivo).
  final Map<int, String> linhasIgnoradas;

  const ResultadoImportacao(this.times, this.linhasIgnoradas);

  List<ConferenciaTime> get prontos => times.where((t) => t.ok).toList();
}

/// Lê o elenco colado da planilha (Excel ou Google Planilhas).
///
/// Uma linha por pessoa, colunas nesta ordem (tabulação, ponto e vírgula ou
/// vírgula): **Time · Número · Nome · Posição · Função**.
/// - Time: sigla (SAM) ou nome (Sampdoria).
/// - Posição: "Goleiro"/"G" ou "Linha"/"L" (vazio = linha).
/// - Função: "Atleta" (padrão), "Técnico" ou "Dirigente". Dirigente com
///   número é também atleta.
/// Linha de cabeçalho é ignorada.
class ImportarElencos {
  /// Mínimo de atletas por elenco (art. 1).
  static const minimoAtletas = 12;

  ResultadoImportacao call(String texto, List<Time> times) {
    String norm(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàâã]'), 'a')
        .replaceAll(RegExp('[éê]'), 'e')
        .replaceAll('í', 'i')
        .replaceAll(RegExp('[óôõ]'), 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    Time? acharTime(String s) {
      final n = norm(s);
      for (final t in times) {
        if (norm(t.sigla) == n || norm(t.nome) == n || norm(t.id) == n) return t;
      }
      return null;
    }

    final porTime = <String, List<Pessoa>>{};
    final ignoradas = <int, String>{};
    final linhas = texto.split(RegExp(r'\r?\n'));

    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.trim().isEmpty) continue;
      final sep = linha.contains('\t') ? '\t' : (linha.contains(';') ? ';' : ',');
      final c = linha.split(sep).map((x) => x.trim()).toList();
      while (c.length < 5) {
        c.add('');
      }
      final numeroLinha = i + 1;

      if (norm(c[0]) == 'time') continue; // cabeçalho
      final time = acharTime(c[0]);
      if (time == null) {
        ignoradas[numeroLinha] = 'Time "${c[0]}" não está entre os times da temporada.';
        continue;
      }
      final nome = c[2];
      if (nome.isEmpty) {
        ignoradas[numeroLinha] = 'Sem nome.';
        continue;
      }
      final numero = int.tryParse(c[1]);
      if (c[1].isNotEmpty && (numero == null || numero < 1 || numero > 99)) {
        ignoradas[numeroLinha] = 'Número "${c[1]}" inválido (use 1 a 99).';
        continue;
      }
      final posicao = norm(c[3]);
      final funcao = norm(c[4]);
      final tecnico = funcao.startsWith('tec');
      final dirigente = funcao.startsWith('dir');

      if (!tecnico && !dirigente && numero == null) {
        ignoradas[numeroLinha] = 'Atleta sem número.';
        continue;
      }

      final id = tecnico
          ? '${time.id.toLowerCase()}-tecnico'
          : numero == null
          ? '${time.id.toLowerCase()}-dirigente'
          : '${time.id.toLowerCase()}-$numero';

      porTime
          .putIfAbsent(time.id, () => [])
          .add(
            Pessoa(
              id: id,
              nome: _capitalizar(nome),
              timeId: time.id,
              funcao: tecnico ? Funcao.tecnico : Funcao.atleta,
              numero: tecnico ? null : numero,
              goleiro: !tecnico && (posicao == 'g' || posicao.startsWith('gol')),
              dirigente: dirigente,
            ),
          );
    }

    final conferencias = <ConferenciaTime>[];
    for (final t in times) {
      final pessoas = porTime[t.id];
      if (pessoas == null) continue;
      final erros = <String>[];
      final avisos = <String>[];

      final atletas = pessoas.where((p) => p.funcao == Funcao.atleta && p.numero != null).toList();
      final numeros = <int>{};
      for (final a in atletas) {
        if (!numeros.add(a.numero!)) erros.add('Número ${a.numero} repetido (art. 47).');
      }
      if (pessoas.where((p) => p.funcao == Funcao.tecnico).length > 1) {
        erros.add('Mais de um técnico.');
      }
      final goleiros = atletas.where((p) => p.goleiro).length;
      if (goleiros != 1) {
        erros.add('$goleiros goleiros. O elenco precisa de exatamente 1 goleiro inscrito.');
      }
      if (atletas.length < minimoAtletas) {
        avisos.add(
          '${atletas.length} atletas. O regulamento pede pelo menos $minimoAtletas (art. 1).',
        );
      }
      if (!pessoas.any((p) => p.dirigente)) avisos.add('Sem dirigente marcado.');
      if (!pessoas.any((p) => p.funcao == Funcao.tecnico)) avisos.add('Sem técnico.');

      conferencias.add(ConferenciaTime(t, pessoas, erros, avisos));
    }
    return ResultadoImportacao(conferencias, ignoradas);
  }

  /// "JOÃO DA SILVA" → "João da Silva".
  static String _capitalizar(String nome) {
    const minusculas = {'da', 'de', 'do', 'das', 'dos', 'e'};
    return nome
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) {
          final l = p.toLowerCase();
          if (minusculas.contains(l)) return l;
          return l[0].toUpperCase() + l.substring(1);
        })
        .join(' ');
  }
}
