/**
 * CTIA - Repositório Acadêmico do CTISM
 * Regras de negócio e lógica de dados do repositório acadêmico
 */

export interface AcademicItem {
  id: string;
  tipo: 'projeto' | 'trabalho' | 'prova';
  titulo: string;
  resumo: string;
  autor: string;
  coautores?: string[];
  area: string;
  materia: string;
  curso: string;
  instituicao: string;
  ano: number;
  avaliacao: number;
  totalAvaliacoes: number;
  imagemUrl?: string;
  linkPublicado?: string;
  linkTipo?: 'LinkedIn' | 'GitHub' | 'Lattes' | 'Outro';
  salvo?: boolean;
  telemetria?: {
    local: string;
    status: string;
    limiteDb: number;
    dbAtual: number;
    sensor: string;
  };
}

export interface SearchFilters {
  termoBusca?: string;
  ano?: number;
  area?: string;
  autor?: string;
  curso?: string;
  titulo?: string;
  materia?: string;
  melhorAvaliacao?: boolean;
}

/**
 * Valida a regra de ordem estritamente crescente de caracteres
 * Especificação do design system do CTIA:
 * Menu: 8 -> 22 caracteres
 * Filtros: 3 -> 16 caracteres
 */
export function verifyCharacterOrdering(labels: string[]): boolean {
  if (labels.length <= 1) return true;
  for (let i = 0; i < labels.length - 1; i++) {
    if (labels[i].length > labels[i + 1].length) {
      return false;
    }
  }
  return true;
}

/**
 * Valida o formulário de cadastro de projeto/trabalho/prova
 * - Resumo limitado a 200 caracteres
 * - Título obrigatório
 * - Área e matéria obrigatórias
 */
export function validateAcademicItem(item: Partial<AcademicItem>): {
  valid: boolean;
  errors: Record<string, string>;
  charCount: number;
} {
  const errors: Record<string, string> = {};
  const resumo = item.resumo || '';
  const charCount = resumo.length;

  if (!item.titulo || item.titulo.trim().length === 0) {
    errors.titulo = 'Título é obrigatório';
  }

  if (!resumo || resumo.trim().length === 0) {
    errors.resumo = 'Resumo é obrigatório';
  } else if (charCount > 200) {
    errors.resumo = `Resumo excede o limite de 200 caracteres (${charCount}/200)`;
  }

  if (!item.area || item.area.trim().length === 0) {
    errors.area = 'Área é obrigatória';
  }

  if (!item.materia || item.materia.trim().length === 0) {
    errors.materia = 'Matéria é obrigatória';
  }

  return {
    valid: Object.keys(errors).length === 0,
    errors,
    charCount,
  };
}

/**
 * Filtra e ordena itens do repositório acadêmico com base nos critérios ativos
 */
export function filterAcademicItems(
  items: AcademicItem[],
  filters: SearchFilters
): AcademicItem[] {
  return items.filter((item) => {
    // Busca textual livre
    if (filters.termoBusca && filters.termoBusca.trim() !== '') {
      const q = filters.termoBusca.toLowerCase().trim();
      const matchTitulo = item.titulo.toLowerCase().includes(q);
      const matchResumo = item.resumo.toLowerCase().includes(q);
      const matchAutor = item.autor.toLowerCase().includes(q);
      const matchArea = item.area.toLowerCase().includes(q);
      const matchMateria = item.materia.toLowerCase().includes(q);
      const matchCurso = item.curso.toLowerCase().includes(q);

      if (!matchTitulo && !matchResumo && !matchAutor && !matchArea && !matchMateria && !matchCurso) {
        return false;
      }
    }

    if (filters.ano && item.ano !== filters.ano) {
      return false;
    }

    if (filters.area && filters.area !== 'Todas as áreas' && item.area !== filters.area) {
      return false;
    }

    if (filters.autor && filters.autor.trim() !== '') {
      if (!item.autor.toLowerCase().includes(filters.autor.toLowerCase().trim())) {
        return false;
      }
    }

    if (filters.curso && filters.curso !== 'Todos os cursos' && item.curso !== filters.curso) {
      return false;
    }

    if (filters.titulo && filters.titulo.trim() !== '') {
      if (!item.titulo.toLowerCase().includes(filters.titulo.toLowerCase().trim())) {
        return false;
      }
    }

    if (filters.materia && filters.materia !== 'Todas as matérias' && item.materia !== filters.materia) {
      return false;
    }

    if (filters.melhorAvaliacao && item.avaliacao < 4.5) {
      return false;
    }

    return true;
  });
}

/**
 * Formata nota decimal com padrão brasileiro (ex: 4,8)
 */
export function formatRatingBR(rating: number): string {
  return rating.toFixed(1).replace('.', ',');
}
