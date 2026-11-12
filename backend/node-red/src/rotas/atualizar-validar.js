// 2) junta o que mudou com o que já estava gravado e valida tudo de novo.
const atual = documentos(msg.payload)[0];
if (!atual) return [null, naoEncontrado('Publicação')];
if (!ehModeracao() && idDe(atual.usuarioId) !== msg.usuarioId) {
    return [null, proibido('Só quem publicou pode alterar esta publicação.')];
}
const campos = ['tipo', 'titulo', 'descricao', 'area', 'subarea', 'disciplina', 'instituicao', 'curso', 'ano',
    'imagemLink', 'link', 'autores', 'plataforma'];
const proposta = {};
campos.forEach(function (c) { proposta[c] = Object.prototype.hasOwnProperty.call(msg.corpo, c) ? msg.corpo[c] : atual[c]; });
const v = validarPublicacao(proposta);
if (v.erros.length) return [null, invalido(v.erros)];
const doc = Object.assign({}, atual, v.dados, { atualizadoEm: agora() });
msg.documento = doc;
msg.payload = doc;
return [msg, null];
