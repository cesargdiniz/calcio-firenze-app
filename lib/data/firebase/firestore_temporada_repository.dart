import 'dart:async';

import 'package:calcio_regras/calcio_regras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/temporada.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/organizacao_repository.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../exemplo/temporada_exemplo.dart';
import 'firestore_usuario_repository.dart';

Map<String, dynamic> _timeParaMapa(Time t) => {'nome': t.nome, 'sigla': t.sigla, 'cor': t.cor};

Time _timeDeMapa(String id, Map<String, dynamic> m) => Time(
  id: id,
  nome: m['nome'] as String? ?? id,
  sigla: m['sigla'] as String? ?? id,
  cor: (m['cor'] as num?)?.toInt() ?? 0xFF6E6E6E,
  escudoUrl: m['escudoUrl'] as String?,
);

Map<String, dynamic> _pessoaParaMapa(Pessoa p) => {
  'nome': p.nome,
  'timeId': p.timeId,
  'funcao': p.funcao.name,
  'numero': p.numero,
  'goleiro': p.goleiro,
  'dirigente': p.dirigente,
};

Pessoa _pessoaDeMapa(String id, Map<String, dynamic> m) => Pessoa(
  id: id,
  nome: m['nome'] as String? ?? '',
  timeId: m['timeId'] as String? ?? '',
  funcao: m['funcao'] == 'tecnico' ? Funcao.tecnico : Funcao.atleta,
  numero: (m['numero'] as num?)?.toInt(),
  goleiro: m['goleiro'] == true,
  dirigente: m['dirigente'] == true,
);

/// Temporada no Firestore (`temporadas/{id}/times` e `/pessoas`).
///
/// Enquanto a Organização não importar elencos, mostra a temporada de
/// exemplo (com os times já salvos no Firestore, se houver). Jogos e
/// súmulas reais entram com o módulo de calendário.
class FirestoreTemporadaRepository implements TemporadaRepository {
  final FirebaseFirestore _db;
  final String temporadaId;

  FirestoreTemporadaRepository(this._db, {this.temporadaId = 'master-2027'});

  CollectionReference<Map<String, dynamic>> _col(String nome) =>
      _db.collection('temporadas').doc(temporadaId).collection(nome);

  @override
  Stream<DadosTemporada> observar() {
    late StreamController<DadosTemporada> saida;
    StreamSubscription<void>? subTimes;
    StreamSubscription<void>? subPessoas;
    List<Time>? times;
    List<Pessoa>? pessoas;

    void emitir() {
      if (times == null || pessoas == null) return;
      final porId = {for (final t in timesMaster2027) t.id: t};
      for (final t in times!) {
        porId[t.id] = t;
      }
      final listaTimes = porId.values.toList();
      if (pessoas!.isEmpty) {
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
            demonstracao: true,
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
            partidas: const [],
          ),
        );
      }
    }

    saida = StreamController<DadosTemporada>(
      onListen: () {
        subTimes = _col('times').snapshots().listen((s) {
          times = [for (final d in s.docs) _timeDeMapa(d.id, d.data())];
          emitir();
        }, onError: saida.addError);
        subPessoas = _col('pessoas').snapshots().listen((s) {
          pessoas = [for (final d in s.docs) _pessoaDeMapa(d.id, d.data())];
          emitir();
        }, onError: saida.addError);
      },
      onCancel: () async {
        await subTimes?.cancel();
        await subPessoas?.cancel();
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
  FirestoreGestaoRepository(this._db);

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
      lote.set(col.doc(t.id), _timeParaMapa(t), SetOptions(merge: true));
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
        lote.set(col.doc(p.id), _pessoaParaMapa(p));
      }
      await lote.commit();
    }
  }
}
