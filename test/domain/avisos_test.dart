import 'package:calcio_firenze/data/exemplo/temporada_exemplo.dart';
import 'package:calcio_firenze/domain/usecases/montar_situacao.dart';
import 'package:calcio_firenze/modules/participante/avisos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dados = montarTemporadaExemplo();
  final montar = MontarSituacao(agora: () => TemporadaExemploRepository.agora);

  List<Aviso> avisosDe(String pessoaId, {bool veTime = false}) {
    final s = montar(dados, pessoaId, verPendenciasDoTime: veTime);
    return montarAvisos(s.pessoal, s.time, veTime: veTime);
  }

  test('atleta com cartão a pagar recebe o aviso com valor e prazo', () {
    final avisos = avisosDe('rafael-souza');
    expect(avisos, hasLength(1));
    expect(avisos.single.titulo, startsWith('Pague R\$ 30,00 até '));
    expect(avisos.single.gravidade, GravidadeAviso.atencao);
    expect(avisos.single.doTime, isFalse);
  });

  test('atleta suspenso recebe o aviso da suspensão em primeiro lugar', () {
    final avisos = avisosDe('ricardo-alves');
    expect(avisos.first.titulo, 'Você está suspenso na Rodada 4');
    expect(avisos.first.gravidade, GravidadeAviso.critico);
  });

  test('atleta não recebe avisos de colegas', () {
    expect(avisosDe('rafael-souza').where((a) => a.doTime), isEmpty);
  });

  test('técnico recebe as pendências do elenco, com o nome de quem deve', () {
    final doTime = avisosDe('helio-ramos', veTime: true).where((a) => a.doTime);
    expect(doTime.map((a) => a.titulo), contains(startsWith('Rafael Souza deve R\$ 30,00 até ')));
  });

  test('os avisos saem do mais grave para o menos grave', () {
    final avisos = avisosDe('helio-ramos', veTime: true);
    final ordem = [for (final a in avisos) a.gravidade.index];
    expect(ordem, [...ordem]..sort());
  });
}
