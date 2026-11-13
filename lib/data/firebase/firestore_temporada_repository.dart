import 'dart:async';

import 'package:calcio_regras/calcio_regras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../exemplo/temporada_exemplo.dart';
import 'firestore_usuario_repository.dart';
import 'mapeadores.dart';

/// Temporada no Firestore: `temporadas/{id}/times`, `/pessoas`, `/partidas`,
/// `/decisoes` e `/pagamentos`.
///
/// Enquanto não houver elencos nem jogos cadastrados, mostra a temporada de
/// exemplo (com os times já salvos no Firestore, se houver).
class FirestoreTemporadaRepository implements TemporadaRepository {
  final FirebaseFirestore _db;
  final String temporadaId;

  FirestoreTemporadaRepository(this._db, {this.temporadaId = 'master-2027'});

  CollectionReference<Map<String, dynamic>> _col(String nome) =>
      _db.collection('temporadas').doc(temporadaId).collection(nome);

  @override
  Stream<DadosTemporada> observar() {
    late StreamController<DadosTemporada> saida;
    final subs = <StreamSubscription<void>>[];
    List<Time>? times;
    List<Pessoa>? pessoas;
    List<Partida>? partidas;
    List<Pagamento>? pagamentos;
    List<DecisaoDisciplinar>? decisoes;
    Parametros? parametros;
    String? patrocinador;

    void emitir() {
      if (times == null ||
          pessoas == null ||
          partidas == null ||
          pagamentos == null ||
          decisoes == null ||
          parametros == null) {
        return;
      }
      final porId = {for (final t in timesMaster2027) t.id: t};
      for (final t in times!) {
        porId[t.id] = t;
      }
      final listaTimes = porId.values.toList();
      if (pessoas!.isEmpty && partidas!.isEmpty) {
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
            demonstracao: true,
            relogio: exemplo.relogio,
          ),
        );
      } else {
        saida.add(
          DadosTemporada(
            id: temporadaId,
            nome: 'Master · Temporada 2027',
            local: 'Arena Gugu',
            times: listaTimes,
            pessoas: pessoas!,
            partidas: partidas!,
            pagamentos: pagamentos!,
            parametros: parametros!,
            patrocinador: patrocinador,
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
        _col(colecao).snapshots().listen(
          (s) {
            guardar([for (final d in s.docs) ler(d.id, d.data())]);
            emitir();
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
              parametros = parametrosDeMapa(s.data()?['parametros'] as Map<String, dynamic>?);
              patrocinador = s.data()?['patrocinador'] as String?;
              emitir();
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
}

class FirestoreOrganizacaoRepository implements OrganizacaoRepository {
  final FirebaseFirestore _db;
  FirestoreOrganizacaoRepository(this._db);

  @override
  Stream<bool> ehOrganizacao(String uid) =>
      _db.collection('organizacao').doc(uid).snapshots().map((s) => s.exists);
}

class FirestoreGestaoRepository implements GestaoRepository {
  final FirebaseFirestore _db;

  /// Temporada cujas movimentações a Organização acompanha.
  final String temporadaId;

  FirestoreGestaoRepository(this._db, {this.temporadaId = 'master-2027'});

  Stream<List<Usuario>> _porStatus(StatusVinculo status) => _db
      .collection('usuarios')
      .where('vinculo.status', isEqualTo: status.name)
      .snapshots()
      .map((s) => [for (final d in s.docs) FirestoreUsuarioRepository.deMapa(d.id, d.data())]);

  @override
  Stream<List<Usuario>> observarPedidos() => _porStatus(StatusVinculo.pendente);

  @override
  Stream<List<Usuario>> observarAprovados() => _porStatus(StatusVinculo.aprovado);

  @override
  Future<void> decidirPedido(String uid, StatusVinculo status) => _db
      .collection('usuarios')
      .doc(uid)
      .update({'vinculo.status': status.name, 'decididoEm': FieldValue.serverTimestamp()});

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
  Future<void> salvarPatrocinador(String temporadaId, String? patrocinador) => _db
      .collection('temporadas')
      .doc(temporadaId)
      .set({'patrocinador': patrocinador}, SetOptions(merge: true));

  @override
  Stream<List<Movimentacao>> observarMovimentacoes() => _col(temporadaId, 'movimentacoes')
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
