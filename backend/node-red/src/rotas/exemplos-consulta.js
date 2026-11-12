// Cria (ou restaura) as 12 publicações de exemplo, as mesmas do app.
// 1) busca as que já existem, para atualizar com a _rev atual em vez de duplicar.
return consultar({ _id: { $in: EXEMPLOS.map(function (e) { return e.id; }) } }, ['_id', '_rev']);
