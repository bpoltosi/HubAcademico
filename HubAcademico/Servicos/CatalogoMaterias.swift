import Foundation

/// Uma disciplina dos currículos da UFSM, ligada a uma subárea do CNPq.
struct MateriaUFSM: Identifiable, Hashable, Sendable {
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

/// Matérias da UFSM organizadas por subárea (`Recursos/materias-ufsm.json`).
///
/// O arquivo é gerado por `ferramentas/catalogo/gerar_catalogo.py` a partir da planilha de currículos dos cursos de
/// graduação da UFSM: cada disciplina foi ligada a uma subárea pelo assunto (nome e departamento);
/// as genéricas, como TCC e estágio, ficam na subárea do curso. A mesma lista está em
/// `docs/materias-por-subarea.csv`, para conferência.
struct CatalogoMaterias: Sendable {
    let fonte: String
    private let porSubarea: [String: [MateriaUFSM]]
    private let todas: [MateriaUFSM]

    /// Carregado na primeira vez que alguém precisa dele (a tela de matérias).
    static let ufsm = CatalogoMaterias(arquivo: Bundle.main.url(forResource: "materias-ufsm", withExtension: "json"))

    /// Matérias da subárea, em ordem alfabética.
    func materias(da subarea: String) -> [MateriaUFSM] {
        porSubarea[subarea] ?? []
    }

    /// Procura pelo nome ou código. Devolve primeiro as da subárea escolhida e, à parte,
    /// as de outras subáreas (até `limiteOutras`), para quando a disciplina foi parar em outra subárea.
    func buscar(_ texto: String, na subarea: String?, limiteOutras: Int = 40) -> (daSubarea: [MateriaUFSM], outras: [MateriaUFSM]) {
        let termos = texto.normalizado
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        guard !termos.isEmpty else {
            return (subarea.map(materias(da:)) ?? [], [])
        }
        func combina(_ materia: MateriaUFSM) -> Bool {
            termos.allSatisfy { materia.chaveBusca.contains($0) }
        }
        let daSubarea = subarea.map { materias(da: $0).filter(combina) } ?? []
        var outras: [MateriaUFSM] = []
        for materia in todas where materia.subarea != subarea && combina(materia) {
            outras.append(materia)
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
            print("Hub Acadêmico: não foi possível ler materias-ufsm.json")
            fonte = ""
            porSubarea = [:]
            todas = []
            return
        }
        var porSubarea: [String: [MateriaUFSM]] = [:]
        for (subarea, itens) in lido.subareas {
            porSubarea[subarea] = itens.map { item in
                MateriaUFSM(
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
