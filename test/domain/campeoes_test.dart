import 'package:calcio_firenze/data/campeoes_mapa.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/campeoes.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/modules/campeoes/campeoes_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _g = PosicaoCampeao.goleiro;
const _z = PosicaoCampeao.zagueiro;
const _m = PosicaoCampeao.meia;
const _a = PosicaoCampeao.ataque;

TituloTemporada _titulo({int ano = 2026, List<JogadorCampeao>? elenco}) => TituloTemporada(
  ano,
  'Teste FC',
  cor: 0xFF123456,
  elenco: elenco ??
      const [
        JogadorCampeao('A', _g, titular: true, numero: 1),
        JogadorCampeao('B', _z, titular: true),
        JogadorCampeao('C', _z, titular: true),
        JogadorCampeao('D', _m, titular: true),
        JogadorCampeao('E', _m, titular: true, curto: 'Edu'),
        JogadorCampeao('F', _a, titular: true),
        JogadorCampeao('G', null),
      ],
  premios: const [PremioTemporada('Artilheiro', 'F'), PremioTemporada('Melhor goleiro', 'X', time: 'Y')],
);

void main() {
  test('todos os campeões do app passam na conferência e ida e volta pelo mapa', () {
    for (final c in Categoria.values) {
      for (final t in campeoesDe(c)) {
        expect(problemaDoTitulo(t), isNull, reason: '${c.nome} ${t.ano}');
        final volta = tituloDeMapa(tituloParaMapa(t));
        expect(tituloParaMapa(volta), tituloParaMapa(t), reason: '${c.nome} ${t.ano}');
      }
    }
  });

  group('conferência antes de salvar', () {
    test('escalação completa e sem titulares passam', () {
      expect(problemaDoTitulo(_titulo()), isNull);
      expect(problemaDoTitulo(_titulo(elenco: const [JogadorCampeao('Só', null)])), isNull);
    });

    test('ano repetido, time vazio e titulares fora do 2-2-1 não passam', () {
      expect(problemaDoTitulo(_titulo(), outrosAnos: [2026]), contains('Já existe'));
      expect(problemaDoTitulo(const TituloTemporada(2026, ' ')), contains('time campeão'));
      final semZagueiro = _titulo(
        elenco: const [
          JogadorCampeao('A', _g, titular: true),
          JogadorCampeao('B', _m, titular: true),
          JogadorCampeao('C', _m, titular: true),
          JogadorCampeao('D', _a, titular: true),
        ],
      );
      expect(problemaDoTitulo(semZagueiro), contains('2 zagueiros'));
      expect(
        problemaDoTitulo(_titulo(elenco: const [JogadorCampeao('A', null, titular: true)])),
        contains('posição'),
      );
    });
  });

  group('controle', () {
    test('começa com os campeões do app e grava a lista inteira ao salvar', () async {
      final repo = MemoriaCampeoesRepository();
      final c = CampeoesController(repo)..iniciar();
      final antes = c.de(Categoria.master).length;
      expect(antes, campeoesDe(Categoria.master).length);

      await c.salvar(Categoria.master, _titulo());
      expect(c.de(Categoria.master).first.ano, 2026);
      expect(repo.gravados(Categoria.master), hasLength(antes + 1));

      // Trocou o ano: substitui o título, não duplica.
      await c.salvar(Categoria.master, _titulo(ano: 2020), anoOriginal: 2026);
      expect(c.de(Categoria.master).map((t) => t.ano), isNot(contains(2026)));
      expect(c.de(Categoria.master).last.ano, 2020);

      await c.excluir(Categoria.master, 2020);
      expect(repo.gravados(Categoria.master), hasLength(antes));
      // As outras categorias seguem com a lista do app.
      expect(repo.gravados(Categoria.livre), isNull);
      await c.close();
    });

    test('lista gravada (mesmo vazia) substitui a do app', () async {
      final repo = MemoriaCampeoesRepository();
      await repo.salvarTodos(Categoria.livre, const []);
      final c = CampeoesController(repo)..iniciar();
      await Future<void>.delayed(Duration.zero);
      expect(c.de(Categoria.livre), isEmpty);
      expect(c.de(Categoria.master), isNotEmpty);
      await c.close();
    });
  });
}
