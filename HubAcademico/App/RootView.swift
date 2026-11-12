import SwiftUI

/// Estrutura fixa do app: cabeçalho institucional no topo (igual ao site da UFSM),
/// a pilha de navegação abaixo dele e a Tela 3 como sheet por cima de tudo.
struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(PublicacaoStore.self) private var store
    @Environment(\.scenePhase) private var fase

    var body: some View {
        @Bindable var router = router

        VStack(spacing: 0) {
            CabecalhoInstitucional()

            NavigationStack(path: $router.caminho) {
                InicioView()
                    .navigationDestination(for: Rota.self) { rota in
                        switch rota {
                        case .busca:
                            BuscaView()
                        case .publicar(let tipo):
                            PublicarView(tipoInicial: tipo)
                        }
                    }
            }
            .tint(UFSM.azulSecundario)
            // Tela 3 — visualização em sheet, por cima da tela atual (normalmente a busca).
            .sheet(item: $router.visualizacao) { selecionado in
                VisualizacaoView(publicacaoID: selecionado.id)
                    .environment(store)
                    .environment(router)
            }
        }
        .background(UFSM.fundo)
        // Com o Node-RED configurado, atualiza a lista ao abrir o app e sempre que ele volta à tela.
        // Ao voltar, também relê o link do servidor, que pode ter mudado nos Ajustes do iPhone.
        .task {
            await store.atualizarConfiguracao()
        }
        .onChange(of: fase) { _, novaFase in
            if novaFase == .active {
                Task { await store.atualizarConfiguracao() }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(PublicacaoStore.previa)
        .environment(Router())
        .environment(BuscaModel())
}
