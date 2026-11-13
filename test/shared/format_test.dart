import 'package:calcio_firenze/shared/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('centavosDe lê o valor digitado', () {
    expect(centavosDe('100'), 10000);
    expect(centavosDe('100,5'), 10050);
    expect(centavosDe('R\$ 1.250,00'), 125000);
    expect(centavosDe(''), 0);
    expect(centavosDe('abc'), isNull);
    expect(centavosDe('10,123'), isNull);
  });

  test('valorParaCampo devolve o que centavosDe entende', () {
    expect(valorParaCampo(0), '');
    expect(valorParaCampo(10000), '100');
    expect(valorParaCampo(10050), '100,50');
    expect(centavosDe(valorParaCampo(2505)), 2505);
  });
}
