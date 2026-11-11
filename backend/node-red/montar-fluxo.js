#!/usr/bin/env node
// =====================================================================
// Copia src/api.js e src/seed.js para dentro de hub-academico-flows.json
// (nós "API" e "Dados de exemplo"). Rode depois de editar o código em src/
// e reimporte o fluxo no Node-RED (Import › Replace).
//
// Uso:  node backend/node-red/montar-fluxo.js
// =====================================================================
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const ARQUIVO = path.join(__dirname, 'hub-academico-flows.json');
const FONTES = { 'API': 'src/api.js', 'Dados de exemplo': 'src/seed.js' };

const fluxo = JSON.parse(fs.readFileSync(ARQUIVO, 'utf8'));
const alterados = [];

Object.keys(FONTES).forEach(function (nome) {
    const no = fluxo.find(function (n) { return n.type === 'function' && n.name === nome; });
    if (!no) throw new Error('Nó "' + nome + '" não encontrado em ' + path.basename(ARQUIVO));
    const codigo = fs.readFileSync(path.join(__dirname, FONTES[nome]), 'utf8');
    if (no.func !== codigo) {
        no.func = codigo;
        alterados.push(FONTES[nome]);
    }
});

// Cada rota da API ("case 'GET /hub/...'") precisa de um nó "http in" no fluxo, e vice-versa.
const api = fluxo.find(function (n) { return n.type === 'function' && n.name === 'API'; });
const casos = Array.from(api.func.matchAll(/case '([A-Z]+) (\/hub\/[^']*)'/g), function (m) { return m[1] + ' ' + m[2]; });
const rotas = fluxo.filter(function (n) { return n.type === 'http in'; })
    .map(function (n) { return n.method.toUpperCase() + ' ' + n.url; });
const semNo = casos.filter(function (c) { return rotas.indexOf(c) < 0; });
const semCase = rotas.filter(function (r) { return casos.indexOf(r) < 0; });

fs.writeFileSync(ARQUIVO, JSON.stringify(fluxo, null, 4) + '\n');
console.log(alterados.length
    ? 'Atualizado em ' + path.basename(ARQUIVO) + ': ' + alterados.join(', ')
    : path.basename(ARQUIVO) + ' já estava igual a src/.');
if (semNo.length) console.log('Atenção: rota sem nó "http in" no fluxo (crie no editor do Node-RED): ' + semNo.join(', '));
if (semCase.length) console.log('Atenção: nó "http in" sem "case" em src/api.js: ' + semCase.join(', '));
