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

  /// Data em que deixou o elenco (demissão, desligamento, lesão ou troca de
  /// goleiro). Nula enquanto faz parte dele.
  final DateTime? saiuEm;

  const Pessoa({
    required this.id,
    required this.nome,
    required this.timeId,
    this.funcao = Funcao.atleta,
    this.numero,
    this.goleiro = false,
    this.dirigente = false,
    this.saiuEm,
  });

  bool get ativo => saiuEm == null;

  /// Fazia parte do elenco na data? (Súmulas de jogos anteriores à saída
  /// ainda podem citar a pessoa.)
  bool noElencoEm(DateTime quando) => saiuEm == null || quando.isBefore(saiuEm!);

  /// Cópia com a saída registrada, ou desfeita quando [quando] é nulo.
  Pessoa comSaida(DateTime? quando) => Pessoa(
    id: id,
    nome: nome,
    timeId: timeId,
    funcao: funcao,
    numero: numero,
    goleiro: goleiro,
    dirigente: dirigente,
    saiuEm: quando,
  );
}

/// Saídas de elenco previstas no regulamento (arts. 82 a 83.2).
enum TipoMovimentacao {
  /// Art. 82: rescisão pedida pelo atleta; ele vai para o Draft 2.
  demissao('Demissão'),

  /// Art. 83.2: o atleta deixa o Calcio e não retorna no 2º turno.
  desligamento('Desligamento'),

  /// Art. 83.2: lesão incapacitante comprovada por exame ou laudo.
  lesao('Lesão'),

  /// Arts. 83 e 83.1: o goleiro sai e outro entra no lugar.
  trocaGoleiro('Troca de goleiro');

  final String rotulo;
  const TipoMovimentacao(this.rotulo);
}

/// Motivos que permitem trocar o goleiro (art. 83).
enum MotivoTroca {
  lesao('Lesão incapacitante'),
  mudanca('Mudança de município');

  final String rotulo;
  const MotivoTroca(this.rotulo);
}

/// Registro de uma saída de elenco feito pela Organização.
class Movimentacao {
  final String id;
  final TipoMovimentacao tipo;
  final String pessoaId;
  final String timeId;

  /// Nome de quem saiu, guardado para o registro continuar legível mesmo
  /// depois de o elenco ser reimportado.
  final String nome;
  final DateTime data;

  /// Exame ou laudo apresentado à Organização (lesão).
  final bool laudo;

  /// Só na troca de goleiro.
  final MotivoTroca? motivoTroca;
  final String? substitutoId;
  final String? substitutoNome;
  final String? observacoes;

  const Movimentacao({
    required this.id,
    required this.tipo,
    required this.pessoaId,
    required this.timeId,
    required this.nome,
    required this.data,
    this.laudo = false,
    this.motivoTroca,
    this.substitutoId,
    this.substitutoNome,
    this.observacoes,
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

  /// Valores do regulamento em vigor na temporada (pontos, R\$, prazos).
  final Parametros parametros;

  /// Verdadeiro enquanto o app mostra a temporada de exemplo (antes de a
  /// Organização importar os elencos reais).
  final bool demonstracao;

  /// Relógio fixo da temporada de exemplo; nulo = hora atual.
  final DateTime? relogio;

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
    this.parametros = Parametros.master2027,
    this.demonstracao = false,
    this.relogio,
  });
}
