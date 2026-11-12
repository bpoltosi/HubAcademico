#!/usr/bin/env node
/*
 * Testes do fluxo do Hub Acadêmico (hub-academico-flows.json) sem precisar do Node-RED nem do Cloudant.
 *
 * O teste executa o fluxo como o Node-RED: entrega as mensagens pelas ligações, roda o código dos nós
 * "function", responde pelos nós "http response" e manda os erros para o nó "catch". Os nós
 * "cloudantplus in/out" usam um Cloudant em memória com as mesmas regras que importam aqui:
 * consulta Mango (limite padrão de 25, sort só com índice), conflito sem _rev, _id e _rev para apagar,
 * gravação em lote. O nó de consulta é testado nas duas formas de resposta: { docs: [...] } (versão 2.x)
 * e a lista de documentos.
 *
 * Uso (na raiz do repositório):  node backend/node-red/testes/testar-fluxo.js
 */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const RAIZ = path.join(__dirname, '..');
const fluxo = JSON.parse(fs.readFileSync(path.join(RAIZ, 'hub-academico-flows.json'), 'utf8'));
const configCloudant = JSON.parse(fs.readFileSync(path.join(RAIZ, 'cloudant-config.json'), 'utf8'));
const montador = require(path.join(RAIZ, 'montar-fluxo.js'));

let aprovados = 0;
const falhas = [];
async function teste(nome, corpo) {
    try {
        await corpo();
        aprovados += 1;
        console.log('  ✓ ' + nome);
    } catch (e) {
        falhas.push(nome);
        console.log('  ✗ ' + nome + '\n      ' + String((e && e.stack) || e).split('\n').slice(0, 5).join('\n      '));
    }
}

// ===================================================================== Cloudant em memória
function criarCloudant() {
    const bancos = {};
    let sequencia = 0;
    const banco = (nome) => bancos[nome] || (bancos[nome] = new Map());
    const copia = (d) => JSON.parse(JSON.stringify(d));
    const novaRev = (anterior) => (anterior ? parseInt(anterior, 10) + 1 : 1) + '-' + (++sequencia).toString(16).padStart(8, '0');
    const erro = (status, mensagem) => Object.assign(new Error(mensagem), { status: status, code: status });
    const valor = (doc, campo) => campo.split('.').reduce((o, k) => (o === null || o === undefined ? undefined : o[k]), doc);

    function casa(doc, seletor) {
        return Object.keys(seletor).every((campo) => {
            const condicao = seletor[campo];
            if (campo === '$or') return condicao.some((s) => casa(doc, s));
            if (campo === '$and') return condicao.every((s) => casa(doc, s));
            const v = valor(doc, campo);
            if (condicao !== null && typeof condicao === 'object' && !Array.isArray(condicao)) {
                return Object.keys(condicao).every((op) => {
                    const a = condicao[op];
                    switch (op) {
                        case '$eq': return v === a;
                        case '$ne': return v !== a;
                        case '$in': return Array.isArray(a) && a.indexOf(v) >= 0;
                        case '$exists': return (v !== undefined) === a;
                        default: throw erro(400, 'Bad Request: invalid_operator ' + op);
                    }
                });
            }
            return v === condicao;
        });
    }

    return {
        bancos: bancos,
        falha: null,
        consultas: 0,
        documentos(nome) { return [...banco(nome).values()].map(copia); },
        colocar(nome, doc) { banco(nome).set(doc._id, Object.assign(copia(doc), { _rev: novaRev() })); },
        find(nome, opcoes) {
            if (this.falha) throw this.falha;
            this.consultas += 1;
            if (!opcoes || typeof opcoes.selector !== 'object') throw erro(400, 'Bad Request: selector is required');
            if (opcoes.sort) throw erro(400, 'no_usable_index: No index exists for this sort, try indexing by the sort fields.');
            const limite = opcoes.limit === undefined ? 25 : opcoes.limit;
            let docs = [...banco(nome).values()].filter((d) => casa(d, opcoes.selector)).slice(0, limite).map(copia);
            if (opcoes.fields) {
                docs = docs.map((d) => {
                    const parcial = {};
                    opcoes.fields.forEach((c) => { if (d[c] !== undefined) parcial[c] = d[c]; });
                    return parcial;
                });
            }
            return { docs: docs, bookmark: 'nil', warning: 'No matching index found, create an index to optimize query time.' };
        },
        gravar(nome, doc) {
            if (this.falha) throw this.falha;
            const b = banco(nome);
            const id = doc._id || ('auto' + (++sequencia).toString(16).padStart(28, '0'));
            const atual = b.get(id);
            if ((atual && doc._rev !== atual._rev) || (!atual && doc._rev)) throw erro(409, 'Conflict: Document update conflict.');
            const novo = copia(doc);
            novo._id = id;
            novo._rev = novaRev(atual && atual._rev);
            if (novo._deleted) b.delete(id); else b.set(id, novo);
            return { ok: true, id: id, rev: novo._rev };
        },
        apagar(nome, id, rev) {
            if (this.falha) throw this.falha;
            const atual = banco(nome).get(id);
            if (!atual) throw erro(404, 'Not Found: deleted');
            if (atual._rev !== rev) throw erro(409, 'Conflict: Document update conflict.');
            banco(nome).delete(id);
            return { ok: true, id: id, rev: novaRev(rev) };
        },
        lote(nome, docs) {
            if (this.falha) throw this.falha;
            return docs.map((d) => {
                try { return this.gravar(nome, d); } catch (e) { return { id: d._id, error: 'conflict', reason: e.message }; }
            });
        }
    };
}

