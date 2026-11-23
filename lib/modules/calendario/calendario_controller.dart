import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/calendario_geral.dart';
import '../../domain/usecases/gerar_calendario.dart';

sealed class CalendarioStatus {
  const CalendarioStatus();
}

final class CalendarioCarregando extends CalendarioStatus {
  const CalendarioCarregando();
}

final class CalendarioPronto extends CalendarioStatus {
  final List<JogoDoCalendario> jogos;
  const CalendarioPronto(this.jogos);
}

/// Junta os jogos das três categorias (e as datas da Copa) num calendário só.
/// Lê só times e jogos de cada categoria.
class CalendarioController extends Cubit<CalendarioStatus> {
  final TemporadaRepository _repository;
  final _subs = <StreamSubscription<void>>[];
  final _dados = <Categoria, DadosCalendario>{};
  var _respostas = 0;

  CalendarioController(this._repository) : super(const CalendarioCarregando());

  void iniciar() {
    // Dias mudados na Gestão: refaz o calendário.
    _subs.add(AjustesCalendario.mudancas.listen((_) => _emitir()));
    for (final c in Categoria.values) {
      var respondeu = false;
      void contar() {
        if (respondeu) return;
        respondeu = true;
        _respostas++;
      }

      _subs.add(
        _repository.observarCalendario(c.temporadaId).listen(
          (d) {
            contar();
            _dados[c] = d;
            _emitir();
          },
          // Uma categoria fora do ar não esconde as outras: entram os
          // horários oficiais dela.
          onError: (Object _) {
            contar();
            _emitir();
          },
        ),
      );
    }
  }

  void _emitir() {
    if (isClosed || _respostas < Categoria.values.length) return;
    emit(CalendarioPronto(montarCalendarioGeral(_dados)));
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
