import 'dart:async';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/push_repository.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../domain/usecases/avisos_push.dart';

/// Mantém os tópicos de notificação do celular de acordo com a categoria
/// escolhida e os vínculos aprovados de quem está logado.
class SincronizadorPush {
  final PushRepository _push;
  final AuthRepository _auth;
  final UsuarioRepository _usuarios;
  final Stream<Categoria> _categorias;

  SincronizadorPush(this._push, this._auth, this._usuarios, this._categorias);

  Categoria? _categoria;
  Usuario? _usuario;
  final _assinaturas = <StreamSubscription<Object?>>[];
  StreamSubscription<Usuario?>? _usuarioSub;

  void iniciar() {
    _assinaturas
      ..add(
        _categorias.listen((c) {
          _categoria = c;
          _aplicar();
        }),
      )
      ..add(
        _auth.observarSessao().listen((s) {
          _usuarioSub?.cancel();
          _usuario = null;
          _aplicar();
          if (s == null) return;
          _usuarioSub = _usuarios.observar(s.uid).listen((u) {
            _usuario = u;
            _aplicar();
          }, onError: (_) {});
        }, onError: (_) {}),
      );
  }

  void _aplicar() =>
      unawaited(_push.sincronizar(topicosDoAparelho(categoria: _categoria, usuario: _usuario)));

  void encerrar() {
    for (final a in _assinaturas) {
      a.cancel();
    }
    _usuarioSub?.cancel();
  }
}
