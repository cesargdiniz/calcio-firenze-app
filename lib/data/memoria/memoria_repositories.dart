import 'dart:async';

import 'package:calcio_regras/calcio_regras.dart';

import '../../domain/entities/aviso_push.dart';
import '../../domain/usecases/calendario_geral.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/preferencias_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/repositories/usuario_repository.dart';

/// Login em memória, para testes e para rodar sem Firebase.
class MemoriaAuthRepository implements AuthRepository {
  @override
  bool get aceitaLinkPorEmail => true;

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
  Future<void> entrarComApple() async => _definir(_sessaoDe('apple@exemplo.com'));

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
  Future<void> pedirVinculo(Usuario usuario, Vinculo vinculo) async {
    final atual = _usuarios[usuario.uid] ?? usuario;
    _usuarios[usuario.uid] = Usuario(
      uid: usuario.uid,
      email: usuario.email,
      nome: usuario.nome,
      perfil: atual.perfil,
      vinculos: atual.vinculos,
    ).comVinculo(vinculo.comStatus(StatusVinculo.pendente));
    _mudancas.add(usuario.uid);
  }

  @override
  Future<void> excluir(String uid) async {
    _usuarios.remove(uid);
    _mudancas.add(uid);
  }
}

/// Temporadas em memória que aceitam as gravações da Organização (testes).
/// Categorias sem dados informados começam vazias.
class MemoriaTemporadaRepository implements TemporadaRepository {
  final Map<String, DadosTemporada> _temporadas;
  final _mudancas = StreamController<DadosTemporada>.broadcast();

  MemoriaTemporadaRepository(DadosTemporada principal, [List<DadosTemporada> outras = const []])
    : _temporadas = {principal.id: principal, for (final d in outras) d.id: d},
      _principal = principal.id;

  final String _principal;

  /// A temporada informada primeiro (a dos testes de uma categoria só).
  DadosTemporada get dados => _temporadas[_principal]!;

  DadosTemporada daTemporada(String id) => _temporadas[id] ?? _vazia(id);

  void substituir(DadosTemporada d) {
    _temporadas[d.id] = d;
    _mudancas.add(d);
  }

  static DadosTemporada _vazia(String id) {
    final c = Categoria.deTemporada(id) ?? Categoria.master;
    return DadosTemporada(
      id: id,
      nome: c.titulo,
      local: 'Arena Gugu',
      times: const [],
      pessoas: const [],
      partidas: const [],
    );
  }

  @override
  Stream<DadosCalendario> observarCalendario(String temporadaId) => observar(temporadaId).map(
    (d) => DadosCalendario(
      times: d.times,
      partidas: d.demonstracao ? const [] : d.partidas,
      drafts: d.drafts,
    ),
  );

  @override
  Stream<DadosTemporada> observar(String temporadaId) async* {
    yield daTemporada(temporadaId);
    yield* _mudancas.stream.where((d) => d.id == temporadaId);
  }
}

class MemoriaOrganizacaoRepository implements OrganizacaoRepository {
  /// uid → categorias que organiza (lista vazia: ainda não informou). Os
  /// [uids] organizam todas.
  final Map<String, List<Categoria>> contas;
  final _mudancas = StreamController<String>.broadcast();

  MemoriaOrganizacaoRepository([
    Set<String> uids = const {},
    Map<String, List<Categoria>>? porCategoria,
  ]) : contas = {for (final u in uids) u: Categoria.values, ...?porCategoria};

  AcessoOrganizacao _de(String uid) {
    final c = contas[uid];
    return c == null ? AcessoOrganizacao.nenhum : AcessoOrganizacao(ehOrganizacao: true, categorias: c);
  }

  @override
  Stream<AcessoOrganizacao> acesso(String uid) async* {
    yield _de(uid);
    yield* _mudancas.stream.where((u) => u == uid).map(_de);
  }

  @override
  Future<void> definirCategoria(String uid, Categoria categoria) async {
    if (contas[uid]?.isEmpty ?? false) contas[uid] = [categoria];
    _mudancas.add(uid);
  }
}

class MemoriaGestaoRepository implements GestaoRepository {
  final MemoriaUsuarioRepository usuarios;
  final MemoriaTemporadaRepository temporada;
  MemoriaGestaoRepository(this.usuarios, this.temporada);

  final List<Movimentacao> _movimentacoes = [];
  final _mudouMovimentacoes = StreamController<void>.broadcast();

