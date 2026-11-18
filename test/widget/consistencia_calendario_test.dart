import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  testWidgets('Gestão avisa qual regra do calendário está sendo violada', (tester) async {
    await abrirApp(
      tester,
      inicio: '/organizacao/gestao',
      sessao: const Sessao(uid: 'org1', email: 'cesar@exemplo.com'),
      organizacao: {'org1'},
    );
    expect(find.text('Inconsistência no calendário'), findsOneWidget);
    expect(
      find.text('Regra 5 · Finais de turno e grandes finais sempre aos sábados.'),
      findsOneWidget,
    );
    expect(find.text('• Qua 15/12: L · Grande final.'), findsOneWidget);
  });
}
