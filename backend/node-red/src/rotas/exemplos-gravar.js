// 2) uma mensagem por publicação: o limitador seguinte manda 4 por segundo para o Cloudant
// (o plano Lite aceita poucas gravações por segundo).
const existentes = {};
documentos(msg.payload).forEach(function (d) { existentes[d._id] = d._rev; });
const lote = Date.now() + '-' + Math.random().toString(16).slice(2);
const atualizados = Object.keys(existentes).length;
return [EXEMPLOS.map(function (e) {
    const doc = documentoDeExemplo(e);
    if (existentes[e.id]) doc._rev = existentes[e.id];
    return { payload: doc, lote: lote, total: EXEMPLOS.length, atualizados: atualizados };
})];