// ===================================================================== Node-RED simulado
function criarNodeRed(opcoes) {
    opcoes = opcoes || {};
    const cloudant = opcoes.cloudant || criarCloudant();
    const forma = opcoes.forma || 'docs';
    const ambiente = opcoes.ambiente || {};
    const porId = new Map(fluxo.map((n) => [n.id, n]));
    const capturas = fluxo.filter((n) => n.type === 'catch');
    const depuracao = [];
    const errosDeFuncao = [];
    const respostasDuplicadas = [];
    const pendentes = new Map();
    const compiladas = new Map();
    const contextos = new Map();
    let contador = 0;
    let ativos = 0;

    function clonar(msg) {
        const { req, res, ...resto } = msg;
        const c = JSON.parse(JSON.stringify(resto));
        if (req !== undefined) c.req = req;
        if (res !== undefined) c.res = res;
        return c;
    }
    function enviar(no, saidas) {
        saidas.forEach((m, i) => {
            if (m === null || m === undefined) return;
            (no.wires[i] || []).forEach((destino, k) => entregar(destino, k === 0 ? m : clonar(m)));
        });
    }
    function entregar(id, msg) {
        ativos += 1;
        setImmediate(() => {
            Promise.resolve().then(() => processar(porId.get(id), msg)).finally(() => { ativos -= 1; });
        });
    }
    function falhar(no, e, msg) {
        if (no.type === 'function') errosDeFuncao.push(no.name + ': ' + ((e && e.message) || e));
        const alvos = capturas.filter((c) => c.z === no.z && (!c.scope || c.scope.indexOf(no.id) >= 0));
        alvos.forEach((c) => {
            const m = clonar(msg);
            m.error = { message: String((e && e.message) || e), source: { id: no.id, type: no.type, name: no.name } };
            enviar(c, [m]);
        });
        if (!alvos.length) depuracao.push({ no: 'sem catch', payload: String(e) });
    }
    function processar(no, msg) {
        try {
            switch (no.type) {
                case 'function': return executarFuncao(no, msg);
                case 'cloudantplus in': return cloudantIn(no, msg);
                case 'cloudantplus out': return cloudantOut(no, msg);
                case 'http response': return responder(no, msg);
                case 'debug': depuracao.push({ no: no.name, payload: msg.payload }); return undefined;
                case 'catch': case 'inject': case 'http in': case 'delay': enviar(no, [msg]); return undefined;
                default: throw new Error('tipo de nó não simulado: ' + no.type);
            }
        } catch (e) {
            falhar(no, e, msg);
            return undefined;
        }
    }
    function executarFuncao(no, msg) {
        let fn = compiladas.get(no.id);
        if (!fn) {
            const contexto = vm.createContext({
                console, Date, Math, JSON, Object, Array, String, Number, RegExp, Error, Map, Set, parseInt, Promise,
                Intl: opcoes.semSegmenter ? {} : Intl
            });
            fn = vm.runInContext('(function (msg, node, env, context, flow, global, RED) {\n' + no.func + '\n})', contexto);
            compiladas.set(no.id, fn);
        }
        const api = {
            id: no.id, name: no.name, status() {}, warn() {}, log() {}, done() {},
            error(e) { throw (e instanceof Error ? e : new Error(String(e))); },
            send(m) { enviar(no, Array.isArray(m) ? m : [m]); }
        };
        const memoria = contextos.get(no.id) || new Map();
        contextos.set(no.id, memoria);
        const contexto = { get: (k) => memoria.get(k), set: (k, v) => (v === undefined ? memoria.delete(k) : memoria.set(k, v)) };
        const resultado = fn(msg, api, { get: (k) => ambiente[k] }, contexto, {}, {}, { util: { cloneMessage: clonar } });
        if (resultado === null || resultado === undefined) return;
        // como no Node-RED: [msg1, msg2] = uma mensagem por saída; [[a, b]] = várias mensagens na 1ª saída
        (Array.isArray(resultado) ? resultado : [resultado]).forEach((saida, i) => {
            (Array.isArray(saida) ? saida : [saida]).forEach((m) => {
                if (m === null || m === undefined) return;
                if (!m._msgid) m._msgid = 'n' + (++contador);
                const lista = [];
                lista[i] = m;
                enviar(no, lista);
            });
        });
    }
    function cloudantIn(no, msg) {
        if (no.search !== '_query_') throw new Error('modo de busca não simulado: ' + no.search);
        const opcoes = msg.options && typeof msg.options === 'object' ? msg.options :
            (msg.payload && typeof msg.payload === 'object' ? msg.payload : {});
        return Promise.resolve()
            .then(() => cloudant.find(msg.database || no.database, opcoes))
            .then((r) => enviar(no, [Object.assign({}, msg, { payload: forma === 'lista' ? r.docs : r })]))
            .catch((e) => falhar(no, e, msg));
    }
    function limparChaves(doc) {
        // como o nó: chaves que começam com "_" (fora _id, _rev, _deleted) perdem o "_"
        const limpo = {};
        Object.keys(doc).forEach((k) => {
            limpo[k.charAt(0) === '_' && ['_id', '_rev', '_deleted', '_attachments'].indexOf(k) < 0 ? k.slice(1) : k] = doc[k];
        });
        return limpo;
    }
    function cloudantOut(no, msg) {
        const nome = msg.database || no.database;
        const operacao = msg.operation || no.operation;
        const dados = no.payonly ? msg.payload : msg;
        return Promise.resolve().then(() => {
            if (Array.isArray(dados)) throw new Error('o fluxo não usa gravação em lote (bulk): mande um documento por mensagem');
            if (operacao === 'insert') {
                if (!dados || typeof dados !== 'object') throw new Error('payload inválido para gravar');
                return { status: 201, result: cloudant.gravar(nome, limparChaves(dados)) };
            }
            if (operacao === 'delete') {
                if (Array.isArray(dados)) {
                    dados.forEach((d) => { if (!d._id || !d._rev) throw new Error('_id and _rev are required to delete a document'); });
                    return { status: 201, result: cloudant.lote(nome, dados.map((d) => ({ _id: d._id, _rev: d._rev, _deleted: true }))) };
                }
                if (!dados || !dados._id || !dados._rev) throw new Error('_id and _rev are required to delete a document');
                return { status: 200, result: cloudant.apagar(nome, dados._id, dados._rev) };
            }
            throw new Error('Unknown node operation requested: ' + operacao);
        })
            .then((r) => enviar(no, [Object.assign({}, msg, { payload: r })]))
            .catch((e) => falhar(no, e, msg));
    }
    function responder(no, msg) {
        const chave = msg.res && msg.res._chave;
        const resolver = pendentes.get(chave);
        if (!resolver) { respostasDuplicadas.push(no.name); return; }
        pendentes.delete(chave);
        resolver({ status: msg.statusCode || 200, corpo: JSON.parse(JSON.stringify(msg.payload)), cabecalhos: msg.headers || {} });
    }
    async function calmaria() {
        for (let i = 0; i < 5; i++) {
            while (ativos > 0) await new Promise((r) => setImmediate(r));
            await new Promise((r) => setImmediate(r));
        }
    }

    return {
        cloudant, depuracao, errosDeFuncao, respostasDuplicadas,
        requisitar(metodo, url, extras) {
            extras = extras || {};
            const [caminho, textoConsulta] = url.split('?');
            const consulta = Object.fromEntries(new URLSearchParams(textoConsulta || ''));
            const entrada = fluxo.find((n) => n.type === 'http in' && n.method === metodo.toLowerCase() && n.url === caminho);
            if (!entrada) return Promise.resolve({ status: 404, corpo: 'Cannot ' + metodo + ' ' + caminho, cabecalhos: {} });
            const cabecalhos = {};
            Object.keys(extras.cabecalhos || {}).forEach((k) => { cabecalhos[k.toLowerCase()] = extras.cabecalhos[k]; });
            contador += 1;
            const chave = contador;
            const msg = {
                _msgid: 'm' + chave,
                req: { method: metodo.toUpperCase(), url: url, headers: cabecalhos, query: consulta, body: extras.corpo },
                res: { _chave: chave },
                payload: metodo.toUpperCase() === 'GET' ? consulta : (extras.corpo === undefined ? {} : JSON.parse(JSON.stringify(extras.corpo)))
            };
            return new Promise((resolve, reject) => {
                const limite = setTimeout(() => {
                    pendentes.delete(chave);
                    reject(new Error('a requisição ' + metodo + ' ' + url + ' ficou sem resposta'));
                }, 2000);
                pendentes.set(chave, (r) => { clearTimeout(limite); resolve(r); });
                enviar(entrada, [msg]);
            }).then(async (r) => { await calmaria(); return r; });
        },
        async injetar(topico) {
            const no = fluxo.find((n) => n.type === 'inject' && n.topic === topico);
            assert.ok(no, 'inject ' + topico);
            contador += 1;
            enviar(no, [{ _msgid: 'i' + contador, payload: Date.now(), topic: topico }]);
            await calmaria();
        },
        async implantar() {
            for (const no of fluxo.filter((n) => n.type === 'inject' && n.once)) await this.injetar(no.topic);
        }
    };
}

