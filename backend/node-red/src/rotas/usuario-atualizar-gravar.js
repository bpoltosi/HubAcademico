const atual = documentos(msg.payload)[0];
if (!atual) return [null, semUsuario()];
const doc = Object.assign({}, atual, { nome: msg.nome, curso: msg.curso, atualizadoEm: agora() });
msg.documento = doc;
msg.payload = doc;
return [msg, null];
