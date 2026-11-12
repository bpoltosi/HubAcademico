import SwiftUI

/// Hub Acadêmico (CTISM/UFSM): projetos, trabalhos acadêmicos, provas e material complementar.
/// Ponto de entrada do app: cria os modelos compartilhados e os injeta no ambiente.
@main
struct HubAcademicoApp: App {
    @State private var store: PublicacaoStore
    @State private var router = Router()
    @State private var busca = BuscaModel()

    init() {
        // Antes de tudo: o que versões anteriores salvaram passa para os nomes padronizados.
        MigracaoDeNomes.atualizarPreferencias()
        FontRegistry.registrarFontes()
        Aparencia.configurar()
        _store = State(initialValue: PublicacaoStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(router)
                .environment(busca)
                .preferredColorScheme(.light)
        }
    }
}
