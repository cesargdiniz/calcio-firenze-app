import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/repositories/preferencias_repository.dart';

sealed class CategoriaStatus {
  const CategoriaStatus();
}

final class CategoriaCarregando extends CategoriaStatus {
  const CategoriaCarregando();
}

/// Primeira abertura: o usuário ainda não escolheu o que ver.
final class CategoriaPendente extends CategoriaStatus {
  const CategoriaPendente();
}

final class CategoriaEscolhida extends CategoriaStatus {
  final Categoria categoria;
  const CategoriaEscolhida(this.categoria);
}

/// Categoria que o Torcedor e o Participante estão vendo. Fica guardada no
/// aparelho.
class CategoriaController extends Cubit<CategoriaStatus> {
  final PreferenciasRepository _preferencias;

  CategoriaController(this._preferencias) : super(const CategoriaCarregando());

  Categoria? get atual => switch (state) {
    CategoriaEscolhida(:final categoria) => categoria,
    _ => null,
  };

  /// Emite a categoria atual (se houver) e cada troca.
  Stream<Categoria> observar() async* {
    final a = atual;
    if (a != null) yield a;
    yield* stream
        .where((s) => s is CategoriaEscolhida)
        .map((s) => (s as CategoriaEscolhida).categoria)
        .distinct();
  }

  Future<void> iniciar() async {
    final salva = Categoria.deTemporada(await _preferencias.categoria());
    if (isClosed) return;
    emit(salva == null ? const CategoriaPendente() : CategoriaEscolhida(salva));
  }

  Future<void> escolher(Categoria c) async {
    if (atual != c) emit(CategoriaEscolhida(c));
    await _preferencias.salvarCategoria(c.temporadaId);
  }
}
