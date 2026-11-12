// 2) guarda as publicações e busca as avaliações, para calcular média e total.
msg.publicacoes = documentos(msg.payload);
return consultar({ colecao: 'avaliacao' }, ['publicacaoId', 'usuarioId', 'nota']);
