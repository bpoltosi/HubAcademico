import Foundation
import Observation

/// Telas empilhadas na navegação.
/// A visualização (Tela 3) não entra na pilha: ela abre como sheet por cima da tela atual.
///
/// Mapa do app — 3 telas + 1 sheet (4 views):
/// Tela 1 Início (raiz) → Tela 2 Busca → Tela 3 Visualização (sheet) · Tela 4 Cadastro
enum Rota: Hashable {
    case busca
    case cadastro(TipoProducao)
}

/// Publicação aberta na sheet da Tela 3.
struct DetalheSelecionado: Identifiable, Hashable {
    let id: UUID
}

/// Controla a pilha de navegação, a sheet de visualização e o menu (☰).
/// Fica fora da NavigationStack para que o cabeçalho institucional também possa navegar.
@Observable
final class Router {
    var caminho: [Rota] = []
    var mostrarMenu = false
    /// Pedido para focar o campo de busca assim que a tela de busca abrir.
    var pedirFocoNaBusca = false
    /// Publicação exibida na sheet da Tela 3 (`nil` = sheet fechada).
    var detalhe: DetalheSelecionado?
    /// Publicação a abrir assim que o menu terminar de fechar (duas sheets não abrem juntas).
    var detalhePendente: UUID?

    var estaNaBusca: Bool { caminho.last == .busca }

    func abrir(_ rota: Rota) {
        caminho.append(rota)
    }

    /// Vai para a busca; se ela já estiver na pilha, volta até ela em vez de empilhar outra.
    func abrirBusca(focar: Bool = true) {
        guard caminho.last != .busca else { return }
        pedirFocoNaBusca = focar
        if let indice = caminho.lastIndex(of: .busca) {
            caminho.removeSubrange((indice + 1)...)
        } else {
            caminho.append(.busca)
        }
    }

    /// Abre a Tela 3 (sheet) com a publicação escolhida.
    func abrirDetalhe(_ id: UUID) {
        detalhe = DetalheSelecionado(id: id)
    }

    func voltarAoInicio() {
        caminho.removeAll()
    }

    /// Volta um nível na pilha de navegação, se possível.
    func voltarUmNivel() {
        if !caminho.isEmpty {
            caminho.removeLast()
        }
    }

    /// Depois de publicar: fecha o cadastro e mostra a nova publicação na sheet.
    func concluirPublicacao(_ id: UUID) {
        if let ultima = caminho.last, case .cadastro = ultima {
            caminho.removeLast()
        }
        // Espera a animação de voltar terminar antes de subir a sheet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.abrirDetalhe(id)
        }
    }

    /// Chamado quando o menu termina de fechar.
    func abrirDetalhePendente() {
        guard let id = detalhePendente else { return }
        detalhePendente = nil
        abrirDetalhe(id)
    }
}

