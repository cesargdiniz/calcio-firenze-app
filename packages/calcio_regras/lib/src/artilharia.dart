import 'entidades.dart';

/// Uma linha da artilharia.
class Artilheiro {
  final String pessoaId;
  final String timeId;
  final int gols;

  /// Colocação, começando em 1. Quem tem os mesmos gols divide a posição, e
  /// a seguinte é pulada (1º, 1º, 3º).
  final int posicao;

  const Artilheiro({
    required this.pessoaId,
    required this.timeId,
    required this.gols,
    required this.posicao,
  });
}

/// Artilharia das partidas com súmula, do [turno] ou, sem ele, da temporada.
///
/// Só contam gols com autor. Ficam de fora:
/// - os gols do W.O. (art. 75), que valem para a classificação mas não são de
///   nenhum jogador;
/// - gols contra;
/// - gols lançados sem autor.
///
/// A disputa de pênaltis do mata-mata também não conta: ela só decide quem
/// avança.
List<Artilheiro> artilharia(Iterable<Partida> partidas, {int? turno}) {
  final gols = <String, int>{};
  final time = <String, String>{};
  for (final p in partidas) {
    final s = p.sumula;
    if (s == null || s.ausenteWo != null) continue;
    if (turno != null && p.turno != turno) continue;
    for (final g in s.gols) {
      final autor = g.autorId;
      if (autor == null || g.contra) continue;
      gols[autor] = (gols[autor] ?? 0) + 1;
      time[autor] = g.timeId;
    }
  }

  // Mais gols primeiro; no empate, ordem estável pelo id.
  final ordem = gols.keys.toList()
    ..sort((a, b) {
      final porGols = gols[b]!.compareTo(gols[a]!);
      return porGols != 0 ? porGols : a.compareTo(b);
    });

  final lista = <Artilheiro>[];
  for (var i = 0; i < ordem.length; i++) {
    final id = ordem[i];
    final empatado = i > 0 && gols[ordem[i - 1]] == gols[id];
    lista.add(
      Artilheiro(
        pessoaId: id,
        timeId: time[id]!,
        gols: gols[id]!,
        posicao: empatado ? lista.last.posicao : i + 1,
      ),
    );
  }
  return lista;
}
