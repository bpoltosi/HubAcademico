import React from 'react';
import { Wifi, Battery } from 'lucide-react';

interface IPhoneFrameProps {
  children: React.ReactNode;
  screenTitle?: string;
  badgeNumber?: number;
  compact?: boolean;
}

export const IPhoneFrame: React.FC<IPhoneFrameProps> = ({
  children,
  screenTitle,
  badgeNumber,
  compact = false,
}) => {
  return (
    <div className="flex flex-col items-center">
      {/* Rótulo superior do protótipo se houver */}
      {screenTitle && (
        <div className="mb-3 flex items-center space-x-2 text-slate-800">
          {badgeNumber !== undefined && (
            <span className="w-6 h-6 rounded-full bg-[#21376B] text-white text-xs font-bold flex items-center justify-center shadow-xs">
              {badgeNumber}
            </span>
          )}
          <span className="font-semibold text-sm tracking-tight text-slate-800">
            {screenTitle}
          </span>
        </div>
      )}

      {/* Frame do iPhone com Borda e Ilha Dinâmica */}
      <div
        className={`relative ${
          compact
            ? 'w-[305px] h-[670px] rounded-[42px] p-2'
            : 'w-[345px] sm:w-[370px] h-[750px] rounded-[48px] p-2.5'
        } bg-black shadow-[0_25px_60px_-15px_rgba(0,0,0,0.35),0_0_0_1px_rgba(255,255,255,0.1)_inset] border-[4px] border-slate-700/80 ring-1 ring-slate-900/40 select-none`}
      >
        {/* Dynamic Island */}
        <div
          className={`absolute ${
            compact ? 'top-3.5 w-[85px] h-[22px]' : 'top-4 w-[100px] h-[26px]'
          } left-1/2 -translate-x-1/2 bg-black rounded-full z-40 flex items-center justify-between px-2.5`}
        >
          <div className="w-2.5 h-2.5 rounded-full bg-[#111] border border-neutral-800" />
          <div className="w-2 h-2 rounded-full bg-[#08182B]" />
        </div>

        {/* Tela Interna com cantos arredondados */}
        <div
          className={`relative w-full h-full bg-[#F1F4F9] ${
            compact ? 'rounded-[34px]' : 'rounded-[38px]'
          } overflow-hidden flex flex-col`}
        >
          {/* iOS Status Bar */}
          <div className="h-10 bg-[#21376B] text-white px-7 flex items-end justify-between pb-1 z-30 select-none">
            {/* Hora 9:41 como no design oficial */}
            <span className="text-[12px] font-semibold tracking-tight">9:41</span>

            {/* Ícones de sinal, wifi e bateria */}
            <div className="flex items-center space-x-1.5 text-white/90">
              <div className="flex items-end space-x-0.5 h-2.5">
                <div className="w-[2px] h-1 bg-white rounded-xs" />
                <div className="w-[2px] h-1.5 bg-white rounded-xs" />
                <div className="w-[2px] h-2 bg-white rounded-xs" />
                <div className="w-[2px] h-2.5 bg-white rounded-xs" />
              </div>
              <Wifi className="w-3.5 h-3.5" />
              <Battery className="w-4 h-4" />
            </div>
          </div>

          {/* Conteúdo da Tela */}
          <div className="flex-1 overflow-y-auto no-scrollbar relative flex flex-col">
            {children}
          </div>

          {/* iOS Home Indicator Bar */}
          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-32 h-1 bg-neutral-800/40 rounded-full z-30 pointer-events-none" />
        </div>
      </div>
    </div>
  );
};
