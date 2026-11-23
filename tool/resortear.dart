// Refaz o sorteio dos turnos já sorteados cujas datas não batem com o
// calendário oficial (gerar_calendario.dart). Lê o JSON de
// tool/resortear/firestore.js e escreve o plano de gravação.
//
//   TZ=America/Sao_Paulo dart run tool/resortear.dart entrada.json plano.json
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';

void main(List<String> args) {
  final entrada = jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  final plano = <String, Object>{};
  var erro = false;
  for (final c in Categoria.values) {
    final dados = entrada[c.temporadaId] as Map<String, dynamic>?;
    if (dados == null) continue;
    final times = (dados['times'] as List).cast<String>();
    final partidas = (dados['partidas'] as List).cast<Map<String, dynamic>>();
    final remover = <String>[];
    final salvar = <Map<String, Object?>>[];
    for (final turno in [1, 2]) {
      final oficiais = [...horariosDe(c)[turno]!]..sort();
      final atuais = [
        for (final p in partidas)
          if (p['turno'] == turno && p['fase'] == 'classificatoria') p,
      ];
      final elim = [
        for (final p in partidas)
          if ((p['turno'] == turno || (turno == 2 && p['turno'] == 0)) &&
              p['fase'] != 'classificatoria')
            p,
      ];
      if (atuais.isEmpty) {
        stdout.writeln('${c.sigla} $turnoº turno: ainda não sorteado (usa as datas novas ao sortear).');
        continue;
      }
      final datas = [for (final p in atuais) DateTime.parse(p['inicio'] as String)]..sort();
      final iguais = datas.length <= oficiais.length &&
          [for (var i = 0; i < datas.length; i++) datas[i].isAtSameMomentAs(oficiais[i])]
              .every((x) => x);
      if (iguais) {
        stdout.writeln('${c.sigla} $turnoº turno: já está nas datas oficiais, mantido.');
        continue;
      }
      if (atuais.any((p) => p['encerrada'] == true)) {
        stderr.writeln('${c.sigla} $turnoº turno: tem súmula encerrada, não refaço.');
        erro = true;
        continue;
      }
      if (times.length != c.times) {
        stderr.writeln('${c.sigla}: ${times.length} times cadastrados, esperado ${c.times}.');
        erro = true;
        continue;
      }
      if (elim.isNotEmpty) {
        stdout.writeln('${c.sigla} $turnoº turno: removo ${elim.length} jogos de mata-mata '
            'criados com as datas antigas (o app propõe de novo ao fim da fase).');
        if (elim.any((p) => p['encerrada'] == true)) {
          stderr.writeln('${c.sigla} $turnoº turno: mata-mata com súmula, não refaço.');
          erro = true;
          continue;
        }
        remover.addAll([for (final p in elim) p['id'] as String]);
      }
      final novos = const GerarCalendario()(
        turno: turno,
        times: times,
        horarios: oficiais,
        sorteio: Random(),
      );
      final ids = {for (final p in novos) p.id};
      remover.addAll([
        for (final p in atuais)
          if (!ids.contains(p['id'])) p['id'] as String,
      ]);
      salvar.addAll([
        for (final p in novos)
          {
            'id': p.id,
            'turno': p.turno,
            'fase': p.fase.name,
            'rodada': p.rodada,
            'mandanteId': p.mandanteId,
            'visitanteId': p.visitanteId,
            'inicio': p.inicio.toUtc().toIso8601String(),
            'local': p.local,
          },
      ]);
      stdout.writeln('${c.sigla} $turnoº turno: sorteio refeito, ${novos.length} jogos de '
          '${novos.map((p) => p.inicio).reduce((a, b) => a.isBefore(b) ? a : b)} em diante.');
    }
    if (remover.isNotEmpty || salvar.isNotEmpty) {
      plano[c.temporadaId] = {'remover': remover, 'salvar': salvar};
    }
  }
  File(args[1]).writeAsStringSync(jsonEncode(plano));
  if (erro) exit(1);
}
