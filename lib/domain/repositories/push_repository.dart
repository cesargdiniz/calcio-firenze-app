/// Notificações no celular (Firebase Cloud Messaging).
abstract interface class PushRepository {
  /// Deixa o celular inscrito exatamente nestes tópicos (pede a permissão
  /// na primeira vez).
  Future<void> sincronizar(Set<String> topicos);

  /// Rotas do app abertas por um toque na notificação.
  Stream<String> get rotasAbertas;
}

/// Sem notificações: web, testes e temporada de exemplo.
class PushDesligado implements PushRepository {
  const PushDesligado();

  @override
  Future<void> sincronizar(Set<String> topicos) async {}

  @override
  Stream<String> get rotasAbertas => const Stream.empty();
}
