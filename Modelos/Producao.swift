import Foundation

/// Tipos de produção acadêmica do repositório.
enum TipoProducao: String, Codable, CaseIterable, Identifiable, Hashable {
    case projeto
    case trabalho
    case prova
    case material

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .projeto: "Projeto"
        case .trabalho: "Trabalho acadêmico"
        case .prova: "Prova"
        case .material: "Material complementar"
        }
    }

    var nomeCurto: String {
        switch self {
        case .projeto: "Projeto"
        case .trabalho: "Trabalho"
        case .prova: "Prova"
        case .material: "Material"
        }
    }

    /// Título da lista (botões da tela inicial).
    var tituloLista: String {
        switch self {
        case .projeto: "Projetos"
        case .trabalho: "Trabalhos acadêmicos"
        case .prova: "Banco de provas"
        case .material: "Material complementar"
        }
    }

    var tituloCadastro: String {
        switch self {
        case .projeto: "Cadastre o seu projeto"
        case .trabalho: "Cadastre o seu trabalho"
        case .prova: "Cadastre a sua prova"
        case .material: "Cadastre o seu material"
        }
    }

    var conviteAvaliacao: String {
        switch self {
        case .projeto: "Avalie este projeto"
        case .trabalho: "Avalie este trabalho"
        case .prova: "Avalie esta prova"
        case .material: "Avalie este material"
        }
    }

    /// SF Symbol equivalente ao ícone Font Awesome do design.
    var simbolo: String {
        switch self {
        case .projeto: "lightbulb.fill"
        case .trabalho: "graduationcap.fill"
        case .prova: "checklist"
        case .material: "book.fill"
        }
    }

    /// Tipos que o(a) estudante pode cadastrar. O material complementar fica para o perfil docente.
    static let cadastraveis: [TipoProducao] = [.projeto, .trabalho, .prova]
}

/// Grandes áreas usadas nas sessões da JAI/UFSM 2026.
enum AreaConhecimento: String, Codable, CaseIterable, Identifiable, Hashable {
    case agrarias
    case biologicas
    case engenharias
    case exatas
    case humanas
    case linguisticaLetrasArtes
    case saude
    case sociaisAplicadas

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .agrarias: "Agrárias"
        case .biologicas: "Biológicas"
        case .engenharias: "Engenharias"
        case .exatas: "Exatas e da Terra"
        case .humanas: "Humanas"
        case .linguisticaLetrasArtes: "Linguística, Letras e Artes"
        case .saude: "Saúde"
        case .sociaisAplicadas: "Sociais Aplicadas"
        }
    }
}

/// Onde a produção foi publicada originalmente.
enum Plataforma: String, Codable, CaseIterable, Identifiable, Hashable {
    case linkedin
    case instagram
    case blog
    case youtube
    case github
    case outro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .linkedin: "LinkedIn"
        case .instagram: "Instagram"
        case .blog: "Blog"
        case .youtube: "YouTube"
        case .github: "GitHub"
        case .outro: "Outro"
        }
    }

    /// Reconhece a plataforma pelo endereço digitado.
    static func detectar(em url: URL?) -> Plataforma? {
        guard let host = url?.host()?.lowercased() else { return nil }
        if host.contains("linkedin") { return .linkedin }
        if host.contains("instagram") { return .instagram }
        if host.contains("youtube") || host.contains("youtu.be") { return .youtube }
        if host.contains("github") { return .github }
        if host.contains("blog") || host.contains("medium") || host.contains("wordpress") { return .blog }
        return nil
    }
}

/// Uma produção acadêmica: projeto, trabalho, prova ou material complementar.
struct Producao: Identifiable, Codable, Hashable {
    static let limiteDescricao = 200

    var id = UUID()
    var tipo: TipoProducao
    var titulo: String
    /// Breve resumo, com até 200 caracteres.
    var descricao: String
    /// Imagem da descrição, informada por URL.
    var imagemURL: URL?
    /// Link de onde foi publicado (blog, LinkedIn, Instagram…).
    var link: URL?
    var plataforma: Plataforma
    var area: AreaConhecimento
    var materia: String
    /// Nome oficial do curso (veja `CursoCTISM`).
    var curso: String
    var instituicao: String
    var ano: Int
    var autores: [String]
    /// Notas de 1 a 5 recebidas da comunidade (modo local).
    var notas: [Int] = []
    var criadoEm = Date()
    /// Média e total de avaliações calculados pelo servidor Node-RED.
    /// Ficam `nil` no modo local, em que valem as `notas` acima.
    var notaMedia: Double? = nil
    var quantidadeAvaliacoes: Int? = nil
}

extension Producao {
    var autoresFormatados: String {
        autores.formatted(.list(type: .and).locale(Locale(identifier: "pt_BR")))
    }

    /// Texto usado pela busca semântica.
    var textoSemantico: String {
        "\(titulo). \(descricao) \(materia). \(area.nome)."
    }
}
