import React, { useState } from 'react';
import { HomeScreen } from './components/screens/HomeScreen';
import { SearchScreen } from './components/screens/SearchScreen';
import { DetailScreen } from './components/screens/DetailScreen';
import { CreateScreen } from './components/screens/CreateScreen';
import { IPhoneFrame } from './components/IPhoneFrame';
import { SwiftCodeViewer } from './components/SwiftCodeViewer';
import { DesignTokensPanel } from './components/DesignTokensPanel';
import { INITIAL_ITEMS } from './data/mockData';
import { AcademicItem, ScreenId } from './types';
import {
  Smartphone,
  LayoutGrid,
  Code2,
  Palette,
  Sparkles,
  ExternalLink,
  Flame,
} from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState<'code' | 'interactive' | 'grid' | 'tokens'>('code');
  const [selectedSwiftFilename, setSelectedSwiftFilename] = useState<string>('CTIA_Combined.swift');
  const [currentScreen, setCurrentScreen] = useState<ScreenId>('inicio');
  const [items, setItems] = useState<AcademicItem[]>(INITIAL_ITEMS);
  const [selectedItem, setSelectedItem] = useState<AcademicItem>(INITIAL_ITEMS[0]);
  const [searchQuery, setSearchQuery] = useState('ruído');

  const openSwiftFileForScreen = (screen: ScreenId) => {
    const fileMap: Record<ScreenId, string> = {
      inicio: 'HomeView.swift',
      busca: 'SearchFilterView.swift',
      visualizacao: 'DetailView.swift',
      cadastro: 'CreateItemView.swift',
    };
    setSelectedSwiftFilename(fileMap[screen]);
    setActiveTab('code');
  };

  const handleAddItem = (newItem: AcademicItem) => {
    setItems((prev) => [newItem, ...prev]);
    setSelectedItem(newItem);
  };

  const renderActiveScreen = () => {
    switch (currentScreen) {
      case 'inicio':
        return (
          <HomeScreen
            onNavigate={(screen) => setCurrentScreen(screen)}
            onSearch={(query) => {
              setSearchQuery(query);
              setCurrentScreen('busca');
            }}
          />
        );
      case 'busca':
        return (
          <SearchScreen
            items={items}
            initialQuery={searchQuery}
            onSelectItem={(item) => setSelectedItem(item)}
            onNavigate={(screen) => setCurrentScreen(screen)}
          />
        );
      case 'visualizacao':
        return (
          <DetailScreen
            item={selectedItem}
            onNavigate={(screen) => setCurrentScreen(screen)}
          />
        );
      case 'cadastro':
        return (
          <CreateScreen
            onNavigate={(screen) => setCurrentScreen(screen)}
            onAddItem={handleAddItem}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col font-sans selection:bg-[#21376B] selection:text-white">
      {/* Top Bar Oficial UFSM / HackaTruck MakerSpace */}
      <header className="bg-[#142140] border-b border-slate-800 text-white sticky top-0 z-50 shadow-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-[#21376B] border border-[#CC8F00] flex items-center justify-center text-[#CC8F00] shadow-sm">
              <Flame className="w-6 h-6 fill-current" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="font-bold text-base tracking-tight text-white">
                  CTIA · Repositório Acadêmico do CTISM
                </span>
                <span className="text-[11px] font-semibold bg-[#CC8F00] text-[#142140] px-2 py-0.5 rounded-full uppercase tracking-wider">
                  Swift / SwiftUI
                </span>
              </div>
              <p className="text-xs text-slate-300">
                Design System oficial de ufsm.br · HackaTruck MakerSpace · Deploy 26.1
              </p>
            </div>
          </div>

          {/* Navegação entre Visualizadores */}
          <div className="flex items-center bg-slate-950/70 p-1 rounded-xl border border-slate-800/80">
            <button
              type="button"
              onClick={() => setActiveTab('code')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center space-x-1.5 transition-all cursor-pointer ${
                activeTab === 'code'
                  ? 'bg-[#21376B] text-white shadow-xs border border-[#CC8F00]/50'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Code2 className="w-3.5 h-3.5 text-[#FFC107]" />
              <span>Código Swift (.swift)</span>
              <span className="text-[10px] bg-[#CC8F00]/30 text-[#FFC107] px-1.5 py-0.2 rounded font-mono ml-1">
                19
              </span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('interactive')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center space-x-1.5 transition-all cursor-pointer ${
                activeTab === 'interactive'
                  ? 'bg-[#21376B] text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span>Simulador iOS</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('grid')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center space-x-1.5 transition-all cursor-pointer ${
                activeTab === 'grid'
                  ? 'bg-[#21376B] text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              <span>4 Telas (Figma)</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('tokens')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center space-x-1.5 transition-all cursor-pointer ${
                activeTab === 'tokens'
                  ? 'bg-[#21376B] text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Palette className="w-3.5 h-3.5" />
              <span>Design System</span>
            </button>
          </div>
        </div>
      </header>

      {/* Conteúdo Principal */}
      <main className={`flex-1 ${activeTab === 'grid' ? 'max-w-[1440px]' : 'max-w-7xl'} w-full mx-auto p-4 sm:p-6 flex flex-col justify-center`}>
        {/* MODO 1: SIMULADOR INTERATIVO */}
        {activeTab === 'interactive' && (
          <div className="flex flex-col lg:flex-row items-center justify-center gap-8 py-4">
            {/* Simulador de iPhone Interativo */}
            <div className="shrink-0">
              <IPhoneFrame
                screenTitle={
                  currentScreen === 'inicio'
                    ? '1. Início (Acesso rápido em ordem de caracteres)'
                    : currentScreen === 'busca'
                    ? '2. Busca e Filtros (Funil + Checkboxes 3 -> 16 chars)'
                    : currentScreen === 'visualizacao'
                    ? '3. Visualização (IoT ao vivo e Avaliações)'
                    : '4. Cadastro (Formulário com limite 200 chars)'
                }
                badgeNumber={
                  currentScreen === 'inicio'
                    ? 1
                    : currentScreen === 'busca'
                    ? 2
                    : currentScreen === 'visualizacao'
                    ? 3
                    : 4
                }
              >
                {renderActiveScreen()}
              </IPhoneFrame>
            </div>

            {/* Painel Lateral com Atalhos e Informações */}
            <div className="w-full max-w-md space-y-4">
              <div className="bg-slate-950 p-5 rounded-2xl border border-slate-800 shadow-lg space-y-4">
                <div className="flex items-center space-x-2 text-[#CC8F00] font-bold text-xs uppercase tracking-wider">
                  <Sparkles className="w-4 h-4" />
                  <span>Navegação Rápida entre Telas</span>
                </div>

                <p className="text-xs text-slate-400 leading-relaxed">
                  Alterne diretamente entre as 4 telas desenvolvidas em SwiftUI ou interaja diretamente com o iPhone ao lado.
                </p>

                <div className="grid grid-cols-2 gap-2.5">
                  <button
                    type="button"
                    onClick={() => setCurrentScreen('inicio')}
                    className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                      currentScreen === 'inicio'
                        ? 'bg-[#21376B] border-[#CC8F00] text-white shadow-md'
                        : 'bg-slate-900 border-slate-800 text-slate-300 hover:bg-slate-800'
                    }`}
                  >
                    <div className="text-[10px] uppercase font-bold text-[#FFC107]">Tela 1</div>
                    <div className="font-semibold text-xs mt-0.5">Início</div>
                    <div className="text-[10.5px] text-slate-400">8 → 22 caracteres</div>
                  </button>

                  <button
                    type="button"
                    onClick={() => setCurrentScreen('busca')}
                    className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                      currentScreen === 'busca'
                        ? 'bg-[#21376B] border-[#CC8F00] text-white shadow-md'
                        : 'bg-slate-900 border-slate-800 text-slate-300 hover:bg-slate-800'
                    }`}
                  >
                    <div className="text-[10px] uppercase font-bold text-[#FFC107]">Tela 2</div>
                    <div className="font-semibold text-xs mt-0.5">Busca e Filtros</div>
                    <div className="text-[10.5px] text-slate-400">Checkboxes raio 5 pt</div>
                  </button>

                  <button
                    type="button"
                    onClick={() => setCurrentScreen('visualizacao')}
                    className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                      currentScreen === 'visualizacao'
                        ? 'bg-[#21376B] border-[#CC8F00] text-white shadow-md'
                        : 'bg-slate-900 border-slate-800 text-slate-300 hover:bg-slate-800'
                    }`}
                  >
                    <div className="text-[10px] uppercase font-bold text-[#FFC107]">Tela 3</div>
                    <div className="font-semibold text-xs mt-0.5">Visualização</div>
                    <div className="text-[10.5px] text-slate-400">IoT 82 dB e Avaliação</div>
                  </button>

                  <button
                    type="button"
                    onClick={() => setCurrentScreen('cadastro')}
                    className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                      currentScreen === 'cadastro'
                        ? 'bg-[#21376B] border-[#CC8F00] text-white shadow-md'
                        : 'bg-slate-900 border-slate-800 text-slate-300 hover:bg-slate-800'
                    }`}
                  >
                    <div className="text-[10px] uppercase font-bold text-[#FFC107]">Tela 4</div>
                    <div className="font-semibold text-xs mt-0.5">Cadastro</div>
                    <div className="text-[10.5px] text-slate-400">Contador 200 chars</div>
                  </button>
                </div>
              </div>

              {/* Card de Regras Implementadas */}
              <div className="bg-slate-950 p-5 rounded-2xl border border-slate-800 shadow-lg space-y-3">
                <div className="text-xs font-bold text-white flex items-center justify-between">
                  <span>Regras do Design System de ufsm.br</span>
                  <span className="text-emerald-400 text-[11px] font-semibold">100% Implementadas</span>
                </div>
                <ul className="text-xs text-slate-400 space-y-2">
                  <li className="flex items-start space-x-2">
                    <span className="text-[#CC8F00] font-bold">▪</span>
                    <span><strong>Cabeçalho oficial:</strong> Azul UFSM (#21376B), brasão e filete dourado de 2 pt.</span>
                  </li>
                  <li className="flex items-start space-x-2">
                    <span className="text-[#CC8F00] font-bold">▪</span>
                    <span><strong>Raios de curvatura:</strong> 10 pt em botões/inputs, 14 pt em cards, 16 pt no menu.</span>
                  </li>
                  <li className="flex items-start space-x-2">
                    <span className="text-[#CC8F00] font-bold">▪</span>
                    <span><strong>Ordem crescente:</strong> 8 → 22 chars no menu, 3 → 16 chars nos filtros.</span>
                  </li>
                  <li className="flex items-start space-x-2">
                    <span className="text-[#CC8F00] font-bold">▪</span>
                    <span><strong>Resumo:</strong> limitado a 200 caracteres com contador dinâmico e validação.</span>
                  </li>
                </ul>

                <div className="flex gap-2 mt-2">
                  <button
                    type="button"
                    onClick={() => openSwiftFileForScreen(currentScreen)}
                    className="flex-1 py-2.5 bg-[#21376B] hover:bg-[#1a2d58] border border-[#CC8F00]/50 text-xs font-semibold text-white rounded-xl flex items-center justify-center space-x-1.5 transition-colors cursor-pointer shadow-md"
                  >
                    <Code2 className="w-4 h-4 text-[#FFC107]" />
                    <span>Ver Swift Desta Tela</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedSwiftFilename('CTIA_Combined.swift');
                      setActiveTab('code');
                    }}
                    className="py-2.5 px-3 bg-slate-900 hover:bg-slate-800 border border-slate-700 text-xs font-semibold text-slate-200 rounded-xl flex items-center justify-center space-x-1 transition-colors cursor-pointer"
                    title="Ver projeto Swift unificado"
                  >
                    <span>Todos</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* MODO 2: GRID DAS 4 TELAS LADO A LADO (FIGMA / APRESENTAÇÃO) */}
        {activeTab === 'grid' && (
          <div className="space-y-6 py-2 max-w-[1360px] mx-auto w-full">
            <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 flex items-center justify-between">
              <div>
                <h2 className="text-sm font-bold text-white flex items-center gap-2">
                  <span>Visualização das 4 Telas do App iOS (SwiftUI)</span>
                  <span className="text-[10px] bg-[#CC8F00]/20 text-[#FFC107] px-2 py-0.5 rounded font-mono">
                    HackaTruck MakerSpace · Deploy 26.1
                  </span>
                </h2>
                <p className="text-xs text-slate-400">
                  Visão simultânea das 4 telas do protótipo em escala idêntica ao painel do Figma
                </p>
              </div>
              <div className="flex items-center space-x-2">
                <button
                  type="button"
                  onClick={() => {
                    setSelectedSwiftFilename('CTIA_Combined.swift');
                    setActiveTab('code');
                  }}
                  className="px-3.5 py-1.5 bg-slate-800 border border-slate-700 text-white text-xs font-semibold rounded-lg hover:bg-slate-700 transition-colors cursor-pointer flex items-center space-x-1"
                >
                  <Code2 className="w-3.5 h-3.5 text-[#FFC107]" />
                  <span>Ver Código Swift</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('interactive')}
                  className="px-3.5 py-1.5 bg-[#21376B] text-white text-xs font-semibold rounded-lg hover:bg-[#1a2d58] transition-colors cursor-pointer"
                >
                  Abrir Simulador Interativo
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 items-start justify-items-center">
              {/* Tela 1: Início */}
              <div className="flex flex-col items-center space-y-2 w-full">
                <IPhoneFrame screenTitle="1. Início" badgeNumber={1} compact={true}>
                  <HomeScreen
                    onNavigate={(screen) => setCurrentScreen(screen)}
                    onSearch={(q) => setSearchQuery(q)}
                  />
                </IPhoneFrame>
                <button
                  type="button"
                  onClick={() => openSwiftFileForScreen('inicio')}
                  className="px-3 py-1 bg-slate-950 hover:bg-slate-800 border border-slate-800 hover:border-[#CC8F00]/50 rounded-lg text-[11px] font-mono text-slate-300 flex items-center space-x-1.5 transition-colors cursor-pointer"
                >
                  <Code2 className="w-3 h-3 text-[#FFC107]" />
                  <span>HomeView.swift</span>
                </button>
              </div>

              {/* Tela 2: Busca e filtros */}
              <div className="flex flex-col items-center space-y-2 w-full">
                <IPhoneFrame screenTitle="2. Busca e filtros" badgeNumber={2} compact={true}>
                  <SearchScreen
                    items={items}
                    initialQuery="ruído"
                    onSelectItem={(item) => setSelectedItem(item)}
                    onNavigate={(screen) => setCurrentScreen(screen)}
                  />
                </IPhoneFrame>
                <button
                  type="button"
                  onClick={() => openSwiftFileForScreen('busca')}
                  className="px-3 py-1 bg-slate-950 hover:bg-slate-800 border border-slate-800 hover:border-[#CC8F00]/50 rounded-lg text-[11px] font-mono text-slate-300 flex items-center space-x-1.5 transition-colors cursor-pointer"
                >
                  <Code2 className="w-3 h-3 text-[#FFC107]" />
                  <span>SearchFilterView.swift</span>
                </button>
              </div>

              {/* Tela 3: Visualização */}
              <div className="flex flex-col items-center space-y-2 w-full">
                <IPhoneFrame screenTitle="3. Visualização" badgeNumber={3} compact={true}>
                  <DetailScreen
                    item={selectedItem}
                    onNavigate={(screen) => setCurrentScreen(screen)}
                  />
                </IPhoneFrame>
                <button
                  type="button"
                  onClick={() => openSwiftFileForScreen('visualizacao')}
                  className="px-3 py-1 bg-slate-950 hover:bg-slate-800 border border-slate-800 hover:border-[#CC8F00]/50 rounded-lg text-[11px] font-mono text-slate-300 flex items-center space-x-1.5 transition-colors cursor-pointer"
                >
                  <Code2 className="w-3 h-3 text-[#FFC107]" />
                  <span>DetailView.swift</span>
                </button>
              </div>

              {/* Tela 4: Cadastro */}
              <div className="flex flex-col items-center space-y-2 w-full">
                <IPhoneFrame screenTitle="4. Cadastro" badgeNumber={4} compact={true}>
                  <CreateScreen
                    onNavigate={(screen) => setCurrentScreen(screen)}
                    onAddItem={handleAddItem}
                  />
                </IPhoneFrame>
                <button
                  type="button"
                  onClick={() => openSwiftFileForScreen('cadastro')}
                  className="px-3 py-1 bg-slate-950 hover:bg-slate-800 border border-slate-800 hover:border-[#CC8F00]/50 rounded-lg text-[11px] font-mono text-slate-300 flex items-center space-x-1.5 transition-colors cursor-pointer"
                >
                  <Code2 className="w-3 h-3 text-[#FFC107]" />
                  <span>CreateItemView.swift</span>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* MODO 3: VISUALIZADOR DE CÓDIGO SWIFT */}
        {activeTab === 'code' && (
          <div className="py-2">
            <SwiftCodeViewer
              initialFile={selectedSwiftFilename}
              onNavigateToPreview={(screen) => {
                setCurrentScreen(screen);
                setActiveTab('interactive');
              }}
            />
          </div>
        )}

        {/* MODO 4: DESIGN TOKENS UFSM */}
        {activeTab === 'tokens' && (
          <div className="py-2">
            <DesignTokensPanel />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-slate-950 border-t border-slate-800/80 py-4 text-center text-xs text-slate-500">
        <p>
          CTIA · Repositório acadêmico do CTISM · HackaTruck MakerSpace · UFSM
        </p>
      </footer>
    </div>
  );
}
