// 2) uma mensagem por publicação, com o _id e a _rev que o Cloudant exige para apagar.
const docs = documentos(msg.payload);
if (!docs.length) {
    msg.payload = 'Não há publicações de exemplo para remover.';
    return [null, msg];
}
const lote = Date.now() + '-' + Math.random().toString(16).slice(2);
return [docs.map(function (d) {
    return { payload: { _id: d._id, _rev: d._rev }, lote: lote, total: docs.length };
}), null];
