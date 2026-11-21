// Regras puras dos avisos (testadas com `npm test`, sem Firebase).

// Mesma regra de lib/domain/usecases/avisos_push.dart (Topicos).
const limpo = (s) => s.replace(/[^a-zA-Z0-9\-_.~%]/g, '_');
const topicoDoTime = (temporadaId, timeId) => limpo(`time_${temporadaId}_${timeId}`);

const NOMES = {
  'master-2027': 'Master',
  'livre-2027': 'Livre',
  'super-master-2027': 'Super Master',
};

const HORA = 60 * 60 * 1000;

// Janela de uma hora que fica a 24 h de `agora`: cada jogo cai em uma só
// execução do agendamento de hora em hora.
function janela24h(agora) {
  return { de: new Date(agora.getTime() + 23 * HORA), ate: new Date(agora.getTime() + 24 * HORA) };
}

const formato = new Intl.DateTimeFormat('pt-BR', {
  weekday: 'short',
  day: '2-digit',
  month: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  timeZone: 'America/Sao_Paulo',
});

// "sáb., 23/11, 20:30" → "Sáb 23/11 às 20:30"
function quando(data) {
  const p = Object.fromEntries(formato.formatToParts(data).map((x) => [x.type, x.value]));
  const dia = p.weekday.replace('.', '');
  return `${dia.charAt(0).toUpperCase()}${dia.slice(1)} ${p.day}/${p.month} às ${p.hour}:${p.minute}`;
}

// Lembrete para os dois times de uma partida ainda sem súmula.
function lembretes({ temporadaId, partidaId, partida, nomes }) {
  if (partida.sumula) return [];
  const m = nomes[partida.mandanteId] || partida.mandanteId;
  const v = nomes[partida.visitanteId] || partida.visitanteId;
  const categoria = NOMES[temporadaId] || temporadaId;
  const local = partida.local || 'Arena Gugu';
  const titulo = `Jogo amanhã · ${m} x ${v}`;
  const corpo = `${categoria} · ${quando(partida.inicio)} · ${local}`;
  return [partida.mandanteId, partida.visitanteId].map((timeId) => ({
    topico: topicoDoTime(temporadaId, timeId),
    titulo,
    corpo,
    rota: `/participante/jogos/${partidaId}`,
  }));
}

module.exports = { limpo, topicoDoTime, janela24h, quando, lembretes, NOMES };
