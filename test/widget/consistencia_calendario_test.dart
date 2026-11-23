import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/calendario_geral.dart';
import 'package:calcio_firenze/domain/usecases/verificar_calendario.dart';
import 'package:calcio_firenze/modules/calendario/consistencia_calendario.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  testWidgets('Gestão mostra o calendário sem inconsistências', (tester) async {
    await abrirApp(
      tester,
      inicio: '/organizacao/gestao',
      sessao: const Sessao(uid: 'org1', email: 'cesar@exemplo.com'),
      organizacao: {'org1'},
    );
    expect(find.textContaining('Calendário sem inconsistências'), findsOneWidget);
  });

  testWidgets('quadro de inconsistências diz qual regra foi violada', (tester) async {
    final jogo = JogoDoCalendario(
      inicio: DateTime(2027, 12, 15, 20, 30),
      competicao: Competicao.livre,
      etapa: 'Grande final',
      turno: 0,
      fase: Fase.grandeFinal,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuadroInconsistencias(verificarCalendario([jogo]))),
      ),
    );
    expect(find.text('Inconsistência no calendário'), findsOneWidget);
    expect(
      find.text(
        'Regra 5 · Finais de turno e grandes finais do Master aos sábados; do Livre, na sexta '
        'ou no sábado; do Super Master, na quinta, na sexta ou no sábado.',
      ),
      findsOneWidget,
    );
    expect(find.text('• Qua 15/12: L · Grande final.'), findsOneWidget);
  });
}
