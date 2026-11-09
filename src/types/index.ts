export type ScreenId = 'inicio' | 'busca' | 'visualizacao' | 'cadastro';

export type ItemType = 'projeto' | 'trabalho' | 'prova';

export interface AcademicItem {
  id: string;
  tipo: ItemType;
  titulo: string;
  resumo: string;
  autores: string;
  area: string;
  materia: string;
  curso: string;
  instituicao: string;
  ano: number;
  avaliacao: number;
  totalAvaliacoes: number;
  imagemUrl?: string;
  linkPublicado?: string;
  linkTipo?: string;
  isSaved?: boolean;
  localTelemetria?: string;
  statusAoVivo?: string;
  limiteDb?: number;
  dbAtual?: number;
  sensorChip?: string;
}

export interface SearchFilterState {
  termoBusca: string;
  anoAtivo: boolean;
  anoValor: string;
  areaAtiva: boolean;
  areaValor: string;
  autorAtivo: boolean;
  autorValor: string;
  cursoAtivo: boolean;
  cursoValor: string;
  tituloAtivo: boolean;
  tituloValor: string;
  materiaAtiva: boolean;
  materiaValor: string;
  melhorAvaliacaoAtivo: boolean;
}
