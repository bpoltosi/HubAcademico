#!/usr/bin/env node
/*
 * Monta o fluxo do Node-RED do Hub Acadêmico a partir de src/:
 *   src/comum.js        funções comuns (cada nó "function" recebe só as que usa)
 *   src/exemplos.js     publicações de exemplo (só nos nós que criam/removem exemplos)
 *   src/rotas/*.js      o código de cada nó "function"
 *
 * Gera:
 *   hub-academico-flows.json   o fluxo para importar (sem o nó de configuração do Cloudant)
 *   cloudant-config.json       só o nó de configuração do Cloudant (para um Node-RED que ainda não o tem)
 *
 * Uso (na raiz do repositório):
 *   node backend/node-red/montar-fluxo.js             grava os dois arquivos
 *   node backend/node-red/montar-fluxo.js --conferir  só confere se estão atualizados
 */
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const AQUI = __dirname;
const ARQUIVO_FLUXO = path.join(AQUI, 'hub-academico-flows.json');
const ARQUIVO_CONFIG = path.join(AQUI, 'cloudant-config.json');

// O mesmo banco e o mesmo nó de configuração do fluxo da equipe (o id igual faz os nós
// do fluxo usarem a configuração que já existe no Node-RED, com a API key já salva).
const BANCO = 'hub-academico-10';
const CONFIG = {
    id: '5ac37d22a9baf72b',
    type: 'cloudantplus',
    host: 'https://f1c0dcf9-5075-4061-a1f8-2f4ca596058a-bluemix.cloudantnosqldb.appdomain.cloud',
    name: '',
    useapikey: true
};

function ler(relativo) {
    return fs.readFileSync(path.join(AQUI, 'src', relativo), 'utf8');
}

// Divide um arquivo de src/ em declarações de nível superior (const/let/var/function na
// coluna 0), cada uma com o comentário logo acima dela. Cabeçalhos soltos, separadores de
// seção e os marcadores do gerador de catálogo não vão para o fluxo.
function declaracoes(arquivo) {
    const lista = [];
    let comentario = [];
    let atual = null;
    ler(arquivo).split('\n').forEach(function (linha) {
        const declaracao = /^(?:const|let|var|function)\s+([A-Za-z_$][\w$]*)/.exec(linha);
        if (declaracao) {
            atual = { nome: declaracao[1], linhas: comentario.concat([linha]) };
            lista.push(atual);
            comentario = [];
        } else if (/^(?:\/\/|\/\*| \*)/.test(linha)) {
            if (!/^\/\/ (?:-{3,}|={3,}|<\/?\w+>)/.test(linha)) comentario.push(linha);
        } else if (!linha.trim()) {
            if (comentario.length) comentario = [];
            else if (atual) atual.linhas.push(linha);
        } else if (atual) {
            atual.linhas = atual.linhas.concat(comentario, [linha]);
            comentario = [];
        }
    });
    lista.forEach(function (d) {
        while (d.linhas.length && !d.linhas[d.linhas.length - 1].trim()) d.linhas.pop();
        d.texto = d.linhas.join('\n');
        d.uso = new RegExp('(?:^|[^\\w$])' + d.nome.replace(/\$/g, '\\$') + '(?![\\w$])');
    });
    return lista;
}

// Código de um nó "function": só as declarações de src/comum.js (e de src/exemplos.js, nos
// nós de exemplos) que a rota usa, direta ou indiretamente, na ordem do arquivo; depois a rota.
function codigo(nome, extras) {
    const disponiveis = declaracoes('comum.js');
    (extras || []).forEach(function (e) { disponiveis.push.apply(disponiveis, declaracoes(e + '.js')); });
    const rota = ler('rotas/' + nome + '.js');
    const usadas = new Set();
    const aExaminar = [rota];
    while (aExaminar.length) {
        const trecho = aExaminar.pop();
        disponiveis.forEach(function (d) {
            if (!usadas.has(d) && d.uso.test(trecho)) {
                usadas.add(d);
                aExaminar.push(d.texto);
            }
        });
    }
    const comuns = disponiveis.filter(function (d) { return usadas.has(d); });
    const fontes = ['src/comum.js'].concat((extras || []).map(function (e) { return 'src/' + e + '.js'; })).join(' e ');
    const partes = [];
    if (comuns.length) {
        partes.push('// ---- funções comuns usadas por este nó (vêm de ' + fontes + '; edite lá) ----\n' +
            comuns.map(function (d) { return d.texto; }).join('\n\n'));
    }
    partes.push('// ===================================================================== ' + nome + '\n' + rota);
    return partes.join('\n\n');
}

