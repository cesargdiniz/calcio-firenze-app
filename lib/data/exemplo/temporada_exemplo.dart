import 'package:calcio_regras/calcio_regras.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/temporada.dart';
import '../../domain/repositories/temporada_repository.dart';

/// Temporada de exemplo, para ver o app funcionando antes do Firebase.
///
/// Turno 1 com as 9 rodadas no calendário e súmulas lançadas até a Rodada 3.
/// Os nomes de atletas são fictícios.
class TemporadaExemploRepository implements TemporadaRepository {
  /// "Agora" coerente com os dados: dia seguinte ao último jogo da Rodada 3.
  static final agora = DateTime(2027, 2, 26, 10);

  /// Só o Master tem exemplo; as outras categorias aparecem vazias.
  @override
  Stream<DadosTemporada> observar(String temporadaId) {
    final exemplo = montarTemporadaExemplo();
    if (temporadaId == exemplo.id) return Stream.value(exemplo);
    final c = Categoria.deTemporada(temporadaId) ?? Categoria.master;
    return Stream.value(
      DadosTemporada(
        id: temporadaId,
        nome: c.titulo,
        local: exemplo.local,
        times: const [],
        pessoas: const [],
        partidas: const [],
      ),
    );
  }
}

/// Os 10 clubes do Master 2027 (cores aproximadas das camisas; a Organização
/// ajusta cor e escudo em Gestão › Times da temporada).
const timesMaster2027 = [
  Time(id: 'INT', nome: 'Inter', sigla: 'INT', cor: 0xFF0A3D91),
  Time(id: 'FIO', nome: 'Fiori', sigla: 'FIO', cor: 0xFF5B2A86),
  Time(id: 'SAM', nome: 'Sampdoria', sigla: 'SAM', cor: 0xFF1B5CC1),
  Time(id: 'FOG', nome: 'Foggia', sigla: 'FOG', cor: 0xFFC8102E),
  Time(id: 'BEN', nome: 'Benevento', sigla: 'BEN', cor: 0xFFD9A400),
  Time(id: 'MIL', nome: 'Milan', sigla: 'MIL', cor: 0xFF9E1B22),
  Time(id: 'UDI', nome: 'Udinese', sigla: 'UDI', cor: 0xFF5A5A5A),
  Time(id: 'COM', nome: 'Como 1907', sigla: 'COM', cor: 0xFF2E6DB4),
  Time(id: 'JUV', nome: 'Juventus', sigla: 'JUV', cor: 0xFF111111),
  Time(id: 'SAS', nome: 'Sassuolo', sigla: 'SAS', cor: 0xFF00A752),
];

