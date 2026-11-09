import Foundation

public enum AcademicType: String, CaseIterable, Identifiable {
    case projeto = "Projeto"
    case trabalho = "Trabalho"
    case prova = "Prova"
    
    public var id: String { rawValue }
    
    public var badgeLabel: String {
        switch self {
        case .projeto: return "PROJETO"
        case .trabalho: return "TRABALHO ACADÊMICO"
        case .prova: return "BANCO DE PROVAS"
        }
    }
}
