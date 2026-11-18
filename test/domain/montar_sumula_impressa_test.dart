import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/usecases/montar_sumula_impressa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dados = montarTemporadaExemplo();
  final montar = MontarSumulaImpressa(agora: () => TemporadaExemploRepository.agora);
  final proximoDoComo = dados.partidas.firstWhere((p) => !p.encerrada && p.envolve('COM'));

  TimeSumulaImpresso monza(SumulaImpressa s) => s.mandante.sigla == 'COM' ? s.mandante : s.visitante;

  test('lista os atletas em ordem alfabética, com técnico à parte e sem placar', () {
    final s = montar(dados, proximoDoComo.id);
    final nomes = [for (final j in s.mandante.jogadores) j.nome.toLowerCase()];
    expect(nomes, [...nomes]..sort());
    expect(s.mandante.jogadores, hasLength(12));
    expect(s.mandante.tecnico, isNotNull);
    expect(s.mandante.jogadores.map((j) => j.nome), isNot(contains(s.mandante.tecnico)));
    expect(s.mandante.gols, isNull);
    expect(s.fase, '1º Turno');
    expect(s.rodada, '${proximoDoComo.rodada}ª Rodada');
    expect(s.nomeArquivo, startsWith('sumula-'));
  });

  test('competição leva o patrocinador e o ano; categoria sai sem o ponto', () {
    DadosTemporada com(String? patrocinador) => DadosTemporada(
      id: dados.id,
      nome: dados.nome,
      local: dados.local,
      times: dados.times,
      pessoas: dados.pessoas,
      partidas: dados.partidas,
      relogio: dados.relogio,
      patrocinador: patrocinador,
    );
    expect(montar(com('CASA ASSIS'), proximoDoComo.id).competicao, 'CF CASA ASSIS 2027');
    expect(montar(com(null), proximoDoComo.id).competicao, 'CF 2027');
    expect(montar(com(null), proximoDoComo.id).categoria, 'Master Temporada 2027');
  });

  test('risca quem está suspenso na partida', () {
    final ricardo = monza(montar(dados, proximoDoComo.id)).jogadores.firstWhere(
      (j) => j.nome == 'Ricardo Alves',
    );
    expect(ricardo.fora, isTrue);
    expect(monza(montar(dados, proximoDoComo.id)).jogadores.where((j) => j.fora), hasLength(1));
  });

  test('quem saiu do elenco antes do jogo não aparece', () {
    final semRicardo = DadosTemporada(
      id: dados.id,
      nome: dados.nome,
      local: dados.local,
      times: dados.times,
      pessoas: [
        for (final p in dados.pessoas)
          p.id == 'ricardo-alves' ? p.comSaida(DateTime(2027, 1, 1)) : p,
      ],
      partidas: dados.partidas,
      relogio: dados.relogio,
    );
    final nomes = monza(montar(semRicardo, proximoDoComo.id)).jogadores.map((j) => j.nome);
    expect(nomes, isNot(contains('Ricardo Alves')));
    expect(nomes, hasLength(11));
  });

  test('jogo encerrado sai com placar e cartões', () {
    final comCartao = dados.partidas.firstWhere((p) => (p.sumula?.cartoes.length ?? 0) > 0);
    final s = montar(dados, comCartao.id);
    expect(s.mandante.gols, comCartao.sumula!.golsMandante);
    expect(s.visitante.gols, comCartao.sumula!.golsVisitante);
    final marcados = [...s.mandante.jogadores, ...s.visitante.jogadores].where(
      (j) => j.amarelos > 0 || j.vermelho,
    );
    expect(marcados, isNotEmpty);
  });
}
