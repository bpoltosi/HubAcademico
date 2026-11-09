import React from 'react';
import { Menu, Search, Wand2, Filter, X } from 'lucide-react';

interface HeaderProps {
  searchText: string;
  onSearchChange: (text: string) => void;
  onHomeClick?: () => void;
  onFilterToggle?: () => void;
  isFilterActive?: boolean;
  onSearchClick?: () => void;
  onAIClick?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  searchText,
  onSearchChange,
  onHomeClick,
  onFilterToggle,
  isFilterActive = false,
  onSearchClick,
  onAIClick,
}) => {
  return (
    <div className="sticky top-0 z-30 flex flex-col w-full shadow-sm select-none">
      {/* Top Banner Oficial: Azul UFSM #21376B */}
      <div className="bg-[#21376B] text-white px-4 pt-2.5 pb-3">
        {/* Brasão + Título CTIA */}
        <div className="flex items-center justify-between mb-2.5">
          <div className="flex items-center space-x-2.5">
            {/* Brasão UFSM estilizado */}
            <div className="w-8 h-8 rounded-full bg-white/15 flex items-center justify-center p-1 border border-white/20 shadow-inner">
              <svg viewBox="0 0 24 24" className="w-5 h-5 text-[#CC8F00] fill-current">
                <path d="M12 2L15 8H9L12 2Z" />
                <path d="M7 9C7 9 5 12 5 15C5 18.866 8.134 22 12 22C15.866 22 19 18.866 19 15C19 12 17 9 17 9H7Z" opacity="0.9" />
                <circle cx="12" cy="15" r="2.5" fill="#FFFFFF" />
              </svg>
            </div>
            <div>
              <div className="font-bold text-[15px] leading-tight tracking-wide flex items-center gap-1.5">
                <span>CTIA</span>
                <span className="text-[10px] bg-white/20 text-white px-1.5 py-0.2 rounded font-medium">UFSM</span>
              </div>
              <div className="text-[10px] text-white/85 font-medium leading-none mt-0.5">
                Repositório acadêmico do CTISM
              </div>
            </div>
          </div>
          <div className="text-[10px] font-semibold text-white/70 tracking-wider">
            UFSM.BR
          </div>
        </div>

        {/* Linha de Busca & Ações */}
        <div className="flex items-center space-x-2">
          {/* Menu Hambúrguer (3 Barras Laterais) - Volta para a Tela Inicial */}
          <button
            type="button"
            aria-label="Voltar para a tela inicial"
            title="Voltar para a tela inicial"
            onClick={onHomeClick}
            className="w-9 h-9 flex items-center justify-center rounded text-white hover:bg-white/10 active:bg-white/20 transition-colors cursor-pointer"
          >
            <Menu className="w-5 h-5" />
          </button>

          {/* Botão de Filtro (Funil) opcional */}
          {onFilterToggle && (
            <button
              type="button"
              aria-label="Abrir filtros de busca"
              onClick={onFilterToggle}
              className={`w-9 h-9 flex items-center justify-center rounded-lg transition-all ${
                isFilterActive
                  ? 'bg-white text-[#21376B] shadow-sm font-bold'
                  : 'bg-white/15 text-white hover:bg-white/25'
              }`}
            >
              <Filter className="w-4 h-4" />
            </button>
          )}

          {/* Input de Busca com Raio de 10 pt */}
          <div className="flex-1 relative flex items-center">
            <Search className="w-4 h-4 text-[#6C757D] absolute left-2.5 pointer-events-none" />
            <input
              type="text"
              value={searchText}
              onChange={(e) => onSearchChange(e.target.value)}
              onClick={onSearchClick}
              placeholder="O que você procura?"
              className="w-full h-9 pl-8 pr-7 bg-white text-[#1C1C1C] text-[13px] rounded-[10px] border border-transparent focus:border-[#204C90] focus:outline-none placeholder-[#6C757D]"
            />
            {searchText && (
              <button
                type="button"
                aria-label="Limpar campo de busca"
                onClick={() => onSearchChange('')}
                className="absolute right-2 text-[#6C757D] hover:text-[#1C1C1C]"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          {/* Botão Especial "Busca IA" */}
          <button
            type="button"
            aria-label="Busca com Inteligência Artificial"
            onClick={onAIClick}
            className="h-9 px-2.5 bg-white/95 text-[#21376B] hover:bg-white active:scale-95 text-[11.5px] font-semibold rounded-[10px] flex items-center space-x-1 shadow-sm transition-all whitespace-nowrap"
          >
            <Wand2 className="w-3.5 h-3.5 text-[#21376B]" />
            <span>Busca IA</span>
          </button>
        </div>
      </div>

      {/* Filete Dourado de 2 pt obrigatório pelo Design System da UFSM */}
      <div className="h-[2px] w-full bg-[#CC8F00]" />
    </div>
  );
};
