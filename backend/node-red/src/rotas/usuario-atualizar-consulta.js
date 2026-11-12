// PUT /UPDATEusuario — corpo { nome, curso } do usuário do cabeçalho X-Hub-Usuario.
msg.usuarioId = usuarioInformado();
if (!msg.usuarioId) return [null, semUsuario()];
const v = validarUsuario(corpoDaRequisicao());
if (v.erros.length) return [null, invalido(v.erros)];
msg.nome = v.nome;
msg.curso = v.curso;
return [consultar({ _id: msg.usuarioId, colecao: 'usuario' }), null];
