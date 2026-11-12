const totais = totaisDeAvaliacao(documentos(msg.payload), msg.usuarioId);
return responder(200, apresentar(msg.documento, totais[msg.publicacaoId], msg.usuarioId));
