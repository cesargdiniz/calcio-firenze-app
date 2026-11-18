import 'package:calcio_regras/calcio_regras.dart';
import 'package:test/test.dart';

var _dia = 0;

Partida _jogo(Sumula? sumula, {int turno = 1}) => Partida(
  id: 'j${++_dia}',
  turno: turno,
  fase: Fase.classificatoria,
  mandanteId: 'SAM',
  visitanteId: 'INT',
  inicio: DateTime(2027, 2, 1).add(Duration(days: _dia)),
  sumula: sumula,
);

CartaoAplicado _c(String pessoa, TipoCartao tipo, {String time = 'SAM', Funcao funcao = Funcao.atleta}) =>
    CartaoAplicado(pessoaId: pessoa, timeId: time, tipo: tipo, funcao: funcao);

const _a = TipoCartao.amarelo;
const _2a = TipoCartao.segundoAmarelo;
const _v = TipoCartao.vermelho;

void main() {
  group('cartões por pessoa', () {
    final partidas = [
      _jogo(Sumula(cartoes: [_c('ana', _a), _c('bia', _a), _c('caio', _v, time: 'INT')])),
      _jogo(Sumula(cartoes: [_c('ana', _a), _c('ana', _2a), _c('bia', _a), _c('bia', _v)])),
      _jogo(Sumula(cartoes: [_c('davi', _a, funcao: Funcao.tecnico)])),
    ];

    test('2º amarelo conta como dois amarelos e um vermelho (art. 67)', () {
      final ana = cartoesPorPessoa(partidas).firstWhere((c) => c.pessoaId == 'ana');
      // 1 amarelo no 1º jogo + 2 amarelos no jogo do 2º amarelo.
      expect((ana.amarelos, ana.vermelhos, ana.total), (3, 1, 4));
    });

    test('amarelo e vermelho direto no mesmo jogo contam os dois (art. 73.1)', () {
      final bia = cartoesPorPessoa(partidas).firstWhere((c) => c.pessoaId == 'bia');
      expect((bia.amarelos, bia.vermelhos), (2, 1));
    });

    test('técnicos entram, com a função indicada', () {
      final davi = cartoesPorPessoa(partidas).firstWhere((c) => c.pessoaId == 'davi');
      expect(davi.funcao, Funcao.tecnico);
      expect(davi.amarelos, 1);
    });

    test('cada critério ordena e filtra pela própria contagem', () {
      List<(String, int)> lista(CriterioCartoes c) => [
        for (final x in cartoesPorPessoa(partidas, criterio: c))
          (
            x.pessoaId,
            switch (c) {
              CriterioCartoes.amarelos => x.amarelos,
              CriterioCartoes.vermelhos => x.vermelhos,
              CriterioCartoes.todos => x.total,
            },
          ),
      ];
      expect(lista(CriterioCartoes.amarelos), [('ana', 3), ('bia', 2), ('davi', 1)]);
      expect(lista(CriterioCartoes.vermelhos), [('ana', 1), ('bia', 1), ('caio', 1)]);
      expect(lista(CriterioCartoes.todos), [('ana', 4), ('bia', 3), ('caio', 1), ('davi', 1)]);
    });

    test('no total, mais vermelhos desempata; empate completo divide a posição', () {
      final todos = cartoesPorPessoa(partidas);
      // caio (1 vermelho) fica à frente de davi (1 amarelo).
      expect([for (final x in todos) x.posicao], [1, 2, 3, 4]);
      final vermelhos = cartoesPorPessoa(partidas, criterio: CriterioCartoes.vermelhos);
      expect([for (final x in vermelhos) x.posicao], [1, 1, 1]);
    });

    test('o turno filtra as partidas', () {
      final dois = [..._jogoTurno2(), ...partidas];
      expect(cartoesPorPessoa(dois, turno: 2).single.pessoaId, 'zeca');
      expect(cartoesPorPessoa(dois, turno: 1).map((x) => x.pessoaId), isNot(contains('zeca')));
    });
  });

  group('melhor da partida', () {
    MelhorDaPartida m(String pessoa) => MelhorDaPartida(pessoaId: pessoa, timeId: 'SAM');

    test('conta as escolhas e ignora jogo de W.O. e sem escolha', () {
      final lista = melhoresDaPartida([
        _jogo(Sumula(melhorDaPartida: m('ana'))),
        _jogo(Sumula(melhorDaPartida: m('ana'))),
        _jogo(Sumula(melhorDaPartida: m('bia'))),
        _jogo(Sumula(ausenteWo: 'INT', melhorDaPartida: m('bia'))),
        _jogo(const Sumula()),
      ]);
      expect([for (final x in lista) (x.pessoaId, x.vezes, x.posicao)], [
        ('ana', 2, 1),
        ('bia', 1, 2),
      ]);
    });
  });

  group('melhor ataque e defesa', () {
    LinhaClassificacao linha(String time, int pro, int contra, {int jogos = 3}) =>
        LinhaClassificacao(time)
          ..jogos = jogos
          ..golsPro = pro
          ..golsContra = contra;

    final tabela = [
      linha('FIO', 8, 2),
      linha('COM', 8, 5),
      linha('INT', 5, 2),
      linha('SAM', 1, 9),
      linha('NOV', 0, 0, jogos: 0),
    ];

    test('ataque: mais gols marcados primeiro; empate divide a posição', () {
      expect([for (final g in melhorAtaque(tabela)) (g.timeId, g.gols, g.posicao)], [
        ('FIO', 8, 1),
        ('COM', 8, 1),
        ('INT', 5, 3),
        ('SAM', 1, 4),
      ]);
    });

    test('defesa: menos gols sofridos primeiro; time sem jogos fica de fora', () {
      expect([for (final g in melhorDefesa(tabela)) (g.timeId, g.gols, g.posicao)], [
        ('FIO', 2, 1),
        ('INT', 2, 1),
        ('COM', 5, 3),
        ('SAM', 9, 4),
      ]);
    });

    test('os gols do W.O. contam, porque vêm da tabela (art. 75)', () {
      final tabelaReal = classificacaoDoTurno(
        turno: 1,
        times: const ['SAM', 'INT'],
        partidas: [_jogo(const Sumula(ausenteWo: 'INT'))],
      );
      expect(melhorAtaque(tabelaReal).first.timeId, 'SAM');
      expect(melhorAtaque(tabelaReal).first.gols, 6);
      expect(melhorDefesa(tabelaReal).last.gols, 6);
    });
  });
}

List<Partida> _jogoTurno2() => [
  _jogo(Sumula(cartoes: [_c('zeca', _a)]), turno: 2),
];
