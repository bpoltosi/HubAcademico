import React, { useState } from 'react';
import { Header } from '../Header';
import { AcademicItem, ScreenId } from '../../types';
import { Filter, Star, ArrowUpDown, ChevronDown, Check, Activity, GraduationCap } from 'lucide-react';

interface SearchScreenProps {
  items: AcademicItem[];
  onSelectItem: (item: AcademicItem) => void;
  onNavigate: (screen: ScreenId) => void;
  initialQuery?: string;
}

export const SearchScreen: React.FC<SearchScreenProps> = ({
  items,
  onSelectItem,
  onNavigate,
  initialQuery = 'ruído',
}) => {
  const [searchText, setSearchText] = useState(initialQuery);
  const [isFilterOpen, setIsFilterOpen] = useState(true);

  // Estados dos filtros (Ordem de caracteres: Ano (3) -> Melhor avaliação (16))
  const [filtroAno, setFiltroAno] = useState(true);
  const [valorAno, setValorAno] = useState('2026');

  const [filtroArea, setFiltroArea] = useState(true);
  const [valorArea, setValorArea] = useState('Engenharias');

  const [filtroAutor, setFiltroAutor] = useState(false);
  const [valorAutor, setValorAutor] = useState('');

  const [filtroCurso, setFiltroCurso] = useState(false);
  const [valorCurso, setValorCurso] = useState('Téc. Segurança do Trabalho');

  const [filtroTitulo, setFiltroTitulo] = useState(false);
  const [valorTitulo, setValorTitulo] = useState('');

  const [filtroMateria, setFiltroMateria] = useState(false);
  const [valorMateria, setValorMateria] = useState('Todas as matérias');

  const [filtroMelhorAvaliacao, setFiltroMelhorAvaliacao] = useState(true);

  const activeCount = [
    filtroAno,
    filtroArea,
    filtroAutor,
    filtroCurso,
    filtroTitulo,
    filtroMateria,
    filtroMelhorAvaliacao,
  ].filter(Boolean).length;

  const handleLimpar = () => {
    setFiltroAno(false);
    setFiltroArea(false);
    setFiltroAutor(false);
    setFiltroCurso(false);
    setFiltroTitulo(false);
    setFiltroMateria(false);
    setFiltroMelhorAvaliacao(false);
  };

  // Filtragem local
  const filteredItems = items.filter((item) => {
    if (searchText.trim()) {
      const q = searchText.toLowerCase();
      const match =
        item.titulo.toLowerCase().includes(q) ||
        item.resumo.toLowerCase().includes(q) ||
        item.autores.toLowerCase().includes(q);
      if (!match) return false;
    }
    if (filtroAno && item.ano.toString() !== valorAno) return false;
    if (filtroArea && item.area !== valorArea) return false;
    if (filtroCurso && item.curso !== valorCurso) return false;
    if (filtroMelhorAvaliacao && item.avaliacao < 4.5) return false;
    return true;
  });

  return (
    <div className="flex flex-col min-h-full bg-[#F1F4F9] text-[#1C1C1C]">
      {/* Cabeçalho */}
      <Header
        searchText={searchText}
        onSearchChange={setSearchText}
        onFilterToggle={() => setIsFilterOpen(!isFilterOpen)}
        isFilterActive={isFilterOpen}
        onAIClick={() => {}}
      />

      <div className="flex-1 px-4 py-4 space-y-4">
        {/* Painel de Filtros Retrátil */}
        {isFilterOpen && (
          <div className="bg-white p-4 rounded-[14px] border border-[#D3D7E1] shadow-[0_1px_3px_rgba(0,0,0,0.02)] space-y-3.5">
            {/* Topo do painel */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-1.5">
                <Filter className="w-4 h-4 text-[#21376B]" />
                <span className="font-bold text-[14px] text-[#1C1C1C]">Filtrar por</span>
                <span className="text-[12.5px] text-[#6C757D]">· {activeCount} ativos</span>
              </div>
              <button
                type="button"
                onClick={handleLimpar}
                className="text-[13px] font-medium text-[#204C90] hover:underline cursor-pointer"
              >
                Limpar
              </button>
            </div>

            <div className="h-[1px] bg-[#D3D7E1] w-full" />

            {/* Grid de Checkboxes com raio de 5 pt e cor Azul UFSM */}
            <div className="space-y-2.5">
              {/* 1. Ano (3 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroAno(!filtroAno)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroAno
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroAno && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Ano</span>
                </label>
                <div className="relative">
                  <select
                    value={valorAno}
                    onChange={(e) => setValorAno(e.target.value)}
                    className="text-[12.5px] bg-[#F1F4F9] text-[#4C4C4C] rounded-[6px] px-2.5 py-1.5 pr-6 appearance-none border border-transparent focus:border-[#21376B] focus:outline-none"
                  >
                    <option value="2026">2026</option>
                    <option value="2025">2025</option>
                    <option value="2024">2024</option>
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-[#6C757D] absolute right-1.5 top-2.5 pointer-events-none" />
                </div>
              </div>

              {/* 2. Área (4 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroArea(!filtroArea)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroArea
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroArea && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Área</span>
                </label>
                <div className="relative">
                  <select
                    value={valorArea}
                    onChange={(e) => setValorArea(e.target.value)}
                    className="text-[12.5px] bg-[#F1F4F9] text-[#4C4C4C] rounded-[6px] px-2.5 py-1.5 pr-6 appearance-none border border-transparent focus:border-[#21376B] focus:outline-none"
                  >
                    <option value="Engenharias">Engenharias</option>
                    <option value="Tecnologia da Informação">Informática</option>
                    <option value="Industrial">Industrial</option>
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-[#6C757D] absolute right-1.5 top-2.5 pointer-events-none" />
                </div>
              </div>

              {/* 3. Autor (5 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroAutor(!filtroAutor)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroAutor
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroAutor && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Autor</span>
                </label>
                <input
                  type="text"
                  value={valorAutor}
                  onChange={(e) => setValorAutor(e.target.value)}
                  placeholder="Nome do(a) autor(a)"
                  className="w-[170px] text-[12.5px] bg-[#F1F4F9] text-[#1C1C1C] rounded-[6px] px-2.5 py-1.5 border border-transparent focus:border-[#21376B] focus:outline-none"
                />
              </div>

              {/* 4. Curso (5 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroCurso(!filtroCurso)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroCurso
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroCurso && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Curso</span>
                </label>
                <div className="relative">
                  <select
                    value={valorCurso}
                    onChange={(e) => setValorCurso(e.target.value)}
                    className="text-[12.5px] bg-[#F1F4F9] text-[#4C4C4C] rounded-[6px] px-2.5 py-1.5 pr-6 appearance-none border border-transparent focus:border-[#21376B] focus:outline-none max-w-[170px] truncate"
                  >
                    <option value="Téc. Segurança do Trabalho">Téc. Segurança do Trabalho</option>
                    <option value="Téc. Mecânica">Téc. Mecânica</option>
                    <option value="Téc. Eletrotécnica">Téc. Eletrotécnica</option>
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-[#6C757D] absolute right-1.5 top-2.5 pointer-events-none" />
                </div>
              </div>

              {/* 5. Título (6 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroTitulo(!filtroTitulo)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroTitulo
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroTitulo && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Título</span>
                </label>
                <input
                  type="text"
                  value={valorTitulo}
                  onChange={(e) => setValorTitulo(e.target.value)}
                  placeholder="Palavras do título"
                  className="w-[170px] text-[12.5px] bg-[#F1F4F9] text-[#1C1C1C] rounded-[6px] px-2.5 py-1.5 border border-transparent focus:border-[#21376B] focus:outline-none"
                />
              </div>

              {/* 6. Matéria (7 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroMateria(!filtroMateria)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroMateria
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroMateria && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Matéria</span>
                </label>
                <div className="relative">
                  <select
                    value={valorMateria}
                    onChange={(e) => setValorMateria(e.target.value)}
                    className="text-[12.5px] bg-[#F1F4F9] text-[#4C4C4C] rounded-[6px] px-2.5 py-1.5 pr-6 appearance-none border border-transparent focus:border-[#21376B] focus:outline-none"
                  >
                    <option value="Todas as matérias">Todas as matérias</option>
                    <option value="Higiene Ocupacional">Higiene Ocupacional</option>
                    <option value="Eletrotécnica">Eletrotécnica</option>
                  </select>
                  <ChevronDown className="w-3.5 h-3.5 text-[#6C757D] absolute right-1.5 top-2.5 pointer-events-none" />
                </div>
              </div>

              {/* 7. Melhor avaliação (16 caracteres) */}
              <div className="flex items-center justify-between min-h-[38px]">
                <label className="flex items-center space-x-2.5 cursor-pointer select-none">
                  <div
                    onClick={() => setFiltroMelhorAvaliacao(!filtroMelhorAvaliacao)}
                    className={`w-5 h-5 rounded-[5px] flex items-center justify-center transition-colors border ${
                      filtroMelhorAvaliacao
                        ? 'bg-[#21376B] border-[#21376B] text-white'
                        : 'bg-white border-[#D3D7E1]'
                    }`}
                  >
                    {filtroMelhorAvaliacao && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                  <span className="text-[14px] font-medium text-[#1C1C1C]">Melhor avaliação ★</span>
                </label>
                <span className="text-[12.5px] font-medium bg-[#F1F4F9] text-[#4C4C4C] px-3 py-1.5 rounded-[6px]">
                  Maior nota
                </span>
              </div>
            </div>

            {/* Botão Primário: Q Aplicar filtros */}
            <button
              type="button"
              onClick={() => {}}
              className="w-full h-11 bg-[#21376B] hover:bg-[#1a2d58] text-white font-semibold text-[15px] rounded-[10px] flex items-center justify-center space-x-2 shadow-sm transition-colors cursor-pointer mt-1"
            >
              <Filter className="w-4 h-4" />
              <span>Aplicar filtros</span>
            </button>
          </div>
        )}

        {/* Linha de Resultados & Ordenação */}
        <div className="flex items-center justify-between px-1">
          <span className="text-[13px] font-medium text-[#4C4C4C]">
            {filteredItems.length} resultados para "{searchText || 'tudo'}"
          </span>
          <button
            type="button"
            className="flex items-center space-x-1 text-[12px] font-medium text-[#21376B] hover:underline cursor-pointer"
          >
            <ArrowUpDown className="w-3 h-3" />
            <span>Melhor avaliação</span>
          </button>
        </div>

        {/* Lista de Resultados (Raio de 14 pt nos cartões) */}
        <div className="space-y-3">
          {filteredItems.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => {
                onSelectItem(item);
                onNavigate('visualizacao');
              }}
              className="w-full text-left bg-white hover:bg-slate-50 active:scale-[0.99] p-3 rounded-[14px] border border-[#D3D7E1] shadow-[0_1px_3px_rgba(0,0,0,0.02)] flex items-start space-x-3 transition-all cursor-pointer"
            >
              {/* Thumbnail / Miniatura Gráfica */}
              <div
                className={`w-[72px] h-[72px] rounded-[10px] shrink-0 flex flex-col items-center justify-center ${
                  item.tipo === 'projeto'
                    ? 'bg-[#142140] text-cyan-300'
                    : 'bg-[#204C90] text-white'
                }`}
              >
                {item.tipo === 'projeto' ? (
                  <>
                    <Activity className="w-6 h-6 text-[#FFC107]" />
                    <span className="text-[9px] font-bold text-white mt-1">82 dB</span>
                  </>
                ) : (
                  <GraduationCap className="w-7 h-7" />
                )}
              </div>

              {/* Detalhes do Item */}
              <div className="flex-1 min-w-0 space-y-1">
                {/* Badge de Categoria */}
                <span className="inline-block text-[9.5px] font-bold uppercase text-[#204C90] bg-[#204C90]/10 px-1.5 py-0.5 rounded-[4px]">
                  {item.tipo === 'projeto'
                    ? 'PROJETO'
                    : item.tipo === 'trabalho'
                    ? 'TRABALHO ACADÊMICO'
                    : 'PROVA'}
                </span>

                {/* Título */}
                <h3 className="font-semibold text-[14px] leading-snug text-[#1C1C1C] line-clamp-2">
                  {item.titulo}
                </h3>

                {/* Avaliação em Âmbar #FFC107 */}
                <div className="flex items-center space-x-1.5 text-[11.5px]">
                  <div className="flex items-center space-x-0.5 text-[#FFC107]">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className={`w-3 h-3 ${
                          i < Math.floor(item.avaliacao)
                            ? 'fill-current'
                            : 'text-[#D3D7E1]'
                        }`}
                      />
                    ))}
                  </div>
                  <span className="font-bold text-[#1C1C1C]">
                    {item.avaliacao.toFixed(1).replace('.', ',')}
                  </span>
                  <span className="text-[#6C757D]">
                    ({item.totalAvaliacoes}) · {item.ano}
                  </span>
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