function nid(chave) {
    return crypto.createHash('sha1').update('hub-academico-cloudant/' + chave).digest('hex').slice(0, 16);
}

// ---------------------------------------------------------------- rotas
// Cada passo: { fn, nome, saidas } (nó function; a 2ª saída vai direto para a resposta),
//             { busca: nome }      (cloudantplus in, consulta Mango)
//             { grava: nome } / { apaga: nome }  (cloudantplus out)
const ROTAS = [
    {
        metodo: 'get', url: '/GETstatus', rotulo: 'Get Status', uso: 'teste de conexão e totais',
        passos: [
            { fn: 'status-consulta', nome: 'Conta documentos' },
            { busca: 'Consulta o banco' },
            { fn: 'status-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'get', url: '/GETpublicacoes', rotulo: 'Get Publicações',
        uso: 'lista (filtros: tipo, ano, area, subarea, curso, disciplina, titulo, autor, q, ordem=media, limite)',
        passos: [
            { fn: 'publicacoes-consulta', nome: 'Consulta publicações' },
            { busca: 'Busca publicações' },
            { fn: 'publicacoes-avaliacoes', nome: 'Consulta avaliações' },
            { busca: 'Busca avaliações' },
            { fn: 'publicacoes-resposta', nome: 'Filtra e monta a lista' }
        ]
    },
    {
        metodo: 'post', url: '/POSTpublicacao', rotulo: 'Post Publicação', uso: 'publica (precisa de X-Hub-Usuario)',
        passos: [
            { fn: 'publicar-usuario', nome: 'Confere o usuário', saidas: 2 },
            { busca: 'Busca o usuário' },
            { fn: 'publicar-validar', nome: 'Valida e monta', saidas: 2 },
            { grava: 'Grava a publicação' },
            { fn: 'publicar-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'put', url: '/UPDATEpublicacao', rotulo: 'Update Publicação', uso: 'altera (?id=…; quem publicou ou X-Hub-Moderacao)',
        passos: [
            { fn: 'atualizar-consulta', nome: 'Confere o pedido', saidas: 2 },
            { busca: 'Busca a publicação' },
            { fn: 'atualizar-validar', nome: 'Valida e junta', saidas: 2 },
            { grava: 'Grava a publicação' },
            { fn: 'atualizar-avaliacoes', nome: 'Consulta avaliações' },
            { busca: 'Busca avaliações' },
            { fn: 'atualizar-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'delete', url: '/DELETEpublicacao', rotulo: 'Delete Publicação', uso: 'remove (?id=…; quem publicou ou X-Hub-Moderacao)',
        passos: [
            { fn: 'remover-consulta', nome: 'Confere o pedido', saidas: 2 },
            { busca: 'Busca a publicação' },
            { fn: 'remover-validar', nome: 'Confere quem remove', saidas: 2 },
            { apaga: 'Apaga a publicação' },
            { fn: 'remover-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'post', url: '/POSTavaliacao', rotulo: 'Post Avaliação', uso: 'nota de 1 a 5; avaliar de novo troca a nota (X-Hub-Usuario)',
        passos: [
            { fn: 'avaliar-consulta', nome: 'Confere o pedido', saidas: 2 },
            { busca: 'Busca usuário e publicação' },
            { fn: 'avaliar-gravar', nome: 'Monta a avaliação', saidas: 2 },
            { grava: 'Grava a avaliação' },
            { fn: 'avaliar-recalcular', nome: 'Consulta avaliações' },
            { busca: 'Busca avaliações' },
            { fn: 'avaliar-resposta', nome: 'Calcula a média' }
        ]
    },
    {
        metodo: 'post', url: '/POSTusuario', rotulo: 'Post Usuário', uso: 'cadastra o usuário e devolve o id',
        passos: [
            { fn: 'usuario-cadastrar', nome: 'Valida e monta', saidas: 2 },
            { grava: 'Grava o usuário' },
            { fn: 'usuario-cadastrar-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'get', url: '/GETusuario', rotulo: 'Get Usuário', uso: 'dados do usuário do cabeçalho X-Hub-Usuario',
        passos: [
            { fn: 'usuario-consulta', nome: 'Confere o cabeçalho', saidas: 2 },
            { busca: 'Busca o usuário' },
            { fn: 'usuario-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'put', url: '/UPDATEusuario', rotulo: 'Update Usuário', uso: 'altera nome e curso (X-Hub-Usuario)',
        passos: [
            { fn: 'usuario-atualizar-consulta', nome: 'Valida o pedido', saidas: 2 },
            { busca: 'Busca o usuário' },
            { fn: 'usuario-atualizar-gravar', nome: 'Junta os dados', saidas: 2 },
            { grava: 'Grava o usuário' },
            { fn: 'usuario-atualizar-resposta', nome: 'Monta a resposta' }
        ]
    },
    {
        metodo: 'get', url: '/GETdisciplinas', rotulo: 'Get Disciplinas', uso: 'disciplinas usadas, com o total de publicações',
        passos: [
            { fn: 'disciplinas-consulta', nome: 'Consulta disciplinas' },
            { busca: 'Busca as publicações' },
            { fn: 'disciplinas-resposta', nome: 'Conta por disciplina' }
        ]
    },
    {
        metodo: 'get', url: '/GETsubareas', rotulo: 'Get Subáreas', uso: 'subáreas de cada área (tabela do CNPq)',
        passos: [
            { fn: 'subareas', nome: 'Subáreas do CNPq' }
        ]
    }
];

const TABELA_ROTAS = '| método | rota | uso |\n|---|---|---|\n' + ROTAS.map(function (r) {
    return '| ' + r.metodo.toUpperCase() + ' | ' + r.url + ' | ' + r.uso + ' |';
}).join('\n');

const INFO_ABA = [
    '### Hub Acadêmico – API e banco no Cloudant',
    '',
    'App iOS do HackaTruck (CTISM/UFSM). As rotas seguem o padrão GET/POST/UPDATE/DELETE + nome, como no fluxo da equipe.',
    '',
    '**Banco:** Cloudant `' + BANCO + '`. Cada documento tem o campo `colecao`:',
    '',
    '| colecao | campos |',
    '|---|---|',
    '| publicacao | _id, tipo, titulo, descricao, autores, ano, area, subarea, disciplina, curso, instituicao, link, plataforma, imagemLink, usuarioId, criadoEm |',
    '| avaliacao | _id, publicacaoId, usuarioId, nota |',
    '| usuario | _id, nome, curso |',
    '',
    'A média (`media`) e o total de avaliações (`totalAvaliacoes`) de cada publicação são calculados a partir das avaliações.',
    '',
    '**Para funcionar:** os nós do Cloudant usam a configuração `' + CONFIG.id + '` (host do Cloudant da equipe + API key). ' +
    'Se o Node-RED ainda não tem essa configuração, importe também `cloudant-config.json` e cole a API key nela.',
    '',
    'Moderação: defina a variável de ambiente `HUB_MODERACAO_TOKEN` e envie o mesmo valor no cabeçalho `X-Hub-Moderacao`.',
    '',
    'Documentação completa: `backend/node-red/README.md` no repositório.'
].join('\n');

const INFO_ROTAS = [
    'Cada rota: **http in → function → cloudantplus → … → http response**.',
    '',
    'O app envia o id do usuário no cabeçalho `X-Hub-Usuario`. Esse id não aparece nas respostas públicas.',
    'Erros do Cloudant caem no nó **catch** e voltam ao app como JSON `{ "erro": "…", "detalhes": [] }`.',
    '',
    TABELA_ROTAS
].join('\n');

const INFO_BANCO = [
    '- **Ao implantar:** testa a conexão com o Cloudant e mostra os totais na barra de depuração (🐞). ' +
    'Com o banco sem nenhuma publicação, cria as 12 publicações de exemplo (as mesmas do app).',
    '- **Criar ou restaurar exemplos:** grava de novo as publicações de exemplo, com as médias originais ' +
    '(4 por segundo, por causa do limite de gravações do plano Lite do Cloudant).',
    '- **Remover exemplos:** apaga só as publicações de exemplo; as publicadas pela turma ficam.'
].join('\n');

// ---------------------------------------------------------------- montagem
function montar() {
    const ABA = nid('aba');
    const nos = [];
    const add = function (no) { no.z = ABA; nos.push(no); return no; };

    nos.push({ id: ABA, type: 'tab', label: 'Hub Acadêmico – Cloudant', disabled: false, info: INFO_ABA, env: [] });
    add({ id: nid('comentario/rotas'), type: 'comment', name: 'API REST do Hub Acadêmico · rotas GET/POST/UPDATE/DELETE + nome · banco Cloudant ' + BANCO, info: INFO_ROTAS, x: 420, y: 40, wires: [] });

    function funcao(id, passo, x, y, extras) {
        return add({
            id: id, type: 'function', name: passo.nome, func: codigo(passo.fn, extras), outputs: passo.saidas || 1,
            timeout: 0, noerr: 0, initialize: '', finalize: '', libs: [], x: x, y: y, wires: []
        });
    }
    function busca(id, nome, x, y) {
        return add({
            id: id, type: 'cloudantplus in', name: nome, cloudant: CONFIG.id, database: BANCO, service: '_ext_',
            search: '_query_', design: '', index: '', x: x, y: y, wires: []
        });
    }
    function grava(id, nome, operacao, x, y) {
        return add({
            id: id, type: 'cloudantplus out', name: nome, cloudant: CONFIG.id, database: BANCO, service: '_ext_',
            payonly: true, operation: operacao, x: x, y: y, wires: []
        });
    }
    function espera(id, nome, x, y) {
        // limitador do núcleo do Node-RED: 4 mensagens por segundo, sem descartar nenhuma
        return add({
            id: id, type: 'delay', name: nome, pauseType: 'rate', timeout: '5', timeoutUnits: 'seconds', rate: '4',
            nbRateUnits: '1', rateUnits: 'second', randomFirst: '1', randomLast: '5', randomUnits: 'seconds',
            drop: false, allowrate: false, outputs: 1, x: x, y: y, wires: []
        });
    }
    function passoParaNo(chave, passo, x, y, extras) {
        if (passo.fn) return funcao(nid(chave + '/fn/' + passo.fn), passo, x, y, extras);
        if (passo.busca) return busca(nid(chave + '/busca/' + passo.busca), passo.busca, x, y);
        if (passo.grava) return grava(nid(chave + '/grava/' + passo.grava), passo.grava, 'insert', x, y);
        if (passo.apaga) return grava(nid(chave + '/apaga/' + passo.apaga), passo.apaga, 'delete', x, y);
        if (passo.espera) return espera(nid(chave + '/espera/' + passo.espera), passo.espera, x, y);
        throw new Error('passo desconhecido em ' + chave);
    }

    // rotas
    ROTAS.forEach(function (r, i) {
        const y = 100 + i * 70;
        const chave = r.metodo + ' ' + r.url;
        const entrada = add({
            id: nid(chave + '/http in'), type: 'http in', name: r.rotulo + ' [' + r.url.slice(1) + ']', url: r.url, method: r.metodo,
            upload: false, swaggerDoc: '', x: 150, y: y, wires: []
        });
        const resposta = add({
            id: nid(chave + '/http response'), type: 'http response', name: 'Response ' + r.rotulo, statusCode: '', headers: {},
            x: 400 + r.passos.length * 240, y: y, wires: []
        });
        let anterior = entrada;
        r.passos.forEach(function (passo, j) {
            const no = passoParaNo(chave, passo, 400 + j * 240, y);
            anterior.wires[0] = (anterior.wires[0] || []).concat(no.id);
            if (passo.fn && (passo.saidas || 1) === 2) no.wires[1] = [resposta.id];
            anterior = no;
        });
        anterior.wires[0] = (anterior.wires[0] || []).concat(resposta.id);
        r.passos.forEach(function () { /* saídas sem ligação ficam [] */ });
    });
    nos.forEach(function (n) {
        if (n.type === 'function') for (let k = 0; k < n.outputs; k++) n.wires[k] = n.wires[k] || [];
        if (n.type.indexOf('cloudantplus') === 0 || n.type === 'http in' || n.type === 'delay') n.wires[0] = n.wires[0] || [];
    });

    // erros
    const yErro = 100 + ROTAS.length * 70 + 30;
    const respostaErro = add({ id: nid('erro/http response'), type: 'http response', name: 'Response Erro', statusCode: '', headers: {}, x: 640, y: yErro, wires: [] });
    const depuracaoErro = add({
        id: nid('erro/debug'), type: 'debug', name: 'Erros', active: true, tosidebar: true, console: false, tostatus: false,
        complete: 'payload', targetType: 'msg', statusVal: '', statusType: 'auto', x: 620, y: yErro + 40, wires: []
    });
    const fnErro = funcao(nid('erro/fn'), { fn: 'erro', nome: 'Monta a resposta de erro', saidas: 2 }, 400, yErro);
    fnErro.wires = [[respostaErro.id], [depuracaoErro.id]];
    add({ id: nid('erro/catch'), type: 'catch', name: 'Erros do Cloudant e do fluxo', scope: null, uncaught: false, x: 170, y: yErro, wires: [[fnErro.id]] });

    // manutenção: conexão e exemplos
    const yBanco = yErro + 120;
    add({ id: nid('comentario/banco'), type: 'comment', name: 'Banco: Cloudant ' + BANCO + ' · conexão e exemplos', info: INFO_BANCO, x: 260, y: yBanco, wires: [] });
    const situacao = add({
        id: nid('banco/debug'), type: 'debug', name: 'Situação do banco', active: true, tosidebar: true, console: false, tostatus: false,
        complete: 'payload', targetType: 'msg', statusVal: '', statusType: 'auto', x: 1960, y: yBanco + 60, wires: []
    });
    function injecao(chave, nome, umaVez, y) {
        return add({
            id: nid('banco/inject/' + chave), type: 'inject', name: nome,
            props: [{ p: 'payload' }, { p: 'topic', vt: 'str' }], repeat: '', crontab: '', once: umaVez, onceDelay: '3',
            topic: chave, payload: '', payloadType: 'date', x: 190, y: y, wires: []
        });
    }
    function corrente(chave, inicio, passos, y, extras) {
        let anterior = inicio;
        const criados = passos.map(function (passo, j) {
            const no = passoParaNo('banco/' + chave, passo, 460 + j * 240, y, extras);
            anterior.wires[0] = (anterior.wires[0] || []).concat(no.id);
            anterior = no;
            return no;
        });
        anterior.wires[0] = (anterior.wires[0] || []).concat(situacao.id);
        return criados;
    }

    // 1) ao implantar: testa a conexão; banco vazio → cria os exemplos
    const testar = injecao('conexao', 'Ao implantar: testa a conexão', true, yBanco + 60);
    const conexao = corrente('conexao', testar, [
        { fn: 'status-consulta', nome: 'Conta documentos' },
        { busca: 'Consulta o banco' },
        { fn: 'conexao-resposta', nome: 'Mostra a situação', saidas: 2 }
    ], yBanco + 60);

    // 2) criar ou restaurar exemplos
    const criar = injecao('exemplos', 'Criar ou restaurar exemplos', false, yBanco + 130);
    const exemplos = corrente('exemplos', criar, [
        { fn: 'exemplos-consulta', nome: 'Busca exemplos existentes' },
        { busca: 'Consulta os exemplos' },
        { fn: 'exemplos-gravar', nome: 'Monta os exemplos' },
        { espera: '4 por segundo (plano Lite)' },
        { grava: 'Grava os exemplos' },
        { fn: 'exemplos-fim', nome: 'Resume' }
    ], yBanco + 130, ['exemplos']);
    conexao[2].wires[1] = [exemplos[0].id];

    // 3) remover exemplos
    const remover = injecao('remover', 'Remover exemplos', false, yBanco + 200);
    const limpeza = corrente('remover', remover, [
        { fn: 'limpar-consulta', nome: 'Busca os exemplos' },
        { busca: 'Consulta os exemplos' },
        { fn: 'limpar-apagar', nome: 'Monta a remoção', saidas: 2 },
        { espera: '4 por segundo (plano Lite)' },
        { apaga: 'Apaga os exemplos' },
        { fn: 'limpar-fim', nome: 'Resume' }
    ], yBanco + 200, ['exemplos']);
    limpeza[2].wires[1] = [situacao.id];

    return nos;
}

function texto(dados) {
    return JSON.stringify(dados, null, 4) + '\n';
}

if (require.main === module) {
    const fluxo = texto(montar());
    const config = texto([CONFIG]);
    if (process.argv.indexOf('--conferir') >= 0) {
        const ok = fs.existsSync(ARQUIVO_FLUXO) && fs.readFileSync(ARQUIVO_FLUXO, 'utf8') === fluxo &&
            fs.existsSync(ARQUIVO_CONFIG) && fs.readFileSync(ARQUIVO_CONFIG, 'utf8') === config;
        console.log(ok ? 'hub-academico-flows.json e cloudant-config.json estão atualizados.' :
            'Desatualizado: rode "node backend/node-red/montar-fluxo.js".');
        process.exit(ok ? 0 : 1);
    }
    fs.writeFileSync(ARQUIVO_FLUXO, fluxo);
    fs.writeFileSync(ARQUIVO_CONFIG, config);
    const nos = JSON.parse(fluxo);
    console.log('hub-academico-flows.json: ' + nos.length + ' nós · ' + ROTAS.length + ' rotas · banco ' + BANCO);
    console.log('cloudant-config.json: nó de configuração ' + CONFIG.id);
}

module.exports = { montar: montar, texto: texto, ROTAS: ROTAS, BANCO: BANCO, CONFIG: CONFIG };
