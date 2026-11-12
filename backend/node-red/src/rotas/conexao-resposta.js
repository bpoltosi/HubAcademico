// Resultado do teste de conexão feito ao implantar. Banco sem nenhuma publicação:
// a 2ª saída cria as publicações de exemplo (as mesmas do app).
const lista = documentos(msg.payload);
const contar = function (colecao) { return lista.filter(function (d) { return d.colecao === colecao; }).length; };
const publicacoes = contar('publicacao');
node.status({ fill: 'green', shape: 'dot', text: 'Cloudant conectado · ' + publicacoes + ' publicações' });
msg.payload = 'Cloudant conectado: ' + publicacoes + ' publicações, ' + contar('usuario') + ' usuários e ' +
    contar('avaliacao') + ' avaliações no banco.' + (publicacoes ? '' : ' Criando as publicações de exemplo…');
return [msg, publicacoes ? null : RED.util.cloneMessage(msg)];
