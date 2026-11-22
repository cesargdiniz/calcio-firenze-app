import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/campeoes.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/campeoes_repository.dart';

/// Campeões de todas as categorias: começa com a lista que vem no app e
/// troca pela que a Organização gravou, quando houver.
class CampeoesController extends Cubit<Map<Categoria, List<TituloTemporada>>> {
  final CampeoesRepository _repo;
  final _assinaturas = <StreamSubscription<void>>[];

  CampeoesController(this._repo) : super({for (final c in Categoria.values) c: campeoesDe(c)});

  void iniciar() {
    for (final c in Categoria.values) {
      _assinaturas.add(
        _repo.observar(c).listen(
          (lista) {
            if (lista != null && !isClosed) emit({...state, c: _ordenada(lista)});
          },
          // Sem conexão ou sem permissão: segue a lista do app.
          onError: (Object _) {},
        ),
      );
    }
  }

  List<TituloTemporada> de(Categoria c) => state[c] ?? const [];

  static List<TituloTemporada> _ordenada(Iterable<TituloTemporada> l) =>
      [...l]..sort((a, b) => b.ano.compareTo(a.ano));

  /// Grava [titulo]. Ao editar um título que mudou de ano, [anoOriginal] diz
  /// qual substituir.
  Future<void> salvar(Categoria c, TituloTemporada titulo, {int? anoOriginal}) async {
    final lista = _ordenada([
      for (final t in de(c))
        if (t.ano != titulo.ano && t.ano != anoOriginal) t,
      titulo,
    ]);
    await _repo.salvarTodos(c, lista);
    emit({...state, c: lista});
  }

  Future<void> excluir(Categoria c, int ano) async {
    final lista = [for (final t in de(c)) if (t.ano != ano) t];
    await _repo.salvarTodos(c, lista);
    emit({...state, c: lista});
  }

  @override
  Future<void> close() async {
    for (final a in _assinaturas) {
      await a.cancel();
    }
    return super.close();
  }
}
