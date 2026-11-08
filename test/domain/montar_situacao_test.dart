import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dados = montarTemporadaExemplo();
  final montar = MontarSituacao(agora: () => TemporadaExemploRepository.agora);

  test('elencos de exemplo: 12 atletas, 1 goleiro, técnico e dirigente por time', () {
    for (final t in dados.times) {
      final elenco = dados.pessoas.where((p) => p.timeId == t.id);
      expect(elenco.where((p) => p.funcao == Funcao.atleta), hasLength(12));
      expect(elenco.where((p) => p.goleiro), hasLength(1));
      expect(elenco.where((p) => p.funcao == Funcao.tecnico), hasLength(1));
      expect(elenco.where((p) => p.dirigente), hasLength(1));
    }
    expect(dados.pessoas.map((p) => p.id).toSet(), hasLength(dados.pessoas.length));
  });

  test('Rafael Souza: 1 amarelo, R\$ 30 a vencer antes da Rodada 4', () {
    final s = montar(dados, 'rafael-souza').pessoal;
    expect(s.amarelosNoCiclo, 1);
    expect(s.totalEmAberto, 3000);
    expect(s.emAberto.single.status, StatusPendencia.aVencer);
    expect(s.proximoJogo?.rodada, 4);
    expect(s.proximoPrazo, s.proximoJogo!.inicio.subtract(const Duration(hours: 24)));
    expect(s.suspenso, isFalse);
  });

  test('Marcos Lima: suspenso por vermelho na Rodada 4', () {
    final s = montar(dados, 'marcos-lima').pessoal;
    expect(s.suspenso, isTrue);
    expect(s.motivoSuspensao, 'Cartão vermelho');
    expect(s.totalEmAberto, 5000);
  });

  test('Meu time: atleta não vê pendências; dirigente e técnico veem', () {
    final atleta = montar(dados, 'rafael-souza').time;
    expect(atleta.pendenciasDoTime, isEmpty);
    expect(atleta.elenco, hasLength(13));

    final tecnico = montar(dados, 'helio-ramos', verPendenciasDoTime: true).time;
    // Rafael (amarelo R3) e o próprio técnico (amarelo R2, já vencido).
    expect(tecnico.pendenciasDoTime.map((p) => p.pessoaId).toSet(), {
      'rafael-souza',
      'helio-ramos',
    });
  });

  test('técnico com pendência vencida aparece impedido', () {
    final s = montar(dados, 'helio-ramos').pessoal;
    expect(s.impedido, isFalse); // prazo da Rodada 4 ainda não chegou
    expect(s.emAberto.any((p) => p.multaAtraso), isTrue); // R2 venceu antes da R3
  });
}
