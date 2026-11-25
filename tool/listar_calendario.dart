// Lista o calendário 2027 como está no app (com os ajustes da Gestão), no
// formato do documento calendario-2027.md.
//   TZ=America/Sao_Paulo dart run tool/listar_calendario.dart entrada.json
import 'dart:convert';
import 'dart:io';

import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/usecases/calendario_geral.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_firenze/domain/usecases/verificar_calendario.dart';
import 'package:calcio_regras/calcio_regras.dart';

const _sem = ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
String _2(int n) => n.toString().padLeft(2, '0');

void main(List<String> args) {
  final e = jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  AjustesCalendario.definir({
    for (final MapEntry(:key, :value) in (e['ajustes'] as Map<String, dynamic>).entries)
      DateTime.parse(key): DateTime.parse(value as String).toLocal(),
  });
  final temporadas = e['temporadas'] as Map<String, dynamic>;
  final dados = <Categoria, DadosCalendario>{
    for (final c in Categoria.values)
      if (temporadas[c.temporadaId] case final Map<String, dynamic> t)
        c: DadosCalendario(
          partidas: [
            for (final p in (t['partidas'] as List).cast<Map<String, dynamic>>())
              Partida(
                id: p['id'] as String,
                turno: p['turno'] as int,
                fase: Fase.values.byName(p['fase'] as String),
                rodada: p['rodada'] as int?,
                mandanteId: p['mandanteId'] as String,
                visitanteId: p['visitanteId'] as String,
                inicio: DateTime.parse(p['inicio'] as String).toLocal(),
              ),
          ],
          drafts: {
            for (final MapEntry(:key, :value) in (t['drafts'] as Map<String, dynamic>).entries)
              int.parse(key): DateTime.parse(value as String).toLocal(),
          },
        ),
  };
  stderr.writeln('chaves: ${[for (final t in temporadas.values) (t as Map)['chaves']]}');
  final jogos = montarCalendarioGeral(dados).where((j) => !j.ehDraft).toList();
  for (final c in Competicao.values) {
    stdout.writeln(c.nome.toUpperCase());
    final daComp = jogos.where((j) => j.competicao == c).toList()..sort((a, b) => a.inicio.compareTo(b.inicio));
    final grupos = <String, List<JogoDoCalendario>>{};
    for (final j in daComp) {
      final turno = j.turno == null || j.turno == 0 ? '' : '${j.turno}º TURNO|';
      final nome = j.fase == Fase.classificatoria ? '${j.rodada}ª rodada — classificatória' : j.etapa;
      (grupos['$turno$nome'] ??= []).add(j);
    }
    String? turnoAtual;
    for (final MapEntry(key: k, value: l) in grupos.entries) {
      final partes = k.split('|');
      if (partes.length == 2 && partes[0] != turnoAtual) {
        turnoAtual = partes[0];
        stdout.writeln(turnoAtual);
      }
      final dias = <DateTime, int>{};
      for (final j in l) {
        final d = DateTime(j.inicio.year, j.inicio.month, j.inicio.day);
        dias[d] = (dias[d] ?? 0) + 1;
      }
      final txt = [
        for (final MapEntry(key: d, value: n) in dias.entries)
          '${_2(d.day)}/${_2(d.month)} (${_sem[d.weekday - 1]}) × $n',
      ].join(' · ');
      stdout.writeln('${partes.last} | $txt');
    }
  }
  final geral = montarCalendarioGeral(dados);
  final problemas = verificarCalendario(geral);
  stdout.writeln('INCONSISTENCIAS ${problemas.length}');
  for (final p in problemas) {
    stdout.writeln('R${p.regra.index + 1} ${p.detalhe}');
  }
  final drafts = geral.where((j) => j.ehDraft);
  for (final d in drafts) {
    stdout.writeln('DRAFT ${d.competicao.sigla} ${d.etapa} ${d.inicio}');
  }
}
