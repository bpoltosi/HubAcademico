import React from 'react';
import { Palette, Type, Sparkles, CheckSquare, Layers } from 'lucide-react';

export const DesignTokensPanel: React.FC = () => {
  const colors = [
    { name: 'Azul UFSM', hex: '#21376B', desc: 'cabeçalho, títulos, botão primário' },
    { name: 'Azul secundário', hex: '#204C90', desc: 'ícones e rótulos do menu' },
    { name: 'Azul profundo', hex: '#142140', desc: 'fundos de destaque e IoT' },
    { name: 'Dourado', hex: '#CC8F00', desc: 'filete do cabeçalho de 2 pt, marcadores' },
    { name: 'Âmbar', hex: '#FFC107', desc: 'estrelas de avaliação' },
    { name: 'Texto', hex: '#1C1C1C', desc: '#4C4C4C e #6C757D nos níveis 2 e 3' },
    { name: 'Fundo', hex: '#F1F4F9', desc: 'bordas #D3D7E1 · superfícies #FFFFFF' },
  ];

  const typography = [
    { role: 'Saudação / título de tela', size: '25 pt', weight: '500 (Medium)', sample: 'Olá, estudante!' },
    { role: 'Título de conteúdo', size: '21 pt', weight: '500 (Medium)', sample: 'Monitor IoT de ruído...' },
    { role: 'Item do menu', size: '17 pt', weight: '500 (Medium)', sample: 'Projetos, Banco de provas...' },
    { role: 'Texto corrido', size: '14-15 pt', weight: '400 (Regular)', sample: 'Explore e compartilhe...' },
    { role: 'Título de seção (caixa alta)', size: '12,5 pt', weight: '500 (Medium)', sample: '| ACESSO RÁPIDO' },
    { role: 'Legendas e rótulos', size: '10,5-12,5 pt', weight: '400 (Regular)', sample: '37 avaliações · 2026' },
  ];

  const iconMapping = [
    { name: 'Projetos', web: 'fa-lightbulb', swift: 'lightbulb.fill' },
    { name: 'Banco de provas', web: 'fa-clipboard-check', swift: 'checklist' },
    { name: 'Trabalhos acadêmicos', web: 'fa-graduation-cap', swift: 'graduationcap.fill' },
    { name: 'Material complementar', web: 'fa-book-open', swift: 'book.fill' },
    { name: 'Cadastre o seu projeto', web: 'fa-plus-circle', swift: 'plus.circle.fill' },
    { name: 'Filtro', web: 'fa-filter', swift: 'line.3.horizontal.decrease.circle' },
    { name: 'Busca IA', web: 'fa-magic', swift: 'wand.and.stars' },
    { name: 'Avaliação', web: 'fa-star', swift: 'star.fill' },
  ];

  const rules = [
    'Cabeçalho igual ao do site: azul UFSM, brasão e filete dourado de 2 pt.',
    'Raios: 10 pt em campos e botões, 14 pt em cards, 16 pt no menu.',
    'Margem lateral de 16 pt, grade de 8 pt e área de toque mínima de 44 pt.',
    'Ordem crescente de caracteres no menu (8 -> 22) e nos filtros (3 -> 16).',
    'Resumo limitado a 200 caracteres, com contador no cadastro.',
    'Checkbox com raio de 5 pt e ativo em azul UFSM, como no Bootstrap do site.',
  ];

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-6">
      <div className="flex items-center space-x-3 border-b border-slate-100 pb-4">
        <div className="w-10 h-10 rounded-xl bg-[#21376B] text-white flex items-center justify-center font-bold">
          <Palette className="w-5 h-5" />
        </div>
        <div>
          <h2 className="text-lg font-bold text-[#1C1C1C]">
            Design System do CTISM / UFSM · Tokens & Regras
          </h2>
          <p className="text-xs text-slate-500">
            Especificações oficiais do tema ufsm.br aplicadas ao SwiftUI no HackaTruck MakerSpace
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Coluna 1: Cores do Site */}
        <div className="space-y-3">
          <div className="flex items-center space-x-1.5 text-xs font-bold text-[#21376B] uppercase tracking-wider">
            <Palette className="w-4 h-4 text-[#CC8F00]" />
            <span>Cores do Site</span>
          </div>
          <div className="space-y-2">
            {colors.map((c) => (
              <div key={c.hex} className="flex items-center space-x-2.5 p-1.5 rounded-lg hover:bg-slate-50">
                <div
                  className="w-7 h-7 rounded-md shrink-0 border border-black/10 shadow-xs"
                  style={{ backgroundColor: c.hex }}
                />
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-slate-800">
                    {c.name} <code className="text-[11px] text-slate-500">{c.hex}</code>
                  </div>
                  <div className="text-[10.5px] text-slate-500 truncate">{c.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Coluna 2: Tipografia Rawline */}
        <div className="space-y-3">
          <div className="flex items-center space-x-1.5 text-xs font-bold text-[#21376B] uppercase tracking-wider">
            <Type className="w-4 h-4 text-[#CC8F00]" />
            <span>Tipografia (Rawline)</span>
          </div>
          <div className="space-y-2.5">
            {typography.map((t) => (
              <div key={t.role} className="p-2 rounded-lg bg-slate-50 border border-slate-100">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-700">{t.role}</span>
                  <span className="text-[11px] font-mono text-[#204C90]">{t.size}</span>
                </div>
                <div className="text-[10.5px] text-slate-500">{t.weight}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Coluna 3: Ícones Site -> SwiftUI */}
        <div className="space-y-3">
          <div className="flex items-center space-x-1.5 text-xs font-bold text-[#21376B] uppercase tracking-wider">
            <Sparkles className="w-4 h-4 text-[#CC8F00]" />
            <span>Ícones: Site → SwiftUI</span>
          </div>
          <div className="space-y-1.5">
            {iconMapping.map((icon) => (
              <div
                key={icon.name}
                className="p-1.5 rounded-lg bg-slate-50 border border-slate-100 flex items-center justify-between text-xs"
              >
                <span className="font-medium text-slate-700 truncate">{icon.name}</span>
                <code className="text-[11px] font-mono text-[#21376B] bg-[#21376B]/10 px-1.5 py-0.5 rounded">
                  {icon.swift}
                </code>
              </div>
            ))}
          </div>
        </div>

        {/* Coluna 4: Componentes e Regras */}
        <div className="space-y-3">
          <div className="flex items-center space-x-1.5 text-xs font-bold text-[#21376B] uppercase tracking-wider">
            <CheckSquare className="w-4 h-4 text-[#CC8F00]" />
            <span>Componentes e Regras</span>
          </div>
          <div className="space-y-2">
            {rules.map((rule, idx) => (
              <div key={idx} className="flex items-start space-x-2 text-xs text-slate-600">
                <span className="text-emerald-600 font-bold mt-0.5">✓</span>
                <span className="leading-snug">{rule}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
