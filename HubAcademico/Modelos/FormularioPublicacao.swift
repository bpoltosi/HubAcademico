import Foundation

/// Campos da tela Publicar, na ordem em que aparecem.
enum CampoPublicacao: Hashable, CaseIterable {
    case titulo
    case descricao
    case imagem
    case link
    case area
    case subarea
    case disciplina
    case instituicao
    case ano

    /// Campos de texto que podem receber o foco do teclado.
    /// Área, subárea e disciplina são escolhidas em listas (cascata área → subárea → disciplina).
    var focavel: Bool {
        switch self {
        case .titulo, .descricao, .imagem, .link, .instituicao: true
        case .area, .subarea, .disciplina, .ano: false
        }
    }
}

/// Estado editável da tela Publicar. É `Codable` para poder ser salvo como rascunho.
struct FormularioPublicacao: Codable, Equatable {
    var tipo: TipoPublicacao
    var titulo = ""
    var descricao = ""
    var imagemLink = ""
    var link = ""
    var plataforma: Plataforma = .linkedin
    var area: AreaConhecimento? = nil
    /// Subárea do CNPq dentro da área (ex.: "Engenharia de Produção").
    var subarea: String? = nil
    /// Disciplina escolhida na lista da subárea (currículos da UFSM) ou digitada.
    var disciplina = ""
    var instituicao = "CTISM – UFSM"
    var ano = Calendar.current.component(.year, from: .now)

    init(tipo: TipoPublicacao) {
        self.tipo = tipo
    }

    // MARK: - Cascata área → subárea → disciplina

    /// Trocar a área limpa a subárea e a disciplina, que dependem dela.
    mutating func escolherArea(_ nova: AreaConhecimento?) {
        guard nova != area else { return }
        area = nova
        subarea = nil
        disciplina = ""
    }

    /// Trocar a subárea limpa a disciplina, que é filtrada por ela.
    mutating func escolherSubarea(_ nova: String) {
        guard nova != subarea else { return }
        subarea = nova
        disciplina = ""
    }

    /// Disciplina da lista. Se ela for de outra subárea (achada pela busca), área e subárea acompanham.
    mutating func escolherDisciplina(_ nome: String, subarea daDisciplina: String?) {
        if let daDisciplina, daDisciplina != subarea, let areaDaDisciplina = Subarea.area(de: daDisciplina) {
            area = areaDaDisciplina
            subarea = daDisciplina
        }
        disciplina = nome
    }

    static var anosPermitidos: [Int] {
        let atual = Calendar.current.component(.year, from: .now)
        return Array(((atual - 10)...atual).reversed())
    }

    /// Mensagens de validação por campo (vazio = formulário válido).
    /// Os limites são os mesmos que o servidor Node-RED confere (backend/node-red/src/api.js).
    var erros: [CampoPublicacao: String] {
        var erros: [CampoPublicacao: String] = [:]
        if titulo.aparado.count < 5 {
            erros[.titulo] = "Informe um título com pelo menos 5 caracteres."
        } else if titulo.aparado.count > 150 {
            erros[.titulo] = "O título pode ter até 150 caracteres."
        }
        if descricao.aparado.count < 20 {
            erros[.descricao] = "Escreva uma descrição com pelo menos 20 caracteres."
        } else if descricao.count > Publicacao.limiteDescricao {
            erros[.descricao] = "A descrição pode ter até \(Publicacao.limiteDescricao) caracteres."
        }
        if !imagemLink.aparado.isEmpty, URL.web(imagemLink) == nil {
            erros[.imagem] = "Confira o link da imagem."
        }
        if !link.aparado.isEmpty, URL.web(link) == nil {
            erros[.link] = "Confira o link da publicação."
        }
        if let area {
            if subarea == nil {
                erros[.subarea] = "Selecione a subárea."
            } else if let subarea, !area.subareas.contains(subarea) {
                erros[.subarea] = "Selecione uma subárea de \(area.nomeCompleto)."
            }
        } else {
            erros[.area] = "Selecione a área do conhecimento."
        }
        if disciplina.aparado.count < 2 {
            erros[.disciplina] = subarea == nil ? "Escolha a subárea e depois a disciplina." : "Selecione a disciplina."
        } else if disciplina.aparado.count > 150 {
            erros[.disciplina] = "O nome da disciplina pode ter até 150 caracteres."
        }
        if instituicao.aparado.count < 2 {
            erros[.instituicao] = "Informe a instituição."
        } else if instituicao.aparado.count > 120 {
            erros[.instituicao] = "O nome da instituição pode ter até 120 caracteres."
        }
        return erros
    }

    /// Primeiro campo com erro, na ordem da tela.
    var primeiroCampoComErro: CampoPublicacao? {
        let erros = self.erros
        return CampoPublicacao.allCases.first { erros[$0] != nil }
    }
}
