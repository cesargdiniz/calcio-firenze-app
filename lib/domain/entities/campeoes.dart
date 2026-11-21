import 'categoria.dart';

/// Campeão de uma temporada.
class TituloTemporada {
  final int ano;
  final String campeao;

  const TituloTemporada(this.ano, this.campeao);
}

/// Campeões de cada categoria, da temporada mais recente para a mais antiga.
const campeoesPorCategoria = <Categoria, List<TituloTemporada>>{
  Categoria.master: [
    TituloTemporada(2025, 'Leoni Azzurri'),
    TituloTemporada(2024, 'Marinai Blu'),
    TituloTemporada(2023, 'Fiamme Rosse'),
    TituloTemporada(2022, 'Brasil'),
    TituloTemporada(2021, 'Corvi Neri'),
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
