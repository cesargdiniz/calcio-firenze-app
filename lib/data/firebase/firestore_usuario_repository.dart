import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';

/// Cadastro em `usuarios/{uid}` (nome, e-mail) e um vínculo por categoria em
/// `temporadas/{id}/vinculos/{uid}`, que a Organização daquela categoria
/// aprova (ver docs/arquitetura.md).
class FirestoreUsuarioRepository implements UsuarioRepository {
  final FirebaseFirestore _db;
  FirestoreUsuarioRepository(this._db);

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('usuarios').doc(uid);

  DocumentReference<Map<String, dynamic>> _vinculo(String temporadaId, String uid) =>
      _db.collection('temporadas').doc(temporadaId).collection('vinculos').doc(uid);

  @override
  Stream<Usuario?> observar(String uid) {
    late StreamController<Usuario?> saida;
    final subs = <StreamSubscription<void>>[];
    Map<String, dynamic>? cadastro;
    var cadastroLido = false;
    final vinculos = <String, Vinculo?>{};

    void emitir() {
      if (!cadastroLido || vinculos.length < Categoria.values.length) return;
      final lista = [for (final v in vinculos.values) ?v];
      if (cadastro == null && lista.isEmpty) return saida.add(null);
      saida.add(
        Usuario(
          uid: uid,
          email: cadastro?['email'] as String? ?? '',
          nome: cadastro?['nome'] as String? ?? '',
          perfil: _porNome(PerfilUsuario.values, cadastro?['perfil'], PerfilUsuario.participante),
          vinculos: lista,
        ),
      );
    }

    saida = StreamController<Usuario?>(
      onListen: () {
        subs.add(
          _doc(uid).snapshots().listen((s) {
            cadastro = s.data();
            cadastroLido = true;
            emitir();
          }, onError: saida.addError),
        );
        for (final c in Categoria.values) {
          subs.add(
            _vinculo(c.temporadaId, uid).snapshots().listen(
              (s) {
                try {
                  vinculos[c.temporadaId] =
                      s.exists ? vinculoDeMapa(c.temporadaId, s.data()!) : null;
                } catch (_) {
                  // Vínculo gravado pela metade conta como inexistente.
                  vinculos[c.temporadaId] = null;
                }
                emitir();
              },
              // Uma categoria fora do ar não pode travar as outras.
              onError: (Object _) {
                vinculos[c.temporadaId] = null;
                emitir();
              },
            ),
          );
        }
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
  Future<void> pedirVinculo(Usuario u, Vinculo v) async {
    await _doc(u.uid).set({
      'nome': u.nome,
      'email': u.email,
      'perfil': PerfilUsuario.participante.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    await _vinculo(v.temporadaId, u.uid).set({
      'nome': u.nome,
      'email': u.email,
      'pessoaId': v.pessoaId,
      'timeId': v.timeId,
      'papel': v.papel.name,
      'status': StatusVinculo.pendente.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> excluir(String uid) async {
    for (final c in Categoria.values) {
      await _vinculo(c.temporadaId, uid).delete();
    }
    await _doc(uid).delete();
  }

  static T _porNome<T extends Enum>(List<T> valores, Object? nome, T padrao) =>
      valores.where((e) => e.name == nome).firstOrNull ?? padrao;

  static Vinculo vinculoDeMapa(String temporadaId, Map<String, dynamic> m) => Vinculo(
    temporadaId: temporadaId,
    pessoaId: m['pessoaId'] as String,
    timeId: m['timeId'] as String,
    papel: _porNome(Papel.values, m['papel'], Papel.atleta),
    status: _porNome(StatusVinculo.values, m['status'], StatusVinculo.pendente),
  );

  /// Pedido como a Organização da categoria vê: o usuário só com o vínculo
  /// daquela categoria.
  static Usuario pedidoDeMapa(String temporadaId, String uid, Map<String, dynamic> m) => Usuario(
    uid: uid,
    email: m['email'] as String? ?? '',
    nome: m['nome'] as String? ?? '',
    vinculos: [vinculoDeMapa(temporadaId, m)],
  );
}
