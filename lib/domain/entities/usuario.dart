/// Quem está logado no aparelho (vem do Firebase Auth).
class Sessao {
  final String uid;
  final String email;
  final String? nome;

  const Sessao({required this.uid, required this.email, this.nome});
}

enum PerfilUsuario { participante, organizacao }

/// Papel escolhido no pedido de vínculo (tela "Vincular ao elenco").
enum Papel {
  atleta,
  dirigente,
  tecnico;

  String get rotulo => switch (this) {
    Papel.atleta => 'Atleta',
    Papel.dirigente => 'Dirigente',
    Papel.tecnico => 'Técnico',
  };

  /// Dirigente e técnico veem as pendências do time (especificação).
  bool get veTime => this != Papel.atleta;
}

enum StatusVinculo { pendente, aprovado, recusado }

/// Pedido para ligar a conta a uma pessoa do elenco. A Organização aprova.
class Vinculo {
  final String temporadaId;
  final String pessoaId;
  final String timeId;
  final Papel papel;
  final StatusVinculo status;

  const Vinculo({
    required this.temporadaId,
    required this.pessoaId,
    required this.timeId,
    required this.papel,
    this.status = StatusVinculo.pendente,
  });
}

/// Cadastro do usuário no app (documento `usuarios/{uid}`).
class Usuario {
  final String uid;
  final String email;
  final String nome;
  final PerfilUsuario perfil;
  final Vinculo? vinculo;

  const Usuario({
    required this.uid,
    required this.email,
    required this.nome,
    this.perfil = PerfilUsuario.participante,
    this.vinculo,
  });
}
