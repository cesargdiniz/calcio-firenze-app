import 'package:calcio_regras/calcio_regras.dart';

import '../entities/categoria.dart';
import '../entities/etapa.dart';
import '../entities/temporada.dart';
import 'gerar_calendario.dart';

/// Times e jogos de uma categoria: o mínimo para o calendário geral.
class DadosCalendario {
  final List<Time> times;
  final List<Partida> partidas;
  const DadosCalendario({this.times = const [], this.partidas = const []});
}

/// Competições do calendário geral: as categorias e a Copa Master.
enum Competicao {
  master('Master'),
  superMaster('Super Master'),
  livre('Livre'),
  copaMaster('Copa Master');

  final String nome;
  const Competicao(this.nome);

  static Competicao de(Categoria c) => switch (c) {
    Categoria.master => Competicao.master,
    Categoria.superMaster => Competicao.superMaster,
    Categoria.livre => Competicao.livre,
  };
}

/// Um jogo no calendário geral: já marcado (com os times) ou um horário
/// oficial cujo confronto ainda não foi definido.
class JogoDoCalendario {
  final DateTime inicio;
  final Competicao competicao;

  /// "Rodada 3", "Quartas de final", "Final do 1º turno", "Preliminar".
  final String etapa;

  /// Nulo enquanto o confronto não existe no app.
  final Partida? partida;
  final Time? mandante;
  final Time? visitante;

  const JogoDoCalendario({
    required this.inicio,
    required this.competicao,
    required this.etapa,
    this.partida,
    this.mandante,
    this.visitante,
  });

  bool get aDefinir => partida == null;
}

/// Junta os jogos de todas as categorias e da Copa num calendário só, em
/// ordem de data. Onde o calendário de um turno ainda não foi sorteado (ou
/// uma etapa do mata-mata ainda não foi criada), entram os horários oficiais
/// com o confronto a definir.
List<JogoDoCalendario> montarCalendarioGeral(Map<Categoria, DadosCalendario> dados) {
  final jogos = <JogoDoCalendario>[
    for (final c in Categoria.values) ..._daCategoria(c, dados[c] ?? const DadosCalendario()),
    for (final d in datasCopaMaster2027)
      for (final h in d.horarios)
        JogoDoCalendario(inicio: h, competicao: Competicao.copaMaster, etapa: d.etapa),
  ];
  return jogos..sort((a, b) => a.inicio.compareTo(b.inicio));
}

List<JogoDoCalendario> _daCategoria(Categoria c, DadosCalendario d) {
  final competicao = Competicao.de(c);
  final times = {for (final t in d.times) t.id: t};
  final horarios = horariosDe(c);
  final porRodada = c.times ~/ 2;
  final classificatoria = c.rodadas * porRodada;

  JogoDoCalendario real(Partida p) => JogoDoCalendario(
    inicio: p.inicio,
    competicao: competicao,
    etapa: Etapa.de(p).rotulo,
    partida: p,
    mandante: times[p.mandanteId],
    visitante: times[p.visitanteId],
  );
  JogoDoCalendario vago(DateTime h, String etapa) =>
      JogoDoCalendario(inicio: h, competicao: competicao, etapa: etapa);

  final etapasMataMata = [
    if (c.temQuartas) (Fase.quartas, 2),
    (Fase.semifinal, 2),
    (Fase.finalTurno, 1),
  ];

  final saida = <JogoDoCalendario>[];
  for (final turno in [1, 2]) {
    final slots = [...?horarios[turno]]..sort();
    final doTurno = d.partidas.where((p) => p.turno == turno).toList();
    final sorteados = doTurno.where((p) => p.fase == Fase.classificatoria);
    if (sorteados.isNotEmpty) {
      saida.addAll(sorteados.map(real));
    } else {
      for (final (i, h) in slots.take(classificatoria).indexed) {
        saida.add(vago(h, 'Rodada ${i ~/ porRodada + 1}'));
      }
    }
    var i = classificatoria;
    for (final (fase, quantos) in etapasMataMata) {
      final criados = doTurno.where((p) => p.fase == fase);
      if (criados.isNotEmpty) {
        saida.addAll(criados.map(real));
      } else {
        for (final h in slots.skip(i).take(quantos)) {
          saida.add(vago(h, Etapa(turno, fase).rotulo));
        }
      }
      i += quantos;
    }
  }
  final grandeFinal = d.partidas.where((p) => p.fase == Fase.grandeFinal);
  if (grandeFinal.isNotEmpty) {
    saida.addAll(grandeFinal.map(real));
  } else {
    for (final h in horarios[0] ?? const <DateTime>[]) {
      saida.add(vago(h, 'Grande final'));
    }
  }
  return saida;
}
