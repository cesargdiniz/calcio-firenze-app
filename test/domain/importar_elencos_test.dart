import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/importar_elencos.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

String elenco(String time, {int atletas = 12, int goleiros = 1, bool repetido = false}) {
  final b = StringBuffer();
  for (var n = 1; n <= atletas; n++) {
    final numero = repetido && n == 2 ? 1 : n;
    final pos = n <= goleiros ? 'Goleiro' : 'Linha';
    final funcao = n == 9 ? 'Dirigente' : 'Atleta';
    b.writeln('$time\t$numero\tATLETA $n DO $time\t$pos\t$funcao');
  }
  b.writeln('$time\t\tTécnico do $time\t\tTécnico');
  return b.toString();
}

void main() {
  final times = montarTemporadaExemplo().times;
  final importar = ImportarElencos();

  test('elenco completo colado do Excel (tabulação), com cabeçalho', () {
    final r = importar('Time\tNº\tNome\tPosição\tFunção\n${elenco('SAM')}', times);
    final sam = r.times.single;
    expect(sam.ok, isTrue);
    expect(sam.avisos, isEmpty);
    expect(sam.atletas, 12);
    expect(sam.pessoas.where((p) => p.funcao == Funcao.tecnico).single.id, 'sam-tecnico');
    expect(sam.pessoas.firstWhere((p) => p.numero == 9).dirigente, isTrue);
    expect(sam.pessoas.firstWhere((p) => p.numero == 1).goleiro, isTrue);
    expect(sam.pessoas.first.nome, 'Atleta 1 do Sam');
    expect(r.linhasIgnoradas, isEmpty);
  });

  test('time por nome e separador ponto e vírgula', () {
    final r = importar('Marinai Blu;7;Rafael Souza;L;Atleta', times);
    expect(r.times.single.time.id, 'SAM');
    expect(r.times.single.pessoas.single.id, 'sam-7');
  });

  test('confere goleiros e números repetidos', () {
    final r = importar(elenco('INT', goleiros: 2) + elenco('FIO', repetido: true), times);
    final inter = r.times.firstWhere((t) => t.time.id == 'INT');
    final fio = r.times.firstWhere((t) => t.time.id == 'FIO');
    expect(inter.ok, isFalse);
    expect(inter.erros.single, contains('2 goleiros'));
    expect(fio.erros.any((e) => e.contains('repetido')), isTrue);
  });

  test('elenco com menos de 12 é aviso, não erro', () {
    final r = importar(elenco('JUV', atletas: 11), times);
    expect(r.times.single.ok, isTrue);
    expect(r.times.single.avisos.first, contains('11 atletas'));
  });

  test('linhas com problema são ignoradas e explicadas', () {
    final r = importar(
      'XYZ\t1\tFulano\t\t\nSAM\t\tSem Número\t\tAtleta\nSAM\t120\tBeltrano',
      times,
    );
    expect(r.linhasIgnoradas.keys, [1, 2, 3]);
    expect(r.linhasIgnoradas[1], contains('XYZ'));
  });
}