/// Atletas com papel na história de exemplo (cartões e suspensões).
const _destaques = [
  Pessoa(id: 'marcos-lima', nome: 'Marcos Lima', timeId: 'UDI', numero: 5),
  Pessoa(id: 'paulo-ribeiro', nome: 'Paulo Ribeiro', timeId: 'JUV', numero: 8),
  Pessoa(id: 'ricardo-alves', nome: 'Ricardo Alves', timeId: 'COM', numero: 6),
  Pessoa(id: 'fabio-costa', nome: 'Fábio Costa', timeId: 'MIL', numero: 4),
  Pessoa(id: 'tiago-moura', nome: 'Tiago Moura', timeId: 'BEN', numero: 10),
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

  for (final t in timesMaster2027) {
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
  final ids = timesMaster2027.map((t) => t.id).toList();
  final fixo = ids.first;
  final roda = ids.sublist(1);
  final r = rodada - 1;
  final girado = [...roda.sublist(r), ...roda.sublist(0, r)];
  final lista = [fixo, ...girado];
  return [
    for (var i = 0; i < 5; i++) rodada.isEven ? (lista[i], lista[9 - i]) : (lista[9 - i], lista[i]),
  ];
}

/// [demonstracao] falso trata o exemplo como temporada real (capturas de
/// tela e testes que cadastram dados).
DadosTemporada montarTemporadaExemplo({bool demonstracao = true}) {
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

  cartao(1, 'paulo-ribeiro', 'JUV', TipoCartao.amarelo);
  cartao(2, 'paulo-ribeiro', 'JUV', TipoCartao.amarelo);
  cartao(3, 'paulo-ribeiro', 'JUV', TipoCartao.amarelo);
  cartao(1, 'fabio-costa', 'MIL', TipoCartao.amarelo);
  cartao(2, 'fabio-costa', 'MIL', TipoCartao.amarelo);
  cartao(2, 'tiago-moura', 'BEN', TipoCartao.amarelo);
  cartao(3, 'tiago-moura', 'BEN', TipoCartao.amarelo);
  cartao(3, 'marcos-lima', 'UDI', TipoCartao.vermelho);
  cartao(3, 'rafael-souza', 'SAM', TipoCartao.amarelo);
  cartao(3, 'leandro-paiva', 'INT', TipoCartao.amarelo);
  cartao(2, 'helio-ramos', 'SAM', TipoCartao.amarelo, funcao: Funcao.tecnico);

  // Autores dos gols: sempre entre os jogadores de linha, com alguns
  // marcando mais que os outros, para a artilharia ter um líder.
  final linha = <String, List<String>>{};
  for (final x in _elencos()) {
    if (x.funcao == Funcao.atleta && !x.goleiro) linha.putIfAbsent(x.timeId, () => []).add(x.id);
  }
  const preferencia = [0, 0, 1, 2, 0, 3, 1, 4];
  List<Gol> autores(Partida p, String timeId, int quantos, int indice) => [
    for (var k = 0; k < quantos; k++)
      Gol(
        timeId: timeId,
        autorId: linha[timeId]![preferencia[(p.rodada! * 5 + indice * 3 + k) % preferencia.length]],
        tempo: 1 + k % 2,
      ),
  ];

  for (var i = 0; i < partidas.length; i++) {
    final p = partidas[i];
    if (p.rodada! > 3) continue;
    final doMandante = gols();
    final doVisitante = gols();
    final listaGols = [
      ...autores(p, p.mandanteId, doMandante, i),
      ...autores(p, p.visitanteId, doVisitante, i + 1),
    ];
    // Melhor da partida: o primeiro a marcar pelo vencedor; no empate, o
    // primeiro a marcar no jogo; no 0 x 0, o goleiro do mandante.
    final vencedor = doMandante == doVisitante
        ? null
        : (doMandante > doVisitante ? p.mandanteId : p.visitanteId);
    final destaque =
        listaGols.where((g) => g.timeId == vencedor).firstOrNull ?? listaGols.firstOrNull;
    final goleiro = _elencos().firstWhere((x) => x.timeId == p.mandanteId && x.goleiro);
    partidas[i] = p.comSumula(
      Sumula(
        golsMandante: doMandante,
        golsVisitante: doVisitante,
        gols: listaGols,
        cartoes: cartoes[p.id] ?? const [],
        melhorDaPartida: destaque == null
            ? MelhorDaPartida(pessoaId: goleiro.id, timeId: goleiro.timeId)
            : MelhorDaPartida(pessoaId: destaque.autorId!, timeId: destaque.timeId),
      ),
    );
  }

  final jogoComo 1907R3 = partidas.firstWhere((p) => p.rodada == 3 && p.envolve('COM'));

  return DadosTemporada(
    id: 'master-2027',
    demonstracao: demonstracao,
    relogio: TemporadaExemploRepository.agora,
    nome: 'Master · Temporada 2027',
    local: 'Arena Gugu',
    times: timesMaster2027,
    pessoas: _elencos(),
    partidas: partidas,
    decisoes: [
      DecisaoDisciplinar(
        id: 'dec-1',
        pessoaId: 'ricardo-alves',
        timeId: 'COM',
        partidaOrigemId: jogoComo 1907R3.id,
        motivo: 'Análise de vídeo · art. 87 · grau médio',
        jogosSuspensao: 2,
      ),
    ],
  );
}
