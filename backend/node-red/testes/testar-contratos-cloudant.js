#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const raiz = path.join(__dirname, '..', 'contratos');
const carregar = (nome) => JSON.parse(fs.readFileSync(path.join(raiz, nome), 'utf8'));

const api = carregar('projeto-api.schema.json');
const criacao = carregar('projeto-criacao.schema.json');
const cloudant = carregar('projeto-cloudant.schema.json');

function exige(condicao, mensagem) {
    assert.ok(condicao, mensagem);
}

console.log('Hub Acadêmico · contratos de publicação');

exige(api.type === 'object', 'contrato público deve ser objeto');
exige(criacao.type === 'object', 'corpo POST deve ser objeto');
exige(cloudant.type === 'object', 'documento Cloudant deve ser objeto');

[
    'id', 'tipo', 'titulo', 'descricao', 'area', 'subarea', 'cadeira',
    'curso', 'instituicao', 'ano', 'autores', 'nota', 'quant',
    'minhaNota', 'meu', 'criadoEm'
].forEach((campo) => exige(api.properties[campo], 'campo público ausente: ' + campo));

['tipo', 'titulo', 'descricao', 'area', 'cadeira', 'ano', 'autores']
    .forEach((campo) => exige(criacao.required.includes(campo), 'campo obrigatório do POST ausente: ' + campo));

['_id', 'tipoDocumento', 'id', 'usuarioId', 'criadoEm']
    .forEach((campo) => exige(cloudant.required.includes(campo), 'campo Cloudant obrigatório ausente: ' + campo));

exige(cloudant.properties._id.pattern.includes('projeto:'), '_id precisa usar o prefixo projeto:');
exige(cloudant.properties.tipoDocumento.const === 'projeto', 'tipoDocumento precisa ser projeto');

['_id', '_rev', 'usuarioId'].forEach((campo) => {
    exige(!api.properties[campo], 'campo interno não pode aparecer na API: ' + campo);
});

['nota', 'quant', 'minhaNota', 'meu'].forEach((campo) => {
    exige(!cloudant.properties[campo], 'campo derivado não deve ser persistido no documento base: ' + campo);
});

exige(api.properties.cadeiraId, 'campo legado cadeiraId deve continuar documentado na resposta');
exige(cloudant.properties.cadeira, 'documento Cloudant deve armazenar snapshot textual da cadeira');
exige(!cloudant.properties.cadeiras, 'não deve haver dependência de coleção de catálogo');

console.log('✓ contratos JSON válidos e legíveis');
console.log('✓ campos públicos e internos separados');
console.log('✓ metadados de avaliação permanecem fora do documento base');
console.log('✓ catálogo acadêmico não virou dependência Cloudant');
