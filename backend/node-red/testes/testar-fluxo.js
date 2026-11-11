#!/usr/bin/env node
// =====================================================================
// Testes do fluxo hub-academico-flows.json sem precisar do Node-RED instalado.
//
// Lê o fluxo exportado, confere a estrutura (ids, ligações, rotas) e
// executa o código dos nós "function" como o Node-RED executa (vm),
// simulando o contexto global, as variáveis de ambiente e as requisições
// HTTP que chegam pelos nós "http in".
//
// Uso:  node backend/node-red/testes/testar-fluxo.js
// =====================================================================
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const ARQUIVO = path.join(__dirname, '..', 'hub-academico-flows.json');
const fluxo = JSON.parse(fs.readFileSync(ARQUIVO, 'utf8'));

let aprovados = 0;
const falhas = [];

async function teste(nome, corpo) {
    try {
        await corpo();
        aprovados++;
        console.log('  ✓ ' + nome);
    } catch (erro) {
        falhas.push(nome);
        console.log('  ✗ ' + nome + '\n      ' + String(erro && erro.stack ? erro.stack : erro).split('\n').slice(0, 6).join('\n      '));
    }
}

// ---------------------------------------------------------------------
// Estrutura do fluxo
// ---------------------------------------------------------------------
const TIPOS_DO_NUCLEO = new Set(['tab', 'comment', 'http in', 'http response', 'function', 'inject', 'debug']);
const porId = new Map(fluxo.map(function (n) { return [n.id, n]; }));
const aba = fluxo.find(function (n) { return n.type === 'tab'; });
const httpIns = fluxo.filter(function (n) { return n.type === 'http in'; });
const funcaoApi = fluxo.find(function (n) { return n.type === 'function' && n.name === 'API'; });
const funcaoSeed = fluxo.find(function (n) { return n.type === 'function' && n.name === 'Dados de exemplo'; });

