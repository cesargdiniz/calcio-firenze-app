import 'categoria.dart';

/// Posição no futebol society 2-2-1 (com goleiro).
enum PosicaoCampeao {
  goleiro('Goleiro', 'Goleiros'),
  zagueiro('Zagueiro', 'Zagueiros'),
  meia('Meia', 'Meias'),
  ataque('Ataque', 'Atacantes');

  final String nome;
  final String plural;
  const PosicaoCampeao(this.nome, this.plural);
}

/// Jogador do elenco campeão. Nos reservas a posição é opcional.
class JogadorCampeao {
  final String nome;
  final PosicaoCampeao? posicao;
  final bool titular;
  final int? numero;

  /// Nome curto no campinho (ex.: "M Jr"). Sem ele, vale [nome].
  final String? curto;

  const JogadorCampeao(this.nome, this.posicao, {this.titular = false, this.numero, this.curto});

  String get noCampo => curto ?? nome;
}

/// Premiação individual da temporada (melhor jogador, artilheiro...).
class PremioTemporada {
  final String premio;
  final String nome;

  /// Time do premiado, quando não é o campeão.
  final String? time;

  const PremioTemporada(this.premio, this.nome, {this.time});
}

/// Campeão de uma temporada e, quando cadastrado, o elenco do título.
class TituloTemporada {
  final int ano;
  final String campeao;
  final List<JogadorCampeao> elenco;
  final List<PremioTemporada> premios;

  /// Cor da camisa no campinho (ARGB), a mesma do escudo na tabela.
  final int? cor;

  /// Cor do número na camisa. Sem ela, branco.
  final int? corNumero;

  const TituloTemporada(
    this.ano,
    this.campeao, {
    this.elenco = const [],
    this.premios = const [],
    this.cor,
    this.corNumero,
  });

  List<JogadorCampeao> get titulares => [for (final j in elenco) if (j.titular) j];
  List<JogadorCampeao> get reservas => [for (final j in elenco) if (!j.titular) j];

  /// Titulares de uma posição, na ordem do cadastro.
  List<JogadorCampeao> titularesDe(PosicaoCampeao p) =>
      [for (final j in elenco) if (j.titular && j.posicao == p) j];
}

const _g = PosicaoCampeao.goleiro;
const _z = PosicaoCampeao.zagueiro;
const _m = PosicaoCampeao.meia;
const _a = PosicaoCampeao.ataque;

