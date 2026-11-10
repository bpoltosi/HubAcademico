import Foundation
import Observation

/// Opções do painel de filtros da busca.
enum CampoFiltro: String, CaseIterable, Identifiable, Hashable {
    case ano
    case area
    case autor
    case curso
    case titulo
    case materia
    case melhorAvaliacao

    var id: String { rawValue }

    var rotulo: String {
        switch self {
        case .ano: "Ano"
        case .area: "Área"
        case .autor: "Autor"
        case .curso: "Curso"
        case .titulo: "Título"
        case .materia: "Matéria"
        case .melhorAvaliacao: "Melhor avaliação"
        }
    }

    /// Texto mostrado quando o filtro está desmarcado.
    var dica: String {
        switch self {
        case .ano: "Qualquer ano"
        case .area: "Todas as áreas"
        case .autor: "Nome do(a) autor(a)"
        case .curso: "Todos os cursos"
        case .titulo: "Palavras do título"
        case .materia: "Todas as matérias"
        case .melhorAvaliacao: "Ordenar por nota"
        }
    }

    /// Regra do projeto: opções em ordem crescente de caracteres
    /// (Ano 3, Área 4, Autor 5, Curso 5, Título 6, Matéria 7, Melhor avaliação 16).
    /// Em caso de empate, vale a ordem alfabética.
    static var ordenados: [CampoFiltro] {
        allCases.sorted { ($0.rotulo.count, $0.rotulo) < ($1.rotulo.count, $1.rotulo) }
    }
}

/// Valores escolhidos no painel de filtros.
struct FiltrosBusca: Equatable {
    var ativos: Set<CampoFiltro> = []
    var ano = Calendar.current.component(.year, from: .now)
    var area: AreaConhecimento = .engenharias
    var autor = ""
    var curso = CursoCTISM.segurancaDoTrabalho
    var titulo = ""
    var materia = ""

    func estaAtivo(_ campo: CampoFiltro) -> Bool {
        ativos.contains(campo)
    }

    var quantidadeAtivos: Int {
        ativos.count
    }
}

/// Estado da busca, compartilhado entre o cabeçalho (campo de texto) e a tela de resultados.
@Observable
final class BuscaModel {
    var texto = ""
    /// Escopo da busca: um tipo (quando se entra por um atalho do Início) ou todos (`nil`).
    var tipo: TipoProducao?
    var usarIA = false
    var mostrarFiltros = false
    var filtros = FiltrosBusca()

    /// Busca semântica no próprio aparelho (framework NaturalLanguage da Apple).
    let motor = BuscaInteligente()

    func limparFiltros() {
        filtros = FiltrosBusca()
    }
}
