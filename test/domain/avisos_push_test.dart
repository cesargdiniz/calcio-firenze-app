import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/categoria.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/entities/usuario.dart';
import 'package:calcio_firenze/domain/usecases/avisos_push.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d = montarTemporadaExemplo(demonstracao: false);
  final jogo = (d.partidas.toList()..sort((a, b) => a.inicio.compareTo(b.inicio))).firstWhere(
    (p) => !p.encerrada,
  );
  final times = {for (final t in d.times) t.id: t.nome};
  final atleta = d.pessoas.firstWhere(
    (p) => p.timeId == jogo.mandanteId && p.funcao == Funcao.atleta,
  );
  final agora = jogo.inicio.add(const Duration(hours: 2));

  test('encerrar a súmula avisa o resultado da categoria', () {
    final avisos = avisosDoEncerramento(
      antes: d,
      partida: jogo.comSumula(const Sumula(golsMandante: 2, golsVisitante: 1)),
      agora: agora,
    );
    expect(avisos, hasLength(1));
    expect(avisos.single.topico, 'res_${d.id}');
    expect(avisos.single.titulo, 'Fim de jogo · Master');
    expect(avisos.single.corpo, '${times[jogo.mandanteId]} 2 x 1 ${times[jogo.visitanteId]}');
    expect(avisos.single.rota, '/torcedor/jogos/${jogo.id}');
  });

  test('vermelho avisa o jogador e os dirigentes do time', () {
    final avisos = avisosDoEncerramento(
      antes: d,
      partida: jogo.comSumula(
        Sumula(
          cartoes: [
            CartaoAplicado(
              pessoaId: atleta.id,
              timeId: atleta.timeId,
              funcao: Funcao.atleta,
              tipo: TipoCartao.vermelho,
            ),
          ],
        ),
      ),
      agora: agora,
    );
    final topicos = avisos.map((a) => a.topico).toList();
    expect(topicos, contains('pessoa_${d.id}_${atleta.id}'));
    expect(topicos, contains('dir_${d.id}_${atleta.timeId}'));
    final doDirigente = avisos.firstWhere((a) => a.topico.startsWith('dir_'));
    expect(doDirigente.titulo, '${atleta.nome} está suspenso');
    expect(doDirigente.corpo, startsWith('Cartão vermelho em '));
  });

  test('correção de súmula já encerrada não repete os avisos', () {
    final encerrado = jogo.comSumula(const Sumula(golsMandante: 1));
    final antes = DadosTemporada(
      id: d.id,
      nome: d.nome,
      local: d.local,
      times: d.times,
      pessoas: d.pessoas,
      partidas: [for (final p in d.partidas) p.id == jogo.id ? encerrado : p],
      decisoes: d.decisoes,
      pagamentos: d.pagamentos,
      parametros: d.parametros,
    );
    final avisos = avisosDoEncerramento(
      antes: antes,
      partida: jogo.comSumula(const Sumula(golsMandante: 2)),
      agora: agora,
    );
    expect(avisos, isEmpty);
  });

  test('tópicos do celular: categoria e vínculos aprovados', () {
    const u = Usuario(
      uid: 'u1',
      email: 'a@exemplo.com',
      nome: 'A',
      vinculos: [
        Vinculo(
          temporadaId: 'master-2027',
          pessoaId: 'p 1',
          timeId: 'inter',
          papel: Papel.dirigente,
          status: StatusVinculo.aprovado,
        ),
        Vinculo(
          temporadaId: 'livre-2027',
          pessoaId: 'p2',
          timeId: 'roma',
          papel: Papel.atleta,
        ),
      ],
    );
    expect(topicosDoAparelho(categoria: Categoria.master, usuario: u), {
      'res_master-2027',
      'time_master-2027_inter',
      'pessoa_master-2027_p_1',
      'dir_master-2027_inter',
    });
    expect(topicosDoAparelho(), isEmpty);
  });
}
