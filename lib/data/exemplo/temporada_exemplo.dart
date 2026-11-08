import 'package:calcio_regras/calcio_regras.dart';

import '../../domain/entities/temporada.dart';
import '../../domain/repositories/temporada_repository.dart';

/// Temporada de exemplo, para ver o app funcionando antes do Firebase.
///
/// Turno 1 com as 9 rodadas no calendário e súmulas lançadas até a Rodada 3.
/// Os nomes de atletas são fictícios.
class TemporadaExemploRepository implements TemporadaRepository {
  /// "Agora" coerente com os dados: dia seguinte ao último jogo da Rodada 3.
  static final agora = DateTime(2027, 2, 26, 10);

  @override
  Stream<DadosTemporada> observar() => Stream.value(montarTemporadaExemplo());
}

const _times = [
  Time(id: 'INT', nome: 'Inter', sigla: 'INT', cor: 0xFF0A3D91),
  Time(id: 'FIO', nome: 'Fiorentina', sigla: 'FIO', cor: 0xFF5B2A86),
  Time(id: 'SAM', nome: 'Sampdoria', sigla: 'SAM', cor: 0xFF1B5CC1),
  Time(id: 'FOG', nome: 'AC Foggia', sigla: 'FOG', cor: 0xFFC8102E),
  Time(id: 'NAP', nome: 'Napoli', sigla: 'NAP', cor: 0xFF12A0D7),
  Time(id: 'ROM', nome: 'Roma', sigla: 'ROM', cor: 0xFF8E1F2F),
  Time(id: 'UDI', nome: 'Udinese', sigla: 'UDI', cor: 0xFF2B2B2B),
  Time(id: 'MON', nome: 'Monza', sigla: 'MON', cor: 0xFFD7263D),
  Time(id: 'CAS', nome: 'Casale', sigla: 'CAS', cor: 0xFF6E6E6E),
  Time(id: 'SAS', nome: 'Sassuolo', sigla: 'SAS', cor: 0xFF00A752),
];

/// Atletas com papel na história de exemplo (cartões e suspensões).
const _destaques = [
  Pessoa(id: 'marcos-lima', nome: 'Marcos Lima', timeId: 'UDI', numero: 5),
  Pessoa(id: 'paulo-ribeiro', nome: 'Paulo Ribeiro', timeId: 'CAS', numero: 8),
  Pessoa(id: 'ricardo-alves', nome: 'Ricardo Alves', timeId: 'MON', numero: 6),
  Pessoa(id: 'fabio-costa', nome: 'Fábio Costa', timeId: 'ROM', numero: 4),
  Pessoa(id: 'tiago-moura', nome: 'Tiago Moura', timeId: 'NAP', numero: 10),
  Pessoa(id: 'rafael-souza', nome: 'Rafael Souza', timeId: 'SAM', numero: 7),
  Pessoa(id: 'leandro-paiva', nome: 'Leandro Paiva', timeId: 'INT', numero: 3),
  Pessoa(id: 'helio-ramos', nome: 'Hélio Ramos', timeId: 'SAM', funcao: Funcao.tecnico),
];

const _nomes = [
  'André',
  'Bruno',
  'Caio',
  'Daniel',
  'Eduardo',
  'Felipe',
  'Gustavo',
  'Henrique',
  'Igor',
  'João',
  'Lucas',
  'Mateus',
  'Nelson',
  'Otávio',
  'Pedro',
  'Renato',
  'Sérgio',
  'Thiago',
  'Vinícius',
  'Wagner',
  'Alex',
  'Diego',
  'Fernando',
  'Gilberto',
];
const _sobrenomes = [
  'Almeida',
  'Barbosa',
  'Cardoso',
  'Dias',
  'Esteves',
  'Ferreira',
  'Gomes',
  'Holanda',
  'Lacerda',
  'Martins',
  'Nogueira',
  'Oliveira',
  'Pereira',
  'Queiroz',
  'Rocha',
  'Santana',
  'Teixeira',
  'Vieira',
  'Xavier',
  'Moreira',
  'Campos',
  'Freitas',
  'Pinto',
  'Rezende',
  'Nunes',
];

