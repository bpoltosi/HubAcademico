import React, { useState, useMemo } from 'react';
import { SWIFT_FILES, SwiftFile } from '../data/swiftCode';
import {
  Copy,
  Check,
  Download,
  FileCode,
  Apple,
  Terminal,
  Archive,
  Search,
  Sparkles,
  ExternalLink,
  Layers,
  Code2
} from 'lucide-react';
import JSZip from 'jszip';

interface SwiftCodeViewerProps {
  initialFile?: string;
  onNavigateToPreview?: (screenId: 'inicio' | 'busca' | 'visualizacao' | 'cadastro') => void;
}

export const SwiftCodeViewer: React.FC<SwiftCodeViewerProps> = ({
  initialFile,
  onNavigateToPreview,
}) => {
  const [selectedFile, setSelectedFile] = useState<SwiftFile>(() => {
    if (initialFile) {
      const match = SWIFT_FILES.find((f) => f.filename === initialFile);
      if (match) return match;
    }
    return SWIFT_FILES[0];
  });

  const [copied, setCopied] = useState(false);
  const [isZipping, setIsZipping] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('Todos');

  const categories = useMemo(() => {
    const set = new Set<string>();
    SWIFT_FILES.forEach((f) => set.add(f.category));
    return ['Todos', ...Array.from(set)];
  }, []);

  const filteredFiles = useMemo(() => {
    return SWIFT_FILES.filter((file) => {
      const matchesCat =
        selectedCategory === 'Todos' || file.category === selectedCategory;
      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        q === '' ||
        file.filename.toLowerCase().includes(q) ||
        file.relativePath.toLowerCase().includes(q) ||
        file.description.toLowerCase().includes(q) ||
        file.category.toLowerCase().includes(q);
      return matchesCat && matchesSearch;
    });
  }, [selectedCategory, searchQuery]);

  const handleCopy = () => {
    navigator.clipboard.writeText(selectedFile.code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownload = (file: SwiftFile) => {
    const blob = new Blob([file.code], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = file.filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const handleDownloadZip = async () => {
    try {
      setIsZipping(true);
      const zip = new JSZip();
      const folder = zip.folder('CTIA-Xcode-Project');

      SWIFT_FILES.forEach((f) => {
        folder?.file(f.relativePath, f.code);
      });

      // Adiciona catálogo de ativos do Xcode (Assets.xcassets)
      folder?.file(
        'CTIA/Assets.xcassets/Contents.json',
        '{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}'
      );
      folder?.file(
        'CTIA/Assets.xcassets/AppIcon.appiconset/Contents.json',
        '{\n  "images" : [\n    {\n      "idiom" : "universal",\n      "platform" : "ios",\n      "size" : "1024x1024"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}'
      );
      folder?.file(
        'CTIA/Assets.xcassets/AccentColor.colorset/Contents.json',
        '{\n  "colors" : [\n    {\n      "color" : {\n        "color-space" : "srgb",\n        "components" : {\n          "alpha" : "1.000",\n          "blue" : "0.420",\n          "green" : "0.216",\n          "red" : "0.129"\n        }\n      },\n      "idiom" : "universal"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}'
      );

      const content = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(content);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'CTIA-Xcode-Project.zip';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Failed to generate zip:', err);
    } finally {
      setIsZipping(false);
    }
  };

  const lineCount = useMemo(() => {
    return selectedFile.code.split('\n').length;
  }, [selectedFile]);

  // Checa se o arquivo corresponde a uma tela que pode ser visualizada no simulador
  const relatedScreen = useMemo<'inicio' | 'busca' | 'visualizacao' | 'cadastro' | null>(() => {
    if (selectedFile.filename === 'HomeView.swift') return 'inicio';
    if (selectedFile.filename === 'SearchFilterView.swift') return 'busca';
    if (selectedFile.filename === 'DetailView.swift') return 'visualizacao';
    if (selectedFile.filename === 'CreateItemView.swift') return 'cadastro';
    return null;
  }, [selectedFile]);

  return (
    <div className="bg-slate-900 text-slate-100 rounded-2xl border border-slate-800 shadow-xl overflow-hidden flex flex-col h-[780px]">
      {/* Header do Visualizador Swift */}
      <div className="bg-slate-950 px-5 py-3.5 border-b border-slate-800 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#21376B] to-[#204C90] flex items-center justify-center text-white shadow-md border border-[#CC8F00]/30">
            <Apple className="w-5 h-5 text-[#FFC107]" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-bold text-sm text-white">
                Projeto Nativo iOS / Xcode (SwiftUI)
              </span>
              <span className="px-2 py-0.5 rounded-full text-[10.5px] font-semibold bg-[#CC8F00]/20 text-[#FFC107] border border-[#CC8F00]/40">
                Pronto para Build & Run (Cmd + R)
              </span>
            </div>
            <p className="text-xs text-slate-400">
              CTIA.xcodeproj + Scheme compartilhado + Scripts para abrir direto no Simulador iPhone
            </p>
          </div>
        </div>

        {/* Botões de Ação */}
        <div className="flex items-center space-x-2">
          {relatedScreen && onNavigateToPreview && (
            <button
              type="button"
              onClick={() => onNavigateToPreview(relatedScreen)}
              className="px-3.5 py-1.5 bg-[#204C90] hover:bg-[#21376B] text-white text-xs font-semibold rounded-lg flex items-center space-x-1.5 shadow-sm transition-all cursor-pointer border border-blue-400/30"
              title="Abrir esta tela no simulador iOS"
            >
              <ExternalLink className="w-3.5 h-3.5 text-[#FFC107]" />
              <span>Ver no Simulador</span>
            </button>
          )}

          <button
            type="button"
            onClick={handleDownloadZip}
            disabled={isZipping}
            className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-500 active:scale-95 text-white text-xs font-semibold rounded-lg flex items-center space-x-1.5 shadow-sm transition-all cursor-pointer disabled:opacity-50"
          >
            <Archive className="w-3.5 h-3.5" />
            <span>{isZipping ? 'Gerando .zip...' : 'Baixar Projeto Xcode (.zip)'}</span>
          </button>

          <button
            type="button"
            onClick={handleCopy}
            className="px-3.5 py-1.5 bg-slate-800 hover:bg-slate-700 active:scale-95 text-slate-200 text-xs font-medium rounded-lg flex items-center space-x-1.5 border border-slate-700 transition-all cursor-pointer"
          >
            {copied ? (
              <>
                <Check className="w-3.5 h-3.5 text-emerald-400" />
                <span className="text-emerald-400 font-semibold">Copiado!</span>
              </>
            ) : (
              <>
                <Copy className="w-3.5 h-3.5" />
                <span>Copiar Swift</span>
              </>
            )}
          </button>

          <button
            type="button"
            onClick={() => handleDownload(selectedFile)}
            className="px-3.5 py-1.5 bg-[#21376B] hover:bg-[#1a2d58] active:scale-95 text-white text-xs font-semibold rounded-lg flex items-center space-x-1.5 shadow-sm transition-all cursor-pointer"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Baixar .swift</span>
          </button>
        </div>
      </div>

      <div className="flex flex-1 min-h-0">
        {/* Sidebar com Arquivos e Categorias */}
        <div className="w-72 bg-slate-950/60 border-r border-slate-800 flex flex-col shrink-0">
          {/* Busca de Arquivos */}
          <div className="p-3 border-b border-slate-800/80">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-slate-500 absolute left-2.5 top-2.5" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Buscar arquivo Swift..."
                className="w-full bg-slate-900 border border-slate-700/80 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-[#CC8F00]"
              />
            </div>

            {/* Categorias */}
            <div className="flex flex-wrap gap-1 mt-2.5">
              {categories.map((cat) => (
                <button
                  key={cat}
                  type="button"
                  onClick={() => setSelectedCategory(cat)}
                  className={`px-2 py-0.5 rounded text-[10px] font-medium transition-colors cursor-pointer ${
                    selectedCategory === cat
                      ? 'bg-[#21376B] text-white font-semibold border border-[#CC8F00]/50'
                      : 'bg-slate-900 text-slate-400 hover:text-white'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* Lista de Arquivos Swift */}
          <div className="flex-1 overflow-y-auto p-2 space-y-1">
            <div className="text-[10.5px] font-bold text-slate-400 uppercase tracking-wider px-2 py-1 flex items-center justify-between">
              <span>Arquivos ({filteredFiles.length})</span>
              <span className="text-[9.5px] text-emerald-400">Swift 5.9+</span>
            </div>

            {filteredFiles.map((file) => {
              const isSelected = selectedFile.filename === file.filename;
              return (
                <button
                  key={file.filename}
                  type="button"
                  onClick={() => setSelectedFile(file)}
                  className={`w-full text-left px-3 py-2 rounded-lg text-xs transition-all flex items-start space-x-2.5 cursor-pointer ${
                    isSelected
                      ? 'bg-[#21376B]/50 text-white font-medium border border-[#204C90]'
                      : 'text-slate-400 hover:bg-slate-900 hover:text-slate-200'
                  }`}
                >
                  <FileCode
                    className={`w-4 h-4 shrink-0 mt-0.5 ${
                      isSelected ? 'text-[#FFC107]' : 'text-slate-500'
                    }`}
                  />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between">
                      <span className="truncate font-mono font-semibold text-[11.5px]">
                        {file.filename}
                      </span>
                      {file.filename === 'CTIA_Combined.swift' && (
                        <span className="text-[9px] bg-[#CC8F00] text-slate-950 font-bold px-1 rounded">
                          ALL-IN-1
                        </span>
                      )}
                    </div>
                    <div className="text-[10px] text-slate-500 truncate mt-0.5 font-mono">
                      {file.relativePath}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          {/* Rodapé da Sidebar: Instruções Xcode */}
          <div className="p-3 bg-slate-950 border-t border-slate-800 text-[11px] text-slate-400 space-y-1">
            <div className="flex items-center space-x-1.5 text-slate-300 font-semibold">
              <Terminal className="w-3.5 h-3.5 text-[#CC8F00]" />
              <span>Build & Run no Simulador</span>
            </div>
            <p className="text-[10px] leading-relaxed text-slate-400">
              1. Abra <code>CTIA.xcodeproj</code> e aperte <code>Cmd + R</code>.<br />
              2. Ou dê duplo clique em <code>RunInSimulator.command</code>.<br />
              3. O app instala e abre direto no iPhone!
            </p>
          </div>
        </div>

        {/* Visualizador de Código Swift */}
        <div className="flex-1 flex flex-col min-w-0 bg-[#0d1117]">
          {/* Barra de metadados do arquivo ativo */}
          <div className="px-4 py-2.5 bg-slate-900/90 border-b border-slate-800 flex items-center justify-between text-xs text-slate-400">
            <div className="flex items-center space-x-3 min-w-0">
              <span className="font-mono text-white font-bold text-xs bg-slate-800 px-2 py-0.5 rounded border border-slate-700">
                {selectedFile.filename}
              </span>
              <span className="text-[11px] text-slate-400 truncate">
                {selectedFile.description}
              </span>
            </div>
            <div className="flex items-center space-x-3 shrink-0 text-[11px] text-slate-400 font-mono">
              <span>{lineCount} linhas</span>
              <span className="text-slate-600">|</span>
              <span className="text-[#FFC107] font-semibold">{selectedFile.category}</span>
            </div>
          </div>

          {/* Área de Código com visual de IDE Xcode / Swift */}
          <div className="flex-1 p-4 overflow-auto font-mono text-[12.5px] leading-relaxed text-slate-200 selection:bg-[#21376B] selection:text-white">
            <pre className="whitespace-pre">
              <code>{selectedFile.code}</code>
            </pre>
          </div>
        </div>
      </div>
    </div>
  );
};
