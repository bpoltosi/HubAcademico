import SwiftUI

// MARK: - Tela 1: Início
// Acesso rápido em ordem crescente de caracteres (8 -> 22)
// Regras do Design System UFSM:
// - Margem lateral de 16 pt, grade de 8 pt
// - Raio de 16 pt nos cartões de menu
// - Ícones SF Symbols: lightbulb.fill, checklist, graduationcap.fill, book.fill, plus.circle.fill
public struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var searchText: String = ""
    var onSelectCategory: (String) -> Void
    var onNavigateToCreate: () -> Void
    var onNavigateToSearch: () -> Void
    
    public init(
        selectedTab: Binding<Int>,
        onSelectCategory: @escaping (String) -> Void = { _ in },
        onNavigateToCreate: @escaping () -> Void = {},
        onNavigateToSearch: @escaping () -> Void = {}
    ) {
        self._selectedTab = selectedTab
        self.onSelectCategory = onSelectCategory
        self.onNavigateToCreate = onNavigateToCreate
        self.onNavigateToSearch = onNavigateToSearch
    }
    
    // Itens ordenados rigorosamente pelo tamanho do título (8 -> 22 caracteres)
    private let menuItems = [
        (titulo: "Projetos", subtitulo: "Pesquisa, extensão e inovação", icone: "lightbulb.fill", charCount: 8),
        (titulo: "Banco de provas", subtitulo: "Provas anteriores por matéria", icone: "checklist", charCount: 15),
        (titulo: "Trabalhos acadêmicos", subtitulo: "TCCs, artigos e relatórios", icone: "graduationcap.fill", charCount: 20),
        (titulo: "Material complementar", subtitulo: "Apostilas, vídeos e links", icone: "book.fill", charCount: 21)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho UFSM com filete dourado
            CTIAHeader(
                searchText: $searchText,
                onMenuTap: { /* Ação do menu lateral */ },
                onAITap: { onNavigateToSearch() }
            )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Saudação e boas-vindas
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Olá, estudante!")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundColor(Color.textoPrincipal)
                        
                        Text("Explore e compartilhe a produção acadêmica do CTISM.")
                            .font(.system(size: 14.5, weight: .regular))
                            .foregroundColor(Color.textoSecundario)
                    }
                    .padding(.top, 16)
                    
                    // Seção de Acesso Rápido com Marcador Dourado
                    SectionTitleView(title: "Acesso Rápido")
                    
                    // Lista de Cartões (Itens 1 a 4 com fundo branco e raio 16 pt)
                    VStack(spacing: 12) {
                        ForEach(menuItems, id: \.titulo) { item in
                            Button(action: {
                                onSelectCategory(item.titulo)
                            }) {
                                HStack(spacing: 14) {
                                    // Ícone com círculo azul suave
                                    ZStack {
                                        Circle()
                                            .fill(Color.azulSecundario.opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: item.icone)
                                            .font(.system(size: 18))
                                            .foregroundColor(Color.azulSecundario)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.titulo)
                                            .font(.system(size: 16.5, weight: .medium))
                                            .foregroundColor(Color.textoPrincipal)
                                        
                                        Text(item.subtitulo)
                                            .font(.system(size: 12.5, weight: .regular))
                                            .foregroundColor(Color.textoTerciario)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.bordaUFSM)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(16) // Raio de 16 pt no menu
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.bordaUFSM, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Item 5: "Cadastre o seu projeto" (22 caracteres)
                        // Destaque em Azul UFSM #21376B com texto branco
                        Button(action: onNavigateToCreate) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Cadastre o seu projeto")
                                        .font(.system(size: 16.5, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Compartilhe a sua produção")
                                        .font(.system(size: 12.5, weight: .regular))
                                        .foregroundColor(Color.white.opacity(0.85))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.azulUFSM)
                            .cornerRadius(16) // Raio de 16 pt no menu
                            .shadow(color: Color.azulUFSM.opacity(0.25), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.fundoUFSM)
        }
    }
}
