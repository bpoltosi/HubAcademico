import React, { useState } from 'react';
import { Header } from '../Header';
import { AcademicItem, ScreenId } from '../../types';
import {
  ChevronLeft,
  Bookmark,
  Share2,
  Calendar,
  Building2,
  ExternalLink,
  Star,
  GraduationCap,
  Book,
} from 'lucide-react';

interface DetailScreenProps {
  item: AcademicItem;
  onNavigate: (screen: ScreenId) => void;
}

export const DetailScreen: React.FC<DetailScreenProps> = ({ item, onNavigate }) => {
  const [isSaved, setIsSaved] = useState(item.isSaved ?? true);
  const [userRating, setUserRating] = useState<number>(0);

  // Bar spectrum data for IoT noise monitoring (18 bars)
  const spectrumHeights = [30, 48, 25, 60, 78, 68, 52, 85, 95, 80, 58, 72, 88, 92, 70, 55, 38, 28];

  return (
    <div className="flex flex-col min-h-full bg-[#F1F4F9] text-[#1C1C1C]">
      {/* Cabeçalho */}
      <Header
        searchText=""
        onSearchChange={() => {}}
        onHomeClick={() => onNavigate('inicio')}
        onSearchClick={() => onNavigate('busca')}
        onAIClick={() => onNavigate('busca')}
      />

      <div className="flex-1 px-4 py-4 space-y-4">
        {/* Barra superior de navegação: < Resultados + Ações */}
        <div className="flex items-center justify-between">
          <button
            type="button"
            onClick={() => onNavigate('busca')}
            className="flex items-center space-x-1 text-[#21376B] font-medium text-[14px] hover:underline cursor-pointer"
          >
            <ChevronLeft className="w-4 h-4" />
            <span>Resultados</span>
          </button>

          <div className="flex items-center space-x-3.5">
            <button
              type="button"
              aria-label="Salvar projeto"
              onClick={() => setIsSaved(!isSaved)}
              className="text-[#6C757D] hover:text-[#21376B] transition-colors"
            >
              <Bookmark
                className={`w-4 h-4 ${isSaved ? 'text-[#21376B] fill-current' : ''}`}
              />
            </button>
            <button
              type="button"
              aria-label="Compartilhar"
              className="text-[#6C757D] hover:text-[#21376B] transition-colors"
            >
              <Share2 className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Metadados: Badge + Ano + Curso */}
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-[10px] font-bold text-[#204C90] bg-[#204C90]/10 px-2 py-0.5 rounded-[4px] uppercase">
            {item.tipo === 'projeto'
              ? 'PROJETO'
              : item.tipo === 'trabalho'
              ? 'TRABALHO ACADÊMICO'
              : 'PROVA'}
          </span>
          <div className="flex items-center space-x-1 text-[11.5px] text-[#6C757D]">
            <Calendar className="w-3 h-3" />
            <span>{item.ano}</span>
          </div>
          <div className="flex items-center space-x-1 text-[11.5px] text-[#6C757D]">
            <Building2 className="w-3 h-3" />
            <span>{item.curso}</span>
          </div>
        </div>

        {/* Título Principal */}
        <h1 className="text-[21px] font-medium leading-snug text-[#1C1C1C]">
          {item.titulo}
        </h1>

        {/* Card IoT Telemetria ao Vivo (Oficina de Mecânica) */}
        <div className="bg-[#142140] text-white p-3.5 rounded-[12px] shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
              <span className="text-[10.5px] font-bold tracking-wider text-white">
                OFICINA DE MECÂNICA · AO VIVO
              </span>
            </div>
            <span className="text-[9.5px] font-semibold bg-white/15 px-2 py-0.5 rounded text-white/90">
              ESP32 · Wi-Fi
            </span>
          </div>

          <div className="flex items-end justify-between pt-1">
            {/* Espectro Sonoro e Linha de Limite */}
            <div className="space-y-1.5 flex-1 pr-4">
              <div className="h-[70px] flex items-end space-x-1 relative">
                {/* Linha de Limite 85 dB(A) */}
                <div className="absolute top-3 left-0 right-0 border-t border-dashed border-[#FFC107] pointer-events-none" />

                {spectrumHeights.map((h, i) => (
                  <div
                    key={i}
                    style={{ height: `${h * 0.7}%` }}
                    className={`w-[4.5px] rounded-xs transition-all ${
                      h > 80 ? 'bg-[#FFC107]' : 'bg-cyan-400/80'
                    }`}
                  />
                ))}
              </div>
              <div className="text-[9px] font-medium text-[#FFC107]">
                Limite 85 dB(A)
              </div>
            </div>

            {/* Medidor Circular 82 dB */}
            <div className="relative w-16 h-16 shrink-0 flex items-center justify-center">
              <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
                <path
                  className="text-white/15"
                  strokeWidth="3.5"
                  stroke="currentColor"
                  fill="none"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
                <path
                  className="text-cyan-400"
                  strokeDasharray="75, 100"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  stroke="currentColor"
                  fill="none"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                <span className="text-[17px] font-bold leading-none">82</span>
                <span className="text-[9px] text-white/80 font-medium leading-none mt-0.5">dB</span>
              </div>
            </div>
          </div>
        </div>

        {/* Autores & Link Externo */}
        <div className="flex items-center justify-between pt-1">
          <div className="text-[13px] font-medium text-[#1C1C1C]">
            {item.autores}
          </div>
          <a
            href={item.linkPublicado || 'https://linkedin.com'}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center space-x-1 text-[12px] font-medium text-[#204C90] hover:underline"
          >
            <span>LinkedIn</span>
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>

        {/* Seção: | RESUMO */}
        <div className="space-y-1.5 pt-1">
          <div className="flex items-center space-x-2">
            <div className="w-[3px] h-3.5 bg-[#CC8F00] rounded-xs" />
            <span className="text-[12.5px] font-bold text-[#4C4C4C] tracking-wider uppercase">
              Resumo
            </span>
          </div>
          <p className="text-[14px] text-[#4C4C4C] leading-relaxed">
            {item.resumo}
          </p>
        </div>

        {/* Seção: | AVALIAÇÕES */}
        <div className="space-y-2 pt-1">
          <div className="flex items-center space-x-2">
            <div className="w-[3px] h-3.5 bg-[#CC8F00] rounded-xs" />
            <span className="text-[12.5px] font-bold text-[#4C4C4C] tracking-wider uppercase">
              Avaliações
            </span>
          </div>

          <div className="bg-white p-3.5 rounded-[12px] border border-[#D3D7E1] shadow-[0_1px_3px_rgba(0,0,0,0.02)] flex items-center justify-between">
            {/* Bloco de Média Geral */}
            <div className="space-y-1">
              <div className="text-[32px] font-bold text-[#1C1C1C] leading-none">
                {item.avaliacao.toFixed(1).replace('.', ',')}
              </div>
              <div className="flex items-center space-x-0.5 text-[#FFC107]">
                {[...Array(5)].map((_, i) => (
                  <Star
                    key={i}
                    className={`w-3.5 h-3.5 ${
                      i < Math.floor(item.avaliacao)
                        ? 'fill-current'
                        : 'text-[#D3D7E1]'
                    }`}
                  />
                ))}
              </div>
              <div className="text-[11px] text-[#6C757D]">
                {item.totalAvaliacoes} avaliações
              </div>
            </div>

            <div className="w-[1px] h-14 bg-[#D3D7E1]" />

            {/* Avalie este projeto (Interativo) */}
            <div className="space-y-1 text-right">
              <div className="text-[12.5px] font-semibold text-[#1C1C1C]">
                Avalie este projeto
              </div>
              <div className="flex items-center space-x-1 justify-end text-[#FFC107] cursor-pointer">
                {[1, 2, 3, 4, 5].map((starVal) => (
                  <button
                    key={starVal}
                    type="button"
                    aria-label={`Avaliar com ${starVal} estrelas`}
                    onClick={() => setUserRating(starVal)}
                    className="hover:scale-110 transition-transform"
                  >
                    <Star
                      className={`w-4 h-4 ${
                        starVal <= userRating
                          ? 'fill-current text-[#FFC107]'
                          : 'text-[#D3D7E1]'
                      }`}
                    />
                  </button>
                ))}
              </div>
              <div className="text-[10.5px] text-[#6C757D]">
                {userRating > 0 ? `Você avaliou com ${userRating} estrelas` : 'Toque para dar sua nota'}
              </div>
            </div>
          </div>
        </div>

        {/* Seções Inferiores: | ÁREA e | MATÉRIA */}
        <div className="grid grid-cols-2 gap-3 pt-1">
          {/* Card Área */}
          <div className="bg-white p-3 rounded-[10px] border border-[#D3D7E1] space-y-1.5">
            <div className="flex items-center space-x-1.5">
              <div className="w-[2.5px] h-3 bg-[#CC8F00] rounded-xs" />
              <span className="text-[11px] font-bold text-[#4C4C4C] uppercase tracking-wider">
                Área
              </span>
            </div>
            <div className="flex items-center space-x-1.5 text-[12.5px] font-medium text-[#1C1C1C]">
              <GraduationCap className="w-4 h-4 text-[#21376B] shrink-0" />
              <span className="truncate">{item.area}</span>
            </div>
          </div>

          {/* Card Matéria */}
          <div className="bg-white p-3 rounded-[10px] border border-[#D3D7E1] space-y-1.5">
            <div className="flex items-center space-x-1.5">
              <div className="w-[2.5px] h-3 bg-[#CC8F00] rounded-xs" />
              <span className="text-[11px] font-bold text-[#4C4C4C] uppercase tracking-wider">
                Matéria
              </span>
            </div>
            <div className="flex items-center space-x-1.5 text-[12.5px] font-medium text-[#1C1C1C]">
              <Book className="w-4 h-4 text-[#21376B] shrink-0" />
              <span className="truncate">{item.materia}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
