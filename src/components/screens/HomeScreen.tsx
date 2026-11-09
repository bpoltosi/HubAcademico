import React from 'react';
import { Header } from '../Header';
import { MENU_ITEMS } from '../../data/mockData';
import { Lightbulb, CheckSquare, GraduationCap, BookOpen, PlusCircle, ChevronRight } from 'lucide-react';
import { ScreenId } from '../../types';

interface HomeScreenProps {
  onNavigate: (screen: ScreenId) => void;
  onSearch: (query: string) => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigate, onSearch }) => {
  const [searchText, setSearchText] = React.useState('');

  const renderIcon = (iconName: string, isWhite = false) => {
    const className = `w-5 h-5 ${isWhite ? 'text-white' : 'text-[#204C90]'}`;
    switch (iconName) {
      case 'lightbulb':
        return <Lightbulb className={className} />;
      case 'checklist':
        return <CheckSquare className={className} />;
      case 'graduation-cap':
        return <GraduationCap className={className} />;
      case 'book':
        return <BookOpen className={className} />;
      case 'plus-circle':
        return <PlusCircle className={className} />;
      default:
        return <Lightbulb className={className} />;
    }
  };

  return (
    <div className="flex flex-col min-h-full bg-[#F1F4F9] text-[#1C1C1C]">
      {/* Cabeçalho */}
      <Header
        searchText={searchText}
        onSearchChange={setSearchText}
        onHomeClick={() => onNavigate('inicio')}
        onSearchClick={() => onNavigate('busca')}
        onAIClick={() => onNavigate('busca')}
      />

      <div className="flex-1 px-4 py-5 space-y-5">
        {/* Saudação e Boas-vindas */}
        <div className="space-y-1">
          <h1 className="text-[25px] font-medium leading-tight text-[#1C1C1C]">
            Olá, estudante!
          </h1>
          <p className="text-[14.5px] text-[#4C4C4C] leading-snug">
            Explore e compartilhe a produção acadêmica do CTISM.
          </p>
        </div>

        {/* Título de Seção com Marcador Dourado (#CC8F00) */}
        <div className="flex items-center space-x-2 pt-1">
          <div className="w-[3px] h-3.5 bg-[#CC8F00] rounded-xs" />
          <span className="text-[12.5px] font-bold text-[#4C4C4C] tracking-wider uppercase">
            Acesso Rápido
          </span>
        </div>

        {/* Lista de Acesso Rápido (Ordem de caracteres 8 -> 22) */}
        <div className="space-y-3">
          {MENU_ITEMS.map((item) => {
            if (item.destaque) {
              // Card Destaque: Cadastre o seu projeto (22 chars) em Azul UFSM #21376B
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => onNavigate('cadastro')}
                  className="w-full text-left bg-[#21376B] hover:bg-[#1a2d58] active:scale-[0.99] text-white p-3.5 rounded-[16px] shadow-sm flex items-center space-x-3.5 transition-all cursor-pointer min-h-[58px]"
                >
                  <div className="w-11 h-11 rounded-full bg-white/20 flex items-center justify-center shrink-0">
                    {renderIcon(item.icone, true)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-[16.5px] leading-snug text-white">
                      {item.titulo}
                    </div>
                    <div className="text-[12.5px] text-white/85 leading-none mt-0.5">
                      {item.subtitulo}
                    </div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-white/70 shrink-0" />
                </button>
              );
            }

            // Cards Padrão: Fundo Branco, Raio 16 pt, Borda #D3D7E1
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => {
                  onSearch(item.titulo);
                  onNavigate('busca');
                }}
                className="w-full text-left bg-white hover:bg-slate-50 active:scale-[0.99] text-[#1C1C1C] p-3.5 rounded-[16px] border border-[#D3D7E1] shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex items-center space-x-3.5 transition-all cursor-pointer min-h-[58px]"
              >
                <div className="w-11 h-11 rounded-full bg-[#204C90]/10 flex items-center justify-center shrink-0">
                  {renderIcon(item.icone, false)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-[16.5px] leading-snug text-[#1C1C1C]">
                    {item.titulo}
                  </div>
                  <div className="text-[12.5px] text-[#6C757D] leading-none mt-0.5">
                    {item.subtitulo}
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-[#D3D7E1] shrink-0" />
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};
