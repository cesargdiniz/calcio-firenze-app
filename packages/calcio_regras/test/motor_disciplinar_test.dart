import 'package:calcio_regras/calcio_regras.dart';
import 'package:test/test.dart';

import 'apoio.dart';

/// Agora padrão: bem antes de qualquer prazo dos testes.
final cedo = DateTime(2027, 1, 1);

int total(Iterable<Pendencia> ps) => ps.fold(0, (s, p) => s + p.valor);

void main() {
  group('valores dos cartões', () {
    test('amarelo R\$ 30 (art. 66)', () {
      final c = Calendario()
        ..jogo('SAM', 'INT', sumula: placar(1, 0, cartoes: [amarelo('rafael', 'SAM')]))
        ..jogo('SAM', 'UDI');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(total(m.pendenciasDe('rafael')), 3000);
    });

    test('dois amarelos: paga só o vermelho, R\$ 50 (art. 67)', () {
      final c = Calendario()
        ..jogo(
          'SAM',
          'INT',
          sumula: placar(
            1,
            0,
            cartoes: [amarelo('rafael', 'SAM'), segundoAmarelo('rafael', 'SAM')],
          ),
        );
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(total(m.pendenciasDe('rafael')), 5000);
      expect(m.pendenciasDe('rafael'), hasLength(1));
    });

    test('amarelo + vermelho direto: R\$ 80 (art. 73.1)', () {
      final c = Calendario()
        ..jogo(
          'SAM',
          'INT',
          sumula: placar(1, 0, cartoes: [amarelo('rafael', 'SAM'), vermelho('rafael', 'SAM')]),
        );
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(total(m.pendenciasDe('rafael')), 8000);
    });

    test('técnico paga os cartões (art. 73.4)', () {
      final c = Calendario()
        ..jogo(
          'SAM',
          'INT',
          sumula: placar(1, 0, cartoes: [vermelho('tec', 'SAM', funcao: Funcao.tecnico)]),
        );
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(total(m.pendenciasDe('tec')), 5000);
    });
  });

  group('suspensões', () {
    test('vermelho: suspenso no jogo seguinte do time (art. 73)', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 1, cartoes: [vermelho('rafael', 'SAM')]));
      final outroTime = c.jogo('UDI', 'ROM');
      final proximo = c.jogo('SAM', 'UDI');
      final depois = c.jogo('SAM', 'ROM');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.suspensosPara(proximo.id).map((s) => s.pessoaId), ['rafael']);
      expect(m.suspensosPara(outroTime.id), isEmpty);
      expect(m.suspensosPara(depois.id), isEmpty);
    });

    test('dois amarelos também suspendem (art. 67)', () {
      final c = Calendario();
      c.jogo(
        'SAM',
        'INT',
        sumula: placar(0, 1, cartoes: [amarelo('rafael', 'SAM'), segundoAmarelo('rafael', 'SAM')]),
      );
      final proximo = c.jogo('SAM', 'UDI');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.suspensosPara(proximo.id).single.motivo, MotivoSuspensao.expulsao);
    });

    test('técnico não é suspenso (arts. 69 e 73)', () {
      final c = Calendario();
      c.jogo(
        'SAM',
        'INT',
        sumula: placar(0, 1, cartoes: [vermelho('tec', 'SAM', funcao: Funcao.tecnico)]),
      );
      final proximo = c.jogo('SAM', 'UDI');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.suspensosPara(proximo.id), isEmpty);
    });

    test('3 amarelos acumulados: 1 jogo; com 2 fica pendurado (art. 69)', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo('SAM', 'UDI', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      final terceiro = c.jogo(
        'SAM',
        'ROM',
        sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]),
      );
      final quarto = c.jogo('SAM', 'NAP');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.penduradosPara(terceiro.id).single.amarelos, 2);
      expect(m.suspensosPara(quarto.id).single.motivo, MotivoSuspensao.amarelos);
      expect(m.penduradosPara(quarto.id), isEmpty);
    });

    test('amarelos que viram vermelho não contam para o acúmulo', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo(
        'SAM',
        'UDI',
        sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM'), segundoAmarelo('rafael', 'SAM')]),
      );
      c.jogo('SAM', 'ROM');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.amarelosNoCiclo('rafael', (turno: 1, eliminatoria: false)), 1);
    });

    test('amarelo antes do vermelho direto continua contando (art. 73.2)', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo(
        'SAM',
        'UDI',
        sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM'), vermelho('rafael', 'SAM')]),
      );
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.amarelosNoCiclo('rafael', (turno: 1, eliminatoria: false)), 2);
    });

    test('vermelho + 3º amarelo no mesmo jogo: 2 jogos, em sequência', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo('SAM', 'UDI', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo(
        'SAM',
        'ROM',
        sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM'), vermelho('rafael', 'SAM')]),
      );
      final p4 = c.jogo('SAM', 'NAP');
      final p5 = c.jogo('SAM', 'MON');
      final p6 = c.jogo('SAM', 'CAS');
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.suspensosPara(p4.id), hasLength(1));
      expect(m.suspensosPara(p5.id), hasLength(1));
      expect(m.suspensosPara(p6.id), isEmpty);
    });

    test('amarelos zeram após a classificatória, mas o 3º no último jogo suspende no mata-mata (art. 70)', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo('SAM', 'UDI', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo('SAM', 'ROM', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      final quartas = c.jogo('SAM', 'NAP', fase: Fase.quartas);
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.suspensosPara(quartas.id).map((s) => s.pessoaId), ['rafael']);
    });

    test('pendurado na classificatória não chega pendurado ao mata-mata', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      c.jogo('SAM', 'UDI', sumula: placar(0, 0, cartoes: [amarelo('rafael', 'SAM')]));
      final quartas = c.jogo('SAM', 'NAP', fase: Fase.quartas);
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.penduradosPara(quartas.id), isEmpty);
    });

    test('decisão da Governança: suspensão e multa', () {
      final c = Calendario();
      final origem = c.jogo('ROM', 'MON', sumula: placar(1, 1));
      final r4 = c.jogo('MON', 'SAM');
      final r5 = c.jogo('MON', 'INT');
      final r6 = c.jogo('MON', 'UDI');
      final m = MotorDisciplinar(
        partidas: c.partidas,
        agora: cedo,
        decisoes: [
          DecisaoDisciplinar(
            id: 'd1',
            pessoaId: 'ricardo',
            timeId: 'MON',
            partidaOrigemId: origem.id,
            motivo: 'Análise de vídeo · art. 87',
            jogosSuspensao: 2,
            multa: 10000,
          ),
        ],
      );
      expect(m.suspensosPara(r4.id), hasLength(1));
      expect(m.suspensosPara(r5.id), hasLength(1));
      expect(m.suspensosPara(r6.id), isEmpty);
      expect(total(m.pendenciasDe('ricardo')), 10000);
    });

    test('calendário incompleto: a suspensão fica com jogos sem data', () {
      final c = Calendario();
      c.jogo('SAM', 'INT', sumula: placar(0, 1, cartoes: [vermelho('rafael', 'SAM')]));
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(m.suspensoes.single.semData, 1);
    });
  });

  group('prazo, multa por atraso e impedimento (arts. 68 e 73.7)', () {
    late Calendario c;
    late Partida origem, proximo;
    setUp(() {
      c = Calendario();
      origem = c.jogo('SAM', 'INT', sumula: placar(1, 0, cartoes: [amarelo('rafael', 'SAM')]));
      proximo = c.jogo('SAM', 'UDI');
    });

    String idAmarelo() => '${origem.id}:rafael:amarelo0';

    test('prazo é 24 h antes do próximo jogo do time', () {
      final m = MotorDisciplinar(partidas: c.partidas, agora: cedo);
      expect(
        m.pendenciasDe('rafael').single.prazo,
        proximo.inicio.subtract(const Duration(hours: 24)),
      );
    });

    test('antes do prazo: a vencer, sem multa, ninguém impedido ainda', () {
      final m = MotorDisciplinar(
        partidas: c.partidas,
        agora: origem.inicio.add(const Duration(days: 1)),
      );
      expect(m.pendenciasDe('rafael').single.status(m.agora), StatusPendencia.aVencer);
      expect(m.impedidosPara(proximo.id), isEmpty);
    });

    test('pago no prazo: quitada, sem multa, liberado', () {
      final m = MotorDisciplinar(
        partidas: c.partidas,
        agora: proximo.inicio,
        pagamentos: [Pagamento(idAmarelo(), origem.inicio.add(const Duration(days: 2)))],
      );
      expect(m.pendenciasDe('rafael'), hasLength(1));
      expect(m.impedidosPara(proximo.id), isEmpty);
    });

    test('vencida sem pagamento: multa do mesmo valor e impedido', () {
      final m = MotorDisciplinar(partidas: c.partidas, agora: proximo.inicio);
      final ps = m.pendenciasDe('rafael');
      expect(total(ps), 6000);
      expect(ps.where((p) => p.multaAtraso), hasLength(1));
      expect(ps.first.status(m.agora), StatusPendencia.vencida);
      expect(m.impedidosPara(proximo.id), {'rafael'});
    });

    test('pago depois do prazo: multa gerada, impedido naquele jogo, liberado no seguinte se quitar a multa', () {
      final terceiro = c.jogo('SAM', 'ROM');
      final pagouAtrasado = proximo.inicio.subtract(const Duration(hours: 2));
      final m = MotorDisciplinar(
        partidas: c.partidas,
        agora: terceiro.inicio,
        pagamentos: [
          Pagamento(idAmarelo(), pagouAtrasado),
          Pagamento('${idAmarelo()}:atraso', pagouAtrasado),
        ],
      );
      expect(m.pendenciasDe('rafael').where((p) => p.multaAtraso), hasLength(1));
      expect(m.impedidosPara(proximo.id), {'rafael'});
      expect(m.impedidosPara(terceiro.id), isEmpty);
    });

    test('técnico com pendência vencida aparece como impedido (beira do campo)', () {
      final c2 = Calendario();
      c2.jogo(
        'SAM',
        'INT',
        sumula: placar(1, 0, cartoes: [amarelo('tec', 'SAM', funcao: Funcao.tecnico)]),
      );
      final prox = c2.jogo('SAM', 'UDI');
      final m = MotorDisciplinar(partidas: c2.partidas, agora: prox.inicio);
      final imp = m.impedimentosPara(prox.id);
      expect(imp.first.funcao, Funcao.tecnico);
    });
  });
}