// ===================================================================== utilidades dos testes
const BANCO = montador.BANCO;
const UUID = /^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/;
const UUID_QUALQUER = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/;
const DATA = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
const MONITOR = '3C657F19-D52A-5F45-AE46-BC31046D13C3';

function novaPublicacao(extra) {
    return Object.assign({
        tipo: 'projeto', titulo: 'Sensor de gás com alerta no celular',
        descricao: 'Protótipo com sensor MQ-2 e ESP32 que avisa no celular quando detecta vazamento de gás.',
        area: 'engenharias', subarea: 'engenharia eletrica', disciplina: 'Sistemas Embarcados', ano: 2026,
        curso: 'Técnico em Eletrônica', autores: ['Ana Clara Machado'], link: 'https://www.linkedin.com/posts/exemplo',
        plataforma: 'linkedin', imagemLink: 'https://example.com/sensor.jpg', instituicao: 'CTISM – UFSM'
    }, extra || {});
}

/** Confere a publicação contra o que o app decodifica (PublicacaoDTO em APIClient.swift). */
function conferirFormatoDoApp(p) {
    assert.match(p.id, UUID_QUALQUER, 'id no formato UUID');
    ['tipo', 'titulo', 'descricao', 'area'].forEach((c) => assert.equal(typeof p[c], 'string', c));
    assert.ok(Number.isInteger(p.ano), 'ano inteiro');
    assert.ok(['projeto', 'trabalho', 'prova', 'material'].indexOf(p.tipo) >= 0);
    assert.ok(Array.isArray(p.autores));
    assert.equal(typeof p.media, 'number');
    assert.ok(Number.isInteger(p.totalAvaliacoes));
    assert.ok(p.minhaNota === null || Number.isInteger(p.minhaNota));
    assert.equal(typeof p.meu, 'boolean');
    assert.match(p.criadoEm, DATA);
    assert.equal(p.usuarioId, undefined, 'o id de quem publicou não sai');
    assert.equal(p._rev, undefined);
    assert.equal(p.colecao, undefined);
}

async function prontoComExemplos(opcoes) {
    const nr = criarNodeRed(opcoes);
    await nr.implantar();
    return nr;
}

async function cadastrar(nr, nome) {
    const r = await nr.requisitar('POST', '/POSTusuario', { corpo: { nome: nome || 'Ana Souza', curso: 'Técnico em Eletrônica' } });
    assert.equal(r.status, 201);
    return r.corpo;
}

