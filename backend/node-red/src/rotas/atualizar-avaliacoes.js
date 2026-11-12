// 3) gravou; busca as avaliações para devolver a média atualizada.
return consultar({ colecao: 'avaliacao', publicacaoId: msg.publicacaoId }, ['publicacaoId', 'usuarioId', 'nota']);
