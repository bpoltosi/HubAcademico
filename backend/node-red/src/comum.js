// =====================================================================
// Hub Acadêmico · funções comuns
// O montar-fluxo.js copia para cada nó "function" só as declarações que ele usa (e as que
// elas usam). Por isso, escreva cada declaração começando na coluna 0, com o comentário
// logo acima dela, sem linha em branco entre os dois.
//
// Banco: Cloudant, um banco só ("hub-academico-10"). Cada documento tem o campo
// "colecao", que diz o que ele guarda:
//   publicacao  _id | tipo | titulo | descricao | autores | ano | area | subarea | disciplina
//               | curso | instituicao | link | plataforma | imagemLink | usuarioId | criadoEm
//   avaliacao   _id ("avaliacao:<publicação>:<usuário>") | publicacaoId | usuarioId | nota
//   usuario     _id | nome | curso
//
// A média ("media") e o total de avaliações ("totalAvaliacoes") são calculados a partir
// das avaliações; "nota" é só a avaliação de 1 a 5 de cada pessoa. As publicações de
// exemplo trazem "avaliacoesBase" (soma e total), somadas às avaliações reais.
//
// Identificação: o app envia o id do usuário no cabeçalho "X-Hub-Usuario". Esse id
// funciona como uma chave do aparelho e nunca é devolvido nas listas (no lugar dele
// vai o campo "meu": true/false). A moderação usa o cabeçalho "X-Hub-Moderacao" com o
// valor da variável de ambiente HUB_MODERACAO_TOKEN.
// =====================================================================

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
    titulo: [5, 150], descricao: [20, 200], disciplina: [2, 150], instituicao: [2, 120],
    curso: [0, 120], autor: [2, 80], nome: [2, 80], link: 500
};
// O Cloudant devolve só 25 documentos por consulta quando não se informa o limite.
const LIMITE_CONSULTA = 5000;
const FORMATO_ID = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/;

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

