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

  const TituloTemporada(this.ano, this.campeao, {this.elenco = const [], this.premios = const []});

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
    TituloTemporada(2025, 'Inter'),
    TituloTemporada(
      2024,
      'Sampdoria',
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
    ),
    TituloTemporada(
      2023,
      'Foggia',
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
    TituloTemporada(2022, 'Brasil'),
    TituloTemporada(2021, 'Juventus'),
  ],
  Categoria.livre: [
    TituloTemporada(2025, 'Foggia'),
    TituloTemporada(2024, 'Roma'),
    TituloTemporada(2023, 'Napoli'),
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
