import SwiftUI

/// Hub Acadêmico — repositório acadêmico do CTISM/UFSM.
/// Ponto de entrada do app: cria os modelos compartilhados e os injeta no ambiente.
@main
struct HubAcademicoApp: App {
    @State private var store = ProducaoStore()
    @State private var router = Router()
    @State private var busca = BuscaModel()

    init() {
        FontRegistry.registrarFontes()
        Aparencia.configurar()
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