// ===================================================================== testes
async function testarEstrutura() {
    console.log('\nEstrutura do fluxo');
    const porId = new Map(fluxo.map((n) => [n.id, n]));
    const aba = fluxo.filter((n) => n.type === 'tab');

    await teste('o arquivo é o que o montar-fluxo.js gera a partir de src/ (rode-o depois de alterar o código)', () => {
        assert.equal(fs.readFileSync(path.join(RAIZ, 'hub-academico-flows.json'), 'utf8'), montador.texto(montador.montar()));
        assert.equal(fs.readFileSync(path.join(RAIZ, 'cloudant-config.json'), 'utf8'), montador.texto([montador.CONFIG]));
    });
    await teste('uma aba; ids únicos de 16 hexadecimais; ligações apontam para nós existentes', () => {
        assert.equal(aba.length, 1);
        assert.equal(new Set(fluxo.map((n) => n.id)).size, fluxo.length);
        fluxo.forEach((n) => {
            assert.match(n.id, /^[0-9a-f]{16}$/);
            if (n.type !== 'tab') assert.equal(n.z, aba[0].id, n.name);
            (n.wires || []).forEach((s) => s.forEach((d) => assert.ok(porId.has(d), n.name + ' → ' + d)));
        });
    });
    await teste('só nós do núcleo e os nós cloudantplus que a equipe já usa', () => {
        const permitidos = ['tab', 'comment', 'http in', 'http response', 'function', 'inject', 'debug', 'catch', 'delay', 'cloudantplus in', 'cloudantplus out'];
        fluxo.forEach((n) => assert.ok(permitidos.indexOf(n.type) >= 0, n.type));
    });
    await teste('nós do Cloudant: banco ' + BANCO + ' e a mesma configuração do fluxo da equipe (5ac37d22a9baf72b)', () => {
        const nos = fluxo.filter((n) => n.type.indexOf('cloudantplus') === 0);
        assert.ok(nos.length > 10);
        nos.forEach((n) => {
            assert.equal(n.cloudant, '5ac37d22a9baf72b');
            assert.equal(n.database, BANCO);
            assert.equal(n.service, '_ext_');
            if (n.type === 'cloudantplus in') assert.equal(n.search, '_query_');
            else { assert.equal(n.payonly, true); assert.ok(['insert', 'delete'].indexOf(n.operation) >= 0); }
        });
        assert.equal(fluxo.find((n) => n.type === 'cloudantplus'), undefined, 'o fluxo não traz a configuração (vem em cloudant-config.json)');
        assert.equal(configCloudant.length, 1);
        assert.equal(configCloudant[0].id, '5ac37d22a9baf72b');
        assert.equal(configCloudant[0].type, 'cloudantplus');
        assert.equal(configCloudant[0].useapikey, true);
        assert.match(configCloudant[0].host, /^https:\/\/.+cloudantnosqldb\.appdomain\.cloud$/);
    });
    await teste('rotas no padrão do fluxo da equipe: GET/POST/UPDATE/DELETE + nome, uma por método', () => {
        const rotas = fluxo.filter((n) => n.type === 'http in').map((n) => n.method.toUpperCase() + ' ' + n.url).sort();
        assert.deepEqual(rotas, [
            'DELETE /DELETEpublicacao', 'GET /GETdisciplinas', 'GET /GETpublicacoes', 'GET /GETstatus', 'GET /GETsubareas', 'GET /GETusuario',
            'POST /POSTavaliacao', 'POST /POSTpublicacao', 'POST /POSTusuario', 'PUT /UPDATEpublicacao', 'PUT /UPDATEusuario'
        ]);
        fluxo.filter((n) => n.type === 'http in').forEach((n) => {
            const prefixo = { get: 'GET', post: 'POST', put: 'UPDATE', delete: 'DELETE' }[n.method];
            assert.ok(n.url.indexOf('/' + prefixo) === 0, n.url);
            assert.ok(n.name.indexOf('[' + n.url.slice(1) + ']') > 0, n.name);
        });
    });
    await teste('toda rota termina em um "http response", por qualquer caminho (nenhuma saída solta)', () => {
        fluxo.filter((n) => n.type === 'http in').forEach((entrada) => {
            const visitados = new Set();
            (function andar(id) {
                const n = porId.get(id);
                if (visitados.has(id)) return;
                visitados.add(id);
                if (n.type === 'http response') return;
                assert.ok(n.wires && n.wires.length, n.name + ' sem saída');
                n.wires.forEach((s, i) => {
                    assert.ok(s.length, entrada.url + ': ' + n.name + ' tem a saída ' + (i + 1) + ' solta');
                    s.forEach(andar);
                });
            })(entrada.id);
        });
    });
    await teste('cada nó function compila e traz só as funções comuns que usa (exemplos fora das rotas da API)', () => {
        const fontes = ['comum.js', 'exemplos.js'].map((a) => fs.readFileSync(path.join(RAIZ, 'src', a), 'utf8')).join('\n');
        const nomes = [...fontes.matchAll(/^(?:const|let|var|function)\s+([A-Za-z_$][\w$]*)/gm)].map((m) => m[1]);
        const declara = (codigo, nome) => new RegExp('^(?:const|let|var|function)\\s+' + nome + '(?![\\w$])', 'm').test(codigo);
        const usa = (codigo, nome) => new RegExp('(?:^|[^\\w$.])' + nome + '(?![\\w$])', 'm').test(codigo);
        let gravaExemplos = 0;
        fluxo.filter((n) => n.type === 'function').forEach((n) => {
            assert.doesNotThrow(() => new Function('msg', 'node', 'context', 'flow', 'global', 'env', 'RED', n.func), n.name);
            nomes.forEach((nome) => {
                const linhas = n.func.split('\n').filter((l) => !/^\s*(?:\/\/|\/\*|\*)/.test(l)).join('\n');
                if (usa(linhas, nome)) assert.ok(declara(n.func, nome), n.name + ' usa ' + nome + ' sem declarar');
            });
            const rota = n.func.slice(n.func.lastIndexOf('// =====')).split('\n')[0];
            const temExemplos = declara(n.func, 'EXEMPLOS');
            if (temExemplos) assert.match(rota, /exemplos|limpar/, n.name + ' (rota da API) não deveria trazer os exemplos');
            if (/exemplos-gravar/.test(rota)) { assert.ok(temExemplos && declara(n.func, 'documentoDeExemplo'), n.name); gravaExemplos++; }
            if (!/exemplos|limpar/.test(rota)) assert.ok(n.func.length < 15000, n.name + ': ' + n.func.length + ' caracteres');
        });
        assert.equal(gravaExemplos, 1);
        const tamanho = Buffer.byteLength(JSON.stringify(fluxo));
        assert.ok(tamanho < 250000, 'fluxo com ' + tamanho + ' bytes (o Cloudant guarda até 1 MB por documento)');
    });
    await teste('8 grandes áreas e 104 subáreas do CNPq em src/comum.js (o mesmo catálogo do app)', async () => {
        const nr = criarNodeRed();
        const r = await nr.requisitar('GET', '/GETsubareas');
        assert.equal(r.status, 200);
        assert.equal(Object.keys(r.corpo).length, 8);
        assert.equal(Object.values(r.corpo).reduce((a, l) => a + l.length, 0), 104);
        assert.ok(r.corpo.engenharias.indexOf('Engenharia de Produção') >= 0);
    });
}