async function testarEstrutura() {
    console.log('\nEstrutura do fluxo');

    await teste('é uma lista de nós com uma única aba', function () {
        assert.ok(Array.isArray(fluxo));
        assert.equal(fluxo.filter(function (n) { return n.type === 'tab'; }).length, 1);
    });

    await teste('ids únicos, no formato do Node-RED (16 hexadecimais)', function () {
        assert.equal(porId.size, fluxo.length);
        fluxo.forEach(function (n) { assert.match(n.id, /^[0-9a-f]{16}$/, n.id); });
    });

    await teste('só usa nós do núcleo (nada para instalar na paleta)', function () {
        fluxo.forEach(function (n) { assert.ok(TIPOS_DO_NUCLEO.has(n.type), n.type); });
    });

    await teste('todos os nós ficam na aba e todas as ligações apontam para nós existentes', function () {
        fluxo.filter(function (n) { return n.type !== 'tab'; }).forEach(function (n) {
            assert.equal(n.z, aba.id, n.id);
            assert.ok(Array.isArray(n.wires), n.id);
            n.wires.forEach(function (saida) {
                saida.forEach(function (destino) { assert.ok(porId.has(destino), n.id + ' → ' + destino); });
            });
            assert.equal(typeof n.x, 'number');
            assert.equal(typeof n.y, 'number');
        });
    });

    await teste('cada "http in" vai para a API, e a API vai para o "http response"', function () {
        assert.ok(funcaoApi, 'nó API');
        assert.ok(httpIns.length > 0);
        httpIns.forEach(function (n) {
            assert.deepEqual(n.wires, [[funcaoApi.id]], n.url);
            assert.match(n.url, /^\/hub\//);
            assert.ok(['get', 'post', 'put', 'delete'].includes(n.method), n.method);
        });
        assert.equal(funcaoApi.outputs, 1);
        assert.equal(funcaoApi.wires.length, 1);
        assert.equal(porId.get(funcaoApi.wires[0][0]).type, 'http response');
    });

    await teste('não há rota repetida, e cada rota tem um "case" na API (e vice-versa)', function () {
        const rotas = httpIns.map(function (n) { return n.method.toUpperCase() + ' ' + n.url; });
        assert.equal(new Set(rotas).size, rotas.length);
        const casos = Array.from(funcaoApi.func.matchAll(/case '([A-Z]+ \/hub\/[^']*)'/g), function (m) { return m[1]; });
        assert.deepEqual(rotas.slice().sort(), casos.slice().sort());
    });

    await teste('o código embutido no fluxo é o mesmo de src/api.js e src/seed.js', function () {
        assert.equal(funcaoApi.func, fs.readFileSync(path.join(__dirname, '..', 'src', 'api.js'), 'utf8'));
        assert.equal(funcaoSeed.func, fs.readFileSync(path.join(__dirname, '..', 'src', 'seed.js'), 'utf8'));
    });

    await teste('injeções de iniciar/restaurar/limpar ligadas aos dados de exemplo', function () {
        const injecoes = fluxo.filter(function (n) { return n.type === 'inject'; });
        assert.deepEqual(injecoes.map(function (n) { return n.topic; }).sort(), ['iniciar', 'limpar-exemplos', 'restaurar']);
        injecoes.forEach(function (n) { assert.deepEqual(n.wires, [[funcaoSeed.id]]); });
        assert.equal(injecoes.find(function (n) { return n.topic === 'iniciar'; }).once, true);
        assert.ok(injecoes.filter(function (n) { return n.topic !== 'iniciar'; }).every(function (n) { return n.once === false; }));
    });
}

// ---------------------------------------------------------------------
// Simulação do Node-RED
// ---------------------------------------------------------------------
/**
 * Contexto global que guarda tudo como JSON, igual ao "localfilesystem":
 * cada get devolve uma cópia, então esquecer um global.set() faz o teste falhar.
 */
function criarArmazenamento(inicial) {
    const dados = Object.assign({}, inicial || {});
    return {
        dados: dados,
        get: function (chave) { return chave in dados ? JSON.parse(dados[chave]) : undefined; },
        set: function (chave, valor) { dados[chave] = JSON.stringify(valor); },
        keys: function () { return Object.keys(dados); }
    };
}

function criarNodeRed(opcoes) {
    opcoes = opcoes || {};
    const armazenamento = opcoes.armazenamento || criarArmazenamento();
    const ambiente = opcoes.ambiente || {};
    const registros = { erros: [], avisos: [], status: null };
    const contexto = vm.createContext({ console: console });
    if (opcoes.semSegmenter) vm.runInContext('Intl.Segmenter = undefined;', contexto);

    function compilar(no) {
        const codigo = '(async function (msg, global, env, node, flow, context) {\n' + no.func + '\n})';
        return vm.runInContext(codigo, contexto, { filename: no.name + '.js' });
    }

    const api = compilar(funcaoApi);
    const seed = compilar(funcaoSeed);
    const global = opcoes.globalFalho || armazenamento;
    const env = { get: function (k) { return ambiente[k]; } };
    const node = {
        error: function (m) { registros.erros.push(m); },
        warn: function (m) { registros.avisos.push(m); },
        log: function () {},
        status: function (s) { registros.status = s; }
    };

    function casar(modelo, caminho) {
        const nomes = [];
        const regex = new RegExp('^' + modelo.replace(/:(\w+)/g, function (_, nome) {
            nomes.push(nome);
            return '([^/]+)';
        }) + '/?$', 'i');
        const m = regex.exec(caminho);
        if (!m) return null;
        const params = {};
        nomes.forEach(function (nome, i) { params[nome] = decodeURIComponent(m[i + 1]); });
        return params;
    }

    async function requisitar(metodo, url, extra) {
        extra = extra || {};
        const partes = url.split('?');
        const caminho = partes[0];
        const query = Object.fromEntries(new URLSearchParams(partes[1] || ''));
        let alvo = null;
        let params = null;
        for (const n of httpIns) {
            if (n.method.toUpperCase() !== metodo) continue;
            params = casar(n.url, caminho);
            if (params) { alvo = n; break; }
        }
        if (!alvo) return { status: 404, corpo: 'Cannot ' + metodo + ' ' + caminho, semRota: true };

        const headers = {};
        Object.keys(extra.cabecalhos || {}).forEach(function (k) { headers[k.toLowerCase()] = extra.cabecalhos[k]; });
        const req = { method: metodo, url: url, route: { path: alvo.url }, params: params, query: query, headers: headers };
        // O nó "http in" põe a query no payload do GET e o corpo JSON nos demais métodos.
        const payload = metodo === 'GET' ? query : JSON.parse(JSON.stringify(extra.corpo === undefined ? {} : extra.corpo));
        const msg = { _msgid: 'teste', req: req, res: {}, payload: payload };

        const saida = await api(msg, global, env, node, {}, {});
        assert.ok(saida && saida.req === req, 'a função deve devolver o próprio msg');
        assert.equal(typeof saida.payload, 'object', 'resposta deve ser JSON');
        // Como o nó "http response": status do msg (ou 200) e o objeto serializado em JSON.
        return {
            status: parseInt(saida.statusCode, 10) || 200,
            headers: saida.headers,
            corpo: JSON.parse(JSON.stringify(saida.payload))
        };
    }

    async function injetar(topico) {
        const saida = await seed({ _msgid: 'inject', topic: topico, payload: Date.now() }, global, env, node, {}, {});
        return saida.payload;
    }

    function banco() { return armazenamento.get('hub_db'); }

    return { requisitar: requisitar, injetar: injetar, banco: banco, armazenamento: armazenamento, registros: registros };
}

const UUID = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/;
const UUID_QUALQUER = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/;
const DATA = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;

function novoProjeto(extra) {
    return Object.assign({
        tipo: 'projeto',
        titulo: 'Sensor de gás com alerta no celular',
        descricao: 'Protótipo com sensor MQ-2 e ESP32 que avisa no celular quando detecta vazamento de gás na cozinha do laboratório.',
        imagemURL: 'https://example.com/hub/gas.jpg',
        link: 'https://www.linkedin.com/posts/exemplo-hub',
        plataforma: 'linkedin',
        area: 'engenharias',
        subarea: 'engenharia de producao',
        cadeira: 'higiene ocupacional',
        instituicao: 'CTISM – UFSM',
        curso: 'Técnico em Segurança do Trabalho',
        ano: new Date().getFullYear(),
        autores: ['Maria Souza']
    }, extra || {});
}

// ---------------------------------------------------------------------
// Cenários
// ---------------------------------------------------------------------
async function testarBancoEExemplos() {
    console.log('\nBanco e dados de exemplo');
    const nr = criarNodeRed({ ambiente: { HUB_ADMIN_TOKEN: 'chave-teste' } });

    await teste('"iniciar" cria as 4 tabelas com os exemplos', async function () {
        const texto = await nr.injetar('iniciar');
        const db = nr.banco();
        assert.match(texto, /Banco do Hub Acadêmico criado/);
        assert.deepEqual(Object.keys(db).filter(function (k) { return typeof db[k] === 'object'; }).sort(),
            ['avaliacoes', 'cadeiras', 'projetos', 'users']);
        assert.equal(Object.keys(db.projetos).length, 12);
        assert.equal(Object.keys(db.cadeiras).length, 10);
        assert.equal(Object.keys(db.users).length, 0);
        assert.equal(Object.keys(db.avaliacoes).length, 232);
        Object.values(db.projetos).forEach(function (p) {
            assert.match(p.id, UUID_QUALQUER);
            assert.ok(db.cadeiras[p.cadeiraId], 'cadeira do projeto ' + p.titulo);
            assert.match(p.criadoEm, DATA);
        });
    });

    await teste('banco da 1ª versão (chave "ctia_db", sem subárea) passa para "hub_db" e continua respondendo', async function () {
        const base = criarNodeRed();
        await base.injetar('iniciar');
        const antigo = base.banco();
        Object.values(antigo.projetos).forEach(function (p) { delete p.subarea; });
        const migrado = criarNodeRed({ armazenamento: criarArmazenamento({ ctia_db: JSON.stringify(antigo) }) });
        const texto = await migrado.injetar('iniciar');
        assert.match(texto, /carregado/);
        assert.deepEqual(migrado.banco(), antigo);
        const lista = (await migrado.requisitar('GET', '/hub/projetos')).corpo;
        assert.equal(lista.length, 12);
        assert.ok(lista.every(function (p) { return p.subarea === null; }), 'publicações antigas vêm com subarea: null');
    });

    await teste('"iniciar" de novo (novo deploy) não duplica nem apaga nada', async function () {
        const antes = nr.armazenamento.dados.hub_db;
        const texto = await nr.injetar('iniciar');
        assert.match(texto, /carregado/);
        assert.equal(nr.armazenamento.dados.hub_db, antes);
    });

    await teste('médias dos exemplos ficam perto das do app', async function () {
        const r = await nr.requisitar('GET', '/hub/projetos');
        const monitor = r.corpo.find(function (p) { return p.titulo.startsWith('Monitor IoT'); });
        assert.equal(monitor.quant, 37);
        assert.ok(Math.abs(monitor.nota - 4.8) < 0.05, String(monitor.nota));
        const redes = r.corpo.find(function (p) { return p.titulo.startsWith('Prova de Redes'); });
        assert.equal(redes.quant, 8);
        assert.ok(Math.abs(redes.nota - 4.1) < 0.1, String(redes.nota));
    });

    await teste('"restaurar" recria os exemplos e mantém os usuários', async function () {
        const u = await nr.requisitar('POST', '/hub/users', { corpo: { nome: 'Joana Lima', curso: '' } });
        const h = { 'X-Hub-User': u.corpo.id };
        const p = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ cadeira: 'Robótica' }), cabecalhos: h });
        assert.equal(p.status, 201);
        await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: p.corpo.id, nota: 5 }, cabecalhos: h });
        assert.equal(Object.keys(nr.banco().projetos).length, 13);

        const texto = await nr.injetar('restaurar');
        const db = nr.banco();
        assert.match(texto, /Exemplos restaurados/);
        assert.equal(Object.keys(db.projetos).length, 12);
        assert.equal(Object.keys(db.cadeiras).length, 10);
        assert.equal(Object.keys(db.avaliacoes).length, 232);
        assert.ok(db.users[u.corpo.id], 'usuário mantido');
    });

    await teste('"limpar-exemplos" tira só os exemplos e não volta no próximo deploy', async function () {
        const u = await nr.requisitar('POST', '/hub/users', { corpo: { nome: 'Caio Rocha' } });
        const h = { 'X-Hub-User': u.corpo.id };
        const p = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ cadeira: 'Robótica Educacional' }), cabecalhos: h });
        const exemplo = Object.values(nr.banco().projetos).find(function (x) { return x.exemplo; });
        await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: exemplo.id, nota: 3 }, cabecalhos: h });
        await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: p.corpo.id, nota: 4 }, cabecalhos: h });

        const extra = await nr.requisitar('POST', '/hub/cadeiras', { corpo: { nome: 'Química Geral' }, cabecalhos: { 'X-Hub-Admin': 'chave-teste' } });
        assert.equal(extra.status, 201);

        await nr.injetar('limpar-exemplos');
        let db = nr.banco();
        assert.deepEqual(Object.keys(db.projetos), [p.corpo.id]);
        assert.deepEqual(Object.values(db.avaliacoes).map(function (a) { return a.projetoId; }), [p.corpo.id]);
        assert.deepEqual(Object.values(db.cadeiras).map(function (c) { return c.nome; }).sort(),
            ['Química Geral', 'Robótica Educacional'], 'cadeiras da turma e da moderação ficam');

        await nr.injetar('iniciar');
        db = nr.banco();
        assert.equal(Object.keys(db.projetos).length, 1, 'exemplos não podem voltar sozinhos');
    });
}