/// Campeões de cada categoria, da temporada mais recente para a mais antiga.
const campeoesPorCategoria = <Categoria, List<TituloTemporada>>{
  Categoria.master: [
    TituloTemporada(
      2025,
      'Inter',
      cor: 0xFF0A3D91,
      elenco: [
        JogadorCampeao('Galvão', _g, titular: true, numero: 1),
        JogadorCampeao('Berg', _z, titular: true, numero: 5),
        JogadorCampeao('Fabrício', _z, titular: true, numero: 16),
        JogadorCampeao('Marcelo Farias', _m, titular: true, numero: 11),
        JogadorCampeao('Rudd Anaisse', _m, titular: true, numero: 89, curto: 'Rudd'),
        JogadorCampeao('Carneiro', _a, titular: true, numero: 10),
        JogadorCampeao('Paulo Anaisse', null),
        JogadorCampeao('Marcelo Anaisse', null),
        JogadorCampeao('Odilon', null),
        JogadorCampeao('Dandara', null),
        JogadorCampeao('Haroldo Carneiro', null),
        JogadorCampeao('Enéas', null),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Rudd'),
        PremioTemporada('Artilheiro', 'Paulinho Macaco', time: 'Sampdoria'),
        PremioTemporada('Melhor goleiro', 'DiChapeu', time: 'Napoli'),
      ],
    ),
    TituloTemporada(
      2024,
      'Sampdoria',
      cor: 0xFF1B5CC1,
      elenco: [
        JogadorCampeao('Marcos Júnior', _g, titular: true, numero: 94, curto: 'M Jr'),
        JogadorCampeao('Marcelo Paiva', _z, titular: true, numero: 4, curto: 'Marcelo'),
        JogadorCampeao('Saymon', _z, titular: true, numero: 100),
        JogadorCampeao('Ferreira', _z),
        JogadorCampeao('Jamerson', _z),
        JogadorCampeao('Tenório', _z),
        JogadorCampeao('Marcio Pedreiro', _m, titular: true, numero: 10, curto: 'Pedreiro'),
        JogadorCampeao('Eddy', _m, titular: true, numero: 20),
        JogadorCampeao('Fran', _m),
        JogadorCampeao('Eurico', _m),
        JogadorCampeao('Paulinho Macaco', _a, titular: true, numero: 9, curto: 'Paulinho'),
        JogadorCampeao('Hélio', _a),
        JogadorCampeao('Alexandre Soberano', _a),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Paulinho'),
        PremioTemporada('Artilheiro', 'Paulinho'),
      ],
    ),
    TituloTemporada(
      2023,
      'Foggia',
      cor: 0xFFC8102E,
      elenco: [
        JogadorCampeao('Toupeira', _g, titular: true, numero: 1),
        JogadorCampeao('Cesar', _z, titular: true, numero: 3),
        JogadorCampeao('Netão', _z, titular: true, numero: 6),
        JogadorCampeao('Sagica', _z),
        JogadorCampeao('Rafael Melul', _z),
        JogadorCampeao('Pedro Reis', _m, titular: true, numero: 7),
        JogadorCampeao('Clayton', _m),
        JogadorCampeao('Klelio', _m, titular: true, numero: 10),
        JogadorCampeao('Dudu', _m),
        JogadorCampeao('Erick Pamplona', _a),
        JogadorCampeao('Daniel Diniz', _a, titular: true, numero: 9),
        JogadorCampeao('Ceará', _a),
        JogadorCampeao('Marcílio', _a),
        JogadorCampeao('Cleuby', null),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Klelio'),
        PremioTemporada('Artilheiro', 'Klelio'),
        PremioTemporada('Melhor goleiro', 'Carmona', time: 'Sampdoria'),
      ],
    ),
    TituloTemporada(
      2022,
      'Brasil',
      cor: 0xFFFFDF00,
      corNumero: 0xFF009C3B,
      elenco: [
        JogadorCampeao('Toupeira', _g, titular: true, numero: 1),
        JogadorCampeao('Olavo', _z, titular: true, numero: 5),
        JogadorCampeao('Maicon', _z, titular: true, numero: 4),
        JogadorCampeao('Cesar', _z),
        JogadorCampeao('Paulo Paiva', _z),
        JogadorCampeao('Silas', _z),
        JogadorCampeao('Claudio Barbalho', _z),
        JogadorCampeao('Fabio', _m, titular: true, numero: 7),
        JogadorCampeao('Macapá', _m, titular: true, numero: 10),
        JogadorCampeao('Clayton', _m),
        JogadorCampeao('Moraes', _m),
        JogadorCampeao('Marcelo Cai Cai', _a, titular: true, numero: 9),
        JogadorCampeao('Luizinho', _a),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Macapá'),
        PremioTemporada('Artilheiro', 'Nayron', time: 'França'),
        PremioTemporada('Melhor goleiro', 'Helielder', time: 'França'),
      ],
    ),
    TituloTemporada(
      2021,
      'Juventus',
      cor: 0xFF111111,
      elenco: [
        JogadorCampeao('Santana', _g, titular: true, numero: 1),
        JogadorCampeao('Sagica', _z, titular: true, numero: 3),
        JogadorCampeao('Robledo', _z, titular: true, numero: 4),
        JogadorCampeao('Ivo Barbosa', _z),
        JogadorCampeao('Antonio Marcos', _z),
        JogadorCampeao('Tárik Toda', _m, titular: true, numero: 8),
        // Atacante de origem; no time titular jogou no meio.
        JogadorCampeao('Renato Cajá', _m, titular: true, numero: 10),
        JogadorCampeao('Jhovan', _m),
        JogadorCampeao('Henrique Bezerra', _m),
        JogadorCampeao('Daniel Diniz', _a, titular: true, numero: 9),
        JogadorCampeao('Marcilio Guerreiro', _a),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Daniel Diniz'),
        PremioTemporada('Artilheiro', 'Daniel Diniz'),
      ],
    ),
  ],
  Categoria.livre: [
    // Números pela posição: 1 no gol, 3 e 4 na zaga, 8 e 10 no meio, 9 no ataque.
    TituloTemporada(
      2025,
      'Foggia',
      cor: 0xFFC8102E,
      elenco: [
        JogadorCampeao('Gabriel Luz', _g, titular: true, numero: 1),
        JogadorCampeao('Elliton Gama', _z, titular: true, numero: 3),
        JogadorCampeao('Rodrigo Hammer', _z, titular: true, numero: 4),
        JogadorCampeao('Victor Bezerra', _m, titular: true, numero: 8),
        JogadorCampeao('Bruno Pantoja', _m, titular: true, numero: 10),
        JogadorCampeao('Francisco Macedo', _a, titular: true, numero: 9, curto: 'F. Macedo'),
        JogadorCampeao('Lucas Gabriel', null),
        JogadorCampeao('Wesley', null),
        JogadorCampeao('Cesar Diniz', null),
        JogadorCampeao('Rafael', null),
        JogadorCampeao('Breno', null),
        JogadorCampeao('Erik Pamplona', null),
        JogadorCampeao('Mateus Tavares', null),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Francisco Macedo'),
        PremioTemporada('Artilheiro', 'Francisco Macedo'),
        PremioTemporada('Melhor goleiro', 'Gustavo', time: 'Udinese'),
      ],
    ),
    TituloTemporada(
      2024,
      'Roma',
      // Grená com número amarelo, as cores da Roma.
      cor: 0xFF8E1F2F,
      corNumero: 0xFFF4B43A,
      elenco: [
        JogadorCampeao('Gabriel Luz', _g, titular: true, numero: 1),
        JogadorCampeao('Alex Nascimento', _z, titular: true, numero: 3),
        JogadorCampeao('Cabeludo', _z, titular: true, numero: 4),
        JogadorCampeao('Toupeira', _m, titular: true, numero: 8),
        JogadorCampeao('Lucas Gabriel', _m, titular: true, numero: 10),
        JogadorCampeao('Marcola', _a, titular: true, numero: 9),
        JogadorCampeao('Marcelo Ferraz', null),
        JogadorCampeao('Jhovan', null),
        JogadorCampeao('Matheus Rodovalho', null),
        JogadorCampeao('Erick', null),
        JogadorCampeao('Murilo', null),
        JogadorCampeao('Felipe Alves', null),
        JogadorCampeao('Carlos Newton', null),
        JogadorCampeao('Bruno Fernandes', null),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Lucas Gabriel'),
        PremioTemporada('Artilheiro', 'Lucas Gabriel'),
        PremioTemporada('Melhor goleiro', 'Gabriel Luz'),
      ],
    ),
    TituloTemporada(
      2023,
      'Napoli',
      // Azul-claro, a cor do Napoli (não está na tabela atual).
      cor: 0xFF12A0D7,
      elenco: [
        JogadorCampeao('Elzeman Gustavo', _g, titular: true, numero: 1, curto: 'Gustavo'),
        JogadorCampeao('Alex Sorín', _z, titular: true, numero: 3),
        JogadorCampeao('Victor Bezerra', _z, titular: true, numero: 4),
        JogadorCampeao('New', _m, titular: true, numero: 8),
        JogadorCampeao('Alessandro Melul', _m, titular: true, numero: 10),
        JogadorCampeao('Vidal', _a, titular: true, numero: 9),
        JogadorCampeao('Frhancys Harrison', null),
        JogadorCampeao('Jameson', null),
        JogadorCampeao('Jadilson', null),
        JogadorCampeao('Jonas', null),
        JogadorCampeao('Neto Martins', null),
        JogadorCampeao('Pedro Silva', null),
        JogadorCampeao('Renato Pantoja', null),
        JogadorCampeao('Romeu', null),
      ],
      premios: [
        PremioTemporada('Melhor jogador', 'Alessandro Melul'),
        PremioTemporada('Artilheiro', 'Lucas Gabriel', time: 'Juventus'),
        PremioTemporada('Melhor goleiro', 'Gustavo'),
      ],
    ),
    TituloTemporada(2022, 'Fiorentina'),
    TituloTemporada(2021, 'Milan'),
  ],
  Categoria.superMaster: [
    TituloTemporada(2025, 'Foggia'),
    TituloTemporada(2024, 'Sport Belém'),
    TituloTemporada(2023, 'Atlético Mineiro'),
    TituloTemporada(2022, 'Bayern de Munique'),
  ],
};