async function testarBancoEExemplos(forma) {
    console.log('\nBanco e exemplos (consulta devolvendo ' + (forma === 'lista' ? 'a lista de documentos' : '{ docs: [...] }') + ')');
    await teste('ao implantar com o banco vazio: testa a conexão e cria as 12 publicações de exemplo', async () => {
        const nr = criarNodeRed({ forma: forma });
        await nr.implantar();
        const docs = nr.cloudant.documentos(BANCO);
        assert.equal(docs.filter((d) => d.colecao === 'publicacao').length, 12);
        assert.ok(docs.every((d) => d.exemplo === true && d.avaliacoesBase && d.avaliacoesBase.total > 0));
        const mensagens = nr.depuracao.map((d) => d.payload).join(' | ');
        assert.match(mensagens, /Cloudant conectado: 0 publicações/);
        assert.match(mensagens, /Publicações de exemplo gravadas no Cloudant: 12 de 12\./);
        assert.deepEqual(nr.errosDeFuncao, []);
    });
    await teste('implantar de novo (Deploy) não duplica nem recria nada', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        await nr.implantar();
        assert.equal(nr.cloudant.documentos(BANCO).length, 12);
        assert.match(nr.depuracao[nr.depuracao.length - 1].payload, /Cloudant conectado: 12 publicações/);
    });
    await teste('"Criar ou restaurar exemplos" atualiza os que existem (com a _rev), sem conflito', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        await nr.injetar('exemplos');
        const docs = nr.cloudant.documentos(BANCO);
        assert.equal(docs.length, 12);
        assert.ok(docs.every((d) => /^2-/.test(d._rev)), 'revisão 2 em todos');
        assert.match(nr.depuracao[nr.depuracao.length - 1].payload, /12 de 12 \(12 já existiam e foram restauradas\)/);
        assert.equal(nr.depuracao.filter((d) => /gravadas no Cloudant/.test(d.payload)).length, 2, 'um aviso por lote, não um por publicação');
    });
    await teste('"Remover exemplos" apaga só os exemplos; banco vazio recebe os exemplos de novo no próximo Deploy', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const u = await cadastrar(nr);
        await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao(), cabecalhos: { 'X-Hub-Usuario': u.id } });
        await nr.injetar('remover');
        assert.match(nr.depuracao[nr.depuracao.length - 1].payload, /removidas: 12/);
        assert.equal(nr.depuracao.filter((d) => /removidas/.test(d.payload)).length, 1);
        const publicacoes = nr.cloudant.documentos(BANCO).filter((d) => d.colecao === 'publicacao');
        assert.equal(publicacoes.length, 1, 'a publicação da turma ficou');
        await nr.injetar('remover');
        assert.match(nr.depuracao[nr.depuracao.length - 1].payload, /Não há publicações de exemplo/);
        await nr.implantar();
        assert.equal(nr.cloudant.documentos(BANCO).filter((d) => d.colecao === 'publicacao').length, 1, 'com publicação da turma, os exemplos não voltam');
    });
    await teste('documentos que não são do app (fluxo antigo: sem "colecao", com "cadeira") ficam de fora', async () => {
        const cloudant = criarCloudant();
        cloudant.colocar(BANCO, { _id: 'a1b2c3', titulo: 'Projeto antigo', area: 'Engenharias', cadeira: 'Física', ano: 2025 });
        cloudant.colocar(BANCO, { _id: 'B5A1C6D2-0000-4000-8000-000000000001', colecao: 'publicacao', titulo: 'Sem tipo', area: 'xyz' });
        const nr = criarNodeRed({ cloudant: cloudant, forma: forma });
        await nr.implantar();
        assert.equal(nr.cloudant.documentos(BANCO).filter((d) => d.exemplo).length, 0, 'já há uma publicação gravada: os exemplos não entram sozinhos');
        await nr.injetar('exemplos');
        const lista = (await nr.requisitar('GET', '/GETpublicacoes')).corpo;
        assert.equal(lista.length, 12);
        lista.forEach(conferirFormatoDoApp);
        const status = (await nr.requisitar('GET', '/GETstatus')).corpo;
        assert.equal(status.totais.publicacoes, 13, 'status conta todas as publicações gravadas');
    });
}

