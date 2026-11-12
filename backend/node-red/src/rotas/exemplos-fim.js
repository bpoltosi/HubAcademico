// 3) conta as gravações do lote e avisa uma vez só, no fim (erros aparecem no nó "Erros").
const chave = 'lote:' + msg.lote;
const feitos = (context.get(chave) || 0) + 1;
if (feitos < msg.total) {
    context.set(chave, feitos);
    return null;
}
context.set(chave, undefined);
node.status({ fill: 'green', shape: 'dot', text: 'exemplos gravados' });
msg.payload = 'Publicações de exemplo gravadas no Cloudant: ' + msg.total + ' de ' + EXEMPLOS.length +
    (msg.atualizados ? ' (' + msg.atualizados + ' já existiam e foram restauradas).' : '.');
return msg;
