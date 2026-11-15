import 'package:calcio_regras/calcio_regras.dart';

/// Um bloco do calendário: uma rodada da fase classificatória ou uma etapa
/// do mata-mata (quartas, semifinais, final do turno, grande final).
class Etapa implements Comparable<Etapa> {
  final int turno;
  final Fase fase;

  /// Só na fase classificatória.
  final int? rodada;

  const Etapa(this.turno, this.fase, [this.rodada]);

  factory Etapa.de(Partida p) =>
      Etapa(p.turno, p.fase, p.fase == Fase.classificatoria ? p.rodada : null);

  bool contem(Partida p) => Etapa.de(p) == this;

  /// "Rodada 4", "Quartas de final", "Final do 1º turno".
  String get rotulo => switch (fase) {
    Fase.classificatoria => 'Rodada $rodada',
    Fase.quartas => 'Quartas de final',
    Fase.semifinal => 'Semifinais',
    Fase.finalTurno => 'Final do $turnoº turno',
    Fase.grandeFinal => 'Grande final',
  };

  /// Texto curto dos botões de filtro: "R4", "Quartas", "Final".
  String get curto => switch (fase) {
    Fase.classificatoria => 'R$rodada',
    Fase.quartas => 'Quartas',
    Fase.semifinal => 'Semi',
    Fase.finalTurno => 'Final',
    Fase.grandeFinal => 'Grande final',
  };

  /// A grande final (turno 0) vem depois dos dois turnos.
  int get _ordemTurno => turno == 0 ? 3 : turno;

  @override
  int compareTo(Etapa o) {
    final t = _ordemTurno.compareTo(o._ordemTurno);
    if (t != 0) return t;
    final f = fase.index.compareTo(o.fase.index);
    if (f != 0) return f;
    return (rodada ?? 0).compareTo(o.rodada ?? 0);
  }

  @override
  bool operator ==(Object o) =>
      o is Etapa && o.turno == turno && o.fase == fase && o.rodada == rodada;

  @override
  int get hashCode => Object.hash(turno, fase, rodada);

  @override
  String toString() => '$turno/$curto';
}

/// Etapas das partidas, em ordem de calendário, sem repetição.
List<Etapa> etapasDe(Iterable<Partida> partidas) =>
    {for (final p in partidas) Etapa.de(p)}.toList()..sort();

/// Texto do resultado de um jogo de mata-mata: quem avança, quem é campeão
/// ou, antes do jogo das quartas, quem joga pelo empate. Nulo fora do
/// mata-mata ou enquanto não dá para saber.
String? resultadoMataMata(Partida p, String Function(String timeId) nome) {
  if (!p.fase.eliminatoria) return null;
  if (!p.encerrada) {
    final v = vantagemDoEmpate(p);
    return v == null ? null : 'Empate classifica ${nome(v)}, mais bem colocado (art. 16.1).';
  }
  final v = vencedorMataMata(p);
  if (v == null) return null;
  return switch (p.fase) {
    Fase.finalTurno => 'Campeão do ${p.turno}º turno: ${nome(v)}',
    Fase.grandeFinal => 'Campeão do Calcio Firenze: ${nome(v)}',
    _ => 'Avança: ${nome(v)}',
  };
}
