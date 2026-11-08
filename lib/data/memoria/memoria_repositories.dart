import 'dart:async';

import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
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

/// Temporada em memória que aceita as gravações da Organização (testes).
class MemoriaTemporadaRepository implements TemporadaRepository {
  DadosTemporada _dados;
  final _mudancas = StreamController<DadosTemporada>.broadcast();

  MemoriaTemporadaRepository(this._dados);

  DadosTemporada get dados => _dados;

  void substituir(DadosTemporada d) {
    _dados = d;
    _mudancas.add(d);
  }

  @override
  Stream<DadosTemporada> observar() async* {
    yield _dados;
    yield* _mudancas.stream;
  }
}

class MemoriaOrganizacaoRepository implements OrganizacaoRepository {
  final Set<String> uids;
  MemoriaOrganizacaoRepository([this.uids = const {}]);

  @override
  Stream<bool> ehOrganizacao(String uid) => Stream.value(uids.contains(uid));
}

class MemoriaGestaoRepository implements GestaoRepository {
  final MemoriaUsuarioRepository usuarios;
  final MemoriaTemporadaRepository temporada;
  MemoriaGestaoRepository(this.usuarios, this.temporada);

  Stream<List<Usuario>> _porStatus(StatusVinculo s) async* {
    List<Usuario> filtrar() =>
        usuarios._usuarios.values.where((u) => u.vinculo?.status == s).toList();
    yield filtrar();
    yield* usuarios._mudancas.stream.map((_) => filtrar());
  }

  @override
  Stream<List<Usuario>> observarPedidos() => _porStatus(StatusVinculo.pendente);

  @override
  Stream<List<Usuario>> observarAprovados() => _porStatus(StatusVinculo.aprovado);

  @override
  Future<void> decidirPedido(String uid, StatusVinculo status) async {
    final u = usuarios._usuarios[uid]!;
    final v = u.vinculo!;
    usuarios._usuarios[uid] = Usuario(
      uid: u.uid,
      email: u.email,
      nome: u.nome,
      perfil: u.perfil,
      vinculo: Vinculo(
        temporadaId: v.temporadaId,
        pessoaId: v.pessoaId,
        timeId: v.timeId,
        papel: v.papel,
        status: status,
      ),
    );
    usuarios._mudancas.add(uid);
  }

  @override
  Future<void> salvarTimes(String temporadaId, List<Time> times) async {
    final d = temporada.dados;
    final porId = {for (final t in d.times) t.id: t, for (final t in times) t.id: t};
    temporada.substituir(_copiar(d, times: porId.values.toList()));
  }

  @override
  Future<void> importarElencos(String temporadaId, Map<String, List<Pessoa>> porTime) async {
    final d = temporada.dados;
    final mantidos = d.demonstracao
        ? <Pessoa>[]
        : d.pessoas.where((p) => !porTime.containsKey(p.timeId)).toList();
    temporada.substituir(
      _copiar(d, pessoas: [...mantidos, for (final l in porTime.values) ...l], demonstracao: false),
    );
  }

  static DadosTemporada _copiar(
    DadosTemporada d, {
    List<Time>? times,
    List<Pessoa>? pessoas,
    bool? demonstracao,
  }) => DadosTemporada(
    id: d.id,
    nome: d.nome,
    local: d.local,
    times: times ?? d.times,
    pessoas: pessoas ?? d.pessoas,
    partidas: (demonstracao ?? d.demonstracao) ? d.partidas : const [],
    decisoes: (demonstracao ?? d.demonstracao) ? d.decisoes : const [],
    demonstracao: demonstracao ?? d.demonstracao,
  );
}
