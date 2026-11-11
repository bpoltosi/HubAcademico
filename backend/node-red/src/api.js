// =====================================================================
// Hub Acadêmico · API REST e banco de dados no Node-RED
// Corpo do nó "function" que atende a todas as rotas /hub/...
//
// Tabelas (guardadas no contexto global do Node-RED, na chave "hub_db"):
//   projetos   id | tipo | titulo | descricao | autores | ano | area | subarea | cadeiraId
//              | userId | instituicao | curso | link | plataforma | imagemURL | criadoEm
//   cadeiras   id | nome
//   users      id | nome | curso
//   avaliacoes id | projetoId | userId | nota   (um voto por pessoa em cada projeto)
//
// A média ("nota") e a quantidade de votos ("quant") saem da tabela avaliacoes
// e são devolvidas junto com cada projeto.
//
// Identificação: o app envia o id do usuário no cabeçalho "X-Hub-User".
// Esse id funciona como uma chave do aparelho, por isso nunca é devolvido
// nas listas públicas (no lugar dele vai o campo "meu": true/false).
// A moderação (remover projeto, criar cadeira) usa o cabeçalho "X-Hub-Admin"
// com o valor da variável de ambiente HUB_ADMIN_TOKEN.
// =====================================================================

const CHAVE = 'hub_db';
const TABELAS = ['projetos', 'cadeiras', 'users', 'avaliacoes'];
const TIPOS = ['projeto', 'trabalho', 'prova', 'material'];
// Subáreas de cada grande área (tabela do CNPq; a mesma lista do app em CatalogoAreas.swift).
// Bloco gerado por ferramentas/catalogo/gerar_catalogo.py: não edite à mão.
// <subareas>
const SUBAREAS = {
    exatas: ['Astronomia', 'Ciência da Computação', 'Física', 'Geociências', 'Matemática', 'Oceanografia', 'Probabilidade e Estatística', 'Química'],
    agrarias: ['Agronomia/Agrometeorologia', 'Agronomia/Ciência do Solo', 'Agronomia/Extensão Rural', 'Agronomia/Fitossanidade', 'Agronomia/Fitotecnia', 'Agronomia/Floricultura, Parques e Jardins', 'Ciência e Tecnologia de Alimentos/Ciência de Alimentos', 'Ciência e Tecnologia de Alimentos/Engenharia de Alimentos', 'Ciência e Tecnologia de Alimentos/Tecnologia de Alimentos', 'Engenharia Agrícola', 'Medicina Veterinária/Clínica e Cirurgia Animal', 'Medicina Veterinária/Inspeção de Produtos de Origem Animal', 'Medicina Veterinária/Medicina Veterinária Preventiva', 'Medicina Veterinária/Patologia Animal', 'Medicina Veterinária/Reprodução Animal', 'Recursos Florestais e Engenharia Florestal', 'Recursos Pesqueiros e Engenharia de Pesca', 'Zootecnia/Ecologia dos Animais Domésticos e Etologia', 'Zootecnia/Genética e Melhoramento dos Animais Domésticos', 'Zootecnia/Nutrição e Alimentação Animal', 'Zootecnia/Pastagem e Forragicultura', 'Zootecnia/Produção Animal'],
    biologicas: ['Biofísica', 'Biologia Geral', 'Bioquímica', 'Botânica', 'Ecologia', 'Farmacologia', 'Fisiologia', 'Genética', 'Imunologia', 'Microbiologia', 'Morfologia', 'Parasitologia', 'Zoologia'],
    saude: ['Educação Física', 'Enfermagem', 'Farmácia', 'Fisioterapia e Terapia Ocupacional', 'Fonoaudiologia', 'Medicina/Clínica Médica', 'Medicina/Cirurgia', 'Medicina/Saúde Materno-Infantil', 'Medicina/Psiquiatria', 'Medicina/Anatomia Patológica e Patologia Clínica', 'Medicina/Radiologia Médica', 'Medicina/Medicina Legal e Deontologia', 'Nutrição', 'Odontologia', 'Saúde Coletiva'],
    humanas: ['Antropologia', 'Arqueologia', 'Ciência Política', 'Educação/Fundamentos da Educação', 'Educação/Administração Educacional', 'Educação/Planejamento e Avaliação Educacional', 'Educação/Ensino-Aprendizagem', 'Educação/Currículo', 'Educação/Orientação e Aconselhamento', 'Educação/Tópicos Especiais em Educação', 'Filosofia', 'Geografia', 'História', 'Psicologia', 'Sociologia'],
    sociaisAplicadas: ['Administração', 'Arquitetura e Urbanismo', 'Arquivologia', 'Comunicação', 'Demografia', 'Desenho Industrial', 'Direito', 'Economia', 'Planejamento Urbano e Regional', 'Serviço Social', 'Turismo'],
    engenharias: ['Engenharia Acústica', 'Engenharia Aeroespacial', 'Engenharia Biomédica', 'Engenharia Civil', 'Engenharia de Materiais e Metalúrgica', 'Engenharia de Minas', 'Engenharia de Produção', 'Engenharia de Transportes', 'Engenharia Elétrica', 'Engenharia Mecânica', 'Engenharia Naval e Oceânica', 'Engenharia Nuclear', 'Engenharia Química', 'Engenharia Sanitária'],
    linguisticaLetrasArtes: ['Artes/Artes Plásticas', 'Artes/Dança', 'Artes/Música', 'Artes/Teatro', 'Letras', 'Linguística'],
};
// </subareas>
const AREAS = Object.keys(SUBAREAS);
const PLATAFORMAS = ['linkedin', 'instagram', 'blog', 'youtube', 'github', 'outro'];
const LIMITES = {
    titulo: [5, 150], descricao: [20, 200], cadeira: [2, 150], instituicao: [2, 120],
    curso: [0, 120], autor: [2, 80], nome: [2, 80], url: 500
};

