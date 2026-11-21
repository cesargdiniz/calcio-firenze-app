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
    TituloTemporada(2022, 'Api Dorate'),
    TituloTemporada(2021, 'Corvi Neri'),
  ],
  Categoria.livre: [
    TituloTemporada(2025, 'Grifoni Verdi'),
    TituloTemporada(2024, 'Orsi Bruni'),
    TituloTemporada(2023, 'Delfini Blu'),
    TituloTemporada(2022, 'Volpi Rosse'),
    TituloTemporada(2021, "Falchi d'Arno"),
  ],
  Categoria.superMaster: [
    TituloTemporada(2025, 'Cavalieri Bianchi'),
    TituloTemporada(2024, 'Torri del Borgo'),
    TituloTemporada(2023, 'Leoni di Pietra'),
    TituloTemporada(2022, 'Querce Antiche'),
  ],
};

List<TituloTemporada> campeoesDe(Categoria c) => campeoesPorCategoria[c] ?? const [];
