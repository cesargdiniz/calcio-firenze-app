import 'package:calcio_regras/calcio_regras.dart';
import 'package:test/test.dart';

Partida _jogo(String id, Sumula? sumula, {int turno = 1, Fase fase = Fase.classificatoria}) =>
    Partida(
      id: id,
      turno: turno,
      fase: fase,
      mandanteId: 'SAM',
      visitanteId: 'INT',
      inicio: DateTime(2027, 2, int.parse(id.substring(1))),
      sumula: sumula,
    );

Gol _gol(String autor, {String time = 'SAM', bool contra = false}) =>
    Gol(timeId: time, autorId: autor, contra: contra);

void main() {
  test('soma os gols de cada jogador e ordena do maior para o menor', () {
    final lista = artilharia([
      _jogo('j1', Sumula(golsMandante: 3, gols: [_gol('ana'), _gol('ana'), _gol('bia')])),
      _jogo('j2', Sumula(golsMandante: 1, golsVisitante: 1, gols: [_gol('ana'), _gol('caio', time: 'INT')])),
    ]);
    expect([for (final a in lista) (a.pessoaId, a.gols)], [('ana', 3), ('bia', 1), ('caio', 1)]);
    expect(lista.last.timeId, 'INT');
  });

  test('empatados dividem a posição e a seguinte é pulada', () {
    final lista = artilharia([
      _jogo('j1', Sumula(golsMandante: 5, gols: [
        _gol('ana'), _gol('ana'), _gol('bia'), _gol('bia'), _gol('caio'),
      ])),
    ]);
    expect([for (final a in lista) a.posicao], [1, 1, 3]);
  });

  test('gols de W.O. não entram, mesmo que haja autores lançados (art. 75)', () {
    final lista = artilharia([
      _jogo('j1', Sumula(ausenteWo: 'INT', golsMandante: 6, gols: [for (var i = 0; i < 6; i++) _gol('ana')])),
      _jogo('j2', Sumula(golsMandante: 1, gols: [_gol('bia')])),
    ]);
    expect([for (final a in lista) a.pessoaId], ['bia']);
  });

  test('gol contra e gol sem autor não contam para ninguém', () {
    final lista = artilharia([
      _jogo('j1', Sumula(golsMandante: 3, gols: [
        _gol('ana'),
        _gol('zeca', contra: true),
        const Gol(timeId: 'SAM'),
      ])),
    ]);
    expect([for (final a in lista) (a.pessoaId, a.gols)], [('ana', 1)]);
  });

  test('jogo sem súmula não conta; o turno filtra as partidas', () {
    final partidas = [
      _jogo('j1', Sumula(golsMandante: 1, gols: [_gol('ana')])),
      _jogo('j2', Sumula(golsMandante: 2, gols: [_gol('ana'), _gol('bia')]), turno: 2),
      _jogo('j3', null),
    ];
    expect([for (final a in artilharia(partidas, turno: 1)) (a.pessoaId, a.gols)], [('ana', 1)]);
    expect(
      [for (final a in artilharia(partidas, turno: 2)) (a.pessoaId, a.gols)],
      [('ana', 1), ('bia', 1)],
    );
    expect(artilharia(partidas).first.gols, 2);
  });

  test('gols do mata-mata do turno entram na artilharia do turno', () {
    final lista = artilharia([
      _jogo('j1', Sumula(golsMandante: 1, gols: [_gol('ana')])),
      _jogo('j2', Sumula(golsMandante: 1, gols: [_gol('ana')]), fase: Fase.semifinal),
    ], turno: 1);
    expect(lista.single.gols, 2);
  });
}
