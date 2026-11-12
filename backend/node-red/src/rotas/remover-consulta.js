// DELETE /DELETEpublicacao?id=… — 1) só quem publicou ou a moderação (cabeçalho X-Hub-Moderacao).
msg.usuarioId = usuarioInformado();
msg.publicacaoId = idDe(parametro('id') || corpoDaRequisicao().id);
if (!msg.publicacaoId) return [null, invalido(['id: informe o id da publicação (?id=…)'])];
if (!msg.usuarioId && !ehModeracao()) return [null, semUsuario()];
return [consultar({ _id: msg.publicacaoId, colecao: 'publicacao' }, ['_id', '_rev', 'usuarioId']), null];
