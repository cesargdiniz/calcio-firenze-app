import 'package:calcio_regras/calcio_regras.dart';

/// Clube da temporada (cadastrado em "Times da temporada").
class Time {
  final String id;
  final String nome;
  final String sigla;

  /// Cor do time em ARGB (0xFFRRGGBB). Fica como int para o domínio não
  /// depender do Flutter.
  final int cor;
  final String? escudoUrl;

  const Time({
    required this.id,
    required this.nome,
    required this.sigla,
    required this.cor,
    this.escudoUrl,
  });
}

/// Atleta, técnico ou dirigente inscrito num elenco.
class Pessoa {
  final String id;
  final String nome;
  final String timeId;
  final Funcao funcao;
  final int? numero;
  final bool goleiro;

  /// Dirigente do time na temporada (pode também ser atleta).
  final bool dirigente;

  const Pessoa({
    required this.id,
    required this.nome,
    required this.timeId,
    this.funcao = Funcao.atleta,
    this.numero,
    this.goleiro = false,
    this.dirigente = false,
  });
}

/// Tudo o que o app precisa saber de uma temporada para calcular as telas.
class DadosTemporada {
  /// Ex.: "master-2027".
  final String id;
  final String nome;
  final String local;
  final List<Time> times;
  final List<Pessoa> pessoas;
  final List<Partida> partidas;
  final List<DecisaoDisciplinar> decisoes;
  final List<Pagamento> pagamentos;
  final List<AjustePontos> ajustes;
  final List<String> ordemSorteio;

  /// Verdadeiro enquanto o app mostra a temporada de exemplo (antes de a
  /// Organização importar os elencos reais).
  final bool demonstracao;

  const DadosTemporada({
    required this.id,
    required this.nome,
    required this.local,
    required this.times,
    required this.pessoas,
    required this.partidas,
    this.decisoes = const [],
    this.pagamentos = const [],
    this.ajustes = const [],
    this.ordemSorteio = const [],
    this.demonstracao = false,
  });
}