/** Devolve o link limpo, null quando vazio ou undefined quando inválido. */
function linkValido(valor) {
    const t = texto(valor);
    if (!t) return null;
    if (t.length > LIMITES.link) return undefined;
    if (/^https?:\/\/[^\s/?#]+\.[^\s]+$/i.test(t) || /^asset:\/\/[\w-]+$/.test(t)) return t;
    return undefined;
}

// ---------- requisição ----------
function cabecalho(nome) {
    const valor = ((msg.req && msg.req.headers) || {})[nome];
    return Array.isArray(valor) ? String(valor[0] || '') : String(valor || '');
}

function parametro(nome) {
    const valor = ((msg.req && msg.req.query) || {})[nome];
    if (Array.isArray(valor)) return String(valor[0] || '').trim();
    return valor === undefined || valor === null ? '' : String(valor).trim();
}

/** Corpo JSON da requisição (guardado em msg.corpo, porque msg.payload muda a cada nó). */
function corpoDaRequisicao() {
    const p = msg.payload;
    return p && typeof p === 'object' && !Array.isArray(p) ? p : {};
}

function usuarioInformado() {
    return idDe(cabecalho('x-hub-usuario'));
}

function ehModeracao() {
    const chave = env.get('HUB_MODERACAO_TOKEN');
    return !!chave && cabecalho('x-hub-moderacao') === String(chave);
}

// ---------- Cloudant ----------
/** Prepara a consulta (Mango) para o nó "cloudantplus in" no modo query. */
function consultar(selector, campos) {
    msg.payload = { selector: selector, limit: LIMITE_CONSULTA };
    if (campos) msg.payload.fields = campos;
    return msg;
}

/** Documentos da resposta do Cloudant, nas duas formas que o nó pode devolver. */
function documentos(resposta) {
    if (Array.isArray(resposta)) return resposta.filter(Boolean);
    if (resposta && Array.isArray(resposta.docs)) return resposta.docs.filter(Boolean);
    if (resposta && resposta.result && Array.isArray(resposta.result.docs)) return resposta.result.docs.filter(Boolean);
    if (resposta && Array.isArray(resposta.rows)) {
        return resposta.rows.map(function (r) { return r && (r.doc || r); }).filter(Boolean);
    }
    return [];
}

function idAvaliacao(publicacaoId, usuarioId) {
    return 'avaliacao:' + publicacaoId + ':' + usuarioId;
}

// ---------- publicações ----------
/** Soma, total e a nota do usuário informado, por publicação. */
function totaisDeAvaliacao(avaliacoes, usuarioId) {
    const t = {};
    avaliacoes.forEach(function (a) {
        const nota = Number(a.nota);
        if (!(nota >= 1 && nota <= 5)) return;
        const chave = idDe(a.publicacaoId);
        const x = t[chave] || (t[chave] = { soma: 0, total: 0, minhaNota: null });
        x.soma += nota;
        x.total += 1;
        if (usuarioId && idDe(a.usuarioId) === usuarioId) x.minhaNota = nota;
    });
    return t;
}

/** A publicação tem o que o app precisa para mostrá-la? (documentos de outros testes ficam de fora) */
function publicacaoValida(p) {
    return !!p && FORMATO_ID.test(idDe(p._id)) && TIPOS.indexOf(p.tipo) >= 0 && AREAS.indexOf(p.area) >= 0 &&
        typeof p.titulo === 'string' && typeof p.descricao === 'string' && Number.isInteger(Number(p.ano));
}

/** Formato público de uma publicação (sem o id de quem publicou). */
function apresentar(p, totais, usuarioId) {
    const base = p.avaliacoesBase || {};
    const t = totais || { soma: 0, total: 0, minhaNota: null };
    const soma = (Number(base.soma) || 0) + t.soma;
    const total = (Number(base.total) || 0) + t.total;
    return {
        id: idDe(p._id),
        tipo: p.tipo,
        titulo: p.titulo,
        descricao: p.descricao,
        imagemLink: p.imagemLink || null,
        link: p.link || null,
        plataforma: PLATAFORMAS.indexOf(p.plataforma) >= 0 ? p.plataforma : 'outro',
        area: p.area,
        subarea: p.subarea || null,
        disciplina: p.disciplina || p.cadeira || '',
        curso: p.curso || '',
        instituicao: p.instituicao || '',
        ano: Number(p.ano),
        autores: Array.isArray(p.autores) ? p.autores.map(String) : [],
        media: total ? Math.round((soma / total) * 100) / 100 : 0,
        totalAvaliacoes: total,
        minhaNota: t.minhaNota,
        meu: !!usuarioId && idDe(p.usuarioId) === usuarioId,
        criadoEm: p.criadoEm || agora()
    };
}

function validarPublicacao(corpo) {
    const erros = [];
    const titulo = texto(corpo.titulo);
    const descricao = texto(corpo.descricao);
    const disciplina = texto(corpo.disciplina);
    const subareaInformada = texto(corpo.subarea);
    const subarea = subareaInformada ? subareaDe(corpo.area, subareaInformada) : null;
    const instituicao = texto(corpo.instituicao) || 'CTISM – UFSM';
    const curso = texto(corpo.curso);
    const ano = Number(corpo.ano);
    const anoAtual = new Date().getFullYear();
    const imagemLink = linkValido(corpo.imagemLink);
    const link = linkValido(corpo.link);
    const lista = Array.isArray(corpo.autores) ? corpo.autores : [corpo.autores];
    const autores = lista.map(texto).filter(Boolean);

    if (TIPOS.indexOf(corpo.tipo) < 0) erros.push('tipo: use ' + TIPOS.join(', '));
    if (!tamanhoOk(titulo, 'titulo')) erros.push('titulo: de 5 a 150 caracteres');
    if (!tamanhoOk(descricao, 'descricao')) erros.push('descricao: de 20 a 200 caracteres');
    if (AREAS.indexOf(corpo.area) < 0) erros.push('area: use ' + AREAS.join(', '));
    else if (subareaInformada && !subarea) erros.push('subarea: não pertence à área ' + corpo.area + ' (veja GET /GETsubareas)');
    if (!tamanhoOk(disciplina, 'disciplina')) erros.push('disciplina: de 2 a 150 caracteres');
    if (!tamanhoOk(instituicao, 'instituicao')) erros.push('instituicao: de 2 a 120 caracteres');
    if (!tamanhoOk(curso, 'curso')) erros.push('curso: até 120 caracteres');
    if (!(Number.isInteger(ano) && ano >= 1990 && ano <= anoAtual + 1)) erros.push('ano: entre 1990 e ' + (anoAtual + 1));
    if (imagemLink === undefined) erros.push('imagemLink: link inválido (use http:// ou https://)');
    if (link === undefined) erros.push('link: link inválido (use http:// ou https://)');
    if (!autores.length || autores.length > 10 || !autores.every(function (a) { return tamanhoOk(a, 'autor'); })) {
        erros.push('autores: de 1 a 10 nomes, cada um com 2 a 80 caracteres');
    }

    return {
        erros: erros,
        dados: {
            tipo: corpo.tipo, titulo: titulo, descricao: descricao, area: corpo.area, subarea: subarea, disciplina: disciplina,
            instituicao: instituicao, curso: curso, ano: ano, imagemLink: imagemLink || null,
            link: link || null, autores: autores,
            plataforma: PLATAFORMAS.indexOf(corpo.plataforma) >= 0 ? corpo.plataforma : 'outro'
        }
    };
}

// ---------- usuários ----------
function usuarioPublico(u) {
    return { id: idDe(u._id), nome: u.nome, curso: u.curso || '', criadoEm: u.criadoEm || agora() };
}

function validarUsuario(corpo) {
    const nome = texto(corpo.nome);
    const curso = texto(corpo.curso);
    const erros = [];
    if (!tamanhoOk(nome, 'nome')) erros.push('nome: de 2 a 80 caracteres');
    if (!tamanhoOk(curso, 'curso')) erros.push('curso: até 120 caracteres');
    return { erros: erros, nome: nome, curso: curso };
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
        detalhes: ['Cadastre-se em POST /POSTusuario e envie o id recebido no cabeçalho X-Hub-Usuario']
    });
}

function naoEncontrado(oque) {
    return responder(404, { erro: oque + ' não encontrada', detalhes: [] });
}

function proibido(motivo) {
    return responder(403, { erro: motivo, detalhes: [] });
}
