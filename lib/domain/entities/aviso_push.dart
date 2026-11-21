/// Notificação para os celulares inscritos em [topico]. O app grava o aviso
/// em `temporadas/{id}/avisosPush` e um serviço no Firebase faz o envio.
class AvisoPush {
  final String topico;
  final String titulo;
  final String corpo;

  /// Rota do app aberta ao tocar na notificação (ex.: `/torcedor/jogos/p1`).
  final String? rota;

  const AvisoPush({required this.topico, required this.titulo, required this.corpo, this.rota});

  @override
  bool operator ==(Object other) =>
      other is AvisoPush &&
      other.topico == topico &&
      other.titulo == titulo &&
      other.corpo == corpo &&
      other.rota == rota;

  @override
  int get hashCode => Object.hash(topico, titulo, corpo, rota);

  @override
  String toString() => 'AvisoPush($topico: $titulo · $corpo)';
}
