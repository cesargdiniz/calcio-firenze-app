import 'package:calcio_regras/calcio_regras.dart';

/// Monta partidas de teste em dias seguidos a partir de 1/3/2027, 20:30.
class Calendario {
  var _dia = 0;
  final partidas = <Partida>[];

  Partida jogo(
    String mandante,
    String visitante, {
    int turno = 1,
    Fase fase = Fase.classificatoria,
    Sumula? sumula,
    int intervaloDias = 7,
  }) {
    final p = Partida(
      id: 'j${partidas.length + 1}',
      turno: turno,
      fase: fase,
      mandanteId: mandante,
      visitanteId: visitante,
      inicio: DateTime(2027, 3, 1, 20, 30).add(Duration(days: _dia)),
      sumula: sumula,
    );
    _dia += intervaloDias;
    partidas.add(p);
    return p;
  }
}

Sumula placar(
  int m,
  int v, {
  List<CartaoAplicado> cartoes = const [],
  Set<String> semPontos = const {},
  Penaltis? penaltis,
}) => Sumula(
  golsMandante: m,
  golsVisitante: v,
  cartoes: cartoes,
  timesSemPontos: semPontos,
  penaltis: penaltis,
);

CartaoAplicado amarelo(String pessoa, String time, {Funcao funcao = Funcao.atleta}) =>
    CartaoAplicado(pessoaId: pessoa, timeId: time, tipo: TipoCartao.amarelo, funcao: funcao);

CartaoAplicado segundoAmarelo(String pessoa, String time, {Funcao funcao = Funcao.atleta}) =>
    CartaoAplicado(pessoaId: pessoa, timeId: time, tipo: TipoCartao.segundoAmarelo, funcao: funcao);

CartaoAplicado vermelho(String pessoa, String time, {Funcao funcao = Funcao.atleta}) =>
    CartaoAplicado(pessoaId: pessoa, timeId: time, tipo: TipoCartao.vermelho, funcao: funcao);
