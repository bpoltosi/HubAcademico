// 2) monta a avaliação (com a _rev da anterior, para o Cloudant atualizar em vez de recusar).
const achados = documentos(msg.payload);
const usuario = achados.find(function (d) { return d.colecao === 'usuario' && idDe(d._id) === msg.usuarioId; });
const publicacao = achados.find(function (d) { return d.colecao === 'publicacao' && idDe(d._id) === msg.publicacaoId; });
const anterior = achados.find(function (d) { return d._id === msg.idAvaliacao; });
if (!usuario) return [null, semUsuario()];
if (!publicacao) return [null, naoEncontrado('Publicação')];
const doc = {
    _id: msg.idAvaliacao, colecao: 'avaliacao', publicacaoId: msg.publicacaoId, usuarioId: msg.usuarioId,
    nota: msg.nota, criadoEm: (anterior && anterior.criadoEm) || agora(), atualizadoEm: agora()
};
if (anterior && anterior._rev) doc._rev = anterior._rev;
msg.publicacao = publicacao;
msg.avaliacao = doc;
msg.payload = doc;
return [msg, null];
