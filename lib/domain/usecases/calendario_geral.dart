import 'package:calcio_regras/calcio_regras.dart';

import '../entities/categoria.dart';
import '../entities/etapa.dart';
import '../entities/temporada.dart';
import 'gerar_calendario.dart';

/// Times e jogos de uma categoria: o mínimo para o calendário geral.
class DadosCalendario {
  final List<Time> times;
  final List<Partida> partidas;

  /// Draft-1 e Draft-2 da categoria (chave 1 e 2).
  final Map<int, DateTime> drafts;
  const DadosCalendario({this.times = const [], this.partidas = const [], this.drafts = const {}});
}

/// Competições do calendário geral: as categorias e a Copa Master.
enum Competicao {
  master('Master', 'M'),
  superMaster('Super Master', 'SM'),
  livre('Livre', 'L'),
  copaMaster('Copa Master', 'CM');

  final String nome;

  /// M, SM, L e CM (Copa Master).
  final String sigla;
  const Competicao(this.nome, this.sigla);

  /// Categoria da competição (nula na Copa Master, que não tem temporada própria).
  Categoria? get categoria => switch (this) {
    Competicao.master => Categoria.master,
    Competicao.superMaster => Categoria.superMaster,
    Competicao.livre => Categoria.livre,
    Competicao.copaMaster => null,
  };

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

  /// Turno do jogo (0: grande final). Nulo na Copa e nos drafts.
  final int? turno;

  /// Fase do jogo no campeonato da categoria. Nula na Copa e nos drafts.
  final Fase? fase;

  /// Rodada, na fase classificatória.
  final int? rodada;

  /// 1 ou 2 quando não é jogo, e sim o Draft-1 ou o Draft-2 da categoria.
  final int? draft;

  /// Horário do calendário oficial (no código) de onde veio um jogo ainda a
  /// definir. É a chave da mudança de dia feita na Gestão.
  final DateTime? oficial;

  const JogoDoCalendario({
    required this.inicio,
    required this.competicao,
    required this.etapa,
    this.partida,
    this.mandante,
    this.visitante,
    this.turno,
    this.fase,
    this.rodada,
    this.draft,
    this.oficial,
  });

  /// O mesmo evento em outro horário (para simular uma mudança de data).
  JogoDoCalendario em(DateTime novo) => JogoDoCalendario(
    inicio: novo,
    competicao: competicao,
    etapa: etapa,
    partida: partida,
    mandante: mandante,
    visitante: visitante,
    turno: turno,
    fase: fase,
    rodada: rodada,
    draft: draft,
    oficial: oficial,
  );

  bool get ehDraft => draft != null;
  bool get aDefinir => partida == null;
}

/// Feriados do calendário anual (do modelo da Organização). [oficial] falso:
/// facultativo ou data local a confirmar.
typedef Feriado = ({DateTime data, String nome, bool oficial});

final feriados2027 = <Feriado>[
  (data: DateTime(2026, 12, 25), nome: 'Natal', oficial: true),
  (data: DateTime(2027, 1, 1), nome: 'Confraternização Universal', oficial: true),
  (data: DateTime(2027, 1, 12), nome: 'Data local a confirmar', oficial: false),
  (data: DateTime(2027, 2, 8), nome: 'Carnaval (segunda-feira)', oficial: false),
  (data: DateTime(2027, 2, 9), nome: 'Carnaval (terça-feira)', oficial: false),
  (data: DateTime(2027, 2, 10), nome: 'Quarta-feira de Cinzas', oficial: false),
  (data: DateTime(2027, 3, 26), nome: 'Paixão de Cristo', oficial: true),
  (data: DateTime(2027, 4, 21), nome: 'Tiradentes', oficial: true),
  (data: DateTime(2027, 5, 1), nome: 'Dia do Trabalho', oficial: true),
  (data: DateTime(2027, 8, 15), nome: 'Data local', oficial: true),
  (data: DateTime(2027, 9, 7), nome: 'Independência do Brasil', oficial: true),
  (data: DateTime(2027, 10, 12), nome: 'Nossa Senhora Aparecida', oficial: true),
  (data: DateTime(2027, 10, 25), nome: 'Data local a confirmar', oficial: false),
  (data: DateTime(2027, 11, 2), nome: 'Finados', oficial: true),
  (data: DateTime(2027, 11, 15), nome: 'Proclamação da República', oficial: true),
  (data: DateTime(2027, 12, 8), nome: 'N. Sra. da Conceição (Belém)', oficial: true),
  (data: DateTime(2027, 12, 25), nome: 'Natal', oficial: true),
];

