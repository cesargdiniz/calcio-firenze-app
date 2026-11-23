import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/entities/superconta.dart';
import 'package:calcio_firenze/domain/usecases/calendario_geral.dart';
import 'package:calcio_firenze/domain/usecases/gerar_calendario.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AjustesCalendario.definir(const {}));

  test('horários de um dia: semana às 20:30, sábado a partir das 17h, jogo único às 19h', () {
    expect(horariosNoDia(DateTime(2027, 1, 25), 0, 2), [
      DateTime(2027, 1, 25, 20, 30),
      DateTime(2027, 1, 25, 21, 30),
    ]);
    expect(horariosNoDia(DateTime(2027, 1, 25), 1, 1), [DateTime(2027, 1, 25, 21, 30)]);
    expect(horariosNoDia(DateTime(2027, 1, 30), 0, 1), [DateTime(2027, 1, 30, 19)]);
    expect(horariosNoDia(DateTime(2027, 1, 30), 2, 2), [
      DateTime(2027, 1, 30, 19),
      DateTime(2027, 1, 30, 20),
    ]);
  });

  test('sem ajustes, os horários são os do código', () {
    expect(horariosDe(Categoria.master), same(horariosMaster2027));
  });

  test('dia mudado vale para o sorteio, o mata-mata, a Copa e o calendário geral', () {
    final quartas = DateTime(2027, 5, 11, 20, 30);
    final copa = DateTime(2027, 6, 16, 20, 30);
    AjustesCalendario.definir({
      quartas: DateTime(2027, 5, 12, 20, 30),
      copa: DateTime(2027, 6, 17, 20, 30),
      // Igual ao oficial: não conta como mudança.
      DateTime(2027, 6, 12, 19): DateTime(2027, 6, 12, 19),
    });
    expect(AjustesCalendario.atual, hasLength(2));
    expect(horariosDe(Categoria.master)[1], contains(DateTime(2027, 5, 12, 20, 30)));
    expect(horariosDe(Categoria.master)[1], isNot(contains(quartas)));
    expect(horariosMaster2027[1], contains(quartas), reason: 'o oficial não muda');

    final qf = datasMataMata(Categoria.master, 1).firstWhere((d) => d.fase == Fase.quartas);
    expect(qf.horarios.first, DateTime(2027, 5, 12, 20, 30));
    expect(datasCopaMaster2027.last.horarios, [DateTime(2027, 6, 17, 20, 30)]);

    final geral = montarCalendarioGeral(const {});
    final movido = geral.firstWhere((j) => j.oficial == quartas);
    expect(movido.inicio, DateTime(2027, 5, 12, 20, 30));
    expect(movido.etapa, 'Quartas de final');
    expect(geral.firstWhere((j) => j.oficial == copa).inicio, DateTime(2027, 6, 17, 20, 30));
  });

  test('supercontas', () {
    expect(ehSuperconta('cesargdiniz@gmail.com'), isTrue);
    expect(ehSuperconta('CesarGDiniz@gmail.com'), isTrue);
    expect(ehSuperconta('outro@gmail.com'), isFalse);
    expect(ehSuperconta(null), isFalse);
  });
}
