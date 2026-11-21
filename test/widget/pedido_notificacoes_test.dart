import 'package:calcio_firenze/domain/repositories/push_repository.dart';
import 'package:calcio_firenze/modules/push/pedido_notificacoes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Push implements PushRepository {
  _Push({this.perguntar = true});
  bool perguntar;
  int autorizou = 0;
  int recusou = 0;

  @override
  Future<void> sincronizar(Set<String> topicos) async {}
  @override
  Future<bool> precisaPerguntar() async => perguntar;
  @override
  Future<bool> autorizar() async {
    autorizou++;
    return true;
  }

  @override
  Future<void> recusar() async => recusou++;
  @override
  Stream<String> get rotasAbertas => const Stream.empty();
}

Future<void> _abrir(WidgetTester t, _Push push, {bool pronto = true}) => t.pumpWidget(
  MaterialApp(
    home: PedidoNotificacoes(push: push, pronto: pronto, child: const Text('App')),
  ),
);

void main() {
  testWidgets('pede a autorização e chama o pedido do sistema ao aceitar', (t) async {
    final push = _Push();
    await _abrir(t, push);
    await t.pumpAndSettle();
    expect(find.textContaining('resultados dos jogos, suspensões, multas'), findsOneWidget);
    await t.tap(find.text('Sim, autorizo'));
    await t.pumpAndSettle();
    expect(push.autorizou, 1);
    expect(find.text('Sim, autorizo'), findsNothing);
  });

  testWidgets('"Agora não" fecha sem pedir ao sistema', (t) async {
    final push = _Push();
    await _abrir(t, push);
    await t.pumpAndSettle();
    await t.tap(find.text('Agora não'));
    await t.pumpAndSettle();
    expect(push.recusou, 1);
    expect(push.autorizou, 0);
  });

  testWidgets('não aparece antes da categoria nem para quem já respondeu', (t) async {
    await _abrir(t, _Push(), pronto: false);
    await t.pumpAndSettle();
    expect(find.text('Sim, autorizo'), findsNothing);

    await _abrir(t, _Push(perguntar: false));
    await t.pumpAndSettle();
    expect(find.text('Sim, autorizo'), findsNothing);
  });
}
