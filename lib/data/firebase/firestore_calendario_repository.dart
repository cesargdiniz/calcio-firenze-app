import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/calendario_repository.dart';

/// `calendario/ajustes`: { horarios: { "2027-05-11T20:30:00.000": Timestamp } }.
/// A chave é o horário oficial (hora local, como no código).
class FirestoreCalendarioRepository implements CalendarioRepository {
  final FirebaseFirestore _db;
  FirestoreCalendarioRepository(this._db);

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('calendario').doc('ajustes');

  @override
  Stream<Map<DateTime, DateTime>> observarAjustes() => _doc.snapshots().map((s) {
    final mapa = s.data()?['horarios'] as Map<String, dynamic>? ?? const {};
    return {
      for (final MapEntry(:key, :value) in mapa.entries)
        if (DateTime.tryParse(key) case final oficial? when value is Timestamp)
          oficial: value.toDate(),
    };
  });

  @override
  Future<void> salvarAjustes(Map<DateTime, DateTime> ajustes) => _doc.set({
    'horarios': {
      for (final MapEntry(:key, :value) in ajustes.entries)
        key.toIso8601String(): Timestamp.fromDate(value),
    },
    'atualizadoEm': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> moverPartidas(String temporadaId, Map<String, DateTime> inicios) async {
    final col = _db.collection('temporadas').doc(temporadaId).collection('partidas');
    final lote = _db.batch();
    for (final MapEntry(:key, :value) in inicios.entries) {
      lote.update(col.doc(key), {'inicio': Timestamp.fromDate(value)});
    }
    await lote.commit();
  }
}
