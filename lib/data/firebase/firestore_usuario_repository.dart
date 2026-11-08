import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';

/// Documento `usuarios/{uid}` (ver docs/arquitetura.md).
class FirestoreUsuarioRepository implements UsuarioRepository {
  final FirebaseFirestore _db;
  FirestoreUsuarioRepository(this._db);

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('usuarios').doc(uid);

  @override
  Stream<Usuario?> observar(String uid) =>
      _doc(uid).snapshots().map((s) => s.exists ? deMapa(uid, s.data()!) : null);

  @override
  Future<void> pedirVinculo(Usuario u) => _doc(u.uid).set({
    'nome': u.nome,
    'email': u.email,
    'perfil': PerfilUsuario.participante.name,
    'vinculo': {
      'temporadaId': u.vinculo!.temporadaId,
      'pessoaId': u.vinculo!.pessoaId,
      'timeId': u.vinculo!.timeId,
      'papel': u.vinculo!.papel.name,
      'status': StatusVinculo.pendente.name,
    },
    'atualizadoEm': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> excluir(String uid) => _doc(uid).delete();

  static Usuario deMapa(String uid, Map<String, dynamic> m) {
    final v = m['vinculo'] as Map<String, dynamic>?;
    T porNome<T extends Enum>(List<T> valores, Object? nome, T padrao) =>
        valores.where((e) => e.name == nome).firstOrNull ?? padrao;
    return Usuario(
      uid: uid,
      email: m['email'] as String? ?? '',
      nome: m['nome'] as String? ?? '',
      perfil: porNome(PerfilUsuario.values, m['perfil'], PerfilUsuario.participante),
      vinculo: v == null
          ? null
          : Vinculo(
              temporadaId: v['temporadaId'] as String,
              pessoaId: v['pessoaId'] as String,
              timeId: v['timeId'] as String,
              papel: porNome(Papel.values, v['papel'], Papel.atleta),
              status: porNome(StatusVinculo.values, v['status'], StatusVinculo.pendente),
            ),
    );
  }
}
