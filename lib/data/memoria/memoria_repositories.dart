import 'dart:async';

import 'package:calcio_regras/calcio_regras.dart';

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

  final List<Movimentacao> _movimentacoes = [];
  final _mudouMovimentacoes = StreamController<void>.broadcast();

  List<Movimentacao> get movimentacoes => List.unmodifiable(_movimentacoes);

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

  @override
  Future<void> salvarPartidas(String temporadaId, List<Partida> partidas) async {
    final d = temporada.dados;
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
    final d = temporada.dados;
    temporada.substituir(
      _copiar(d, partidas: d.partidas.where((p) => !ids.contains(p.id)).toList()),
    );
  }

  @override
  Future<void> registrarPagamento(String temporadaId, String pendenciaId, DateTime pagoEm) async {
    final d = temporada.dados;
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
    final d = temporada.dados;
    temporada.substituir(
      _copiar(d, pagamentos: d.pagamentos.where((p) => p.pendenciaId != pendenciaId).toList()),
    );
  }

  @override
  Future<void> salvarDecisao(String temporadaId, DecisaoDisciplinar decisao) async {
    final d = temporada.dados;
    temporada.substituir(
      _copiar(d, decisoes: [...d.decisoes.where((x) => x.id != decisao.id), decisao]),
    );
  }

  @override
  Future<void> excluirDecisao(String temporadaId, String decisaoId) async {
    final d = temporada.dados;
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
      temporada.substituir(_copiar(temporada.dados, parametros: parametros));

  @override
  Future<void> salvarPatrocinador(String temporadaId, String? patrocinador) async =>
      temporada.substituir(_copiar(temporada.dados, patrocinador: () => patrocinador));

  @override
  Stream<List<Movimentacao>> observarMovimentacoes() async* {
    yield movimentacoes;
    yield* _mudouMovimentacoes.stream.map((_) => movimentacoes);
  }

  @override
  Future<void> registrarMovimentacao(
    String temporadaId,
    Movimentacao movimentacao, {
    Pessoa? substituto,
  }) async {
    final d = temporada.dados;
    _movimentacoes.add(movimentacao);
    _mudouMovimentacoes.add(null);
    temporada.substituir(
      _copiar(
        d,
        pessoas: [
          for (final p in d.pessoas)
            p.id == movimentacao.pessoaId ? p.comSaida(movimentacao.data) : p,
          if (substituto != null) substituto,
        ],
      ),
    );
  }

  @override
  Future<void> desfazerMovimentacao(String temporadaId, Movimentacao movimentacao) async {
    final d = temporada.dados;
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
      demonstracao: demo,
      relogio: demo ? d.relogio : null,
    );
  }
}
