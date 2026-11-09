import SwiftUI

// MARK: - Entry Point da Aplicação CTIA (SwiftUI)
// Projeto: CTIA · Repositório acadêmico do CTISM
// Design system oficial de ufsm.br · HackaTruck MakerSpace · Deploy 26.1

@main
struct CTIAApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .preferredColorScheme(.light) // O Design System da UFSM é otimizado para Light Mode
        }
    }
}

// MARK: - Navegação Principal do App
struct MainContainerView: View {
    @State private var currentScreen: AppScreen = .inicio
    @State private var selectedItem: AcademicItem = AcademicItem.mockNoiseMonitor
    @State private var academicItems: [AcademicItem] = AcademicItem.mockList
    
    enum AppScreen {
        case inicio
        case buscaFiltros
        case visualizacao
        case cadastro
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch currentScreen {
                case .inicio:
                    HomeView(
                        selectedTab: .constant(0),
                        onSelectCategory: { category in
                            currentScreen = .buscaFiltros
                        },
                        onNavigateToCreate: {
                            currentScreen = .cadastro
                        },
                        onNavigateToSearch: {
                            currentScreen = .buscaFiltros
                        }
                    )
                    
                case .buscaFiltros:
                    SearchFilterView(
                        onSelectItem: { item in
                            selectedItem = item
                            currentScreen = .visualizacao
                        }
                    )
                    
                case .visualizacao:
                    DetailView(
                        item: selectedItem,
                        onBack: {
                            currentScreen = .buscaFiltros
                        }
                    )
                    
                case .cadastro:
                    CreateItemView(
                        onBack: {
                            currentScreen = .inicio
                        },
                        onPublishSuccess: { newItem in
                            academicItems.insert(newItem, at: 0)
                            selectedItem = newItem
                            currentScreen = .visualizacao
                        }
                    )
                }
            }
        }
    }
}