async function testarRotas(forma) {
    console.log('\nRotas (consulta devolvendo ' + (forma === 'lista' ? 'a lista de documentos' : '{ docs: [...] }') + ')');
    const ambiente = { HUB_MODERACAO_TOKEN: 'chave-da-moderacao' };

    await teste('GET /GETstatus responde com os totais', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const r = await nr.requisitar('GET', '/GETstatus');
        assert.equal(r.status, 200);
        assert.equal(r.corpo.ok, true);
        assert.deepEqual(r.corpo.totais, { publicacoes: 12, disciplinas: 10, usuarios: 0, avaliacoes: 0 });
        assert.match(r.cabecalhos['Content-Type'], /application\/json/);
    });
    await teste('GET /GETpublicacoes: 12 exemplos, mais recentes primeiro, médias iguais às do app e formato do app', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const r = await nr.requisitar('GET', '/GETpublicacoes');
        assert.equal(r.status, 200);
        assert.equal(r.corpo.length, 12);
        r.corpo.forEach(conferirFormatoDoApp);
        const datas = r.corpo.map((p) => p.criadoEm);
        assert.deepEqual(datas, datas.slice().sort().reverse());
        const monitor = r.corpo.find((p) => p.id === MONITOR);
        assert.equal(monitor.media, 4.81);
        assert.equal(monitor.totalAvaliacoes, 37);
        assert.equal(monitor.disciplina, 'Higiene Ocupacional');
        assert.equal(monitor.imagemLink, 'asset://imagem-monitor-ruido');
        assert.ok(r.corpo.every((p) => p.meu === false && p.minhaNota === null));
    });
    await teste('filtros: tipo, ano, area, subarea, curso, disciplina (e "cadeira"), titulo, autor, q, ordem=media, limite', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const n = async (q) => (await nr.requisitar('GET', '/GETpublicacoes?' + q)).corpo;
        assert.ok((await n('tipo=prova')).every((p) => p.tipo === 'prova'));
        assert.equal((await n('tipo=prova')).length, 3);
        assert.ok((await n('ano=2025')).every((p) => p.ano === 2025));
        assert.ok((await n('area=saude')).every((p) => p.area === 'saude'));
        assert.equal((await n('subarea=engenharia%20de%20producao')).length, 3);
        assert.equal((await n('disciplina=higiene')).length, 3);
        assert.equal((await n('cadeira=HIGIENE')).length, 3, 'aceita o nome antigo do filtro');
        assert.equal((await n('titulo=ru%C3%ADdo')).length, 2);
        assert.equal((await n('autor=ana%20clara')).length, 1);
        assert.equal((await n('q=ruido%20oficinas')).length, 1);
        const ordenada = await n('ordem=media');
        assert.equal(ordenada[0].media, Math.max.apply(null, ordenada.map((p) => p.media)));
        assert.equal((await n('limite=5')).length, 5);
        assert.ok((await n('curso=T%C3%A9cnico%20em%20Seguran%C3%A7a%20do%20Trabalho')).length >= 3);
    });
    await teste('POST /POSTusuario valida e devolve o id; GET /GETusuario e PUT /UPDATEusuario usam X-Hub-Usuario', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        assert.equal((await nr.requisitar('POST', '/POSTusuario', { corpo: { nome: 'A' } })).status, 400);
        const u = await cadastrar(nr, 'Ana Souza');
        assert.match(u.id, UUID);
        assert.equal(u.nome, 'Ana Souza');
        assert.match(u.criadoEm, DATA);
        assert.equal((await nr.requisitar('GET', '/GETusuario')).status, 401);
        assert.equal((await nr.requisitar('GET', '/GETusuario', { cabecalhos: { 'X-Hub-Usuario': 'nao-existe' } })).status, 401);
        const lido = await nr.requisitar('GET', '/GETusuario', { cabecalhos: { 'X-Hub-Usuario': u.id.toLowerCase() } });
        assert.equal(lido.status, 200);
        assert.equal(lido.corpo.nome, 'Ana Souza');
        const novo = await nr.requisitar('PUT', '/UPDATEusuario', { corpo: { nome: 'Ana S. Souza', curso: 'Técnico em Mecânica' }, cabecalhos: { 'X-Hub-Usuario': u.id } });
        assert.equal(novo.status, 200);
        assert.equal(novo.corpo.nome, 'Ana S. Souza');
        assert.equal((await nr.requisitar('PUT', '/UPDATEusuario', { corpo: { nome: '' }, cabecalhos: { 'X-Hub-Usuario': u.id } })).status, 400);
        assert.equal((await nr.requisitar('PUT', '/UPDATEusuario', { corpo: { nome: 'Fulano' }, cabecalhos: { 'X-Hub-Usuario': 'B5A1C6D2-0000-4000-8000-000000000009' } })).status, 401);
        assert.equal((await nr.requisitar('GET', '/GETstatus')).corpo.totais.usuarios, 1);
    });
    await teste('POST /POSTpublicacao: exige usuário cadastrado, valida os campos e grava com a grafia oficial da subárea', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        assert.equal((await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao() })).status, 401);
        const desconhecido = await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao(), cabecalhos: { 'X-Hub-Usuario': 'B5A1C6D2-0000-4000-8000-000000000009' } });
        assert.equal(desconhecido.status, 401);
        assert.match(desconhecido.corpo.detalhes[0], /POST \/POSTusuario/);
        const u = await cadastrar(nr);
        const h = { 'X-Hub-Usuario': u.id };
        const ruim = await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao({ tipo: 'x', titulo: 'oi', area: 'saude', ano: 1800, link: 'nada' }), cabecalhos: h });
        assert.equal(ruim.status, 400);
        assert.equal(ruim.corpo.erro, 'Dados inválidos');
        ['tipo:', 'titulo:', 'subarea:', 'ano:', 'link:'].forEach((c) => assert.ok(ruim.corpo.detalhes.some((d) => d.indexOf(c) === 0), c));
        const ok = await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao(), cabecalhos: h });
        assert.equal(ok.status, 201);
        conferirFormatoDoApp(ok.corpo);
        assert.equal(ok.corpo.meu, true);
        assert.equal(ok.corpo.media, 0);
        assert.equal(ok.corpo.totalAvaliacoes, 0);
        assert.equal(ok.corpo.subarea, 'Engenharia Elétrica');
        const gravado = nr.cloudant.documentos(BANCO).find((d) => d._id === ok.corpo.id);
        assert.equal(gravado.colecao, 'publicacao');
        assert.equal(gravado.usuarioId, u.id);
        const lista = (await nr.requisitar('GET', '/GETpublicacoes', { cabecalhos: h })).corpo;
        assert.equal(lista.length, 13);
        assert.equal(lista[0].id, ok.corpo.id, 'a mais nova vem primeiro');
        assert.deepEqual(lista.filter((p) => p.meu).map((p) => p.id), [ok.corpo.id]);
        const outra = (await nr.requisitar('GET', '/GETpublicacoes', { cabecalhos: { 'X-Hub-Usuario': 'B5A1C6D2-0000-4000-8000-000000000009' } })).corpo;
        assert.ok(outra.every((p) => p.meu === false));
    });
    await teste('limites contam caracteres como o Swift (emoji composto = 1), também sem Intl.Segmenter', async () => {
        for (const semSegmenter of [false, true]) {
            const nr = await prontoComExemplos({ forma: forma, semSegmenter: semSegmenter });
            const u = await cadastrar(nr);
            const descricao = '👍🏽'.repeat(20) + 'x'.repeat(180);
            const r = await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao({ descricao: descricao }), cabecalhos: { 'X-Hub-Usuario': u.id } });
            assert.equal(r.status, semSegmenter ? 400 : 201);
        }
    });
    await teste('POST /POSTavaliacao: uma avaliação por pessoa; avaliar de novo troca a nota; média soma os exemplos', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const u = await cadastrar(nr);
        const h = { 'X-Hub-Usuario': u.id };
        assert.equal((await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: MONITOR, nota: 5 } })).status, 401);
        assert.equal((await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: MONITOR, nota: 7 }, cabecalhos: h })).status, 400);
        assert.equal((await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: 'B5A1C6D2-0000-4000-8000-000000000009', nota: 4 }, cabecalhos: h })).status, 404);
        const primeira = await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: MONITOR.toLowerCase(), nota: 1 }, cabecalhos: h });
        assert.equal(primeira.status, 200);
        assert.deepEqual(primeira.corpo, { publicacaoId: MONITOR, media: Math.round((178 + 1) / 38 * 100) / 100, totalAvaliacoes: 38, minhaNota: 1 });
        const segunda = await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: MONITOR, nota: 5 }, cabecalhos: h });
        assert.equal(segunda.corpo.totalAvaliacoes, 38, 'trocar a nota não soma outra avaliação');
        assert.equal(segunda.corpo.minhaNota, 5);
        assert.equal(segunda.corpo.media, Math.round((178 + 5) / 38 * 100) / 100);
        const avaliacoes = nr.cloudant.documentos(BANCO).filter((d) => d.colecao === 'avaliacao');
        assert.equal(avaliacoes.length, 1);
        assert.equal(avaliacoes[0]._id, 'avaliacao:' + MONITOR + ':' + u.id);
        const lista = (await nr.requisitar('GET', '/GETpublicacoes', { cabecalhos: h })).corpo;
        const monitor = lista.find((p) => p.id === MONITOR);
        assert.equal(monitor.minhaNota, 5);
        assert.equal(monitor.totalAvaliacoes, 38);
        const v2 = await cadastrar(nr, 'Bruno Lima');
        const outra = await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: MONITOR, nota: 3 }, cabecalhos: { 'X-Hub-Usuario': v2.id } });
        assert.equal(outra.corpo.totalAvaliacoes, 39);
        assert.equal((await nr.requisitar('GET', '/GETstatus')).corpo.totais.avaliacoes, 2);
    });
    await teste('PUT /UPDATEpublicacao: só quem publicou (ou a moderação), validando os campos', async () => {
        const nr = await prontoComExemplos({ forma: forma, ambiente: ambiente });
        const autor = await cadastrar(nr, 'Autora');
        const outro = await cadastrar(nr, 'Outro');
        const p = (await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao(), cabecalhos: { 'X-Hub-Usuario': autor.id } })).corpo;
        assert.equal((await nr.requisitar('PUT', '/UPDATEpublicacao', { corpo: { titulo: 'Título novo do sensor' } })).status, 400, 'sem id');
        assert.equal((await nr.requisitar('PUT', '/UPDATEpublicacao?id=' + p.id, { corpo: { titulo: 'Título novo do sensor' } })).status, 401);
        assert.equal((await nr.requisitar('PUT', '/UPDATEpublicacao?id=' + p.id, { corpo: { titulo: 'Título novo do sensor' }, cabecalhos: { 'X-Hub-Usuario': outro.id } })).status, 403);
        assert.equal((await nr.requisitar('PUT', '/UPDATEpublicacao?id=' + p.id, { corpo: { titulo: 'x' }, cabecalhos: { 'X-Hub-Usuario': autor.id } })).status, 400);
        assert.equal((await nr.requisitar('PUT', '/UPDATEpublicacao?id=B5A1C6D2-0000-4000-8000-000000000009', { corpo: {}, cabecalhos: { 'X-Hub-Usuario': autor.id } })).status, 404);
        const ok = await nr.requisitar('PUT', '/UPDATEpublicacao?id=' + p.id, { corpo: { titulo: 'Título novo do sensor' }, cabecalhos: { 'X-Hub-Usuario': autor.id } });
        assert.equal(ok.status, 200);
        assert.equal(ok.corpo.titulo, 'Título novo do sensor');
        assert.equal(ok.corpo.descricao, p.descricao, 'o resto continua igual');
        assert.equal(ok.corpo.meu, true);
        const moderacao = await nr.requisitar('PUT', '/UPDATEpublicacao?id=' + p.id, { corpo: { ano: 2025 }, cabecalhos: { 'X-Hub-Moderacao': 'chave-da-moderacao' } });
        assert.equal(moderacao.status, 200);
        assert.equal(moderacao.corpo.ano, 2025);
        const gravado = nr.cloudant.documentos(BANCO).find((d) => d._id === p.id);
        assert.equal(gravado.usuarioId, autor.id, 'a autoria não muda');
        assert.match(gravado.atualizadoEm, DATA);
    });
    await teste('DELETE /DELETEpublicacao: quem publicou ou a moderação; as avaliações dela deixam de contar', async () => {
        const nr = await prontoComExemplos({ forma: forma, ambiente: ambiente });
        const autor = await cadastrar(nr, 'Autora');
        const outro = await cadastrar(nr, 'Outro');
        const p = (await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao(), cabecalhos: { 'X-Hub-Usuario': autor.id } })).corpo;
        await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: p.id, nota: 4 }, cabecalhos: { 'X-Hub-Usuario': outro.id } });
        assert.equal((await nr.requisitar('DELETE', '/DELETEpublicacao')).status, 400);
        assert.equal((await nr.requisitar('DELETE', '/DELETEpublicacao?id=' + p.id)).status, 401);
        assert.equal((await nr.requisitar('DELETE', '/DELETEpublicacao?id=' + p.id, { cabecalhos: { 'X-Hub-Usuario': outro.id } })).status, 403);
        assert.equal((await nr.requisitar('DELETE', '/DELETEpublicacao?id=' + p.id, { cabecalhos: { 'X-Hub-Moderacao': 'errada' } })).status, 401);
        const ok = await nr.requisitar('DELETE', '/DELETEpublicacao?id=' + p.id.toLowerCase(), { cabecalhos: { 'X-Hub-Usuario': autor.id } });
        assert.deepEqual(ok.corpo, { ok: true, id: p.id });
        assert.equal((await nr.requisitar('DELETE', '/DELETEpublicacao?id=' + p.id, { cabecalhos: { 'X-Hub-Usuario': autor.id } })).status, 404);
        assert.equal((await nr.requisitar('GET', '/GETpublicacoes')).corpo.length, 12);
        assert.equal((await nr.requisitar('GET', '/GETstatus')).corpo.totais.avaliacoes, 0);
        const exemplo = await nr.requisitar('DELETE', '/DELETEpublicacao?id=' + MONITOR, { cabecalhos: { 'X-Hub-Moderacao': 'chave-da-moderacao' } });
        assert.equal(exemplo.status, 200);
        assert.equal((await nr.requisitar('GET', '/GETpublicacoes')).corpo.length, 11);
        const semChave = criarNodeRed({ forma: forma, cloudant: nr.cloudant });
        assert.equal((await semChave.requisitar('DELETE', '/DELETEpublicacao?id=' + (await semChave.requisitar('GET', '/GETpublicacoes')).corpo[0].id, { cabecalhos: { 'X-Hub-Moderacao': '' } })).status, 401, 'sem HUB_MODERACAO_TOKEN, nenhuma chave vale');
    });
    await teste('GET /GETdisciplinas: em ordem alfabética, com o total de publicações de cada uma', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const r = await nr.requisitar('GET', '/GETdisciplinas');
        assert.equal(r.status, 200);
        assert.equal(r.corpo.length, 10);
        const nomes = r.corpo.map((d) => d.nome);
        assert.deepEqual(nomes, nomes.slice().sort((a, b) => a.localeCompare(b, 'pt-BR')));
        assert.equal(r.corpo.find((d) => d.nome === 'Higiene Ocupacional').totalPublicacoes, 3);
    });
    await teste('erros do Cloudant voltam ao app como JSON (nenhuma requisição fica sem resposta)', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const u = await cadastrar(nr);
        const casos = [
            ['Unauthorized: invalid API key', 502, /API key/],
            ['Too Many Requests (429)', 503, /espera/],
            ['getaddrinfo ENOTFOUND cloudant', 502, /internet/],
            ['Conflict: Document update conflict. (409)', 409, /ao mesmo tempo/]
        ];
        for (const [mensagem, status, aviso] of casos) {
            nr.cloudant.falha = new Error(mensagem);
            const r = await nr.requisitar('GET', '/GETpublicacoes');
            assert.equal(r.status, status, mensagem);
            assert.match(r.corpo.erro, aviso);
            assert.equal(r.corpo.detalhes[0], mensagem);
            const p = await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao(), cabecalhos: { 'X-Hub-Usuario': u.id } });
            assert.equal(p.status, status);
        }
        nr.cloudant.falha = null;
        assert.equal((await nr.requisitar('GET', '/GETpublicacoes')).status, 200);
        assert.deepEqual(nr.errosDeFuncao, []);
        assert.deepEqual(nr.respostasDuplicadas, []);
    });
    await teste('falha ao implantar sem Cloudant aparece na depuração (e não trava nada)', async () => {
        const cloudant = criarCloudant();
        cloudant.falha = new Error('Unauthorized: invalid API key');
        const nr = criarNodeRed({ cloudant: cloudant, forma: forma });
        await nr.implantar();
        assert.ok(nr.depuracao.some((d) => d.no === 'Erros' && /API key/.test(d.payload)));
    });
    await teste('a nota acabada de gravar entra na média mesmo se a consulta ainda não a enxergar', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const u = await cadastrar(nr);
        const find = nr.cloudant.find.bind(nr.cloudant);
        nr.cloudant.find = function (nome, opcoes) {
            const r = find(nome, opcoes);
            if (opcoes.selector.publicacaoId) r.docs = []; // consulta ainda sem a avaliação nova
            return r;
        };
        const r = await nr.requisitar('POST', '/POSTavaliacao', { corpo: { publicacaoId: MONITOR, nota: 2 }, cabecalhos: { 'X-Hub-Usuario': u.id } });
        assert.equal(r.corpo.totalAvaliacoes, 38);
        assert.equal(r.corpo.minhaNota, 2);
    });
    await teste('consultas sempre com limite (o Cloudant devolve só 25 sem ele) e sem "sort" (exigiria índice)', async () => {
        const nr = await prontoComExemplos({ forma: forma });
        const u = await cadastrar(nr);
        for (let i = 0; i < 30; i++) {
            await nr.requisitar('POST', '/POSTpublicacao', { corpo: novaPublicacao({ titulo: 'Publicação de teste número ' + i }), cabecalhos: { 'X-Hub-Usuario': u.id } });
        }
        assert.equal((await nr.requisitar('GET', '/GETpublicacoes')).corpo.length, 42);
        assert.equal((await nr.requisitar('GET', '/GETstatus')).corpo.totais.publicacoes, 42);
    });
    await teste('rota inexistente dá 404 (como no Node-RED)', async () => {
        const nr = criarNodeRed({ forma: forma });
        assert.equal((await nr.requisitar('GET', '/hub/publicacoes')).status, 404);
    });
}

(async function () {
    console.log('Hub Acadêmico · testes do fluxo Node-RED com Cloudant (hub-academico-flows.json)');
    await testarEstrutura();
    for (const forma of ['docs', 'lista']) {
        await testarBancoEExemplos(forma);
        await testarRotas(forma);
    }
    console.log('\n' + aprovados + ' testes aprovados, ' + falhas.length + ' com falha.');
    process.exit(falhas.length ? 1 : 0);
})();
