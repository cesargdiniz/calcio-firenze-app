const test = require('node:test');
const assert = require('node:assert');
const { limpo, janela24h, quando, lembretes } = require('../avisos');

test('tópico só com caracteres aceitos pelo FCM', () => {
  assert.strictEqual(limpo('time_master-2027_são paulo'), 'time_master-2027_s_o_paulo');
});

test('janela de uma hora a 24 h', () => {
  const agora = new Date('2027-03-10T12:00:00-03:00');
  const { de, ate } = janela24h(agora);
  assert.strictEqual(de.toISOString(), '2027-03-11T14:00:00.000Z');
  assert.strictEqual(ate.toISOString(), '2027-03-11T15:00:00.000Z');
});

test('data e hora no fuso de Brasília', () => {
  assert.strictEqual(quando(new Date('2027-03-13T20:00:00Z')), 'Sáb 13/03 às 17:00');
});

test('lembrete vai para os dois times, e não sai depois da súmula', () => {
  const partida = {
    mandanteId: 'inter',
    visitanteId: 'roma',
    inicio: new Date('2027-03-15T23:30:00Z'),
  };
  const avisos = lembretes({
    temporadaId: 'master-2027',
    partidaId: 'p1',
    partida,
    nomes: { inter: 'Inter', roma: 'Roma' },
  });
  assert.deepStrictEqual(
    avisos.map((a) => a.topico),
    ['time_master-2027_inter', 'time_master-2027_roma'],
  );
  assert.strictEqual(avisos[0].titulo, 'Jogo amanhã · Inter x Roma');
  assert.strictEqual(avisos[0].corpo, 'Master · Seg 15/03 às 20:30 · Arena Gugu');
  assert.deepStrictEqual(
    lembretes({ temporadaId: 'master-2027', partidaId: 'p1', partida: { ...partida, sumula: {} }, nomes: {} }),
    [],
  );
});
