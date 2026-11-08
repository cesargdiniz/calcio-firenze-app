import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/exemplo/temporada_exemplo.dart';
import 'domain/usecases/montar_painel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enquanto o Firebase não está ligado, o app roda com a temporada de
  // exemplo e com o relógio parado no dia seguinte à Rodada 3.
  runApp(
    CalcioApp(
      repository: TemporadaExemploRepository(),
      montarPainel: MontarPainel(agora: () => TemporadaExemploRepository.agora),
    ),
  );
}
