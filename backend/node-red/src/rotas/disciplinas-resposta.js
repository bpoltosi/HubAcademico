const contagem = {};
documentos(msg.payload).forEach(function (d) {
    const nome = texto(d.disciplina);
    if (!nome) return;
    const chave = normalizar(nome);
    const item = contagem[chave] || (contagem[chave] = { nome: nome, totalPublicacoes: 0 });
    item.totalPublicacoes += 1;
});
const lista = Object.values(contagem).sort(function (a, b) { return a.nome.localeCompare(b.nome, 'pt-BR'); });
return responder(200, lista);
