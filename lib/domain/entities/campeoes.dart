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

  const JogadorCampeao(this.nome, this.posicao, {this.titular = false, this.numero});
}

/// Campeão de uma temporada e, quando cadastrado, o elenco do título.
class TituloTemporada {
  final int ano;
  final String campeao;
  final List<JogadorCampeao> elenco;

  const TituloTemporada(this.ano, this.campeao, {this.elenco = const []});

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
    TituloTemporada(2024, 'Sampdoria'),
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
