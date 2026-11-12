// 3) gravou no Cloudant (se der erro, quem responde é o nó catch).
node.status({ fill: 'green', shape: 'dot', text: 'publicada: ' + msg.documento.titulo.slice(0, 30) });
return responder(201, apresentar(msg.documento, null, msg.usuarioId));
