// POST /POSTpublicacao — 1) confere quem está publicando (cabeçalho X-Hub-Usuario).
msg.corpo = corpoDaRequisicao();
msg.usuarioId = usuarioInformado();
if (!msg.usuarioId) return [null, semUsuario()];
return [consultar({ _id: msg.usuarioId, colecao: 'usuario' }), null];
