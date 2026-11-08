/// Valores do regulamento que podem mudar de temporada para temporada.
///
/// Ficam num lugar só para que a Organização possa ajustá-los em
/// "Regulamento e parâmetros" sem mexer no código.
class Parametros {
  /// Art. 42.
  final int pontosVitoria;
  final int pontosEmpate;
  final int pontosDerrota;

  /// Art. 66 — valor do cartão amarelo, em centavos.
  final int valorAmarelo;

  /// Arts. 67 e 72 — valor do cartão vermelho (inclusive por dois amarelos), em centavos.
  final int valorVermelho;

  /// Art. 69 — amarelos acumulados que geram 1 jogo de suspensão.
  final int amarelosParaSuspensao;

  /// Arts. 67 e 73 — jogos de suspensão por expulsão.
  final int jogosPorExpulsao;

  /// Arts. 68 e 73.7 — antecedência da quitação em relação à partida seguinte.
  final Duration prazoQuitacao;

  /// Art. 75 — placar e dedução do W.O.
  final int golsWo;
  final int deducaoWo;

  /// Art. 16 — times que passam para o mata-mata.
  final int classificadosMataMata;

  /// Art. 89 — clubes rebaixados por temporada.
  final int rebaixados;

  const Parametros({
    this.pontosVitoria = 3,
    this.pontosEmpate = 1,
    this.pontosDerrota = 0,
    this.valorAmarelo = 3000,
    this.valorVermelho = 5000,
    this.amarelosParaSuspensao = 3,
    this.jogosPorExpulsao = 1,
    this.prazoQuitacao = const Duration(hours: 24),
    this.golsWo = 6,
    this.deducaoWo = 3,
    this.classificadosMataMata = 6,
    this.rebaixados = 2,
  });

  static const master2027 = Parametros();
}