  List<Movimentacao> get movimentacoes => List.unmodifiable(_movimentacoes);

  /// Notificações gravadas (nos testes, para conferir o que seria enviado).
  final List<AvisoPush> avisos = [];

  @override
  Future<void> enviarAvisos(String temporadaId, List<AvisoPush> avisos) async =>
      this.avisos.addAll(avisos);

  Stream<List<Usuario>> _porStatus(String temporadaId, StatusVinculo s) async* {
    List<Usuario> filtrar() => [
      for (final u in usuarios._usuarios.values)
        if (u.vinculoEm(temporadaId) case final v? when v.status == s)
          Usuario(uid: u.uid, email: u.email, nome: u.nome, perfil: u.perfil, vinculos: [v]),
    ];
    yield filtrar();
    yield* usuarios._mudancas.stream.map((_) => filtrar());
  }

  @override
  Stream<List<Usuario>> observarPedidos(String temporadaId) =>
      _porStatus(temporadaId, StatusVinculo.pendente);

  @override
  Stream<List<Usuario>> observarAprovados(String temporadaId) =>
      _porStatus(temporadaId, StatusVinculo.aprovado);

  @override
  Future<void> decidirPedido(String temporadaId, String uid, StatusVinculo status) async {
    final u = usuarios._usuarios[uid]!;
    usuarios._usuarios[uid] = u.comVinculo(u.vinculoEm(temporadaId)!.comStatus(status));
    usuarios._mudancas.add(uid);
  }

  @override
  Future<void> salvarTimes(String temporadaId, List<Time> times) async {
    final d = temporada.daTemporada(temporadaId);
    final porId = {for (final t in d.times) t.id: t, for (final t in times) t.id: t};
    temporada.substituir(_copiar(d, times: porId.values.toList()));
  }

  @override
  Future<void> importarElencos(String temporadaId, Map<String, List<Pessoa>> porTime) async {
    final d = temporada.daTemporada(temporadaId);
    final mantidos = d.demonstracao
        ? <Pessoa>[]
        : d.pessoas.where((p) => !porTime.containsKey(p.timeId)).toList();
    temporada.substituir(
      _copiar(d, pessoas: [...mantidos, for (final l in porTime.values) ...l], demonstracao: false),
    );
  }

  @override
  Future<void> salvarPartidas(String temporadaId, List<Partida> partidas) async {
    final d = temporada.daTemporada(temporadaId);
    final base = d.demonstracao ? <Partida>[] : d.partidas;
    final porId = {for (final p in base) p.id: p, for (final p in partidas) p.id: p};
    temporada.substituir(
      _copiar(
        d,
        pessoas: d.demonstracao ? const [] : d.pessoas,
        partidas: porId.values.toList(),
        demonstracao: false,
      ),
    );
  }

  @override
  Future<void> excluirPartidas(String temporadaId, List<String> ids) async {
    final d = temporada.daTemporada(temporadaId);
    temporada.substituir(
      _copiar(d, partidas: d.partidas.where((p) => !ids.contains(p.id)).toList()),
    );
  }

  @override
  Future<void> registrarPagamento(String temporadaId, String pendenciaId, DateTime pagoEm) async {
    final d = temporada.daTemporada(temporadaId);
    temporada.substituir(
      _copiar(
        d,
        pagamentos: [
          ...d.pagamentos.where((p) => p.pendenciaId != pendenciaId),
          Pagamento(pendenciaId, pagoEm),
        ],
      ),
    );
  }

  @override
  Future<void> desfazerPagamento(String temporadaId, String pendenciaId) async {
    final d = temporada.daTemporada(temporadaId);
    temporada.substituir(
      _copiar(d, pagamentos: d.pagamentos.where((p) => p.pendenciaId != pendenciaId).toList()),
    );
  }

  @override
  Future<void> salvarDecisao(String temporadaId, DecisaoDisciplinar decisao) async {
    final d = temporada.daTemporada(temporadaId);
    temporada.substituir(
      _copiar(d, decisoes: [...d.decisoes.where((x) => x.id != decisao.id), decisao]),
    );
  }

  @override
  Future<void> excluirDecisao(String temporadaId, String decisaoId) async {
    final d = temporada.daTemporada(temporadaId);
    final quitacoes = idsPendenciasDaDecisao(decisaoId);
    temporada.substituir(
      _copiar(
        d,
        decisoes: d.decisoes.where((x) => x.id != decisaoId).toList(),
        pagamentos: d.pagamentos.where((p) => !quitacoes.contains(p.pendenciaId)).toList(),
      ),
    );
  }

