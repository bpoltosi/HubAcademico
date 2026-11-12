// GET /GETusuario — dados do usuário do cabeçalho X-Hub-Usuario.
msg.usuarioId = usuarioInformado();
if (!msg.usuarioId) return [null, semUsuario()];
return [consultar({ _id: msg.usuarioId, colecao: 'usuario' }), null];
