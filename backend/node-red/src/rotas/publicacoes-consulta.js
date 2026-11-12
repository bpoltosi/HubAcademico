// GET /GETpublicacoes — 1) busca as publicações.
// Filtros opcionais (na URL): tipo, ano, area, subarea, curso, disciplina (ou cadeira), titulo, autor, q,
// ordem=media e limite. Sem filtros, devolve todas, das mais recentes para as mais antigas.
return consultar({ colecao: 'publicacao' });