  @override
  Future<void> salvarParametros(String temporadaId, Parametros parametros) async =>
      temporada.substituir(_copiar(temporada.daTemporada(temporadaId), parametros: parametros));

  @override
  Future<void> salvarPatrocinador(String temporadaId, String? patrocinador) async =>
      temporada.substituir(
        _copiar(temporada.daTemporada(temporadaId), patrocinador: () => patrocinador),
      );

  @override
  Future<void> salvarDrafts(String temporadaId, Map<int, DateTime> drafts) async =>
      temporada.substituir(_copiar(temporada.daTemporada(temporadaId), drafts: drafts));

  @override
  Future<void> salvarSorteio(String temporadaId, int turno, List<String> ordem) async {
    final d = temporada.daTemporada(temporadaId);
    temporada.substituir(_copiar(d, sorteios: {...d.sorteios, turno: ordem}));
  }

  @override
  Stream<List<Movimentacao>> observarMovimentacoes(String temporadaId) async* {
    yield movimentacoes;
    yield* _mudouMovimentacoes.stream.map((_) => movimentacoes);
  }

  @override
  Future<void> registrarMovimentacao(
    String temporadaId,
    Movimentacao movimentacao, {
    Pessoa? substituto,
  }) async {
    final d = temporada.daTemporada(temporadaId);
    _movimentacoes.add(movimentacao);
    _mudouMovimentacoes.add(null);
    temporada.substituir(
      _copiar(
        d,
        pessoas: [
          for (final p in d.pessoas)
            p.id == movimentacao.pessoaId ? p.comSaida(movimentacao.data) : p,
          ?substituto,
        ],
      ),
    );
  }

  @override
  Future<void> desfazerMovimentacao(String temporadaId, Movimentacao movimentacao) async {
    final d = temporada.daTemporada(temporadaId);
    _movimentacoes.removeWhere((m) => m.id == movimentacao.id);
    _mudouMovimentacoes.add(null);
    temporada.substituir(
      _copiar(
        d,
        pessoas: [
          for (final p in d.pessoas)
            if (p.id != movimentacao.substitutoId)
              p.id == movimentacao.pessoaId ? p.comSaida(null) : p,
        ],
      ),
    );
  }

  static DadosTemporada _copiar(
    DadosTemporada d, {
    Parametros? parametros,
    String? Function()? patrocinador,
    List<Time>? times,
    List<Pessoa>? pessoas,
    List<Partida>? partidas,
    List<Pagamento>? pagamentos,
    List<DecisaoDisciplinar>? decisoes,
    Map<int, List<String>>? sorteios,
    Map<int, DateTime>? drafts,
    bool? demonstracao,
  }) {
    final demo = demonstracao ?? d.demonstracao;
    // Ao sair da demonstração, jogos e cartões de exemplo saem junto.
    final saindoDaDemo = d.demonstracao && !demo;
    return DadosTemporada(
      id: d.id,
      nome: d.nome,
      local: d.local,
      times: times ?? d.times,
      pessoas: pessoas ?? d.pessoas,
      partidas: partidas ?? (saindoDaDemo ? const [] : d.partidas),
      pagamentos: pagamentos ?? (saindoDaDemo ? const [] : d.pagamentos),
      decisoes: decisoes ?? (saindoDaDemo ? const [] : d.decisoes),
      parametros: parametros ?? d.parametros,
      patrocinador: patrocinador == null ? d.patrocinador : patrocinador(),
      ajustes: d.ajustes,
      sorteios: sorteios ?? d.sorteios,
      drafts: drafts ?? d.drafts,
      demonstracao: demo,
      relogio: demo ? d.relogio : null,
    );
  }
}

/// Preferências em memória (testes). [categoriaInicial] simula uma escolha
/// já feita em outra abertura do app.
class MemoriaPreferencias implements PreferenciasRepository {
  String? _categoria;
  String? _perfil;
  MemoriaPreferencias([String? categoriaInicial, String? perfilInicial])
    : _categoria = categoriaInicial,
      _perfil = perfilInicial;

  @override
  Future<String?> perfil() async => _perfil;

  @override
  Future<void> salvarPerfil(String rota) async => _perfil = rota;

  @override
  Future<String?> categoria() async => _categoria;

  @override
  Future<void> salvarCategoria(String temporadaId) async => _categoria = temporadaId;
}
