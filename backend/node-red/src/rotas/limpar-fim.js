const chave = 'lote:' + msg.lote;
const feitos = (context.get(chave) || 0) + 1;
if (feitos < msg.total) {
    context.set(chave, feitos);
    return null;
}
context.set(chave, undefined);
node.status({ fill: 'grey', shape: 'ring', text: 'exemplos removidos' });
msg.payload = 'Publicações de exemplo removidas: ' + msg.total + '. Com o banco sem nenhuma publicação, elas voltam no próximo Deploy.';
return msg;
