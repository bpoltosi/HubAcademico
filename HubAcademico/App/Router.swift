import Foundation
import Observation

/// Telas empilhadas na navegação.
/// A visualização (Tela 3) não entra na pilha: ela abre como sheet por cima da tela atual.
///
/// Mapa do app — 3 telas + 1 sheet (4 views):
/// Tela 1 Início (raiz) → Tela 2 Busca → Tela 3 Visualização (sheet) · Tela 4 Publicar
///
/// Navegação: "‹ Voltar" volta uma tela; o botão ☰ do cabeçalho volta direto para o Início.
enum Rota: Hashable {
    case busca
    case publicar(TipoPublicacao)
}

/// Publicação aberta na sheet da Tela 3.
struct VisualizacaoSelecionada: Identifiable, Hashable {
    let id: UUID
}

/// Controla a pilha de navegação e a sheet de visualização.
/// Fica fora da NavigationStack para que o cabeçalho institucional também possa navegar.
@Observable
final class Router {
    var caminho: [Rota] = []
    /// Pedido para focar o campo de busca assim que a tela de busca abrir.
    var pedirFocoNaBusca = false
    /// Publicação exibida na sheet da Tela 3 (`nil` = sheet fechada).
    var visualizacao: VisualizacaoSelecionada?

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
    func abrirVisualizacao(_ id: UUID) {
        visualizacao = VisualizacaoSelecionada(id: id)
    }

    /// Botão ☰ do cabeçalho: volta direto para a tela inicial, de qualquer ponto do app.
    func voltarAoInicio() {
        visualizacao = nil
        caminho.removeAll()
    }

    /// Depois de publicar: fecha a Tela 4 e mostra a nova publicação na sheet.
    func concluirPublicacao(_ id: UUID) {
        if let ultima = caminho.last, case .publicar = ultima {
            caminho.removeLast()
        }
        // Espera a animação de voltar terminar antes de subir a sheet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.abrirVisualizacao(id)
        }
    }
}
