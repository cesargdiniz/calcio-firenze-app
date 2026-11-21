import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/push_repository.dart';

/// Notificações pelo Firebase Cloud Messaging, por tópicos. Os tópicos em que
/// o celular está inscrito ficam guardados no aparelho, para sair dos antigos
/// quando a pessoa troca de categoria ou de vínculo.
class FirebasePushRepository implements PushRepository {
  final FirebaseMessaging _fcm;
  FirebasePushRepository(this._fcm);

  static const _chave = 'push.topicos';
  static const _perguntado = 'push.perguntado';
  final _rotas = StreamController<String>.broadcast();
  Future<void> _fila = Future.value();

  /// Liga a abertura de notificações (app fechado ou em segundo plano).
  Future<void> iniciar() async {
    await _fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessageOpenedApp.listen(_abrir);
    final inicial = await _fcm.getInitialMessage();
    if (inicial != null) _abrir(inicial);
  }

  void _abrir(RemoteMessage m) {
    final rota = m.data['rota'];
    if (rota is String && rota.startsWith('/')) _rotas.add(rota);
  }

  @override
  Stream<String> get rotasAbertas => _rotas.stream;

  @override
  Future<void> sincronizar(Set<String> topicos) =>
      _fila = _fila.then((_) => _sincronizar(topicos)).catchError((Object e) {
        debugPrint('Notificações: $e');
      });

  @override
  Future<bool> precisaPerguntar() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_perguntado) ?? false) return false;
    final s = await _fcm.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.notDetermined;
  }

  @override
  Future<bool> autorizar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_perguntado, true);
    final r = await _fcm.requestPermission();
    return r.authorizationStatus == AuthorizationStatus.authorized ||
        r.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> recusar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_perguntado, true);
  }

  Future<void> _sincronizar(Set<String> topicos) async {
    final prefs = await SharedPreferences.getInstance();
    final atuais = (prefs.getStringList(_chave) ?? const <String>[]).toSet();
    for (final t in atuais.difference(topicos)) {
      await _fcm.unsubscribeFromTopic(t);
    }
    for (final t in topicos.difference(atuais)) {
      await _fcm.subscribeToTopic(t);
    }
    await prefs.setStringList(_chave, topicos.toList()..sort());
  }
}
