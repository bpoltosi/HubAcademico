// 3) gravou; busca as avaliações da publicação para devolver a média nova.
return consultar({ colecao: 'avaliacao', publicacaoId: msg.publicacaoId }, ['_id', 'publicacaoId', 'usuarioId', 'nota']);