List<TituloTemporada> campeoesDe(Categoria c) => campeoesPorCategoria[c] ?? const [];

/// Quantos titulares cada posição tem no campinho (goleiro e 2-2-1).
const titularesPorPosicao = {
  PosicaoCampeao.goleiro: 1,
  PosicaoCampeao.zagueiro: 2,
  PosicaoCampeao.meia: 2,
  PosicaoCampeao.ataque: 1,
};

/// O que impede gravar o título, ou nulo se está tudo certo. Sem titulares
/// também vale: o painel mostra só a lista do elenco.
String? problemaDoTitulo(TituloTemporada t, {Iterable<int> outrosAnos = const []}) {
  if (t.ano < 1990 || t.ano > 2100) return 'Informe o ano do título.';
  if (outrosAnos.contains(t.ano)) return 'Já existe um campeão em ${t.ano}.';
  if (t.campeao.trim().isEmpty) return 'Informe o time campeão.';
  if (t.elenco.any((j) => j.nome.trim().isEmpty)) return 'Há jogador sem nome no elenco.';
  if (t.premios.any((p) => p.premio.trim().isEmpty || p.nome.trim().isEmpty)) {
    return 'Complete ou apague os prêmios em branco.';
  }
  final titulares = t.titulares;
  if (titulares.isEmpty) return null;
  if (titulares.any((j) => j.posicao == null)) return 'Todo titular precisa de posição.';
  for (final MapEntry(key: p, value: n) in titularesPorPosicao.entries) {
    final tem = t.titularesDe(p).length;
    if (tem != n) {
      return 'Os titulares precisam ser 1 goleiro, 2 zagueiros, 2 meias e 1 atacante '
          '(há $tem ${tem == 1 ? p.nome.toLowerCase() : p.plural.toLowerCase()}).';
    }
  }
  return null;
}
