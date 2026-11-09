import test from 'node:test';
import assert from 'node:assert/strict';
import {
  verifyCharacterOrdering,
  validateAcademicItem,
  filterAcademicItems,
  formatRatingBR,
  AcademicItem,
} from './academicCatalog';

test('menu character ordering strictly follows 8 -> 22 rule', () => {
  const menuItems = [
    'Projetos',              // 8
    'Banco de provas',       // 15
    'Trabalhos acadêmicos',  // 20
    'Material complementar', // 21
    'Cadastre o seu projeto' // 22
  ];

  assert.equal(verifyCharacterOrdering(menuItems), true);
  assert.equal(menuItems[0].length, 8);
  assert.equal(menuItems[4].length, 22);

  // Check out of order fails
  assert.equal(verifyCharacterOrdering(['Trabalhos acadêmicos', 'Projetos']), false);
});

test('filters character ordering strictly follows 3 -> 16 rule', () => {
  const filterLabels = [
    'Ano',              // 3
    'Área',             // 4
    'Autor',            // 5
    'Curso',            // 5
    'Título',           // 6
    'Matéria',          // 7
    'Melhor avaliação'  // 16
  ];

  assert.equal(verifyCharacterOrdering(filterLabels), true);
  assert.equal(filterLabels[0].length, 3);
  assert.equal(filterLabels[filterLabels.length - 1].length, 16);
});

test('validates summary character limit up to 200 characters', () => {
  const validItem: Partial<AcademicItem> = {
    titulo: 'Monitor IoT de ruído nas oficinas do CTISM',
    resumo: 'Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas.',
    area: 'Engenharias',
    materia: 'Higiene Ocupacional',
  };

  const result = validateAcademicItem(validItem);
  assert.equal(result.valid, true);
  assert.equal(result.charCount <= 200, true);
  assert.equal(result.charCount, 176);

  // Exceeding 200 characters
  const longText = 'A'.repeat(201);
  const invalidResult = validateAcademicItem({ ...validItem, resumo: longText });
  assert.equal(invalidResult.valid, false);
  assert.match(invalidResult.errors.resumo, /excede o limite de 200/);
});

test('filters academic items by text query and rating', () => {
  const sampleItems: AcademicItem[] = [
    {
      id: '1',
      tipo: 'projeto',
      titulo: 'Monitor IoT de ruído nas oficinas do CTISM',
      resumo: 'Protótipo com ESP32 e sensor de som que mede o ruído...',
      autor: 'Ana Clara Machado e Lucas Ferreira',
      area: 'Engenharias',
      materia: 'Higiene Ocupacional',
      curso: 'Téc. Segurança do Trabalho',
      instituicao: 'CTISM - UFSM',
      ano: 2026,
      avaliacao: 4.8,
      totalAvaliacoes: 37,
    },
    {
      id: '2',
      tipo: 'trabalho',
      titulo: 'Dosimetria de ruído na oficina de soldagem',
      resumo: 'Estudo prático de ruído contínuo...',
      autor: 'Pedro Santos',
      area: 'Engenharias',
      materia: 'Higiene Ocupacional',
      curso: 'Téc. Mecânica',
      instituicao: 'CTISM - UFSM',
      ano: 2026,
      avaliacao: 4.6,
      totalAvaliacoes: 21,
    },
    {
      id: '3',
      tipo: 'prova',
      titulo: 'Prova 1 - Circuitos Elétricos',
      resumo: 'Avaliação teórica e prática',
      autor: 'Prof. Silva',
      area: 'Engenharias',
      materia: 'Eletrotécnica',
      curso: 'Téc. Eletrotécnica',
      instituicao: 'CTISM - UFSM',
      ano: 2025,
      avaliacao: 4.0,
      totalAvaliacoes: 12,
    },
  ];

  // Search 'ruído'
  const filteredByRuido = filterAcademicItems(sampleItems, { termoBusca: 'ruído' });
  assert.equal(filteredByRuido.length, 2);

  // Best rating >= 4.5
  const bestRatings = filterAcademicItems(sampleItems, { melhorAvaliacao: true });
  assert.equal(bestRatings.length, 2);

  // Year filter 2025
  const year2025 = filterAcademicItems(sampleItems, { ano: 2025 });
  assert.equal(year2025.length, 1);
  assert.equal(year2025[0].id, '3');
});

test('formats rating to Brazilian decimal comma', () => {
  assert.equal(formatRatingBR(4.8), '4,8');
  assert.equal(formatRatingBR(4.6), '4,6');
  assert.equal(formatRatingBR(5.0), '5,0');
});
