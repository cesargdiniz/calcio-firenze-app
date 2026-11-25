// Lê o calendário como está no banco (ajustes da Gestão e partidas).
const fs = require('fs');
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'calcio-firenze' });
const db = admin.firestore();

(async () => {
  const aj = (await db.collection('calendario').doc('ajustes').get()).data()?.horarios ?? {};
  const ajustes = Object.fromEntries(Object.entries(aj).map(([k, v]) => [k, v.toDate().toISOString()]));
  const temporadas = {};
  for (const id of ['master-2027', 'super-master-2027', 'livre-2027']) {
    const ref = db.collection('temporadas').doc(id);
    const doc = (await ref.get()).data() ?? {};
    const partidas = (await ref.collection('partidas').get()).docs.map((d) => {
      const m = d.data();
      return {
        id: d.id, turno: m.turno ?? 1, fase: m.fase ?? 'classificatoria', rodada: m.rodada ?? null,
        mandanteId: m.mandanteId, visitanteId: m.visitanteId, inicio: m.inicio.toDate().toISOString(),
      };
    });
    const drafts = {};
    for (const n of [1, 2]) {
      const v = doc[`draft${n}`];
      if (v && v.toDate) drafts[n] = v.toDate().toISOString();
    }
    temporadas[id] = { partidas, drafts, chaves: Object.keys(doc) };
    console.log(`${id}: ${partidas.length} partidas`);
  }
  console.log(`ajustes: ${Object.keys(ajustes).length}`);
  fs.writeFileSync(process.argv[2], JSON.stringify({ ajustes, temporadas }));
})().catch((e) => { console.error(e); process.exit(1); });
