import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/montar_painel.dart';

sealed class TorcedorStatus {
  const TorcedorStatus();
}

final class TorcedorCarregando extends TorcedorStatus {
  const TorcedorCarregando();
}

final class TorcedorPronto extends TorcedorStatus {
  final Painel painel;
  const TorcedorPronto(this.painel);
}

final class TorcedorFalha extends TorcedorStatus {
  final String mensagem;
  const TorcedorFalha(this.mensagem);
}

/// Escuta a temporada e recalcula o painel público a cada mudança.
class TorcedorController extends Cubit<TorcedorStatus> {
  final TemporadaRepository _repository;
  final MontarPainel _montarPainel;
  StreamSubscription<void>? _assinatura;

  TorcedorController(this._repository, this._montarPainel) : super(const TorcedorCarregando());

  void iniciar() {
    _assinatura?.cancel();
    emit(const TorcedorCarregando());
    _assinatura = _repository.observar().listen(
      (dados) => emit(TorcedorPronto(_montarPainel(dados))),
      onError: (Object e) => emit(const TorcedorFalha('Não foi possível carregar a temporada.')),
    );
  }

  @override
  Future<void> close() async {
    await _assinatura?.cancel();
    return super.close();
  }
}
