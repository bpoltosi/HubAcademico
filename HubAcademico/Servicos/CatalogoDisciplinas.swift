import Foundation

/// Uma disciplina dos currículos da UFSM, ligada a uma subárea do CNPq.
struct DisciplinaUFSM: Identifiable, Hashable, Sendable {
    let nome: String
    let subarea: String
    /// Até 3 códigos da disciplina na UFSM (ex.: DPS1142).
    let codigos: [String]
    /// Cursos de graduação da UFSM em que ela aparece.
    let cursos: [String]
    /// Nome e códigos normalizados, para a busca.
    let chaveBusca: String

    var id: String { subarea + "|" + nome }

    /// Ex.: "Engenharia de Produção, Engenharia Mecânica e mais 2 cursos".
    var cursosResumidos: String {
        guard cursos.count > 2 else {
            return cursos.formatted(.list(type: .and).locale(Locale(identifier: "pt_BR")))
        }
        return cursos.prefix(2).joined(separator: ", ") + " e mais \(cursos.count - 2) cursos"
    }
}

/// Disciplinas da UFSM organizadas por subárea (`Recursos/disciplinas-ufsm.json`).
///
/// O arquivo é gerado por `ferramentas/catalogo/gerar_catalogo.py` a partir da planilha de currículos dos cursos de
/// graduação da UFSM: cada disciplina foi ligada a uma subárea pelo assunto (nome e departamento);
/// as genéricas, como TCC e estágio, ficam na subárea do curso. A mesma lista está em
/// `docs/disciplinas-por-subarea.csv`, para conferência.
struct CatalogoDisciplinas: Sendable {
    let fonte: String
    private let porSubarea: [String: [DisciplinaUFSM]]
    private let todas: [DisciplinaUFSM]

    /// Carregado na primeira vez que alguém precisa dele (a tela de disciplinas).
    static let ufsm = CatalogoDisciplinas(arquivo: Bundle.main.url(forResource: "disciplinas-ufsm", withExtension: "json"))

    /// Disciplinas da subárea, em ordem alfabética.
    func disciplinas(da subarea: String) -> [DisciplinaUFSM] {
        porSubarea[subarea] ?? []
    }

    /// Procura pelo nome ou código. Devolve primeiro as da subárea escolhida e, à parte,
    /// as de outras subáreas (até `limiteOutras`), para quando a disciplina foi parar em outra subárea.
    func buscar(_ texto: String, na subarea: String?, limiteOutras: Int = 40) -> (daSubarea: [DisciplinaUFSM], outras: [DisciplinaUFSM]) {
        let termos = texto.normalizado
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        guard !termos.isEmpty else {
            return (subarea.map(disciplinas(da:)) ?? [], [])
        }
        func combina(_ disciplina: DisciplinaUFSM) -> Bool {
            termos.allSatisfy { disciplina.chaveBusca.contains($0) }
        }
        let daSubarea = subarea.map { disciplinas(da: $0).filter(combina) } ?? []
        var outras: [DisciplinaUFSM] = []
        for disciplina in todas where disciplina.subarea != subarea && combina(disciplina) {
            outras.append(disciplina)
            if outras.count == limiteOutras { break }
        }
        return (daSubarea, outras)
    }

    // MARK: - Leitura do arquivo

    private struct Arquivo: Decodable {
        struct Item: Decodable {
            let nome: String
            let codigos: [String]
            let cursos: [Int]
        }

        let fonte: String
        let cursos: [String]
        let subareas: [String: [Item]]
    }

    init(arquivo: URL?) {
        guard let arquivo,
              let dados = try? Data(contentsOf: arquivo),
              let lido = try? JSONDecoder().decode(Arquivo.self, from: dados) else {
            print("Hub Acadêmico: não foi possível ler disciplinas-ufsm.json")
            fonte = ""
            porSubarea = [:]
            todas = []
            return
        }
        var porSubarea: [String: [DisciplinaUFSM]] = [:]
        for (subarea, itens) in lido.subareas {
            porSubarea[subarea] = itens.map { item in
                DisciplinaUFSM(
                    nome: item.nome,
                    subarea: subarea,
                    codigos: item.codigos,
                    cursos: item.cursos.compactMap { lido.cursos.indices.contains($0) ? lido.cursos[$0] : nil },
                    chaveBusca: ([item.nome] + item.codigos).joined(separator: " ").normalizado
                )
            }
        }
        fonte = lido.fonte
        self.porSubarea = porSubarea
        // Ordem fixa (a das áreas e subáreas do CNPq) para a busca em outras subáreas.
        todas = AreaConhecimento.naOrdemDoCNPq
            .flatMap(\.subareas)
            .flatMap { porSubarea[$0] ?? [] }
    }
}
