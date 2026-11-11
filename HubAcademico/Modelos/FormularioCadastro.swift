import Foundation

/// Campos da tela de cadastro, na ordem em que aparecem.
enum CampoCadastro: Hashable, CaseIterable {
    case titulo
    case descricao
    case imagem
    case link
    case area
    case subarea
    case materia
    case instituicao
    case ano

    /// Campos de texto que podem receber o foco do teclado.
    /// Área, subárea e matéria são escolhidas em listas (cascata área → subárea → matéria).
    var focavel: Bool {
        switch self {
        case .titulo, .descricao, .imagem, .link, .instituicao: true
        case .area, .subarea, .materia, .ano: false
        }
    }
}

/// Estado editável do cadastro. É `Codable` para poder ser salvo como rascunho.
struct FormularioCadastro: Codable, Equatable {
    var tipo: TipoProducao
    var titulo = ""
    var descricao = ""
    var imagemURL = ""
    var link = ""
    var plataforma: Plataforma = .linkedin
    var area: AreaConhecimento? = nil
    /// Subárea do CNPq dentro da área (ex.: "Engenharia de Produção").
    var subarea: String? = nil
    /// Matéria escolhida na lista da subárea (currículos da UFSM) ou digitada.
    var materia = ""
    var instituicao = "CTISM – UFSM"
    var ano = Calendar.current.component(.year, from: .now)

    init(tipo: TipoProducao) {
        self.tipo = tipo
    }

    // MARK: - Cascata área → subárea → matéria

    /// Trocar a área limpa a subárea e a matéria, que dependem dela.
    mutating func escolherArea(_ nova: AreaConhecimento?) {
        guard nova != area else { return }
        area = nova
        subarea = nil
        materia = ""
    }

    /// Trocar a subárea limpa a matéria, que é filtrada por ela.
    mutating func escolherSubarea(_ nova: String) {
        guard nova != subarea else { return }
        subarea = nova
        materia = ""
    }

    /// Matéria da lista. Se ela for de outra subárea (achada pela busca), área e subárea acompanham.
    mutating func escolherMateria(_ nome: String, subarea daMateria: String?) {
        if let daMateria, daMateria != subarea, let areaDaMateria = Subarea.area(de: daMateria) {
            area = areaDaMateria
            subarea = daMateria
        }
        materia = nome
    }

    static var anosPermitidos: [Int] {
        let atual = Calendar.current.component(.year, from: .now)
        return Array(((atual - 10)...atual).reversed())
    }

    /// Mensagens de validação por campo (vazio = formulário válido).
    /// Os limites são os mesmos que o servidor Node-RED confere (backend/node-red/src/api.js).
    var erros: [CampoCadastro: String] {
        var erros: [CampoCadastro: String] = [:]
        if titulo.aparado.count < 5 {
            erros[.titulo] = "Informe um título com pelo menos 5 caracteres."
        } else if titulo.aparado.count > 150 {
            erros[.titulo] = "O título pode ter até 150 caracteres."
        }
        if descricao.aparado.count < 20 {
            erros[.descricao] = "Escreva um resumo com pelo menos 20 caracteres."
        } else if descricao.count > Producao.limiteDescricao {
            erros[.descricao] = "O resumo pode ter até \(Producao.limiteDescricao) caracteres."
        }
        if !imagemURL.aparado.isEmpty, URL.web(imagemURL) == nil {
            erros[.imagem] = "Confira o endereço da imagem."
        }
        if !link.aparado.isEmpty, URL.web(link) == nil {
            erros[.link] = "Confira o endereço da publicação."
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
        if materia.aparado.count < 2 {
            erros[.materia] = subarea == nil ? "Escolha a subárea e depois a matéria." : "Selecione a matéria."
        } else if materia.aparado.count > 150 {
            erros[.materia] = "O nome da matéria pode ter até 150 caracteres."
        }
        if instituicao.aparado.count < 2 {
            erros[.instituicao] = "Informe a instituição."
        } else if instituicao.aparado.count > 120 {
            erros[.instituicao] = "O nome da instituição pode ter até 120 caracteres."
        }
        return erros
    }

    /// Primeiro campo com erro, na ordem da tela.
    var primeiroCampoComErro: CampoCadastro? {
        let erros = self.erros
        return CampoCadastro.allCases.first { erros[$0] != nil }
    }
}
