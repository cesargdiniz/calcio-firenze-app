// Serviços do Calcio Firenze no Firebase: notificações nos celulares.
//
// - enviarAvisoPush: o app da Organização grava em
//   temporadas/{id}/avisosPush (resultado e suspensões, ao encerrar a
//   súmula); aqui o aviso vai para o tópico e é marcado como enviado.
// - lembrete24h: de hora em hora, avisa os dois times dos jogos que começam
//   dali a 24 horas.
const { setGlobalOptions } = require('firebase-functions/v2');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { janela24h, lembretes } = require('./avisos');

initializeApp();
setGlobalOptions({ region: 'southamerica-east1', maxInstances: 2 });

async function enviar({ topico, titulo, corpo, rota }) {
  await getMessaging().send({
    topic: topico,
    notification: { title: titulo, body: corpo },
    data: rota ? { rota } : {},
    android: { priority: 'high', notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
  });
}

exports.enviarAvisoPush = onDocumentCreated(
  'temporadas/{temporadaId}/avisosPush/{avisoId}',
  async (event) => {
    const aviso = event.data && event.data.data();
    if (!aviso || aviso.enviadoEm || !aviso.topico) return;
    await enviar(aviso);
    await event.data.ref.update({ enviadoEm: FieldValue.serverTimestamp() });
  },
);

exports.lembrete24h = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'America/Sao_Paulo' },
  async () => {
    const db = getFirestore();
    const { de, ate } = janela24h(new Date());
    const temporadas = await db.collection('temporadas').get();
    for (const t of temporadas.docs) {
      const jogos = await t.ref
        .collection('partidas')
        .where('inicio', '>=', Timestamp.fromDate(de))
        .where('inicio', '<', Timestamp.fromDate(ate))
        .get();
      if (jogos.empty) continue;
      const times = await t.ref.collection('times').get();
      const nomes = Object.fromEntries(times.docs.map((d) => [d.id, d.get('nome') || d.id]));
      for (const j of jogos.docs) {
        const dados = j.data();
        // Já avisado para este horário (o jogo pode ter sido remarcado).
        if (dados.lembrete24h && dados.lembrete24h.isEqual(dados.inicio)) continue;
        const avisos = lembretes({
          temporadaId: t.id,
          partidaId: j.id,
          partida: { ...dados, inicio: dados.inicio.toDate() },
          nomes,
        });
        for (const a of avisos) await enviar(a);
        if (avisos.length) await j.ref.update({ lembrete24h: dados.inicio });
      }
    }
  },
);