// ---------- utilidades ----------
function agora() {
    // ISO 8601 sem milissegundos (formato lido direto pelo JSONDecoder do iOS)
    return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function novoId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16).toUpperCase();
    });
}

function idDe(valor) {
    return valor === undefined || valor === null ? '' : String(valor).trim().toUpperCase();
}

function texto(valor) {
    return typeof valor === 'string' ? valor.trim() : '';
}

function normalizar(valor) {
    return String(valor || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
}

/** Conta caracteres como o Swift conta (um emoji composto vale 1). */
function caracteres(valor) {
    if (typeof Intl !== 'undefined' && typeof Intl.Segmenter === 'function') {
        let total = 0;
        const partes = new Intl.Segmenter('pt-BR', { granularity: 'grapheme' }).segment(valor);
        for (const parte of partes) { if (parte) total++; }
        return total;
    }
    return Array.from(valor).length;
}

function tamanhoOk(valor, campo) {
    const n = caracteres(valor);
    return n >= LIMITES[campo][0] && n <= LIMITES[campo][1];
}

/** Devolve o nome oficial da subárea (sem diferenciar acentos/maiúsculas) ou null se não for da área. */
function subareaDe(area, nome) {
    const chave = normalizar(nome);
    const lista = SUBAREAS[area] || [];
    return lista.find(function (s) { return normalizar(s) === chave; }) || null;
}

/** Devolve a URL limpa, null quando vazia ou undefined quando inválida. */
function urlValida(valor) {
    const t = texto(valor);
    if (!t) return null;
    if (t.length > LIMITES.url) return undefined;
    if (/^https?:\/\/[^\s/?#]+\.[^\s]+$/i.test(t) || /^asset:\/\/[\w-]+$/.test(t)) return t;
    return undefined;
}

function cabecalho(nome) {
    const valor = (req.headers || {})[nome];
    return Array.isArray(valor) ? String(valor[0] || '') : String(valor || '');
}

function ehModeracao() {
    const chave = env.get('HUB_ADMIN_TOKEN');
    return !!chave && cabecalho('x-hub-admin') === String(chave);
}

// ---------- banco ----------
function abrirBanco() {
    let db = global.get(CHAVE);
    if (!db || typeof db !== 'object') db = { versao: 1 };
    TABELAS.forEach(function (t) { if (!db[t] || typeof db[t] !== 'object') db[t] = {}; });
    return db;
}

function gravarBanco(db) {
    global.set(CHAVE, db);
}

function usuarioAtual(db) {
    const id = idDe(cabecalho('x-hub-user'));
    return id && db.users[id] ? db.users[id] : null;
}

function cadeiraPorNome(db, nome) {
    const chave = normalizar(nome);
    const existente = Object.values(db.cadeiras).find(function (c) { return normalizar(c.nome) === chave; });
    if (existente) return existente;
    const nova = { id: novoId(), nome: nome.trim(), criadoEm: agora() };
    db.cadeiras[nova.id] = nova;
    return nova;
}

/** Soma e quantidade de votos por projeto (e o voto do usuário informado). */
function resumos(db, userId) {
    const r = {};
    Object.values(db.avaliacoes).forEach(function (a) {
        const x = r[a.projetoId] || (r[a.projetoId] = { soma: 0, quant: 0, minhaNota: null });
        x.soma += a.nota;
        x.quant += 1;
        if (userId && a.userId === userId) x.minhaNota = a.nota;
    });
    return r;
}

function media(resumo) {
    return resumo && resumo.quant ? Math.round((resumo.soma / resumo.quant) * 100) / 100 : 0;
}

/** Formato público de um projeto (sem o id do usuário que publicou). */
function apresentar(db, p, resumo, userId) {
    const r = resumo || { soma: 0, quant: 0, minhaNota: null };
    const cadeira = db.cadeiras[p.cadeiraId];
    return {
        id: p.id,
        tipo: p.tipo,
        titulo: p.titulo,
        descricao: p.descricao,
        imagemURL: p.imagemURL || null,
        link: p.link || null,
        plataforma: p.plataforma || 'outro',
        area: p.area,
        subarea: p.subarea || null,
        cadeira: cadeira ? cadeira.nome : '',
        cadeiraId: p.cadeiraId || null,
        curso: p.curso || '',
        instituicao: p.instituicao || '',
        ano: p.ano,
        autores: p.autores || [],
        nota: media(r),
        quant: r.quant,
        minhaNota: r.minhaNota,
        meu: !!userId && p.userId === userId,
        criadoEm: p.criadoEm
    };
}

function validarProjeto(corpo) {
    const erros = [];
    const titulo = texto(corpo.titulo);
    const descricao = texto(corpo.descricao);
    const cadeira = texto(corpo.cadeira);
    const subareaInformada = texto(corpo.subarea);
    const subarea = subareaInformada ? subareaDe(corpo.area, subareaInformada) : null;
    const instituicao = texto(corpo.instituicao) || 'CTISM – UFSM';
    const curso = texto(corpo.curso);
    const ano = Number(corpo.ano);
    const anoAtual = new Date().getFullYear();
    const imagemURL = urlValida(corpo.imagemURL);
    const link = urlValida(corpo.link);
    const lista = Array.isArray(corpo.autores) ? corpo.autores : [corpo.autores];
    const autores = lista.map(texto).filter(Boolean);

    if (TIPOS.indexOf(corpo.tipo) < 0) erros.push('tipo: use ' + TIPOS.join(', '));
    if (!tamanhoOk(titulo, 'titulo')) erros.push('titulo: de 5 a 150 caracteres');
    if (!tamanhoOk(descricao, 'descricao')) erros.push('descricao: de 20 a 200 caracteres');
    if (AREAS.indexOf(corpo.area) < 0) erros.push('area: use ' + AREAS.join(', '));
    else if (subareaInformada && !subarea) erros.push('subarea: não pertence à área ' + corpo.area + ' (veja GET /hub/subareas)');
    if (!tamanhoOk(cadeira, 'cadeira')) erros.push('cadeira: de 2 a 150 caracteres');
    if (!tamanhoOk(instituicao, 'instituicao')) erros.push('instituicao: de 2 a 120 caracteres');
    if (!tamanhoOk(curso, 'curso')) erros.push('curso: até 120 caracteres');
    if (!(Number.isInteger(ano) && ano >= 1990 && ano <= anoAtual + 1)) erros.push('ano: entre 1990 e ' + (anoAtual + 1));
    if (imagemURL === undefined) erros.push('imagemURL: endereço inválido (use http:// ou https://)');
    if (link === undefined) erros.push('link: endereço inválido (use http:// ou https://)');
    if (!autores.length || autores.length > 10 || !autores.every(function (a) { return tamanhoOk(a, 'autor'); })) {
        erros.push('autores: de 1 a 10 nomes, cada um com 2 a 80 caracteres');
    }

    return {
        erros: erros,
        dados: {
            tipo: corpo.tipo, titulo: titulo, descricao: descricao, area: corpo.area, subarea: subarea, cadeira: cadeira,
            instituicao: instituicao, curso: curso, ano: ano, imagemURL: imagemURL || null,
            link: link || null, autores: autores,
            plataforma: PLATAFORMAS.indexOf(corpo.plataforma) >= 0 ? corpo.plataforma : 'outro'
        }
    };
}

// ---------- resposta HTTP ----------
function responder(status, dados) {
    msg.statusCode = status;
    msg.headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store'
    };
    msg.payload = dados;
    return msg;
}

function invalido(detalhes) {
    return responder(400, { erro: 'Dados inválidos', detalhes: detalhes });
}

function semUsuario() {
    return responder(401, {
        erro: 'Usuário não identificado',
        detalhes: ['Cadastre-se em POST /hub/users e envie o id recebido no cabeçalho X-Hub-User']
    });
}

function atualizarStatus(db) {
    node.status({
        fill: 'green', shape: 'dot',
        text: Object.keys(db.projetos).length + ' publicações · ' + Object.keys(db.users).length + ' usuários'
    });
}

// ---------- roteamento ----------
const req = msg.req || {};
const metodo = String(req.method || 'GET').toUpperCase();
const rota = (req.route && req.route.path) || '';
const params = req.params || {};
const consulta = req.query || {};
const corpo = (msg.payload && typeof msg.payload === 'object' && !Array.isArray(msg.payload)) ? msg.payload : {};

try {
    const db = abrirBanco();
    atualizarStatus(db);

    switch (metodo + ' ' + rota) {

    case 'GET /hub/status': {
        return responder(200, {
            ok: true,
            servico: 'Hub Acadêmico – Repositório acadêmico do CTISM',
            versao: db.versao || 1,
            horario: agora(),
            totais: {
                projetos: Object.keys(db.projetos).length,
                cadeiras: Object.keys(db.cadeiras).length,
                users: Object.keys(db.users).length,
                avaliacoes: Object.keys(db.avaliacoes).length
            }
        });
    }

    // ----- projetos -----
    case 'GET /hub/projetos': {
        const usuario = usuarioAtual(db);
        const userId = usuario ? usuario.id : '';
        const r = resumos(db, userId);
        const termos = normalizar(consulta.q).split(/\s+/).filter(function (t) { return t.length >= 2; });
        let lista = Object.values(db.projetos).map(function (p) { return apresentar(db, p, r[p.id], userId); });

        if (consulta.tipo) lista = lista.filter(function (p) { return p.tipo === consulta.tipo; });
        if (consulta.ano) lista = lista.filter(function (p) { return String(p.ano) === String(consulta.ano); });
        if (consulta.area) lista = lista.filter(function (p) { return p.area === consulta.area; });
        if (consulta.subarea) {
            const s = normalizar(consulta.subarea);
            lista = lista.filter(function (p) { return normalizar(p.subarea) === s; });
        }
        if (consulta.curso) lista = lista.filter(function (p) { return p.curso === consulta.curso; });
        if (consulta.cadeira) {
            const c = normalizar(consulta.cadeira);
            lista = lista.filter(function (p) { return normalizar(p.cadeira).indexOf(c) >= 0; });
        }
        if (consulta.autor) {
            const a = normalizar(consulta.autor);
            lista = lista.filter(function (p) {
                return p.autores.some(function (n) { return normalizar(n).indexOf(a) >= 0; });
            });
        }
        if (termos.length) {
            lista = lista.filter(function (p) {
                const alvo = normalizar([p.titulo, p.descricao, p.cadeira, p.autores.join(' ')].join(' '));
                return termos.every(function (t) { return alvo.indexOf(t) >= 0; });
            });
        }
        if (consulta.ordem === 'nota') {
            lista.sort(function (a, b) { return (b.nota - a.nota) || (b.quant - a.quant); });
        } else {
            lista.sort(function (a, b) { return String(b.criadoEm).localeCompare(String(a.criadoEm)); });
        }
        const limite = Math.min(Math.max(parseInt(consulta.limite, 10) || 500, 1), 1000);
        return responder(200, lista.slice(0, limite));
    }

    case 'GET /hub/projetos/:id': {
        const p = db.projetos[idDe(params.id)];
        if (!p) return responder(404, { erro: 'Projeto não encontrado' });
        const usuario = usuarioAtual(db);
        const userId = usuario ? usuario.id : '';
        return responder(200, apresentar(db, p, resumos(db, userId)[p.id], userId));
    }

    case 'POST /hub/projetos': {
        const usuario = usuarioAtual(db);
        if (!usuario) return semUsuario();
        const v = validarProjeto(corpo);
        if (v.erros.length) return invalido(v.erros);
        const cadeira = cadeiraPorNome(db, v.dados.cadeira);
        const p = {
            id: novoId(), tipo: v.dados.tipo, titulo: v.dados.titulo, descricao: v.dados.descricao,
            autores: v.dados.autores, ano: v.dados.ano, area: v.dados.area, subarea: v.dados.subarea, cadeiraId: cadeira.id,
            userId: usuario.id, instituicao: v.dados.instituicao, curso: v.dados.curso,
            link: v.dados.link, plataforma: v.dados.plataforma, imagemURL: v.dados.imagemURL,
            criadoEm: agora()
        };
        db.projetos[p.id] = p;
        gravarBanco(db);
        atualizarStatus(db);
        return responder(201, apresentar(db, p, null, usuario.id));
    }

    case 'DELETE /hub/projetos/:id': {
        const id = idDe(params.id);
        const p = db.projetos[id];
        const usuario = usuarioAtual(db);
        const dono = !!(p && usuario && p.userId === usuario.id);
        if (!dono && !ehModeracao()) {
            return responder(403, { erro: 'Só quem publicou ou a moderação (cabeçalho X-Hub-Admin) pode remover' });
        }
        if (!p) return responder(404, { erro: 'Projeto não encontrado' });
        delete db.projetos[id];
        Object.keys(db.avaliacoes).forEach(function (k) {
            if (db.avaliacoes[k].projetoId === id) delete db.avaliacoes[k];
        });
        gravarBanco(db);
        atualizarStatus(db);
        return responder(200, { ok: true, removido: id });
    }

    // ----- avaliações -----
    case 'POST /hub/avaliacoes': {
        const usuario = usuarioAtual(db);
        if (!usuario) return semUsuario();
        const projetoId = idDe(corpo.projetoId);
        const nota = Number(corpo.nota);
        if (!db.projetos[projetoId]) return responder(404, { erro: 'Projeto não encontrado' });
        if (!(Number.isInteger(nota) && nota >= 1 && nota <= 5)) return invalido(['nota: número inteiro de 1 a 5']);

        const existente = Object.values(db.avaliacoes).find(function (a) {
            return a.projetoId === projetoId && a.userId === usuario.id;
        });
        if (existente) {
            existente.nota = nota;
            existente.atualizadoEm = agora();
        } else {
            const a = { id: novoId(), projetoId: projetoId, userId: usuario.id, nota: nota, criadoEm: agora() };
            db.avaliacoes[a.id] = a;
        }
        gravarBanco(db);
        const r = resumos(db, usuario.id)[projetoId];
        return responder(200, { projetoId: projetoId, nota: media(r), quant: r.quant, minhaNota: r.minhaNota });
    }

    case 'GET /hub/subareas': {
        return responder(200, SUBAREAS);
    }

    // ----- cadeiras -----
    case 'GET /hub/cadeiras': {
        const contagem = {};
        Object.values(db.projetos).forEach(function (p) { contagem[p.cadeiraId] = (contagem[p.cadeiraId] || 0) + 1; });
        const lista = Object.values(db.cadeiras)
            .map(function (c) { return { id: c.id, nome: c.nome, total: contagem[c.id] || 0 }; })
            .sort(function (a, b) { return a.nome.localeCompare(b.nome, 'pt-BR'); });
        return responder(200, lista);
    }

    case 'POST /hub/cadeiras': {
        if (!ehModeracao()) return responder(403, { erro: 'Cadastro de cadeiras só pela moderação (cabeçalho X-Hub-Admin)' });
        const nome = texto(corpo.nome);
        if (!tamanhoOk(nome, 'cadeira')) return invalido(['nome: de 2 a 80 caracteres']);
        const c = cadeiraPorNome(db, nome);
        gravarBanco(db);
        return responder(201, { id: c.id, nome: c.nome });
    }

    // ----- users -----
    case 'POST /hub/users': {
        const nome = texto(corpo.nome);
        const curso = texto(corpo.curso);
        const erros = [];
        if (!tamanhoOk(nome, 'nome')) erros.push('nome: de 2 a 80 caracteres');
        if (!tamanhoOk(curso, 'curso')) erros.push('curso: até 120 caracteres');
        if (erros.length) return invalido(erros);
        const u = { id: novoId(), nome: nome, curso: curso, criadoEm: agora() };
        db.users[u.id] = u;
        gravarBanco(db);
        atualizarStatus(db);
        return responder(201, u);
    }

    case 'GET /hub/perfil': {
        const usuario = usuarioAtual(db);
        return usuario ? responder(200, usuario) : semUsuario();
    }

    case 'PUT /hub/perfil': {
        const usuario = usuarioAtual(db);
        if (!usuario) return semUsuario();
        const erros = [];
        const nome = corpo.nome === undefined ? usuario.nome : texto(corpo.nome);
        const curso = corpo.curso === undefined ? (usuario.curso || '') : texto(corpo.curso);
        if (!tamanhoOk(nome, 'nome')) erros.push('nome: de 2 a 80 caracteres');
        if (!tamanhoOk(curso, 'curso')) erros.push('curso: até 120 caracteres');
        if (erros.length) return invalido(erros);
        usuario.nome = nome;
        usuario.curso = curso;
        usuario.atualizadoEm = agora();
        gravarBanco(db);
        return responder(200, usuario);
    }

    default:
        return responder(404, { erro: 'Rota não encontrada: ' + metodo + ' ' + (rota || req.url || '') });
    }
} catch (e) {
    // Sem o msg de propósito: assim um nó "catch" não tenta responder de novo à mesma requisição.
    node.error('Hub Acadêmico: ' + (e && e.stack ? e.stack : e));
    return responder(500, { erro: 'Erro interno no servidor', detalhes: [String(e && e.message ? e.message : e)] });
}
