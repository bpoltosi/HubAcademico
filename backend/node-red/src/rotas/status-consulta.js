// GET /GETstatus (e o teste de conexão ao implantar): conta os documentos de cada coleção.
return consultar({ colecao: { $in: ['publicacao', 'avaliacao', 'usuario'] } }, ['_id', 'colecao', 'publicacaoId', 'disciplina']);
