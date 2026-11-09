import Foundation

// MARK: - Regras de Negócio e Lógica do Catálogo Acadêmico (CTIA)
// Implementação nativa em Swift para validação, filtros e ordenação

/// Estrutura para parâmetros de filtro na tela de busca
public struct SearchFilters: Hashable {
    public var termoBusca: String
    public var ano: Int?
    public var area: String?
    public var autor: String?
    public var curso: String?
    public var titulo: String?
    public var materia: String?
    public var melhorAvaliacao: Bool
    
    public init(
        termoBusca: String = "",
        ano: Int? = nil,
        area: String? = nil,
        autor: String? = nil,
        curso: String? = nil,
        titulo: String? = nil,
        materia: String? = nil,
        melhorAvaliacao: Bool = false
    ) {
        self.termoBusca = termoBusca
        self.ano = ano
        self.area = area
        self.autor = autor
        self.curso = curso
        self.titulo = titulo
        self.materia = materia
        self.melhorAvaliacao = melhorAvaliacao
    }
}

/// Resultado da validação de formulário de cadastro
public struct ValidationResult {
    public let isValid: Bool
    public let errors: [String: String]
    public let charCount: Int
    
    public init(isValid: Bool, errors: [String: String], charCount: Int) {
        self.isValid = isValid
        self.errors = errors
        self.charCount = charCount
    }
}

public enum AcademicCatalogLogic {
    
    /// Regra do Design System CTIA / UFSM:
    /// Valida se uma lista de rótulos segue ordem estritamente crescente de caracteres
    /// - Menu principal: 8 -> 22 caracteres
    /// - Filtros em checkbox: 3 -> 16 caracteres
    public static func verifyCharacterOrdering(_ labels: [String]) -> Bool {
        guard labels.count > 1 else { return true }
        for i in 0..<(labels.count - 1) {
            if labels[i].count > labels[i + 1].count {
                return false
            }
        }
        return true
    }
    
    /// Validação do cadastro de projetos/trabalhos/provas:
    /// - Resumo limitado a até 200 caracteres (contador dinâmico)
    /// - Título, área e matéria obrigatórios
    public static func validateAcademicItem(
        titulo: String,
        resumo: String,
        area: String,
        materia: String
    ) -> ValidationResult {
        var errors: [String: String] = [:]
        let trimmedTitulo = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResumo = resumo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArea = area.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMateria = materia.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let charCount = resumo.count
        
        if trimmedTitulo.isEmpty {
            errors["titulo"] = "Título é obrigatório"
        }
        
        if trimmedResumo.isEmpty {
            errors["resumo"] = "Resumo é obrigatório"
        } else if charCount > 200 {
            errors["resumo"] = "Resumo excede o limite de 200 caracteres (\(charCount)/200)"
        }
        
        if trimmedArea.isEmpty || trimmedArea == "Todas as áreas" {
            errors["area"] = "Área é obrigatória"
        }
        
        if trimmedMateria.isEmpty || trimmedMateria == "Todas as matérias" {
            errors["materia"] = "Matéria é obrigatória"
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            charCount: charCount
        )
    }
    
    /// Filtra itens acadêmicos conforme busca textual e opções ativas
    public static func filterAcademicItems(
        items: [AcademicItem],
        filters: SearchFilters
    ) -> [AcademicItem] {
        return items.filter { item in
            // Busca textual livre
            if !filters.termoBusca.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let query = filters.termoBusca.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                let itemText = "\(item.titulo) \(item.resumo) \(item.autores) \(item.area) \(item.materia) \(item.curso)"
                    .lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                
                if !itemText.contains(query) {
                    return false
                }
            }
            
            // Filtro por ano
            if let ano = filters.ano, item.ano != ano {
                return false
            }
            
            // Filtro por área
            if let area = filters.area, !area.isEmpty, area != "Todas as áreas", item.area != area {
                return false
            }
            
            // Filtro por autor
            if let autor = filters.autor, !autor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let qAutor = autor.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                let itemAutor = item.autores.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                if !itemAutor.contains(qAutor) {
                    return false
                }
            }
            
            // Filtro por curso
            if let curso = filters.curso, !curso.isEmpty, curso != "Todos os cursos", item.curso != curso {
                return false
            }
            
            // Filtro por título
            if let titulo = filters.titulo, !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let qTitulo = titulo.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                let itemTitulo = item.titulo.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                if !itemTitulo.contains(qTitulo) {
                    return false
                }
            }
            
            // Filtro por matéria
            if let materia = filters.materia, !materia.isEmpty, materia != "Todas as matérias", item.materia != materia {
                return false
            }
            
            // Filtro por melhor avaliação (>= 4.5)
            if filters.melhorAvaliacao && item.avaliacao < 4.5 {
                return false
            }
            
            return true
        }
    }
    
    /// Formata nota com vírgula padrão brasileira (ex: 4,8)
    public static func formatRatingBR(_ rating: Double) -> String {
        return String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
    }
}
