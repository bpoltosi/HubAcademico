import Foundation

/// Cursos oferecidos pelo CTISM, conforme a página oficial
/// https://www.ufsm.br/unidades-universitarias/ctism/cursos (consultada em 07/11/2026).
struct CursoCTISM: Identifiable, Hashable {
    enum Nivel: String, CaseIterable, Identifiable {
        case integrado = "Técnico integrado ao ensino médio"
        case integradoEJA = "Técnico integrado – EJA-EPT"
        case subsequente = "Técnico subsequente (pós-médio)"
        case superior = "Superior de tecnologia"
        case posGraduacao = "Pós-graduação"

        var id: String { rawValue }
    }

    let nome: String
    let nomeCurto: String
    let nivel: Nivel

    var id: String { nome }

    static let todos: [CursoCTISM] = [
        CursoCTISM(nome: "Técnico em Eletrotécnica Integrado ao Ensino Médio",
                   nomeCurto: "Téc. Eletrotécnica (Integrado)", nivel: .integrado),
        CursoCTISM(nome: "Técnico em Informática para Internet Integrado ao Ensino Médio",
                   nomeCurto: "Téc. Informática para Internet (Integrado)", nivel: .integrado),
        CursoCTISM(nome: "Técnico em Internet das Coisas Integrado ao Ensino Médio",
                   nomeCurto: "Téc. Internet das Coisas (Integrado)", nivel: .integrado),
        CursoCTISM(nome: "Técnico em Mecânica Integrado ao Ensino Médio",
                   nomeCurto: "Téc. Mecânica (Integrado)", nivel: .integrado),
        CursoCTISM(nome: "Técnico em Eletromecânica Integrado ao Ensino Médio na modalidade de Educação para Jovens e Adultos (EJA-EPT)",
                   nomeCurto: "Téc. Eletromecânica (EJA-EPT)", nivel: .integradoEJA),
        CursoCTISM(nome: "Técnico em Automação Industrial",
                   nomeCurto: "Téc. Automação Industrial", nivel: .subsequente),
        CursoCTISM(nome: "Técnico em Eletrotécnica",
                   nomeCurto: "Téc. Eletrotécnica", nivel: .subsequente),
        CursoCTISM(nome: "Técnico em Mecânica",
                   nomeCurto: "Téc. Mecânica", nivel: .subsequente),
        CursoCTISM(nome: "Técnico em Soldagem",
                   nomeCurto: "Téc. Soldagem", nivel: .subsequente),
        CursoCTISM(nome: "Técnico em Eletromecânica",
                   nomeCurto: "Téc. Eletromecânica", nivel: .subsequente),
        CursoCTISM(nome: "Técnico em Eletrônica",
                   nomeCurto: "Téc. Eletrônica", nivel: .subsequente),
        CursoCTISM(nome: "Técnico em Segurança do Trabalho",
                   nomeCurto: "Téc. Segurança do Trabalho", nivel: .subsequente),
        CursoCTISM(nome: "Curso Superior de Tecnologia em Eletrônica Industrial",
                   nomeCurto: "Tecnologia em Eletrônica Industrial", nivel: .superior),
        CursoCTISM(nome: "Curso Superior de Tecnologia em Fabricação Mecânica",
                   nomeCurto: "Tecnologia em Fabricação Mecânica", nivel: .superior),
        CursoCTISM(nome: "Curso Superior de Tecnologia em Redes de Computadores",
                   nomeCurto: "Tecnologia em Redes de Computadores", nivel: .superior),
        CursoCTISM(nome: "Curso Superior de Tecnologia em Segurança Cibernética",
                   nomeCurto: "Tecnologia em Segurança Cibernética", nivel: .superior),
        CursoCTISM(nome: "Programa de Pós-Graduação em Educação Profissional e Tecnológica – PPGEPT",
                   nomeCurto: "PPGEPT", nivel: .posGraduacao),
    ]

    static let segurancaDoTrabalho = "Técnico em Segurança do Trabalho"

    static func cursos(do nivel: Nivel) -> [CursoCTISM] {
        todos.filter { $0.nivel == nivel }
    }

    /// Nome curto para exibição; devolve o próprio texto se o curso não estiver no catálogo.
    static func curto(_ nome: String) -> String {
        todos.first { $0.nome == nome }?.nomeCurto ?? nome
    }
}
