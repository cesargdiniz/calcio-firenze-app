/// Notificações no celular (Firebase Cloud Messaging).
abstract interface class PushRepository {
  /// Deixa o celular inscrito exatamente nestes tópicos.
  Future<void> sincronizar(Set<String> topicos);

  /// Verdadeiro se o app ainda não perguntou (nem o sistema) se a pessoa
  /// quer receber notificações.
  Future<bool> precisaPerguntar();

  /// A pessoa aceitou na tela do app: pede a permissão do sistema.
  /// Devolve se ficou autorizado.
  Future<bool> autorizar();

  /// A pessoa escolheu "Agora não": não pergunta de novo.
  Future<void> recusar();

  /// Rotas do app abertas por um toque na notificação.
  Stream<String> get rotasAbertas;
}

/// Sem notificações: web, testes e temporada de exemplo.
class PushDesligado implements PushRepository {
  const PushDesligado();

  @override
  Future<void> sincronizar(Set<String> topicos) async {}

  @override
  Future<bool> precisaPerguntar() async => false;

  @override
  Future<bool> autorizar() async => false;

  @override
  Future<void> recusar() async {}

  @override
  Stream<String> get rotasAbertas => const Stream.empty();
}
