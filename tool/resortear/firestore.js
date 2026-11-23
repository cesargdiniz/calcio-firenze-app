// Lê e grava as partidas das temporadas para o novo sorteio (tool/resortear.dart).
//   node firestore.js ler  saida.json
//   node firestore.js gravar plano.json
const fs = require('fs');
const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'calcio-firenze' });
const db = admin.firestore();
const TEMPORADAS = ['master-2027', 'super-master-2027', 'livre-2027'];

async function ler(saida) {
  const dados = {};
  for (const id of TEMPORADAS) {
    const ref = db.collection('temporadas').doc(id);
    const times = (await ref.collection('times').get()).docs.map((d) => d.id);
    const partidas = (await ref.collection('partidas').get()).docs.map((d) => {
      const m = d.data();
      return {
        id: d.id,
        turno: m.turno ?? 1,
        fase: m.fase ?? 'classificatoria',
        inicio: m.inicio.toDate().toISOString(),
        encerrada: m.sumula != null,
      };
    });
    dados[id] = { times, partidas };
    console.log(`${id}: ${times.length} times, ${partidas.length} partidas`);
  }
  fs.writeFileSync(saida, JSON.stringify(dados));
}

async function gravar(arquivo) {
  const plano = JSON.parse(fs.readFileSync(arquivo, 'utf8'));
  for (const [id, { remover, salvar }] of Object.entries(plano)) {
    const col = db.collection('temporadas').doc(id).collection('partidas');
    const lote = db.batch();
    for (const pid of remover) lote.delete(col.doc(pid));
    for (const p of salvar) {
      lote.set(col.doc(p.id), {
        turno: p.turno,
        fase: p.fase,
        rodada: p.rodada,
        mandanteId: p.mandanteId,
        visitanteId: p.visitanteId,
        inicio: admin.firestore.Timestamp.fromDate(new Date(p.inicio)),
        local: p.local ?? null,
        sumula: null,
      });
    }
    await lote.commit();
    console.log(`${id}: ${remover.length} removidas, ${salvar.length} gravadas`);
  }
}

const [modo, arquivo] = process.argv.slice(2);
(modo === 'gravar' ? gravar(arquivo) : ler(arquivo)).catch((e) => {
  console.error(e);
  process.exit(1);
});
