import 'categoria.dart';

/// Campeão e vice de uma temporada. Sem campeão: temporada em andamento.
class TituloTemporada {
  final int ano;
  final String? campeao;
  final String? vice;

  const TituloTemporada(this.ano, {this.campeao, this.vice});

  bool get emAndamento => campeao == null;
}

/// Campeões e vices de cada categoria, da temporada mais recente para a mais
/// antiga. Categorias sem histórico ficam de fora.
const campeoesPorCategoria = <Categoria, List<TituloTemporada>>{
  Categoria.master: [
    TituloTemporada(2026),
    TituloTemporada(2025, campeao: 'Inter', vice: 'Napoli'),
    TituloTemporada(2024, campeao: 'Sampdoria', vice: 'Inter'),
    TituloTemporada(2023, campeao: 'Foggia', vice: 'Sampdoria'),
    TituloTemporada(2022, campeao: 'Brasil', vice: 'França'),
    TituloTemporada(2021, campeao: 'Juventus', vice: 'Roma'),
  ],
};

List<TituloTemporada> campeoesDe(Categoria c) => campeoesPorCategoria[c] ?? const [];
