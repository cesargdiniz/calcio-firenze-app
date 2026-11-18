/// Categorias do Calcio Firenze. Cada uma é uma competição à parte, com seus
/// times, elencos, calendário, tabela e Organização (`temporadas/{id}`).
///
/// A Copa Master entra quando o formato dela estiver definido.
enum Categoria {
  master('master-2027', 'Master', 'M', times: 10, classificados: 6),
  superMaster('super-master-2027', 'Super Master', 'SM', times: 6, classificados: 4),
  livre('livre-2027', 'Livre', 'L', times: 8, classificados: 6);

  /// Documento da temporada no Firestore.
  final String temporadaId;
  final String nome;

  /// M (Master), SM (Super Master) e L (Livre).
  final String sigla;

  /// Times da fase classificatória (todos contra todos, só ida).
  final int times;

  /// Quantos passam ao mata-mata: 6 (1º e 2º direto na semifinal, 3º a 6º
  /// nas quartas) ou 4 (semifinal direta).
  final int classificados;

  const Categoria(
    this.temporadaId,
    this.nome,
    this.sigla, {
    required this.times,
    required this.classificados,
  });

  bool get temQuartas => classificados > 4;

  int get rodadas => times - 1;

  /// "Master · Temporada 2027".
  String get titulo => '$nome · Temporada 2027';

  static Categoria? deTemporada(String? id) =>
      values.where((c) => c.temporadaId == id).firstOrNull;
}
