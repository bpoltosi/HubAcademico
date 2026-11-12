const lista = documentos(msg.payload);
const publicacoes = {};
const disciplinas = {};
const avaliacoes = [];
let usuarios = 0;
lista.forEach(function (d) {
    if (d.colecao === 'publicacao') {
        publicacoes[idDe(d._id)] = true;
        const nome = normalizar(d.disciplina);
        if (nome) disciplinas[nome] = true;
    } else if (d.colecao === 'avaliacao') {
        avaliacoes.push(d);
    } else if (d.colecao === 'usuario') {
        usuarios += 1;
    }
});
const totais = {
    publicacoes: Object.keys(publicacoes).length,
    disciplinas: Object.keys(disciplinas).length,
    usuarios: usuarios,
    // avaliações de publicações que já foram removidas não contam
    avaliacoes: avaliacoes.filter(function (a) { return publicacoes[idDe(a.publicacaoId)]; }).length
};
node.status({ fill: 'green', shape: 'dot', text: totais.publicacoes + ' publicações · ' + totais.usuarios + ' usuários' });
return responder(200, { ok: true, servico: 'Hub Acadêmico', banco: 'Cloudant', horario: agora(), totais: totais });
