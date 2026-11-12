// Nó catch: um erro no Cloudant ou no fluxo vira uma resposta JSON (a requisição não fica sem resposta).
const detalhe = String((msg.error && (msg.error.message || msg.error)) || 'erro desconhecido');
const origem = (msg.error && msg.error.source && msg.error.source.type) || '';
let status = 502;
let aviso = 'Falha ao acessar o Cloudant.';
if (origem === 'function') {
    status = 500;
    aviso = 'Erro interno no fluxo do Hub Acadêmico.';
} else if (/\b(401|403)\b|unauthori|forbidden|iam|api ?key|credential/i.test(detalhe)) {
    aviso = 'O Cloudant recusou o acesso. Confira a API key no nó de configuração do Cloudant.';
} else if (/\b429\b|too many/i.test(detalhe)) {
    status = 503;
    aviso = 'O Cloudant pediu para esperar (limite de requisições do plano Lite). Tente de novo em alguns segundos.';
} else if (/\b409\b|conflict/i.test(detalhe)) {
    status = 409;
    aviso = 'Outra pessoa alterou este registro ao mesmo tempo. Tente de novo.';
} else if (/ENOTFOUND|ECONNREFUSED|ETIMEDOUT|EAI_AGAIN|ECONNRESET|socket|network/i.test(detalhe)) {
    aviso = 'Sem conexão com o Cloudant. Confira a internet do computador que roda o Node-RED.';
}
node.status({ fill: 'red', shape: 'ring', text: aviso.slice(0, 40) });
if (msg.res) return [responder(status, { erro: aviso, detalhes: [detalhe] }), null];
msg.payload = aviso + ' (' + detalhe + ')';
return [null, msg];
