import 'package:calcio_regras/calcio_regras.dart';

import 'calendario_geral.dart';

/// Regras do calendário anual, valendo para as três categorias juntas.
enum RegraCalendario {
  duasPorDia('Máximo de duas partidas por dia útil, somando todas as competições.'),
  semDomingo('Nenhuma partida aos domingos.'),
  semanaDoMaster('Nenhuma semana do Master com partidas do Livre ou do Super Master.'),
  sabadoClassificatorio(
    'Nenhum jogo classificatório do Master ou do Super Master aos sábados, exceto as '
    'aberturas dos turnos, finais e grandes finais.',
  ),
  finalNoSabado('Finais de turno e grandes finais sempre aos sábados.');

  final String texto;
  const RegraCalendario(this.texto);

  /// "Regra 1", "Regra 2"...
  int get numero => index + 1;
}

/// Uma regra violada e os jogos que a violam.
class Inconsistencia {
  final RegraCalendario regra;

  /// "Qua 25/08: 3 partidas (L2, SM1)."
  final String detalhe;
  final List<JogoDoCalendario> jogos;
  const Inconsistencia(this.regra, this.detalhe, this.jogos);
}

const _semana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
String _dd(int n) => n.toString().padLeft(2, '0');
String _data(DateTime d) => '${_semana[d.weekday - 1]} ${_dd(d.day)}/${_dd(d.month)}';
DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _segunda(DateTime d) => _dia(d).subtract(Duration(days: d.weekday - 1));

/// "M2, SM1": jogos de cada competição.
String _contagem(Iterable<JogoDoCalendario> jogos) {
  final n = <Competicao, int>{};
  for (final j in jogos) {
    n[j.competicao] = (n[j.competicao] ?? 0) + 1;
  }
  return [for (final c in Competicao.values) if (n[c] case final q?) '${c.sigla}$q'].join(', ');
}

/// "SM · 2º turno · Rodada 2", "L · Grande final".
String _jogo(JogoDoCalendario j) => [
  j.competicao.sigla,
  if (j.turno case final t? when t > 0 && j.fase == Fase.classificatoria) '$tº turno',
  j.etapa,
].join(' · ');

/// Confere o calendário (todas as categorias e a Copa) contra as cinco
/// regras. Drafts não contam. A Copa Master conta como Master na regra 3.
List<Inconsistencia> verificarCalendario(List<JogoDoCalendario> eventos) {
  final jogos = [for (final e in eventos) if (!e.ehDraft) e]
    ..sort((a, b) => a.inicio.compareTo(b.inicio));
  final saida = <Inconsistencia>[];

  final porDia = <DateTime, List<JogoDoCalendario>>{};
  final porSemana = <DateTime, List<JogoDoCalendario>>{};
  for (final j in jogos) {
    porDia.putIfAbsent(_dia(j.inicio), () => []).add(j);
    porSemana.putIfAbsent(_segunda(j.inicio), () => []).add(j);
  }

  // 1 e 2: por dia.
  for (final MapEntry(key: dia, value: doDia) in porDia.entries) {
    if (dia.weekday <= DateTime.friday && doDia.length > 2) {
      saida.add(
        Inconsistencia(
          RegraCalendario.duasPorDia,
          '${_data(dia)}: ${doDia.length} partidas (${_contagem(doDia)}).',
          doDia,
        ),
      );
    }
    if (dia.weekday == DateTime.sunday) {
      saida.add(
        Inconsistencia(RegraCalendario.semDomingo, '${_data(dia)}: ${_contagem(doDia)}.', doDia),
      );
    }
  }

  // 3: semana do Master.
  for (final MapEntry(key: segunda, value: daSemana) in porSemana.entries) {
    final master = daSemana.where(
      (j) => j.competicao == Competicao.master || j.competicao == Competicao.copaMaster,
    );
    final outros = daSemana.where(
      (j) => j.competicao == Competicao.livre || j.competicao == Competicao.superMaster,
    );
    if (master.isEmpty || outros.isEmpty) continue;
    final domingo = segunda.add(const Duration(days: 6));
    saida.add(
      Inconsistencia(
        RegraCalendario.semanaDoMaster,
        'Semana de ${_dd(segunda.day)}/${_dd(segunda.month)} a '
        '${_dd(domingo.day)}/${_dd(domingo.month)}: ${_contagem(master)} com '
        '${[for (final j in outros) '${j.competicao.sigla} em ${_data(j.inicio)}'].toSet().join(', ')}.',
        [...master, ...outros],
      ),
    );
  }

  // 4 e 5: por jogo.
  for (final j in jogos) {
    final sabado = j.inicio.weekday == DateTime.saturday;
    final masterOuSm =
        j.competicao == Competicao.master || j.competicao == Competicao.superMaster;
    if (masterOuSm && sabado && j.fase == Fase.classificatoria && j.rodada != 1) {
      saida.add(
        Inconsistencia(
          RegraCalendario.sabadoClassificatorio,
          '${_data(j.inicio)}: ${_jogo(j)}.',
          [j],
        ),
      );
    }
    if ((j.fase == Fase.finalTurno || j.fase == Fase.grandeFinal) && !sabado) {
      saida.add(
        Inconsistencia(RegraCalendario.finalNoSabado, '${_data(j.inicio)}: ${_jogo(j)}.', [j]),
      );
    }
  }

  // Agrupadas por regra, mantendo a ordem de data dentro de cada uma.
  return [
    for (final r in RegraCalendario.values) ...saida.where((i) => i.regra == r),
  ];
}
