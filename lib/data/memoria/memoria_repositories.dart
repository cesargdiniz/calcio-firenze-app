import 'dart:async';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/usuario_repository.dart';

/// Login em memória, para testes e para rodar sem Firebase.
class MemoriaAuthRepository implements AuthRepository {
  Sessao? _sessao;
  final _mudancas = StreamController<Sessao?>.broadcast();
  final Map<String, String> _senhas = {};

  /// E-mails para os quais um link foi "enviado".
  final List<String> linksEnviados = [];

  MemoriaAuthRepository({Sessao? sessao}) : _sessao = sessao;

  void _definir(Sessao? s) {
    _sessao = s;
    _mudancas.add(s);
  }

  Sessao _sessaoDe(String email) => Sessao(uid: 'uid-$email', email: email);

  @override
  Stream<Sessao?> observarSessao() async* {
    yield _sessao;
    yield* _mudancas.stream;
  }

  @override
  Future<void> entrarComGoogle() async => _definir(_sessaoDe('google@exemplo.com'));

  @override
  Future<void> enviarLinkPorEmail(String email) async => linksEnviados.add(email);

  @override
  Future<bool> concluirLinkSeHouver(String link) async => false;

  @override
  Future<void> entrarComSenha(String email, String senha) async {
    if (_senhas[email] != senha) throw const FalhaLogin('E-mail ou senha incorretos.');
    _definir(_sessaoDe(email));
  }

  @override
  Future<void> criarContaComSenha(String email, String senha) async {
    _senhas[email] = senha;
    _definir(_sessaoDe(email));
  }

  @override
  Future<void> redefinirSenha(String email) async {}

  @override
  Future<void> sair() async => _definir(null);

  @override
  Future<void> excluirConta() async => _definir(null);
}

class MemoriaUsuarioRepository implements UsuarioRepository {
  final Map<String, Usuario> _usuarios;
  final _mudancas = StreamController<String>.broadcast();

  MemoriaUsuarioRepository([Map<String, Usuario>? iniciais]) : _usuarios = {...?iniciais};

  @override
  Stream<Usuario?> observar(String uid) async* {
    yield _usuarios[uid];
    yield* _mudancas.stream.where((u) => u == uid).map((_) => _usuarios[uid]);
  }

  @override
  Future<void> pedirVinculo(Usuario usuario) async {
    _usuarios[usuario.uid] = usuario;
    _mudancas.add(usuario.uid);
  }

  @override
  Future<void> excluir(String uid) async {
    _usuarios.remove(uid);
    _mudancas.add(uid);
  }
}
