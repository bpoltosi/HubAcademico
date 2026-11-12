// 3) monta a lista no formato do app, aplica os filtros e ordena.
const usuarioId = usuarioInformado();
const totais = totaisDeAvaliacao(documentos(msg.payload), usuarioId);
let lista = (msg.publicacoes || []).filter(publicacaoValida).map(function (p) {
    return apresentar(p, totais[idDe(p._id)], usuarioId);
});

const contem = function (valor, procurado) { return normalizar(valor).indexOf(normalizar(procurado)) >= 0; };
const tipo = parametro('tipo');
const ano = parametro('ano');
const area = parametro('area');
const subarea = parametro('subarea');
const curso = parametro('curso');
const disciplina = parametro('disciplina') || parametro('cadeira');
const titulo = parametro('titulo');
const autor = parametro('autor');
const termos = normalizar(parametro('q')).split(/\s+/).filter(function (x) { return x.length >= 2; });

if (tipo) lista = lista.filter(function (p) { return p.tipo === tipo; });
if (ano) lista = lista.filter(function (p) { return String(p.ano) === ano; });
if (area) lista = lista.filter(function (p) { return p.area === area; });
if (subarea) lista = lista.filter(function (p) { return normalizar(p.subarea) === normalizar(subarea); });
if (curso) lista = lista.filter(function (p) { return p.curso === curso; });
if (disciplina) lista = lista.filter(function (p) { return contem(p.disciplina, disciplina); });
if (titulo) lista = lista.filter(function (p) { return contem(p.titulo, titulo); });
if (autor) lista = lista.filter(function (p) { return p.autores.some(function (n) { return contem(n, autor); }); });
if (termos.length) {
    lista = lista.filter(function (p) {
        const alvo = normalizar([p.titulo, p.descricao, p.disciplina, p.subarea, p.curso, p.autores.join(' ')].join(' '));
        return termos.every(function (x) { return alvo.indexOf(x) >= 0; });
    });
}

if (parametro('ordem') === 'media') {
    lista.sort(function (a, b) { return (b.media - a.media) || (b.totalAvaliacoes - a.totalAvaliacoes); });
} else {
    lista.sort(function (a, b) { return String(b.criadoEm).localeCompare(String(a.criadoEm)); });
}
const limite = parseInt(parametro('limite'), 10);
if (limite > 0) lista = lista.slice(0, limite);

node.status({ fill: 'green', shape: 'dot', text: lista.length + ' publicações' });
return responder(200, lista);
