import React, { useState } from 'react';
import { Header } from '../Header';
import { AcademicItem, ItemType, ScreenId } from '../../types';
import {
  ChevronLeft,
  Image as ImageIcon,
  ChevronDown,
  Paperclip,
  CheckCircle2,
} from 'lucide-react';

interface CreateScreenProps {
  onNavigate: (screen: ScreenId) => void;
  onAddItem: (item: AcademicItem) => void;
}

export const CreateScreen: React.FC<CreateScreenProps> = ({
  onNavigate,
  onAddItem,
}) => {
  const [tipo, setTipo] = useState<ItemType>('projeto');
  const [titulo, setTitulo] = useState('Monitor IoT de ruído nas oficinas do CTISM');
  const [resumo, setResumo] = useState(
    'Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas.'
  );
  const [imagemUrl, setImagemUrl] = useState('https://example.com/monitor-ruido');
  const [linkTipo, setLinkTipo] = useState('LinkedIn');
  const [linkUrl, setLinkUrl] = useState('linkedin.com/posts/ana-clara-machado');
  const [area, setArea] = useState('Engenharias');
  const [materia, setMateria] = useState('Higiene Ocupacional');
  const [instituicao, setInstituicao] = useState('CTISM - UFSM');
  const [ano, setAno] = useState('2026');

  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const charCount = resumo.length;
  const isOverLimit = charCount > 200;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!titulo.trim()) {
      alert('Por favor, informe o título.');
      return;
    }
    if (isOverLimit) {
      alert('O resumo não pode ultrapassar 200 caracteres.');
      return;
    }

    const newItem: AcademicItem = {
      id: `item-${Date.now()}`,
      tipo,
      titulo,
      resumo,
      autores: 'Estudante do CTISM',
      area,
      materia,
      curso: 'Téc. Segurança do Trabalho',
      instituicao,
      ano: parseInt(ano, 10) || 2026,
      avaliacao: 5.0,
      totalAvaliacoes: 1,
      imagemUrl,
      linkPublicado: linkUrl,
      linkTipo,
      isSaved: false,
      localTelemetria: 'OFICINA DO CTISM',
      statusAoVivo: 'ATIVO',
      limiteDb: 85,
      dbAtual: 82,
      sensorChip: 'ESP32 · Wi-Fi',
    };

    onAddItem(newItem);
    setToastMessage('Projeto publicado com sucesso!');
    setTimeout(() => {
      onNavigate('visualizacao');
    }, 1200);
  };

  return (
    <div className="flex flex-col min-h-full bg-[#F1F4F9] text-[#1C1C1C]">
      {/* Cabeçalho */}
      <Header
        searchText=""
        onSearchChange={() => {}}
        onSearchClick={() => onNavigate('busca')}
        onAIClick={() => onNavigate('busca')}
      />

      <div className="flex-1 px-4 py-4 space-y-4">
        {/* Barra superior de navegação: < Início + Título */}
        <div className="flex items-center justify-between">
          <button
            type="button"
            onClick={() => onNavigate('inicio')}
            className="flex items-center space-x-1 text-[#21376B] font-medium text-[14px] hover:underline cursor-pointer"
          >
            <ChevronLeft className="w-4 h-4" />
            <span>Início</span>
          </button>

          <h2 className="text-[15px] font-bold text-[#1C1C1C]">
            Cadastre o seu projeto
          </h2>

          <div className="w-12" />
        </div>

        {/* Feedback de sucesso */}
        {toastMessage && (
          <div className="p-3 bg-emerald-50 border border-emerald-300 text-emerald-800 rounded-[10px] text-[13px] flex items-center space-x-2 animate-fadeIn">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span>{toastMessage}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-3.5">
          {/* Segmented Control: Projeto / Trabalho / Prova */}
          <div className="grid grid-cols-3 bg-[#E2E6EF] p-1 rounded-[10px] text-[13px] font-semibold">
            <button
              type="button"
              onClick={() => setTipo('projeto')}
              className={`py-1.5 rounded-[8px] transition-all cursor-pointer ${
                tipo === 'projeto'
                  ? 'bg-white text-[#21376B] shadow-xs'
                  : 'text-[#4C4C4C] hover:text-[#1C1C1C]'
              }`}
            >
              Projeto
            </button>
            <button
              type="button"
              onClick={() => setTipo('trabalho')}
              className={`py-1.5 rounded-[8px] transition-all cursor-pointer ${
                tipo === 'trabalho'
                  ? 'bg-white text-[#21376B] shadow-xs'
                  : 'text-[#4C4C4C] hover:text-[#1C1C1C]'
              }`}
            >
              Trabalho
            </button>
            <button
              type="button"
              onClick={() => setTipo('prova')}
              className={`py-1.5 rounded-[8px] transition-all cursor-pointer ${
                tipo === 'prova'
                  ? 'bg-white text-[#21376B] shadow-xs'
                  : 'text-[#4C4C4C] hover:text-[#1C1C1C]'
              }`}
            >
              Prova
            </button>
          </div>

          {/* Campo: Título * */}
          <div className="space-y-1">
            <label className="text-[12.5px] font-medium text-[#4C4C4C]">
              Título *
            </label>
            <input
              type="text"
              value={titulo}
              onChange={(e) => setTitulo(e.target.value)}
              placeholder="Monitor IoT de ruído nas oficinas do CTISM"
              className="w-full h-10 px-3 bg-white text-[#1C1C1C] text-[13.5px] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none"
              required
            />
          </div>

          {/* Campo: Descrição / Resumo com contador de caracteres (até 200) */}
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              <label className="text-[12px] font-medium text-[#4C4C4C]">
                Descrição — breve resumo (até 200 caracteres) *
              </label>
              <span
                className={`text-[11px] font-semibold ${
                  isOverLimit ? 'text-red-600' : 'text-[#6C757D]'
                }`}
              >
                {charCount}/200
              </span>
            </div>
            <textarea
              value={resumo}
              onChange={(e) => setResumo(e.target.value)}
              rows={3}
              className={`w-full p-2.5 bg-white text-[#1C1C1C] text-[13px] rounded-[10px] border focus:outline-none transition-colors ${
                isOverLimit
                  ? 'border-red-500 focus:border-red-600'
                  : 'border-[#D3D7E1] focus:border-[#21376B]'
              }`}
              required
            />
          </div>

          {/* Campo: Imagem da descrição (URL) */}
          <div className="space-y-1">
            <label className="text-[12.5px] font-medium text-[#4C4C4C]">
              Imagem da descrição (URL)
            </label>
            <div className="flex items-center space-x-2">
              <input
                type="url"
                value={imagemUrl}
                onChange={(e) => setImagemUrl(e.target.value)}
                placeholder="https://example.com/monitor-ruido"
                className="flex-1 h-10 px-3 bg-white text-[#1C1C1C] text-[13px] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none truncate"
              />
              <button
                type="button"
                aria-label="Selecionar imagem"
                className="w-10 h-10 rounded-[10px] bg-[#21376B] text-white flex items-center justify-center shrink-0 hover:bg-[#1a2d58] transition-colors"
              >
                <ImageIcon className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Campo: Link onde foi publicado */}
          <div className="space-y-1">
            <label className="text-[12.5px] font-medium text-[#4C4C4C]">
              Link onde foi publicado
            </label>
            <div className="flex items-center space-x-2">
              <div className="relative shrink-0">
                <select
                  value={linkTipo}
                  onChange={(e) => setLinkTipo(e.target.value)}
                  className="h-10 text-[12.5px] font-medium bg-[#E9ECF3] text-[#21376B] rounded-[8px] px-2.5 pr-6 appearance-none border border-transparent focus:outline-none"
                >
                  <option value="LinkedIn">LinkedIn</option>
                  <option value="GitHub">GitHub</option>
                  <option value="Lattes">Lattes</option>
                  <option value="Outro">Outro</option>
                </select>
                <ChevronDown className="w-3.5 h-3.5 text-[#21376B] absolute right-1.5 top-3 pointer-events-none" />
              </div>
              <input
                type="text"
                value={linkUrl}
                onChange={(e) => setLinkUrl(e.target.value)}
                placeholder="linkedin.com/posts/ana-clara-..."
                className="flex-1 h-10 px-3 bg-white text-[#1C1C1C] text-[13px] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none truncate"
              />
            </div>
          </div>

          {/* Dropdown: Área * */}
          <div className="space-y-1">
            <label className="text-[12.5px] font-medium text-[#4C4C4C]">
              Área *
            </label>
            <div className="relative">
              <select
                value={area}
                onChange={(e) => setArea(e.target.value)}
                className="w-full h-10 px-3 text-[13px] bg-white text-[#1C1C1C] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none appearance-none"
              >
                <option value="Engenharias">Engenharias</option>
                <option value="Tecnologia da Informação">Tecnologia da Informação</option>
                <option value="Ciências Exatas">Ciências Exatas</option>
              </select>
              <ChevronDown className="w-4 h-4 text-[#6C757D] absolute right-3 top-3 pointer-events-none" />
            </div>
          </div>

          {/* Dropdown: Matéria * */}
          <div className="space-y-1">
            <label className="text-[12.5px] font-medium text-[#4C4C4C]">
              Matéria *
            </label>
            <div className="relative">
              <select
                value={materia}
                onChange={(e) => setMateria(e.target.value)}
                className="w-full h-10 px-3 text-[13px] bg-white text-[#1C1C1C] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none appearance-none"
              >
                <option value="Higiene Ocupacional">Higiene Ocupacional</option>
                <option value="Segurança do Trabalho">Segurança do Trabalho</option>
                <option value="Eletrotécnica">Eletrotécnica</option>
                <option value="Mecânica Aplicada">Mecânica Aplicada</option>
              </select>
              <ChevronDown className="w-4 h-4 text-[#6C757D] absolute right-3 top-3 pointer-events-none" />
            </div>
          </div>

          {/* Linha: Instituição e Ano */}
          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2 space-y-1">
              <label className="text-[12.5px] font-medium text-[#4C4C4C]">
                Instituição *
              </label>
              <input
                type="text"
                value={instituicao}
                onChange={(e) => setInstituicao(e.target.value)}
                className="w-full h-10 px-3 bg-white text-[#1C1C1C] text-[13px] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none"
              />
            </div>
            <div className="space-y-1">
              <label className="text-[12.5px] font-medium text-[#4C4C4C]">
                Ano *
              </label>
              <div className="relative">
                <select
                  value={ano}
                  onChange={(e) => setAno(e.target.value)}
                  className="w-full h-10 px-2.5 text-[13px] bg-white text-[#1C1C1C] rounded-[10px] border border-[#D3D7E1] focus:border-[#21376B] focus:outline-none appearance-none"
                >
                  <option value="2026">2026</option>
                  <option value="2025">2025</option>
                  <option value="2024">2024</option>
                </select>
                <ChevronDown className="w-3.5 h-3.5 text-[#6C757D] absolute right-2 top-3 pointer-events-none" />
              </div>
            </div>
          </div>

          {/* Botões de Ação (Raio 10 pt) */}
          <div className="grid grid-cols-2 gap-3 pt-2">
            <button
              type="button"
              onClick={() => {
                alert('Rascunho salvo localmente.');
              }}
              className="h-11 bg-white hover:bg-slate-50 text-[#1C1C1C] font-semibold text-[14px] rounded-[10px] border border-[#D3D7E1] flex items-center justify-center transition-colors cursor-pointer"
            >
              Salvar rascunho
            </button>

            <button
              type="submit"
              className="h-11 bg-[#21376B] hover:bg-[#1a2d58] active:scale-[0.99] text-white font-bold text-[14px] rounded-[10px] flex items-center justify-center space-x-1.5 shadow-sm transition-all cursor-pointer"
            >
              <Paperclip className="w-3.5 h-3.5 rotate-45" />
              <span>Publicar</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
