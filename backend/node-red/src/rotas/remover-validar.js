// 2) para apagar, o Cloudant precisa do _id e da _rev atual do documento.
const atual = documentos(msg.payload)[0];
if (!atual) return [null, naoEncontrado('Publicação')];
if (!ehModeracao() && idDe(atual.usuarioId) !== msg.usuarioId) {
    return [null, proibido('Só quem publicou (ou a moderação) pode remover esta publicação.')];
}
msg.payload = { _id: atual._id, _rev: atual._rev };
return [msg, null];
