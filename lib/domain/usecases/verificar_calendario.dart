import 'package:calcio_regras/calcio_regras.dart';

import 'calendario_geral.dart';

/// Regras do calendário anual, valendo para as três categorias juntas.
enum RegraCalendario {
  duasPorDia('Máximo de duas partidas por dia útil, somando todas as competições.'),
  semDomingo('Nenhuma partida aos domingos.'),
  semanaDoMaster('Nenhuma semana do Master com partidas do Livre ou do Super Master.'),
  sabadoClassificatorio(
    'Aos sábados, só aberturas de turno e mata-mata: nenhuma rodada classificatória, '
    'em nenhuma categoria, fora a 1ª de cada turno.',
  ),
  finalNoSabado('Finais de turno e grandes finais sempre aos sábados.'),
  tresNaSemana('Nenhum time joga três vezes na mesma semana.'),
  descanso(
    'Entre dois jogos do mesmo time, pelo menos 4 dias: quem joga segunda volta na sexta; '
    'quem joga terça, no sábado.',
  ),
  sabado('No sábado, no máximo 4 jogos, a partir das 17:00.');

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

/// "Rodada 2 do 2º turno", "Semifinais do 1º turno", "Grande final".
String _etapa(JogoDoCalendario j) => switch (j.turno) {
  final t? when t > 0 && j.fase != Fase.finalTurno => '${j.etapa} do $tº turno',
  _ => j.etapa,
};

/// Confere o calendário (todas as categorias e a Copa) contra as cinco
/// regras. Drafts não contam. A Copa Master conta como Master nas regras 3
/// e 6 (os times são os mesmos).
///
/// Regra 6: com os confrontos definidos, conta os jogos de cada time na
/// semana; com horários ainda a definir, conta as etapas (cada time joga uma
/// vez por rodada ou fase do mata-mata), que é o máximo possível.
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
    if (dia.weekday == DateTime.saturday &&
        (doDia.length > 4 || doDia.any((j) => j.inicio.hour < 17))) {
      saida.add(
        Inconsistencia(
          RegraCalendario.sabado,
          doDia.length > 4
              ? '${_data(dia)}: ${doDia.length} partidas (${_contagem(doDia)}).'
              : '${_data(dia)}: jogo antes das 17:00.',
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

  // 6: três jogos do mesmo time na semana.
  String grupo(Competicao c) => c == Competicao.copaMaster ? Competicao.master.sigla : c.sigla;
  for (final MapEntry(key: segunda, value: daSemana) in porSemana.entries) {
    final domingo = segunda.add(const Duration(days: 6));
    final semana =
        'Semana de ${_dd(segunda.day)}/${_dd(segunda.month)} a ${_dd(domingo.day)}/${_dd(domingo.month)}';
    final porGrupo = <String, List<JogoDoCalendario>>{};
    for (final j in daSemana) {
      porGrupo.putIfAbsent(grupo(j.competicao), () => []).add(j);
    }
    for (final MapEntry(key: sigla, value: doGrupo) in porGrupo.entries) {
      if (doGrupo.every((j) => !j.aDefinir)) {
        final jogosDoTime = <String, List<JogoDoCalendario>>{};
        final nomes = <String, String>{};
        for (final j in doGrupo) {
          final p = j.partida!;
          for (final (id, time) in [(p.mandanteId, j.mandante), (p.visitanteId, j.visitante)]) {
            jogosDoTime.putIfAbsent(id, () => []).add(j);
            nomes[id] = time?.nome ?? id;
          }
        }
        for (final MapEntry(key: id, value: doTime) in jogosDoTime.entries) {
          if (doTime.length >= 3) {
            saida.add(
              Inconsistencia(
                RegraCalendario.tresNaSemana,
                '$semana: ${nomes[id]} ($sigla) joga ${doTime.length} vezes.',
                doTime,
              ),
            );
          }
        }
        continue;
      }
      final etapas = <String>{for (final j in doGrupo) '${j.competicao.sigla} ${_etapa(j)}'};
      if (etapas.length >= 3) {
        saida.add(
          Inconsistencia(
            RegraCalendario.tresNaSemana,
            '$semana: ${etapas.join(', ')} (o mesmo time pode jogar ${etapas.length} vezes).',
            doGrupo,
          ),
        );
      }
    }
  }

  // 7: descanso de 72 horas.
  saida.addAll(_descanso(jogos, grupo));

  // 4 e 5: por jogo (um aviso por etapa e dia).
  final vistos = <String>{};
  for (final j in jogos) {
    final sabado = j.inicio.weekday == DateTime.saturday;
    if (sabado &&
        j.fase == Fase.classificatoria &&
        j.rodada != 1 &&
        vistos.add('${_data(j.inicio)} ${_jogo(j)}')) {
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

/// Dias de calendário entre dois jogos (segunda → sexta = 4).
const _minimo = 4;
int _dias(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
String _intervalo(int dias) => dias == 1 ? '1 dia' : '$dias dias';

/// Regra 7. Com os confrontos definidos, mede o intervalo entre os jogos de
/// cada time. Com horários a definir, compara etapas seguidas da mesma
/// categoria (a Copa junto com o Master): entre duas rodadas da
/// classificatória, vê se dá para distribuir os times com 4 dias de folga
/// (cada time joga uma vez por rodada); nas demais, vale o pior caso (quem
/// jogou por último numa etapa pode jogar primeiro na seguinte).
List<Inconsistencia> _descanso(
  List<JogoDoCalendario> jogos,
  String Function(Competicao) grupo,
) {
  final saida = <Inconsistencia>[];
  final porGrupo = <String, List<JogoDoCalendario>>{};
  for (final j in jogos) {
    porGrupo.putIfAbsent(grupo(j.competicao), () => []).add(j);
  }
  for (final MapEntry(key: sigla, value: doGrupo) in porGrupo.entries) {
    // Times conhecidos.
    final porTime = <String, List<JogoDoCalendario>>{};
    for (final j in doGrupo.where((j) => !j.aDefinir)) {
      porTime.putIfAbsent(j.partida!.mandanteId, () => []).add(j);
      porTime.putIfAbsent(j.partida!.visitanteId, () => []).add(j);
    }
    for (final MapEntry(key: id, value: doTime) in porTime.entries) {
      for (var i = 1; i < doTime.length; i++) {
        final (a, b) = (doTime[i - 1], doTime[i]);
        final intervalo = _dias(a.inicio, b.inicio);
        if (intervalo < _minimo) {
          final nome = (a.partida!.mandanteId == id ? a.mandante : a.visitante)?.nome ?? id;
          saida.add(
            Inconsistencia(
              RegraCalendario.descanso,
              '$nome ($sigla): ${_data(a.inicio)} e ${_data(b.inicio)} (${_intervalo(intervalo)}).',
              [a, b],
            ),
          );
        }
      }
    }

    // Etapas com horários a definir.
    final etapas = <String, List<JogoDoCalendario>>{};
    for (final j in doGrupo) {
      etapas.putIfAbsent('${j.competicao.sigla} ${_etapa(j)}', () => []).add(j);
    }
    final ordem = etapas.entries.toList()
      ..sort((a, b) => a.value.first.inicio.compareTo(b.value.first.inicio));
    for (var i = 1; i < ordem.length; i++) {
      final (antes, depois) = (ordem[i - 1], ordem[i]);
      final a = antes.value;
      final b = depois.value;
      if (a.every((j) => !j.aDefinir) && b.every((j) => !j.aDefinir)) continue;
      final rodadas = a.first.fase == Fase.classificatoria &&
          b.first.fase == Fase.classificatoria &&
          a.first.competicao == b.first.competicao;
      DateTime? de;
      DateTime? para;
      if (rodadas) {
        // Duas vagas por jogo; a k-ésima vaga de uma rodada precisa de 4 dias
        // até a k-ésima da seguinte.
        List<DateTime> vagas(List<JogoDoCalendario> l) =>
            [for (final j in l) ...[j.inicio, j.inicio]]..sort();
        final va = vagas(a);
        final vb = vagas(b);
        for (var k = 0; k < va.length && k < vb.length; k++) {
          if (_dias(va[k], vb[k]) < _minimo) {
            (de, para) = (va[k], vb[k]);
            break;
          }
        }
      } else {
        final fim = a.map((j) => j.inicio).reduce((x, y) => x.isAfter(y) ? x : y);
        final inicio = b.first.inicio;
        if (_dias(fim, inicio) < _minimo) (de, para) = (fim, inicio);
      }
      if (de != null && para != null) {
        final intervalo = _dias(de, para);
        saida.add(
          Inconsistencia(
            RegraCalendario.descanso,
            '${antes.key} → ${depois.key}: quem joga ${_data(de)} pode voltar a jogar '
            '${_data(para)} (${intervalo < 0 ? 'etapas no mesmo período' : _intervalo(intervalo)}).',
            [...a, ...b],
          ),
        );
      }
    }
  }
  return saida;
}
