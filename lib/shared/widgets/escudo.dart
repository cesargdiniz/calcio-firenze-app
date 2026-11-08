import 'package:flutter/material.dart';

import '../../domain/entities/temporada.dart';

/// Escudo do time: imagem enviada em "Editar time" ou, enquanto não houver,
/// círculo com a cor e a sigla.
class Escudo extends StatelessWidget {
  final Time time;
  final double tamanho;

  const Escudo(this.time, {super.key, this.tamanho = 36});

  @override
  Widget build(BuildContext context) {
    final url = time.escudoUrl;
    return Semantics(
      label: 'Escudo ${time.nome}',
      child: SizedBox.square(
        dimension: tamanho,
        child: url != null
            ? ClipOval(child: Image.network(url, fit: BoxFit.cover))
            : DecoratedBox(
                decoration: BoxDecoration(color: Color(time.cor), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    time.sigla,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: tamanho * 0.27,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
