import 'dart:async';

import 'package:calcio_regras/calcio_regras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/aviso_push.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/calendario_geral.dart';
import '../exemplo/temporada_exemplo.dart';
import 'firestore_usuario_repository.dart';
import 'mapeadores.dart';

/// Temporada no Firestore: `temporadas/{id}/times`, `/pessoas`, `/partidas`,
/// `/decisoes` e `/pagamentos`. Uma temporada por categoria.
///
/// No Master, enquanto não houver elencos nem jogos cadastrados, mostra a
/// temporada de exemplo (com os times já salvos no Firestore, se houver). As
/// outras categorias começam vazias, com os times que a Organização cadastrar.
class FirestoreTemporadaRepository implements TemporadaRepository {
  final FirebaseFirestore _db;

  FirestoreTemporadaRepository(this._db);

  @override
  Stream<DadosTemporada> observar(String temporadaId) {
    final categoria = Categoria.deTemporada(temporadaId) ?? Categoria.master;
    CollectionReference<Map<String, dynamic>> col(String nome) =>
        _db.collection('temporadas').doc(temporadaId).collection(nome);

    late StreamController<DadosTemporada> saida;
    final subs = <StreamSubscription<void>>[];
    List<Time>? times;
    List<Pessoa>? pessoas;
    List<Partida>? partidas;
    List<Pagamento>? pagamentos;
    List<DecisaoDisciplinar>? decisoes;
    Parametros? parametros;
    String? patrocinador;
    var sorteios = const <int, List<String>>{};
    var drafts = const <int, DateTime>{};

    void emitir() {
      if (times == null ||
          pessoas == null ||
          partidas == null ||
          pagamentos == null ||
          decisoes == null ||
          parametros == null) {
        return;
      }
      final porId = {
        if (categoria == Categoria.master)
          for (final t in timesMaster2027) t.id: t,
      };
      for (final t in times!) {
        porId[t.id] = t;
      }
      final listaTimes = porId.values.toList();
      if (categoria != Categoria.master && pessoas!.isEmpty && partidas!.isEmpty) {
        // Livre e Super Master sem elencos nem jogos: times fictícios e os
        // dois turnos já sorteados (com cor e escudo salvos na Gestão).
        final salvos = {for (final t in times!) t.id: t};
        final demo = montarCategoriaSorteada(
          categoria,
          times: [for (final t in timesPadrao(categoria)) salvos[t.id] ?? t],
          parametros: parametros,
        );
        saida.add(
          DadosTemporada(
            id: demo.id,
            nome: demo.nome,
            local: demo.local,
            times: demo.times,
            pessoas: demo.pessoas,
            partidas: demo.partidas,
            parametros: parametros!,
            patrocinador: patrocinador,
            sorteios: sorteios,
            drafts: drafts,
            demonstracao: true,
          ),
        );
      } else if (categoria == Categoria.master && pessoas!.isEmpty && partidas!.isEmpty) {
        final exemplo = montarTemporadaExemplo();
        saida.add(
          DadosTemporada(
            id: exemplo.id,
            nome: exemplo.nome,
            local: exemplo.local,
            times: listaTimes,
            pessoas: exemplo.pessoas,
            partidas: exemplo.partidas,
            decisoes: exemplo.decisoes,
            parametros: parametros!,
            patrocinador: patrocinador,
            // Datas e sorteios da Organização valem também na demonstração.
            sorteios: sorteios,
            drafts: drafts,
            demonstracao: true,
            relogio: exemplo.relogio,
          ),
        );
      } else {
        saida.add(
          DadosTemporada(
            id: temporadaId,
            nome: categoria.titulo,
            local: 'Arena Gugu',
            times: listaTimes,
            pessoas: pessoas!,
            partidas: partidas!,
            pagamentos: pagamentos!,
            parametros: parametros!,
            patrocinador: patrocinador,
            sorteios: sorteios,
            drafts: drafts,
            // Decisão cujo jogo de origem saiu do calendário não tem como ser
            // calculada; fica de fora em vez de derrubar as telas.
            decisoes: [
              for (final x in decisoes!)
                if (partidas!.any((p) => p.id == x.partidaOrigemId)) x,
            ],
          ),
        );
      }
    }

    void ouvir<T>(
      String colecao,
      T Function(String, Map<String, dynamic>) ler,
      void Function(List<T>) guardar, {
      bool opcional = false,
    }) {
      subs.add(
        col(colecao).snapshots().listen(
          (s) {
            // Documento com formato inesperado vira erro do fluxo (e aparece
            // na tela), em vez de sumir e deixar a tela carregando para sempre.
            try {
              guardar([for (final d in s.docs) ler(d.id, d.data())]);
              emitir();
            } catch (e) {
              saida.addError('$colecao: $e');
            }
          },
          onError: (Object e) {
            // Pagamentos só podem ser lidos com login: o Torcedor segue sem eles.
            // Decisões: uma falha de leitura não pode derrubar a tabela e os jogos.
            if (opcional) {
              guardar(<T>[]);
              emitir();
            } else {
              saida.addError(e);
            }
          },
        ),
      );
    }

    saida = StreamController<DadosTemporada>(
      onListen: () {
        ouvir<Time>('times', timeDeMapa, (l) => times = l);
        ouvir<Pessoa>('pessoas', pessoaDeMapa, (l) => pessoas = l);
        ouvir<Partida>('partidas', partidaDeMapa, (l) => partidas = l);
        ouvir<Pagamento>(
          'pagamentos',
          (id, m) => Pagamento(id, (m['pagoEm'] as Timestamp).toDate()),
          (l) => pagamentos = l,
          opcional: true,
        );
        ouvir<DecisaoDisciplinar>('decisoes', decisaoDeMapa, (l) => decisoes = l, opcional: true);
        // Parâmetros ficam no documento da temporada; sem ele (ou se a
        // leitura falhar), valem os do regulamento.
        subs.add(
          _db.collection('temporadas').doc(temporadaId).snapshots().listen(
            (s) {
              try {
                parametros = parametrosDeMapa(s.data()?['parametros'] as Map<String, dynamic>?);
                patrocinador = s.data()?['patrocinador'] as String?;
                sorteios = sorteiosDeMapa(s.data()?['sorteios']);
                drafts = draftsDeMapa(s.data());
                emitir();
              } catch (e) {
                saida.addError('temporada: $e');
              }
            },
            onError: (Object _) {
              parametros = Parametros.master2027;
              emitir();
            },
          ),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return saida.stream;
  }

  @override
  Stream<DadosCalendario> observarCalendario(String temporadaId) {
    final categoria = Categoria.deTemporada(temporadaId) ?? Categoria.master;
    final ref = _db.collection('temporadas').doc(temporadaId);
    late StreamController<DadosCalendario> saida;
    final subs = <StreamSubscription<void>>[];
    List<Time>? times;
    List<Partida>? partidas;
    var drafts = const <int, DateTime>{};
    void emitir() {
      if (times == null || partidas == null) return;
      final porId = {
        if (categoria == Categoria.master)
          for (final t in timesMaster2027) t.id: t,
        for (final t in times!) t.id: t,
      };
      saida.add(
        DadosCalendario(times: porId.values.toList(), partidas: partidas!, drafts: drafts),
      );
    }

    saida = StreamController<DadosCalendario>(
      onListen: () {
        subs.add(
          ref.collection('times').snapshots().listen((s) {
            try {
              times = [for (final d in s.docs) timeDeMapa(d.id, d.data())];
              emitir();
            } catch (e) {
              saida.addError('times: $e');
            }
          }, onError: saida.addError),
        );
        subs.add(
          ref.collection('partidas').snapshots().listen((s) {
            try {
              partidas = [for (final d in s.docs) partidaDeMapa(d.id, d.data())];
              emitir();
            } catch (e) {
              saida.addError('partidas: $e');
            }
          }, onError: saida.addError),
        );
        subs.add(
          ref.snapshots().listen((s) {
            drafts = draftsDeMapa(s.data());
            emitir();
          }, onError: (Object _) {}),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return saida.stream;
  }
}

/// `organizacao/{uid}`: quem existe ali é da Organização. O campo
/// `temporadas` (lista de ids) diz quais categorias a pessoa organiza; sem
/// ele, ela ainda precisa informar a categoria no perfil.
class FirestoreOrganizacaoRepository implements OrganizacaoRepository {
  final FirebaseFirestore _db;
  FirestoreOrganizacaoRepository(this._db);

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('organizacao').doc(uid);

  @override
  Stream<AcessoOrganizacao> acesso(String uid) => _doc(uid).snapshots().map((s) {
    if (!s.exists) return AcessoOrganizacao.nenhum;
    final ids = s.data()?['temporadas'];
    return AcessoOrganizacao(
      ehOrganizacao: true,
      categorias: [
        if (ids is List)
          for (final c in Categoria.values)
            if (ids.contains(c.temporadaId)) c,
      ],
    );
  });

  @override
  Future<void> definirCategoria(String uid, Categoria categoria) =>
      _doc(uid).update({'temporadas': [categoria.temporadaId]});
}

class FirestoreGestaoRepository implements GestaoRepository {
  final FirebaseFirestore _db;

  FirestoreGestaoRepository(this._db);

  Stream<List<Usuario>> _porStatus(String temporadaId, StatusVinculo status) =>
      _col(temporadaId, 'vinculos')
          .where('status', isEqualTo: status.name)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs) FirestoreUsuarioRepository.pedidoDeMapa(temporadaId, d.id, d.data()),
            ],
          );

  @override
  Stream<List<Usuario>> observarPedidos(String temporadaId) =>
      _porStatus(temporadaId, StatusVinculo.pendente);

  @override
  Stream<List<Usuario>> observarAprovados(String temporadaId) =>
      _porStatus(temporadaId, StatusVinculo.aprovado);

  @override
  Future<void> decidirPedido(String temporadaId, String uid, StatusVinculo status) =>
      _col(temporadaId, 'vinculos').doc(uid).update({
        'status': status.name,
        'decididoEm': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> salvarTimes(String temporadaId, List<Time> times) async {
    final lote = _db.batch();
    final col = _db.collection('temporadas').doc(temporadaId).collection('times');
    for (final t in times) {
      lote.set(col.doc(t.id), timeParaMapa(t), SetOptions(merge: true));
    }
    await lote.commit();
  }

  @override
  Future<void> importarElencos(String temporadaId, Map<String, List<Pessoa>> porTime) async {
    final col = _db.collection('temporadas').doc(temporadaId).collection('pessoas');
    for (final MapEntry(key: timeId, value: pessoas) in porTime.entries) {
      final antigos = await col.where('timeId', isEqualTo: timeId).get();
      final lote = _db.batch();
      final novos = {for (final p in pessoas) p.id};
      for (final d in antigos.docs) {
        if (!novos.contains(d.id)) lote.delete(d.reference);
      }
      for (final p in pessoas) {
        lote.set(col.doc(p.id), pessoaParaMapa(p));
      }
      await lote.commit();
    }
  }

  CollectionReference<Map<String, dynamic>> _col(String temporadaId, String nome) =>
      _db.collection('temporadas').doc(temporadaId).collection(nome);

  @override
  Future<void> salvarPartidas(String temporadaId, List<Partida> partidas) async {
    final col = _col(temporadaId, 'partidas');
    for (var i = 0; i < partidas.length; i += 400) {
      final lote = _db.batch();
      for (final p in partidas.skip(i).take(400)) {
        lote.set(col.doc(p.id), partidaParaMapa(p));
      }
      await lote.commit();
    }
  }

  @override
  Future<void> enviarAvisos(String temporadaId, List<AvisoPush> avisos) async {
    final col = _col(temporadaId, 'avisosPush');
    final lote = _db.batch();
    for (final a in avisos) {
      lote.set(col.doc(), {
        'topico': a.topico,
        'titulo': a.titulo,
        'corpo': a.corpo,
        'rota': a.rota,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
    await lote.commit();
  }

  @override
  Future<void> excluirPartidas(String temporadaId, List<String> ids) async {
    final col = _col(temporadaId, 'partidas');
    final lote = _db.batch();
    for (final id in ids) {
      lote.delete(col.doc(id));
    }
    await lote.commit();
  }

  @override
  Future<void> registrarPagamento(String temporadaId, String pendenciaId, DateTime pagoEm) =>
      _col(temporadaId, 'pagamentos').doc(pendenciaId).set({
        'pagoEm': Timestamp.fromDate(pagoEm),
        'registradoEm': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> desfazerPagamento(String temporadaId, String pendenciaId) =>
      _col(temporadaId, 'pagamentos').doc(pendenciaId).delete();

  @override
  Future<void> salvarDecisao(String temporadaId, DecisaoDisciplinar decisao) =>
      _col(temporadaId, 'decisoes').doc(decisao.id).set({
        ...decisaoParaMapa(decisao),
        'registradaEm': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> excluirDecisao(String temporadaId, String decisaoId) async {
    final lote = _db.batch();
    lote.delete(_col(temporadaId, 'decisoes').doc(decisaoId));
    for (final id in idsPendenciasDaDecisao(decisaoId)) {
      lote.delete(_col(temporadaId, 'pagamentos').doc(id));
    }
    await lote.commit();
  }

  @override
  Future<void> salvarParametros(String temporadaId, Parametros parametros) => _db
      .collection('temporadas')
      .doc(temporadaId)
      .set({'parametros': parametrosParaMapa(parametros)}, SetOptions(merge: true));

  @override
  Future<void> salvarDrafts(String temporadaId, Map<int, DateTime> drafts) => _db
      .collection('temporadas')
      .doc(temporadaId)
      .set({
        for (final n in [1, 2])
          'draft$n': drafts[n] == null ? FieldValue.delete() : Timestamp.fromDate(drafts[n]!),
      }, SetOptions(merge: true));

  @override
  Future<void> salvarSorteio(String temporadaId, int turno, List<String> ordem) => _db
      .collection('temporadas')
      .doc(temporadaId)
      .set({
        'sorteios': {'$turno': ordem},
      }, SetOptions(merge: true));

  @override
  Future<void> salvarPatrocinador(String temporadaId, String? patrocinador) => _db
      .collection('temporadas')
      .doc(temporadaId)
      .set({'patrocinador': patrocinador}, SetOptions(merge: true));

  @override
  Stream<List<Movimentacao>> observarMovimentacoes(String temporadaId) =>
      _col(temporadaId, 'movimentacoes')
      .snapshots()
      .map((s) => [for (final d in s.docs) movimentacaoDeMapa(d.id, d.data())]);

  @override
  Future<void> registrarMovimentacao(
    String temporadaId,
    Movimentacao movimentacao, {
    Pessoa? substituto,
  }) async {
    final pessoas = _col(temporadaId, 'pessoas');
    final lote = _db.batch();
    lote.set(_col(temporadaId, 'movimentacoes').doc(movimentacao.id), {
      ...movimentacaoParaMapa(movimentacao),
      'registradaEm': FieldValue.serverTimestamp(),
    });
    lote.update(pessoas.doc(movimentacao.pessoaId), {
      'saiuEm': Timestamp.fromDate(movimentacao.data),
    });
    if (substituto != null) lote.set(pessoas.doc(substituto.id), pessoaParaMapa(substituto));
    await lote.commit();
  }

  @override
  Future<void> desfazerMovimentacao(String temporadaId, Movimentacao movimentacao) async {
    final pessoas = _col(temporadaId, 'pessoas');
    // A pessoa pode não existir mais se o elenco foi reimportado.
    final pessoa = await pessoas.doc(movimentacao.pessoaId).get();
    final lote = _db.batch();
    lote.delete(_col(temporadaId, 'movimentacoes').doc(movimentacao.id));
    if (pessoa.exists) lote.update(pessoa.reference, {'saiuEm': null});
    final substituto = movimentacao.substitutoId;
    if (substituto != null) lote.delete(pessoas.doc(substituto));
    await lote.commit();
  }
}

/// `sorteios` do documento da temporada: {"1": [ids], "2": [...], "0": [...]}.
Map<int, List<String>> sorteiosDeMapa(Object? m) {
  if (m is! Map) return const {};
  return {
    for (final e in m.entries)
      if (int.tryParse('${e.key}') case final turno? when e.value is List)
        turno: [for (final id in e.value as List) '$id'],
  };
}

/// `draft1` e `draft2` do documento da temporada.
Map<int, DateTime> draftsDeMapa(Map<String, dynamic>? m) => {
  for (final n in [1, 2])
    if (m?['draft$n'] case final Timestamp t) n: t.toDate(),
};
