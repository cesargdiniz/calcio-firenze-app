import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/campeoes.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/campeoes_repository.dart';
import '../campeoes_mapa.dart';

/// Um documento por categoria: temporadas/{id}/campeoes/lista.
class FirestoreCampeoesRepository implements CampeoesRepository {
  final FirebaseFirestore _db;
  FirestoreCampeoesRepository(this._db);

  DocumentReference<Map<String, dynamic>> _doc(Categoria c) =>
      _db.collection('temporadas').doc(c.temporadaId).collection('campeoes').doc('lista');

  @override
  Stream<List<TituloTemporada>?> observar(Categoria categoria) =>
      _doc(categoria).snapshots().map((s) {
        final titulos = s.data()?['titulos'] as List?;
        if (titulos == null) return null;
        return [for (final t in titulos.cast<Map<String, Object?>>()) tituloDeMapa(t)];
      });

  @override
  Future<void> salvarTodos(Categoria categoria, List<TituloTemporada> titulos) =>
      _doc(categoria).set({
        'titulos': [for (final t in titulos) tituloParaMapa(t)],
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
}