/// Elencos completos: 12 atletas (o nº 1 é o goleiro), técnico e dirigente.
List<Pessoa> _elencos() {
  final pessoas = <Pessoa>[..._destaques];
  var k = 0;
  String proximoNome() {
    final n = '${_nomes[k % _nomes.length]} ${_sobrenomes[(k * 7 + 3) % _sobrenomes.length]}';
    k++;
    return n;
  }

  for (final t in _times) {
    final ocupados = {
      for (final p in _destaques)
        if (p.timeId == t.id && p.numero != null) p.numero!,
    };
    var atletas = pessoas.where((p) => p.timeId == t.id && p.funcao == Funcao.atleta).length;
    for (var numero = 1; atletas < 12; numero++) {
      if (ocupados.contains(numero)) continue;
      pessoas.add(
        Pessoa(
          id: '${t.id.toLowerCase()}-$numero',
          nome: proximoNome(),
          timeId: t.id,
          numero: numero,
          goleiro: numero == 1,
          // O nº 9 de cada time é também o dirigente.
          dirigente: numero == 9,
        ),
      );
      atletas++;
    }
    if (!pessoas.any((p) => p.timeId == t.id && p.funcao == Funcao.tecnico)) {
      pessoas.add(
        Pessoa(
          id: '${t.id.toLowerCase()}-tecnico',
          nome: proximoNome(),
          timeId: t.id,
          funcao: Funcao.tecnico,
        ),
      );
    }
  }
  return pessoas;
}

/// Calendário pelo método do círculo: 10 times, 9 rodadas, só ida (art. 16).
List<(String, String)> _confrontos(int rodada) {
  final ids = _times.map((t) => t.id).toList();
  final fixo = ids.first;
  final roda = ids.sublist(1);
  final r = rodada - 1;
  final girado = [...roda.sublist(r), ...roda.sublist(0, r)];
  final lista = [fixo, ...girado];
  return [
    for (var i = 0; i < 5; i++) rodada.isEven ? (lista[i], lista[9 - i]) : (lista[9 - i], lista[i]),
  ];
}

DadosTemporada montarTemporadaExemplo() {
  final partidas = <Partida>[];
  const dias = [0, 2, 3, 7, 9];
  for (var rodada = 1; rodada <= 9; rodada++) {
    final base = DateTime(2027, 1, 19, 20, 30).add(Duration(days: 14 * (rodada - 1)));
    final jogos = _confrontos(rodada);
    for (var i = 0; i < jogos.length; i++) {
      partidas.add(
        Partida(
          id: 'r$rodada-${i + 1}',
          turno: 1,
          fase: Fase.classificatoria,
          rodada: rodada,
          mandanteId: jogos[i].$1,
          visitanteId: jogos[i].$2,
          inicio: base.add(Duration(days: dias[i])),
        ),
      );
    }
  }

  // Placar determinístico para as Rodadas 1 a 3.
  var semente = 7;
  int gols() {
    semente = (semente * 1103515245 + 12345) & 0x7fffffff;
    return (semente >> 16) % 4;
  }

  final cartoes = <String, List<CartaoAplicado>>{};
  void cartao(
    int rodada,
    String pessoa,
    String time,
    TipoCartao tipo, {
    Funcao funcao = Funcao.atleta,
  }) {
    final p = partidas.firstWhere((p) => p.rodada == rodada && p.envolve(time));
    cartoes
        .putIfAbsent(p.id, () => [])
        .add(CartaoAplicado(pessoaId: pessoa, timeId: time, tipo: tipo, funcao: funcao));
  }

  cartao(1, 'paulo-ribeiro', 'CAS', TipoCartao.amarelo);
  cartao(2, 'paulo-ribeiro', 'CAS', TipoCartao.amarelo);
  cartao(3, 'paulo-ribeiro', 'CAS', TipoCartao.amarelo);
  cartao(1, 'fabio-costa', 'ROM', TipoCartao.amarelo);
  cartao(2, 'fabio-costa', 'ROM', TipoCartao.amarelo);
  cartao(2, 'tiago-moura', 'NAP', TipoCartao.amarelo);
  cartao(3, 'tiago-moura', 'NAP', TipoCartao.amarelo);
  cartao(3, 'marcos-lima', 'UDI', TipoCartao.vermelho);
  cartao(3, 'rafael-souza', 'SAM', TipoCartao.amarelo);
  cartao(3, 'leandro-paiva', 'INT', TipoCartao.amarelo);
  cartao(2, 'helio-ramos', 'SAM', TipoCartao.amarelo, funcao: Funcao.tecnico);

  for (var i = 0; i < partidas.length; i++) {
    final p = partidas[i];
    if (p.rodada! > 3) continue;
    partidas[i] = p.comSumula(
      Sumula(golsMandante: gols(), golsVisitante: gols(), cartoes: cartoes[p.id] ?? const []),
    );
  }

  final jogoMonzaR3 = partidas.firstWhere((p) => p.rodada == 3 && p.envolve('MON'));

  return DadosTemporada(
    id: 'master-2027',
    nome: 'Master · Temporada 2027',
    local: 'Arena Gugu',
    times: _times,
    pessoas: _elencos(),
    partidas: partidas,
    decisoes: [
      DecisaoDisciplinar(
        id: 'dec-1',
        pessoaId: 'ricardo-alves',
        timeId: 'MON',
        partidaOrigemId: jogoMonzaR3.id,
        motivo: 'Análise de vídeo · art. 87 · grau médio',
        jogosSuspensao: 2,
      ),
    ],
  );
}
