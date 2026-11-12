// POST /POSTusuario — corpo { nome, curso }. Devolve o id que o app manda no cabeçalho X-Hub-Usuario.
const v = validarUsuario(corpoDaRequisicao());
if (v.erros.length) return [null, invalido(v.erros)];
const doc = { _id: novoId(), colecao: 'usuario', nome: v.nome, curso: v.curso, criadoEm: agora() };
msg.documento = doc;
msg.payload = doc;
return [msg, null];
