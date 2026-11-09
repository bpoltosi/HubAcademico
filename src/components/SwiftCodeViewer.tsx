import React, { useState } from 'react';
import { SWIFT_FILES, SwiftFile } from '../data/swiftCode';
import { Copy, Check, Download, FileCode, Apple, Terminal } from 'lucide-react';

export const SwiftCodeViewer: React.FC = () => {
  const [selectedFile, setSelectedFile] = useState<SwiftFile>(SWIFT_FILES[0]);
  const [copied, setCopied] = useState(false);

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

  return (
    <div className="bg-slate-900 text-slate-100 rounded-2xl border border-slate-800 shadow-xl overflow-hidden flex flex-col h-[750px]">
      {/* Header com Informações e Ações */}
      <div className="bg-slate-950/80 px-5 py-4 border-b border-slate-800 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center space-x-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-[#21376B] to-[#204C90] flex items-center justify-center text-white shadow-md">
            <Apple className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-bold text-sm text-white">Código Swift (SwiftUI)</span>
              <span className="px-2 py-0.5 rounded text-[10px] font-semibold bg-[#CC8F00]/20 text-[#FFC107] border border-[#CC8F00]/30">
                Deploy 26.1
              </span>
            </div>
            <p className="text-xs text-slate-400">
              Arquivos .swift para Xcode e HackaTruck MakerSpace
            </p>
          </div>
        </div>

        {/* Botões de Ação */}
        <div className="flex items-center space-x-2">
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
                <span>Copiar {selectedFile.filename}</span>
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
        {/* Sidebar com Lista de Arquivos Swift */}
        <div className="w-64 bg-slate-950/40 border-r border-slate-800 p-3 overflow-y-auto space-y-1 shrink-0">
          <div className="text-[11px] font-bold text-slate-400 uppercase tracking-wider px-2 py-1">
            Arquivos SwiftUI
          </div>
          {SWIFT_FILES.map((file) => {
            const isSelected = selectedFile.filename === file.filename;
            return (
              <button
                key={file.filename}
                type="button"
                onClick={() => setSelectedFile(file)}
                className={`w-full text-left px-3 py-2.5 rounded-lg text-xs transition-all flex items-start space-x-2.5 cursor-pointer ${
                  isSelected
                    ? 'bg-[#21376B]/40 text-white font-medium border border-[#204C90]/60'
                    : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'
                }`}
              >
                <FileCode
                  className={`w-4 h-4 shrink-0 mt-0.5 ${
                    isSelected ? 'text-[#FFC107]' : 'text-slate-500'
                  }`}
                />
                <div className="min-w-0 flex-1">
                  <div className="truncate font-mono">{file.filename}</div>
                  <div className="text-[10px] text-slate-500 truncate mt-0.5">
                    {file.category}
                  </div>
                </div>
              </button>
            );
          })}

          <div className="pt-4 px-2">
            <div className="p-3 bg-slate-900 rounded-xl border border-slate-800 text-[11px] text-slate-400 space-y-1.5">
              <div className="flex items-center space-x-1.5 text-slate-300 font-semibold">
                <Terminal className="w-3.5 h-3.5 text-[#CC8F00]" />
                <span>Como usar no Xcode</span>
              </div>
              <p className="text-[10.5px] leading-relaxed text-slate-400">
                1. Crie um projeto iOS App no Xcode.<br />
                2. Cole o conteúdo de <code>CTIA_Combined.swift</code> no arquivo <code>ContentView.swift</code>.<br />
                3. Pressione <code>Cmd + R</code> ou visualize no Canvas.
              </p>
            </div>
          </div>
        </div>

        {/* Visualizador de Código */}
        <div className="flex-1 flex flex-col min-w-0 bg-[#0d1117]">
          {/* Barra de descrição do arquivo */}
          <div className="px-4 py-2 bg-slate-900/60 border-b border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
            <span className="font-mono text-slate-300">{selectedFile.filename}</span>
            <span className="text-[11px] text-slate-500">{selectedFile.description}</span>
          </div>

          {/* Área de Código */}
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
