import SwiftUI

/// Estrutura fixa do app: cabeçalho institucional no topo (igual ao site da UFSM),
/// a pilha de navegação abaixo dele e a Tela 3 como sheet por cima de tudo.
struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(ProducaoStore.self) private var store
    @Environment(BuscaModel.self) private var busca
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
                        case .cadastro(let tipo):
                            CadastroView(tipoInicial: tipo)
                        }
                    }
            }
            .tint(UFSM.azulSecundario)
            // Tela 3 — visualização em sheet, por cima da tela atual (normalmente a busca).
            .sheet(item: $router.detalhe) { selecionado in
                DetalheView(producaoID: selecionado.id)
                    .environment(store)
                    .environment(router)
            }
        }
        .background(UFSM.fundo)
        // Com o Node-RED configurado, atualiza a lista ao abrir o app e sempre que ele volta à tela.
        .task {
            await store.sincronizar()
        }
        .onChange(of: fase) { _, novaFase in
            if novaFase == .active {
                Task { await store.sincronizar() }
            }
        }
        .sheet(isPresented: $router.mostrarMenu, onDismiss: {
            router.abrirDetalhePendente()
        }) {
            MenuView()
                .environment(store)
                .environment(router)
                .environment(busca)
        }
    }
}

#Preview {
    RootView()
        .environment(ProducaoStore.previa)
        .environment(Router())
        .environment(BuscaModel())
}