async function testarApi() {
    console.log('\nAPI REST');
    const nr = criarNodeRed({ ambiente: { HUB_ADMIN_TOKEN: 'segredo-moderacao' } });
    await nr.injetar('iniciar');
    let usuario;
    let outro;
    let criado;

    await teste('GET /hub/status responde com os totais', async function () {
        const r = await nr.requisitar('GET', '/hub/status');
        assert.equal(r.status, 200);
        assert.equal(r.corpo.ok, true);
        assert.deepEqual(r.corpo.totais, { projetos: 12, cadeiras: 10, users: 0, avaliacoes: 232 });
        assert.match(r.corpo.horario, DATA);
        assert.equal(r.headers['Content-Type'], 'application/json; charset=utf-8');
        assert.equal(r.headers['Cache-Control'], 'no-store');
    });

    await teste('GET /hub/projetos lista do mais recente para o mais antigo, sem expor ids de usuários', async function () {
        const r = await nr.requisitar('GET', '/hub/projetos');
        assert.equal(r.status, 200);
        assert.equal(r.corpo.length, 12);
        const datas = r.corpo.map(function (p) { return p.criadoEm; });
        assert.deepEqual(datas, datas.slice().sort().reverse());
        r.corpo.forEach(function (p) {
            assert.deepEqual(Object.keys(p).sort(), ['ano', 'area', 'autores', 'cadeira', 'cadeiraId', 'criadoEm', 'curso',
                'descricao', 'id', 'imagemURL', 'instituicao', 'link', 'meu', 'minhaNota', 'nota', 'plataforma', 'quant',
                'subarea', 'tipo', 'titulo'].sort());
            assert.equal(p.meu, false);
            assert.equal(p.minhaNota, null);
            assert.ok(p.cadeira.length > 0);
            assert.ok(p.subarea, 'exemplo com subárea: ' + p.titulo);
        });
    });

    await teste('GET /hub/subareas devolve as 8 áreas e as 104 subáreas da tabela do CNPq', async function () {
        const r = await nr.requisitar('GET', '/hub/subareas');
        assert.equal(r.status, 200);
        assert.deepEqual(Object.keys(r.corpo).sort(), ['agrarias', 'biologicas', 'engenharias', 'exatas', 'humanas',
            'linguisticaLetrasArtes', 'saude', 'sociaisAplicadas']);
        const todas = [].concat.apply([], Object.values(r.corpo));
        assert.equal(todas.length, 104);
        assert.equal(new Set(todas).size, 104, 'nomes únicos');
        assert.ok(r.corpo.engenharias.includes('Engenharia de Produção'));
        assert.ok(r.corpo.agrarias.includes('Agronomia/Ciência do Solo'));
        assert.ok(r.corpo.saude.includes('Medicina/Medicina Legal e Deontologia'));
    });

    await teste('filtros: tipo, ano, área, curso, cadeira, autor, q (sem acento), ordem e limite', async function () {
        const n = async function (q) { return (await nr.requisitar('GET', '/hub/projetos?' + q)).corpo; };
        assert.equal((await n('tipo=prova')).length, 3);
        assert.ok((await n('ano=2025')).every(function (p) { return p.ano === 2025; }));
        assert.equal((await n('area=saude')).length, 2);
        assert.equal((await n('curso=' + encodeURIComponent('Técnico em Segurança do Trabalho'))).length, 5);
        assert.equal((await n('cadeira=higiene')).length, 3);
        assert.equal((await n('subarea=engenharia%20de%20producao')).length, 3);
        assert.ok((await n('subarea=' + encodeURIComponent('Saúde Coletiva'))).every(function (p) { return p.area === 'saude'; }));
        assert.deepEqual((await n('autor=ana%20clara')).map(function (p) { return p.titulo; }), ['Monitor IoT de ruído nas oficinas do CTISM']);
        const ruido = await n('q=RUIDO');
        assert.deepEqual(ruido.map(function (p) { return p.titulo; }).sort(),
            ['Dosimetria de ruído na oficina de soldagem', 'Monitor IoT de ruído nas oficinas do CTISM']);
        assert.equal((await n('q=ruido%20soldagem')).length, 1);
        const porNota = await n('ordem=nota');
        assert.ok(porNota[0].nota >= porNota[1].nota && porNota[1].nota >= porNota[11].nota);
        assert.equal(porNota[0].titulo, 'Braço robótico didático impresso em 3D');
        assert.equal((await n('limite=2')).length, 2);
        assert.equal((await n('tipo=inexistente')).length, 0);
    });

    await teste('POST /hub/users valida e devolve um id no formato UUID', async function () {
        let r = await nr.requisitar('POST', '/hub/users', { corpo: { nome: ' A ' } });
        assert.equal(r.status, 400);
        assert.deepEqual(r.corpo.detalhes, ['nome: de 2 a 80 caracteres']);
        r = await nr.requisitar('POST', '/hub/users', { corpo: { nome: '  Laura Dias ', curso: 'Técnico em Eletrotécnica' } });
        assert.equal(r.status, 201);
        assert.match(r.corpo.id, UUID);
        assert.equal(r.corpo.nome, 'Laura Dias');
        assert.match(r.corpo.criadoEm, DATA);
        usuario = r.corpo;
        outro = (await nr.requisitar('POST', '/hub/users', { corpo: { nome: 'Rui Prates' } })).corpo;
    });

    await teste('GET e PUT /hub/perfil usam o cabeçalho X-Hub-User', async function () {
        let r = await nr.requisitar('GET', '/hub/perfil');
        assert.equal(r.status, 401);
        r = await nr.requisitar('GET', '/hub/perfil', { cabecalhos: { 'X-Hub-User': 'nao-existe' } });
        assert.equal(r.status, 401);
        r = await nr.requisitar('GET', '/hub/perfil', { cabecalhos: { 'X-Hub-User': usuario.id.toLowerCase() } });
        assert.equal(r.status, 200);
        assert.equal(r.corpo.nome, 'Laura Dias');
        r = await nr.requisitar('PUT', '/hub/perfil', { corpo: { nome: 'L' }, cabecalhos: { 'X-Hub-User': usuario.id } });
        assert.equal(r.status, 400);
        r = await nr.requisitar('PUT', '/hub/perfil', { corpo: { curso: 'Técnico em Segurança do Trabalho' }, cabecalhos: { 'X-Hub-User': usuario.id } });
        assert.equal(r.status, 200);
        assert.equal(r.corpo.nome, 'Laura Dias');
        assert.equal(r.corpo.curso, 'Técnico em Segurança do Trabalho');
        assert.equal(nr.banco().users[usuario.id].curso, 'Técnico em Segurança do Trabalho', 'gravado no banco');
    });

    await teste('POST /hub/projetos exige usuário e valida todos os campos', async function () {
        let r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto() });
        assert.equal(r.status, 401);
        r = await nr.requisitar('POST', '/hub/projetos', {
            corpo: { tipo: 'post', titulo: 'Oi', descricao: 'curta', area: 'x', cadeira: '', ano: 1800, imagemURL: 'javascript:alert(1)', link: 'ftp://x', autores: [] },
            cabecalhos: { 'X-Hub-User': usuario.id }
        });
        assert.equal(r.status, 400);
        assert.equal(r.corpo.erro, 'Dados inválidos');
        ['tipo', 'titulo', 'descricao', 'area', 'cadeira', 'ano', 'imagemURL', 'link', 'autores'].forEach(function (campo) {
            assert.ok(r.corpo.detalhes.some(function (d) { return d.startsWith(campo + ':'); }), campo);
        });
        assert.equal(Object.keys(nr.banco().projetos).length, 12, 'nada gravado');
    });

    await teste('POST /hub/projetos grava, reaproveita a cadeira (sem diferenciar acento/maiúscula) e marca "meu"', async function () {
        const r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto(), cabecalhos: { 'X-Hub-User': usuario.id } });
        assert.equal(r.status, 201);
        criado = r.corpo;
        assert.match(criado.id, UUID);
        assert.equal(criado.cadeira, 'Higiene Ocupacional');
        assert.equal(criado.subarea, 'Engenharia de Produção', 'grafia oficial da subárea');
        assert.equal(criado.meu, true);
        assert.equal(criado.nota, 0);
        assert.equal(criado.quant, 0);
        const db = nr.banco();
        assert.equal(Object.keys(db.cadeiras).length, 10, 'não criou cadeira repetida');
        assert.equal(db.projetos[criado.id].userId, usuario.id, 'coluna user preenchida');

        const nova = await nr.requisitar('POST', '/hub/projetos', {
            corpo: novoProjeto({ cadeira: '  Robótica Móvel ', autores: 'Pedro Alves', imagemURL: '', link: null, plataforma: 'tiktok', instituicao: '' }),
            cabecalhos: { 'X-Hub-User': outro.id }
        });
        assert.equal(nova.status, 201);
        assert.equal(nova.corpo.cadeira, 'Robótica Móvel');
        assert.deepEqual(nova.corpo.autores, ['Pedro Alves']);
        assert.equal(nova.corpo.imagemURL, null);
        assert.equal(nova.corpo.link, null);
        assert.equal(nova.corpo.plataforma, 'outro');
        assert.equal(nova.corpo.instituicao, 'CTISM – UFSM');
        assert.equal(Object.keys(nr.banco().cadeiras).length, 11);
        assert.equal(nova.corpo.subarea, 'Engenharia de Produção');
    });

    await teste('subárea: precisa ser da área escolhida; sem subárea continua aceito (versões antigas do app)', async function () {
        const h = { 'X-Hub-User': outro.id };
        let r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ subarea: 'Enfermagem' }), cabecalhos: h });
        assert.equal(r.status, 400);
        assert.deepEqual(r.corpo.detalhes.filter(function (d) { return d.startsWith('subarea:'); }).length, 1);
        r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ area: 'saude', subarea: 'medicina/medicina legal e deontologia' }), cabecalhos: h });
        assert.equal(r.status, 201);
        assert.equal(r.corpo.subarea, 'Medicina/Medicina Legal e Deontologia');
        const semSubarea = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ subarea: undefined }), cabecalhos: h });
        assert.equal(semSubarea.status, 201);
        assert.equal(semSubarea.corpo.subarea, null);
        await nr.requisitar('DELETE', '/hub/projetos/' + r.corpo.id, { cabecalhos: h });
        await nr.requisitar('DELETE', '/hub/projetos/' + semSubarea.corpo.id, { cabecalhos: h });
    });

    await teste('matéria (cadeira) aceita até 150 caracteres, como no app', async function () {
        const h = { 'X-Hub-User': outro.id };
        let r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ cadeira: 'M'.repeat(151) }), cabecalhos: h });
        assert.equal(r.status, 400);
        assert.ok(r.corpo.detalhes.includes('cadeira: de 2 a 150 caracteres'));
        const longa = 'Estágio Supervisionado em Terapia Ocupacional no Campo da Deficiência - Ênfase Reabilitação Baseada na Comunidade (RBC)';
        r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ cadeira: longa }), cabecalhos: h });
        assert.equal(r.status, 201);
        assert.equal(r.corpo.cadeira, longa);
        await nr.requisitar('DELETE', '/hub/projetos/' + r.corpo.id, { cabecalhos: h });
    });

    await teste('limites contam caracteres como o Swift (emoji composto = 1)', async function () {
        const familia = '\u{1F468}‍\u{1F469}‍\u{1F467}';
        const h = { 'X-Hub-User': usuario.id };
        let r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ descricao: 'a'.repeat(199) + familia }), cabecalhos: h });
        assert.equal(r.status, 201, JSON.stringify(r.corpo));
        r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ descricao: 'a'.repeat(200) + familia }), cabecalhos: h });
        assert.equal(r.status, 400);
        r = await nr.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ titulo: 't'.repeat(151) }), cabecalhos: h });
        assert.equal(r.status, 400);
        await nr.requisitar('DELETE', '/hub/projetos/' + Object.values(nr.banco().projetos)
            .find(function (p) { return p.descricao.endsWith(familia); }).id, { cabecalhos: h });
    });

    await teste('sem Intl.Segmenter o limite continua funcionando (conta por código)', async function () {
        const sem = criarNodeRed({ semSegmenter: true, armazenamento: criarArmazenamento(nr.armazenamento.dados) });
        const h = { 'X-Hub-User': usuario.id };
        let r = await sem.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ descricao: 'b'.repeat(200) }), cabecalhos: h });
        assert.equal(r.status, 201);
        r = await sem.requisitar('POST', '/hub/projetos', { corpo: novoProjeto({ descricao: 'b'.repeat(201) }), cabecalhos: h });
        assert.equal(r.status, 400);
    });

    await teste('GET /hub/projetos com o cabeçalho marca só as publicações do usuário', async function () {
        const r = await nr.requisitar('GET', '/hub/projetos', { cabecalhos: { 'X-Hub-User': usuario.id } });
        const meus = r.corpo.filter(function (p) { return p.meu; });
        assert.deepEqual(meus.map(function (p) { return p.id; }), [criado.id]);
        assert.equal(r.corpo[0].id, criado.id, 'mais recente primeiro');
    });

    await teste('GET /hub/projetos/:id aceita id em minúsculas e dá 404 para id desconhecido', async function () {
        let r = await nr.requisitar('GET', '/hub/projetos/' + criado.id.toLowerCase());
        assert.equal(r.status, 200);
        assert.equal(r.corpo.titulo, criado.titulo);
        assert.equal(r.corpo.meu, false, 'sem cabeçalho não é "meu"');
        r = await nr.requisitar('GET', '/hub/projetos/00000000-0000-4000-8000-000000000000');
        assert.equal(r.status, 404);
    });

    await teste('POST /hub/avaliacoes: 1 voto por pessoa, votar de novo troca a nota', async function () {
        const h = { 'X-Hub-User': usuario.id };
        let r = await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: criado.id, nota: 5 } });
        assert.equal(r.status, 401);
        for (const nota of [0, 6, 4.5, 'x', null]) {
            r = await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: criado.id, nota: nota }, cabecalhos: h });
            assert.equal(r.status, 400, 'nota ' + nota);
        }
        r = await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: 'nao-existe', nota: 5 }, cabecalhos: h });
        assert.equal(r.status, 404);

        r = await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: criado.id.toLowerCase(), nota: 5 }, cabecalhos: h });
        assert.equal(r.status, 200);
        assert.deepEqual(r.corpo, { projetoId: criado.id, nota: 5, quant: 1, minhaNota: 5 });
        r = await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: criado.id, nota: '3' }, cabecalhos: h });
        assert.deepEqual(r.corpo, { projetoId: criado.id, nota: 3, quant: 1, minhaNota: 3 });
        r = await nr.requisitar('POST', '/hub/avaliacoes', { corpo: { projetoId: criado.id, nota: 4 }, cabecalhos: { 'X-Hub-User': outro.id } });
        assert.deepEqual(r.corpo, { projetoId: criado.id, nota: 3.5, quant: 2, minhaNota: 4 });

        const lista = await nr.requisitar('GET', '/hub/projetos', { cabecalhos: h });
        const p = lista.corpo.find(function (x) { return x.id === criado.id; });
        assert.equal(p.nota, 3.5);
        assert.equal(p.quant, 2);
        assert.equal(p.minhaNota, 3);
    });

    await teste('GET /hub/cadeiras em ordem alfabética, com o total de publicações', async function () {
        const r = await nr.requisitar('GET', '/hub/cadeiras');
        assert.equal(r.status, 200);
        const nomes = r.corpo.map(function (c) { return c.nome; });
        assert.deepEqual(nomes, nomes.slice().sort(function (a, b) { return a.localeCompare(b, 'pt-BR'); }));
        assert.equal(r.corpo.find(function (c) { return c.nome === 'Higiene Ocupacional'; }).total, 4);
    });

    await teste('POST /hub/cadeiras só com a chave da moderação', async function () {
        let r = await nr.requisitar('POST', '/hub/cadeiras', { corpo: { nome: 'Química Geral' } });
        assert.equal(r.status, 403);
        r = await nr.requisitar('POST', '/hub/cadeiras', { corpo: { nome: 'Química Geral' }, cabecalhos: { 'X-Hub-Admin': 'errada' } });
        assert.equal(r.status, 403);
        r = await nr.requisitar('POST', '/hub/cadeiras', { corpo: { nome: 'Química Geral' }, cabecalhos: { 'X-Hub-Admin': 'segredo-moderacao' } });
        assert.equal(r.status, 201);
        const de_novo = await nr.requisitar('POST', '/hub/cadeiras', { corpo: { nome: 'quimica geral' }, cabecalhos: { 'X-Hub-Admin': 'segredo-moderacao' } });
        assert.equal(de_novo.corpo.id, r.corpo.id);
    });

    await teste('DELETE /hub/projetos/:id: autor ou moderação; apaga também os votos', async function () {
        let r = await nr.requisitar('DELETE', '/hub/projetos/' + criado.id);
        assert.equal(r.status, 403);
        r = await nr.requisitar('DELETE', '/hub/projetos/' + criado.id, { cabecalhos: { 'X-Hub-User': outro.id } });
        assert.equal(r.status, 403, 'outra pessoa não pode remover');
        r = await nr.requisitar('DELETE', '/hub/projetos/' + criado.id, { cabecalhos: { 'X-Hub-User': usuario.id } });
        assert.equal(r.status, 200);
        assert.ok(!Object.values(nr.banco().avaliacoes).some(function (a) { return a.projetoId === criado.id; }));

        const exemplo = Object.values(nr.banco().projetos).find(function (p) { return p.exemplo; });
        r = await nr.requisitar('DELETE', '/hub/projetos/' + exemplo.id, { cabecalhos: { 'X-Hub-Admin': 'segredo-moderacao' } });
        assert.equal(r.status, 200);
        r = await nr.requisitar('DELETE', '/hub/projetos/' + exemplo.id, { cabecalhos: { 'X-Hub-Admin': 'segredo-moderacao' } });
        assert.equal(r.status, 404);
    });

    await teste('sem HUB_ADMIN_TOKEN definido, nenhuma chave de moderação é aceita', async function () {
        const sem = criarNodeRed({ armazenamento: criarArmazenamento(nr.armazenamento.dados) });
        const algum = Object.keys(sem.banco().projetos)[0];
        let r = await sem.requisitar('DELETE', '/hub/projetos/' + algum, { cabecalhos: { 'X-Hub-Admin': '' } });
        assert.equal(r.status, 403);
        r = await sem.requisitar('DELETE', '/hub/projetos/' + algum, { cabecalhos: { 'X-Hub-Admin': 'undefined' } });
        assert.equal(r.status, 403);
    });

    await teste('dados continuam após reiniciar o Node-RED (contexto em arquivo)', async function () {
        const salvo = JSON.parse(JSON.stringify(nr.armazenamento.dados));
        const reiniciado = criarNodeRed({ armazenamento: criarArmazenamento(salvo) });
        await reiniciado.injetar('iniciar');
        const r = await reiniciado.requisitar('GET', '/hub/perfil', { cabecalhos: { 'X-Hub-User': usuario.id } });
        assert.equal(r.status, 200);
        assert.equal((await reiniciado.requisitar('GET', '/hub/status')).corpo.totais.projetos,
            Object.keys(nr.banco().projetos).length);
    });

    await teste('rota sem "case" e erro inesperado viram 404/500 em JSON', async function () {
        const r = await nr.requisitar('PATCH', '/hub/projetos/1');
        assert.equal(r.semRota, true, 'o Node-RED nem chega na função');
        const quebrado = criarNodeRed({ globalFalho: { get: function () { throw new Error('disco cheio'); }, set: function () {} } });
        const e = await quebrado.requisitar('GET', '/hub/status');
        assert.equal(e.status, 500);
        assert.deepEqual(e.corpo, { erro: 'Erro interno no servidor', detalhes: ['disco cheio'] });
        assert.equal(quebrado.registros.erros.length, 1);
    });

    await teste('o banco inteiro continua serializável em JSON e com datas no formato do iOS', async function () {
        const db = nr.banco();
        Object.values(db.projetos).forEach(function (p) { assert.match(p.criadoEm, DATA); });
        Object.values(db.users).forEach(function (u) { assert.match(u.criadoEm, DATA); });
        assert.ok(nr.armazenamento.dados.hub_db.length < 200000, 'tamanho razoável');
    });
}

(async function () {
    console.log('Hub Acadêmico · testes do fluxo Node-RED (' + path.basename(ARQUIVO) + ')');
    await testarEstrutura();
    await testarBancoEExemplos();
    await testarApi();
    console.log('\n' + aprovados + ' testes aprovados, ' + falhas.length + ' com falha.');
    process.exitCode = falhas.length ? 1 : 0;
})();
