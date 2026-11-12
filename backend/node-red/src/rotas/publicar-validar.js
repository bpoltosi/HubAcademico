// 2) valida os campos e monta o documento da publicação.
if (!documentos(msg.payload)[0]) return [null, semUsuario()];
const v = validarPublicacao(msg.corpo || {});
if (v.erros.length) return [null, invalido(v.erros)];
const doc = Object.assign({ _id: novoId(), colecao: 'publicacao' }, v.dados, { usuarioId: msg.usuarioId, criadoEm: agora() });
msg.documento = doc;
msg.payload = doc;
return [msg, null];