/// Junta os jogos de todas as categorias e da Copa num calendário só, em
/// ordem de data. Onde o calendário de um turno ainda não foi sorteado (ou
/// uma etapa do mata-mata ainda não foi criada), entram os horários oficiais
/// com o confronto a definir.
List<JogoDoCalendario> montarCalendarioGeral(Map<Categoria, DadosCalendario> dados) {
  final jogos = <JogoDoCalendario>[
    for (final c in Categoria.values) ..._daCategoria(c, dados[c] ?? const DadosCalendario()),
    for (final c in Categoria.values)
      for (final MapEntry(key: n, value: data) in (dados[c]?.drafts ?? const {}).entries)
        JogoDoCalendario(inicio: data, competicao: Competicao.de(c), etapa: 'Draft-$n', draft: n),
    for (final d in datasCopaOficiais2027)
      for (final h in d.horarios)
        JogoDoCalendario(
          inicio: AjustesCalendario.aplicar(h),
          competicao: Competicao.copaMaster,
          etapa: d.etapa,
          oficial: h,
        ),
  ];
  return jogos..sort((a, b) => a.inicio.compareTo(b.inicio));
}

List<JogoDoCalendario> _daCategoria(Categoria c, DadosCalendario d) {
  final competicao = Competicao.de(c);
  final times = {for (final t in d.times) t.id: t};
  // Horários oficiais, na ordem do código; cada um no dia em que está hoje.
  final horarios = horariosOficiaisDe(c);
  final porRodada = c.times ~/ 2;
  final classificatoria = c.rodadas * porRodada;

  JogoDoCalendario real(Partida p) => JogoDoCalendario(
    inicio: p.inicio,
    competicao: competicao,
    etapa: Etapa.de(p).rotulo,
    partida: p,
    mandante: times[p.mandanteId],
    visitante: times[p.visitanteId],
    turno: p.turno,
    fase: p.fase,
    rodada: p.fase == Fase.classificatoria ? p.rodada : null,
  );
  JogoDoCalendario vago(DateTime h, String etapa, int turno, Fase fase, [int? rodada]) =>
      JogoDoCalendario(
        inicio: AjustesCalendario.aplicar(h),
        competicao: competicao,
        etapa: etapa,
        turno: turno,
        fase: fase,
        rodada: rodada,
        oficial: h,
      );

  final etapasMataMata = [
    if (c.temQuartas) (Fase.quartas, 2),
    (Fase.semifinal, 2),
    (Fase.finalTurno, 1),
  ];

  final saida = <JogoDoCalendario>[];
  for (final turno in [1, 2]) {
    final slots = [...?horarios[turno]];
    final doTurno = d.partidas.where((p) => p.turno == turno).toList();
    final sorteados = doTurno.where((p) => p.fase == Fase.classificatoria);
    if (sorteados.isNotEmpty) {
      saida.addAll(sorteados.map(real));
    } else {
      for (final (i, h) in slots.take(classificatoria).indexed) {
        final rodada = i ~/ porRodada + 1;
        saida.add(vago(h, 'Rodada $rodada', turno, Fase.classificatoria, rodada));
      }
    }
    var i = classificatoria;
    for (final (fase, quantos) in etapasMataMata) {
      final criados = doTurno.where((p) => p.fase == fase);
      if (criados.isNotEmpty) {
        saida.addAll(criados.map(real));
      } else {
        for (final h in slots.skip(i).take(quantos)) {
          saida.add(vago(h, Etapa(turno, fase).rotulo, turno, fase));
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
      saida.add(vago(h, 'Grande final', 0, Fase.grandeFinal));
    }
  }
  return saida;
}

/// Horários de [quantos] jogos levados para [dia], depois dos [jaNoDia] que
/// já estão lá: dia de semana às 20:30, 21:30...; sábado a partir das 17h, um
/// por hora, e jogo único às 19h.
List<DateTime> horariosNoDia(DateTime dia, int jaNoDia, int quantos) {
  final d = DateTime(dia.year, dia.month, dia.day);
  if (dia.weekday == DateTime.saturday || dia.weekday == DateTime.sunday) {
    if (jaNoDia == 0 && quantos == 1) return [d.add(const Duration(hours: 19))];
    return [for (var i = 0; i < quantos; i++) d.add(Duration(hours: 17 + jaNoDia + i))];
  }
  return [for (var i = 0; i < quantos; i++) d.add(Duration(hours: 20 + jaNoDia + i, minutes: 30))];
}
