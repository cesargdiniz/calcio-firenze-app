import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/repositories/temporada_repository.dart';
import '../../domain/usecases/montar_painel.dart';
import '../categoria/categoria_controller.dart';

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

/// Escuta a temporada da categoria escolhida e recalcula o painel público a
/// cada mudança (ou troca de categoria).
class TorcedorController extends Cubit<TorcedorStatus> {
  final TemporadaRepository _repository;
  final MontarPainel _montarPainel;
  final CategoriaController _categorias;
  StreamSubscription<void>? _assinatura;
  StreamSubscription<void>? _subCategoria;

  TorcedorController(this._repository, this._montarPainel, this._categorias)
    : super(const TorcedorCarregando());

  void iniciar() {
    _subCategoria?.cancel();
    _subCategoria = _categorias.observar().listen(_ouvir);
  }

  void _ouvir(Categoria c) {
    _assinatura?.cancel();
    emit(const TorcedorCarregando());
    _assinatura = _repository.observar(c.temporadaId).listen(
      (dados) => emit(TorcedorPronto(_montarPainel(dados))),
      onError: (Object e) => emit(const TorcedorFalha('Não foi possível carregar a temporada.')),
    );
  }

  @override
  Future<void> close() async {
    await _subCategoria?.cancel();
    await _assinatura?.cancel();
    return super.close();
  }
}
