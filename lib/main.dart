import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/exemplo/temporada_exemplo.dart';
import 'data/firebase/firebase_auth_repository.dart';
import 'data/firebase/firestore_temporada_repository.dart';
import 'data/firebase/firestore_usuario_repository.dart';
import 'domain/usecases/montar_painel.dart';
import 'domain/usecases/montar_situacao.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuthRepository(FirebaseAuth.instance);

  // Quem chegou pelo link do e-mail entra direto na área do Participante.
  var inicio = '/';
  try {
    if (await auth.concluirLinkSeHouver(Uri.base.toString())) inicio = '/participante';
  } catch (e) {
    debugPrint('Link de acesso: $e');
  }

  // Times e elencos vêm do Firestore. Enquanto a Organização não importar os
  // elencos, o app mostra a temporada de exemplo, com o relógio parado no dia
  // seguinte à Rodada 3.
  final db = FirebaseFirestore.instance;
  final temporada = FirestoreTemporadaRepository(db);
  DateTime agora() => TemporadaExemploRepository.agora;
  runApp(
    CalcioApp(
      temporada: temporada,
      auth: auth,
      usuarios: FirestoreUsuarioRepository(db),
      organizacao: FirestoreOrganizacaoRepository(db),
      gestao: FirestoreGestaoRepository(db),
      montarPainel: MontarPainel(agora: agora),
      montarSituacao: MontarSituacao(agora: agora),
      initialLocation: inicio,
    ),
  );
}
