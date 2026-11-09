import SwiftUI

/// Entry point oficial do aplicativo CTIA em SwiftUI para iOS 16+ / 17+ / 18+
/// Projeto: CTIA · Repositório Acadêmico do CTISM
/// Tema oficial: ufsm.br · HackaTruck MakerSpace · Deploy 26.1
@main
public struct CTIAApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainContainerView()
                .preferredColorScheme(.light)
        }
    }
}

public struct MainContainerView: View {
    @State private var currentScreen: AppScreen = .inicio
    @State private var selectedItem: AcademicItem = AcademicItem.mockNoiseMonitor
    @State private var academicItems: [AcademicItem] = AcademicItem.mockList
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                switch currentScreen {
                case .inicio:
                    HomeView(
                        onSelectCategory: { _ in currentScreen = .buscaFiltros },
                        onNavigateToCreate: { currentScreen = .cadastro },
                        onNavigateToSearch: { currentScreen = .buscaFiltros }
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
                        onBack: { currentScreen = .buscaFiltros }
                    )
                case .cadastro:
                    CreateItemView(
                        onBack: { currentScreen = .inicio },
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

public enum AppScreen {
    case inicio
    case buscaFiltros
    case visualizacao
    case cadastro
}
