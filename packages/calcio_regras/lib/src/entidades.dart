/// Entidades do campeonato. Dart puro: nada de Flutter, JSON ou Firebase aqui.
library;

/// Fase de uma partida (art. 16).
enum Fase {
  classificatoria,
  quartas,
  semifinal,
  finalTurno,

  /// Art. 16.4 — só existe se os campeões dos dois turnos forem diferentes.
  grandeFinal;

  bool get eliminatoria => this != Fase.classificatoria;
}

/// Quem recebeu o cartão. Técnico paga, mas não é suspenso (arts. 69 e 73).
enum Funcao { atleta, tecnico }

enum TipoCartao {
  amarelo,

  /// Segundo amarelo na mesma partida: vira vermelho (art. 67).
  segundoAmarelo,

  /// Vermelho direto (arts. 71–73).
  vermelho;

  bool get expulsao => this != TipoCartao.amarelo;
}

class CartaoAplicado {
  final String pessoaId;
  final String timeId;
  final Funcao funcao;
  final TipoCartao tipo;

  const CartaoAplicado({
    required this.pessoaId,
    required this.timeId,
    required this.tipo,
    this.funcao = Funcao.atleta,
  });
}

class Gol {
  final String timeId;

  /// Autor do gol. Em gol contra, é o atleta do time adversário.
  final String? autorId;
  final bool contra;
  final int tempo;

  const Gol({required this.timeId, this.autorId, this.contra = false, this.tempo = 1});
}

/// Resultado da disputa de pênaltis (só no mata-mata).
class Penaltis {
  final int mandante;
  final int visitante;
  const Penaltis(this.mandante, this.visitante);
}

/// Súmula lançada pela Organização depois do jogo.
class Sumula {
  final int golsMandante;
  final int golsVisitante;

  /// Time que não compareceu (art. 75). Quando preenchido, o placar
  /// registrado é ignorado e vale 6 x 0 para o time presente.
  final String? ausenteWo;
  final Penaltis? penaltis;
  final List<CartaoAplicado> cartoes;
  final List<Gol> gols;

  /// Times que perdem os pontos da partida: atleta que assinou e não jogou
  /// (art. 43.1), atleta ou técnico com débito em campo (art. 68), equipe
  /// reduzida a menos de 4 atletas (art. 4).
  final Set<String> timesSemPontos;

  const Sumula({
    this.golsMandante = 0,
    this.golsVisitante = 0,
    this.ausenteWo,
    this.penaltis,
    this.cartoes = const [],
    this.gols = const [],
    this.timesSemPontos = const {},
  });
}

class Partida {
  final String id;

  /// 1 ou 2. A grande final usa 0.
  final int turno;
  final Fase fase;
  final int? rodada;
  final String mandanteId;
  final String visitanteId;
  final DateTime inicio;

  /// Nula enquanto a súmula não foi encerrada.
  final Sumula? sumula;

  const Partida({
    required this.id,
    required this.turno,
    required this.fase,
    required this.mandanteId,
    required this.visitanteId,
    required this.inicio,
    this.rodada,
    this.sumula,
  });

  bool get encerrada => sumula != null;
  bool envolve(String timeId) => mandanteId == timeId || visitanteId == timeId;
  String adversario(String timeId) => timeId == mandanteId ? visitanteId : mandanteId;

  Partida comSumula(Sumula s) => Partida(
    id: id,
    turno: turno,
    fase: fase,
    rodada: rodada,
    mandanteId: mandanteId,
    visitanteId: visitanteId,
    inicio: inicio,
    sumula: s,
  );
}

/// Perda ou ajuste de pontos decidido pela Governança.
class AjustePontos {
  final String timeId;
  final int turno;
  final int pontos;
  final String motivo;

  const AjustePontos({
    required this.timeId,
    required this.turno,
    required this.pontos,
    required this.motivo,
  });
}

/// Decisão da Governança sobre uma pessoa: suspensão e/ou multa (arts. 86–88).
class DecisaoDisciplinar {
  final String id;
  final String pessoaId;
  final String timeId;

  /// Partida a partir da qual a suspensão começa a contar (a seguinte a ela).
  final String partidaOrigemId;
  final int jogosSuspensao;

  /// Em centavos.
  final int multa;
  final String motivo;

  const DecisaoDisciplinar({
    required this.id,
    required this.pessoaId,
    required this.timeId,
    required this.partidaOrigemId,
    required this.motivo,
    this.jogosSuspensao = 0,
    this.multa = 0,
  });
}

/// Registro de quitação feito pela Organização.
class Pagamento {
  final String pendenciaId;
  final DateTime pagoEm;
  const Pagamento(this.pendenciaId, this.pagoEm);
}
