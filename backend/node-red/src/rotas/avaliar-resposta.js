// 4) a avaliação recém-gravada entra na conta mesmo que a consulta ainda não a enxergue.
const lista = documentos(msg.payload).filter(function (a) { return a._id !== msg.avaliacao._id; });
lista.push(msg.avaliacao);
const t = totaisDeAvaliacao(lista, msg.usuarioId)[msg.publicacaoId];
const p = apresentar(msg.publicacao, t, msg.usuarioId);
return responder(200, { publicacaoId: msg.publicacaoId, media: p.media, totalAvaliacoes: p.totalAvaliacoes, minhaNota: msg.nota });
