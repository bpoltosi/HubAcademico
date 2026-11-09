import SwiftUI

// MARK: - Cabeçalho Oficial CTIA / UFSM
// Regra do Design System: Azul UFSM #21376B, brasão e filete dourado de 2 pt #CC8F00
public struct CTIAHeader: View {
    @Binding var searchText: String
    var onMenuTap: () -> Void = {}
    var onAITap: () -> Void = {}
    var onFilterTap: (() -> Void)? = nil
    var showFilterActive: Bool = false
    
    public init(
        searchText: Binding<String>,
        onMenuTap: @escaping () -> Void = {},
        onAITap: @escaping () -> Void = {},
        onFilterTap: (() -> Void)? = nil,
        showFilterActive: Bool = false
    ) {
        self._searchText = searchText
        self.onMenuTap = onMenuTap
        self.onAITap = onAITap
        self.onFilterTap = onFilterTap
        self.showFilterActive = showFilterActive
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Top: Brasão UFSM e Identidade CTIA
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.douradoUFSM)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CTIA")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Repositório acadêmico do CTISM")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    Text("UFSM")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                // Barra de Ações: Menu + Campo de Busca + Busca IA
                HStack(spacing: 8) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                    
                    if let onFilterTap = onFilterTap {
                        Button(action: onFilterTap) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(showFilterActive ? Color.white : Color.white.opacity(0.18))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(showFilterActive ? Color.azulUFSM : .white)
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textoTerciario)
                        
                        TextField("O que você procura?", text: $searchText)
                            .font(.system(size: 13))
                            .foregroundColor(Color.textoPrincipal)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.textoTerciario)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    Button(action: onAITap) {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12))
                            Text("Busca IA")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(Color.azulUFSM)
                        .padding(.horizontal, 8)
                        .frame(height: 36)
                        .background(Color.white.opacity(0.92))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .background(Color.azulUFSM)
            
            // Filete Dourado de 2 pt
            Rectangle()
                .fill(Color.douradoUFSM)
                .frame(height: 2)
        }
    }
}
