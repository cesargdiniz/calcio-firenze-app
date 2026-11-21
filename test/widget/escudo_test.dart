import 'dart:convert';
import 'dart:typed_data';

import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/data/memoria/memoria_repositories.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/shared/seletor_imagem.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _org = Sessao(uid: 'org1', email: 'cesar@exemplo.com');

/// PNG transparente de 1 x 1.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _SeletorFixo implements SeletorImagem {
  final Uint8List? imagem;
  const _SeletorFixo(this.imagem);

  @override
  Future<Uint8List?> escolherEscudo() async => imagem;
}

Time _sam(MemoriaGestaoRepository gestao) =>
    gestao.temporada.dados.times.firstWhere((t) => t.id == 'SAM');

void main() {
  testWidgets('enviar o escudo do time', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/times/SAM',
      sessao: _org,
      organizacao: {'org1'},
      seletorImagem: _SeletorFixo(_png),
    );
    await acionar(tester, 'Enviar escudo');
    expect(find.text('Trocar escudo'), findsOneWidget);
    // Só vale depois de salvar.
    expect(_sam(gestao).escudo, isNull);

    await acionar(tester, 'Salvar');
    expect(_sam(gestao).escudo, _png);
  });

  testWidgets('desistir de escolher a imagem não muda nada', (tester) async {
    await abrirApp(
      tester,
      inicio: '/organizacao/gestao/times/SAM',
      sessao: _org,
      organizacao: {'org1'},
      seletorImagem: const _SeletorFixo(null),
    );
    await acionar(tester, 'Enviar escudo');
    expect(find.text('Enviar escudo'), findsOneWidget);
    expect(find.text('Remover escudo'), findsNothing);
  });

  testWidgets('remover o escudo volta para a cor com a sigla', (tester) async {
    final exemplo = montarTemporadaExemplo();
    final dados = DadosTemporada(
      id: exemplo.id,
      nome: exemplo.nome,
      local: exemplo.local,
      times: [
        for (final t in exemplo.times)
          t.id == 'SAM'
              ? Time(id: t.id, nome: t.nome, sigla: t.sigla, cor: t.cor, escudo: _png)
              : t,
      ],
      pessoas: exemplo.pessoas,
      partidas: exemplo.partidas,
      demonstracao: true,
      relogio: exemplo.relogio,
    );
    final gestao = await abrirApp(
      tester,
      inicio: '/organizacao/gestao/times/SAM',
      sessao: _org,
      organizacao: {'org1'},
      dados: dados,
    );
    expect(find.text('Trocar escudo'), findsOneWidget);
    await acionar(tester, 'Remover escudo');
    await acionar(tester, 'Salvar');
    expect(_sam(gestao).escudo, isNull);
  });

  testWidgets('dirigente troca o escudo do próprio time', (tester) async {
    final gestao = await abrirApp(
      tester,
      inicio: '/participante/time',
      sessao: const Sessao(uid: 'u1', email: 'dirigente@exemplo.com'),
      seletorImagem: _SeletorFixo(_png),
      usuarios: {
        'u1': const Usuario(
          uid: 'u1',
          email: 'dirigente@exemplo.com',
          nome: 'Rafael Souza',
          vinculos: [
            Vinculo(
              temporadaId: 'master-2027',
              pessoaId: 'rafael-souza',
              timeId: 'SAM',
              papel: Papel.dirigente,
              status: StatusVinculo.aprovado,
            ),
          ],
        ),
      },
    );
    expect(_sam(gestao).escudo, isNull);
    await tester.tap(find.text('Trocar escudo do time'));
    await tester.pumpAndSettle();
    expect(_sam(gestao).escudo, _png);
    expect(_sam(gestao).nome, 'Marinai Blu', reason: 'só o escudo muda');
  });

  testWidgets('atleta não vê a troca de escudo', (tester) async {
    await abrirApp(
      tester,
      inicio: '/participante/time',
      sessao: const Sessao(uid: 'u1', email: 'atleta@exemplo.com'),
      usuarios: {
        'u1': const Usuario(
          uid: 'u1',
          email: 'atleta@exemplo.com',
          nome: 'Rafael Souza',
          vinculos: [
            Vinculo(
              temporadaId: 'master-2027',
              pessoaId: 'rafael-souza',
              timeId: 'SAM',
              papel: Papel.atleta,
              status: StatusVinculo.aprovado,
            ),
          ],
        ),
      },
    );
    expect(find.text('Trocar escudo do time'), findsNothing);
  });
}
