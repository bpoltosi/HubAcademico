// POST /POSTavaliacao — corpo { publicacaoId, nota }. Uma avaliação por pessoa; avaliar de novo troca a nota.
// 1) busca, numa consulta só, o usuário, a publicação e a avaliação anterior (se houver).
msg.corpo = corpoDaRequisicao();
msg.usuarioId = usuarioInformado();
if (!msg.usuarioId) return [null, semUsuario()];
msg.publicacaoId = idDe(msg.corpo.publicacaoId);
msg.nota = Number(msg.corpo.nota);
const erros = [];
if (!msg.publicacaoId) erros.push('publicacaoId: informe o id da publicação');
if (!(Number.isInteger(msg.nota) && msg.nota >= 1 && msg.nota <= 5)) erros.push('nota: número inteiro de 1 a 5');
if (erros.length) return [null, invalido(erros)];
msg.idAvaliacao = idAvaliacao(msg.publicacaoId, msg.usuarioId);
return [consultar({ $or: [{ _id: msg.usuarioId }, { _id: msg.publicacaoId }, { _id: msg.idAvaliacao }] }), null];
