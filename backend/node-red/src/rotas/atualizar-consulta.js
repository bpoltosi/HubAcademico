// PUT /UPDATEpublicacao?id=… — 1) só quem publicou (ou a moderação) altera. O corpo traz os campos novos.
msg.corpo = corpoDaRequisicao();
msg.usuarioId = usuarioInformado();
msg.publicacaoId = idDe(parametro('id') || msg.corpo.id);
if (!msg.publicacaoId) return [null, invalido(['id: informe o id da publicação (?id=…)'])];
if (!msg.usuarioId && !ehModeracao()) return [null, semUsuario()];
return [consultar({ _id: msg.publicacaoId, colecao: 'publicacao' }), null];
