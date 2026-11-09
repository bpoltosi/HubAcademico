import SwiftUI

// MARK: - Tela 2: Busca e filtros
// Funil + campo de busca, filtros em checkbox (3 -> 16 caracteres)
// Regras do Design System UFSM:
// - Checkbox com raio de 5 pt e ativo em Azul UFSM #21376B
// - Campos e botões com raio de 10 pt
// - Cartões de resultados com raio de 14 pt
public struct SearchFilterView: View {
    @State private var searchText: String = "ruído"
    @State private var isFilterPanelExpanded: Bool = true
    
    // Estados dos checkboxes de filtro (Ordem crescente de caracteres: 3 -> 16)
    @State private var filtroAnoAtivo: Bool = true             // Ano (3)
    @State private var selectedAno: String = "2026"
    
    @State private var filtroAreaAtivo: Bool = true            // Área (4)
    @State private var selectedArea: String = "Engenharias"
    
    @State private var filtroAutorAtivo: Bool = false          // Autor (5)
    @State private var textAutor: String = ""
    
    @State private var filtroCursoAtivo: Bool = false          // Curso (5)
    @State private var selectedCurso: String = "Téc. Segurança do Trabalho"
    
    @State private var filtroTituloAtivo: Bool = false         // Título (6)
    @State private var textTitulo: String = ""
    
    @State private var filtroMateriaAtivo: Bool = false        // Matéria (7)
    @State private var selectedMateria: String = "Todas as matérias"
    
    @State private var filtroAvaliacaoAtivo: Bool = true       // Melhor avaliação (16)
    
    // Resultados
    @State private var items: [AcademicItem] = AcademicItem.mockList
    public var onSelectItem: (AcademicItem) -> Void
    
    public init(onSelectItem: @escaping (AcademicItem) -> Void = { _ in }) {
        self.onSelectItem = onSelectItem
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filtroAnoAtivo { count += 1 }
        if filtroAreaAtivo { count += 1 }
        if filtroAutorAtivo { count += 1 }
        if filtroCursoAtivo { count += 1 }
        if filtroTituloAtivo { count += 1 }
        if filtroMateriaAtivo { count += 1 }
        if filtroAvaliacaoAtivo { count += 1 }
        return count
    }
    
    private func resetFilters() {
        filtroAnoAtivo = false
        filtroAreaAtivo = false
        filtroAutorAtivo = false
        filtroCursoAtivo = false
        filtroTituloAtivo = false
        filtroMateriaAtivo = false
        filtroAvaliacaoAtivo = false
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho UFSM com busca ativa
            CTIAHeader(
                searchText: $searchText,
                onMenuTap: {},
                onAITap: {},
                onFilterTap: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFilterPanelExpanded.toggle()
                    }
                },
                showFilterActive: isFilterPanelExpanded
            )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if isFilterPanelExpanded {
                        VStack(spacing: 14) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.azulUFSM)
                                    
                                    Text("Filtrar por")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.textoPrincipal)
                                    
                                    Text("· \(activeFilterCount) ativos")
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundColor(Color.textoTerciario)
                                }
                                
                                Spacer()
                                
                                Button(action: resetFilters) {
                                    Text("Limpar")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.azulSecundario)
                                }
                            }
                            
                            Divider()
                                .background(Color.bordaUFSM)
                            
                            // Grid com os 7 filtros (Ordem de caracteres: Ano (3) até Melhor avaliação (16))
                            VStack(spacing: 10) {
                                // 1. Ano (3)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAnoAtivo, label: "Ano")
                                    Spacer()
                                    Picker("Ano", selection: $selectedAno) {
                                        Text("2026").tag("2026")
                                        Text("2025").tag("2025")
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.textoSecundario)
                                }
                                
                                // 2. Área (4)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAreaAtivo, label: "Área")
                                    Spacer()
                                    Picker("Área", selection: $selectedArea) {
                                        Text("Engenharias").tag("Engenharias")
                                        Text("Informática").tag("Informática")
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.textoSecundario)
                                }
                                
                                // 3. Autor (5)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAutorAtivo, label: "Autor")
                                    Spacer()
                                    TextField("Nome do(a) autor(a)", text: $textAutor)
                                        .font(.system(size: 12.5))
                                        .frame(width: 170)
                                }
                                
                                // 4. Curso (5)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroCursoAtivo, label: "Curso")
                                    Spacer()
                                    Picker("Curso", selection: $selectedCurso) {
                                        Text("Téc. Segurança do Trabalho").tag("Téc. Segurança do Trabalho")
                                        Text("Téc. Mecânica").tag("Téc. Mecânica")
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.textoSecundario)
                                }
                                
                                // 5. Título (6)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroTituloAtivo, label: "Título")
                                    Spacer()
                                    TextField("Palavras do título", text: $textTitulo)
                                        .font(.system(size: 12.5))
                                        .frame(width: 170)
                                }
                                
                                // 6. Matéria (7)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroMateriaAtivo, label: "Matéria")
                                    Spacer()
                                    Picker("Matéria", selection: $selectedMateria) {
                                        Text("Todas as matérias").tag("Todas as matérias")
                                        Text("Higiene Ocupacional").tag("Higiene Ocupacional")
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.textoSecundario)
                                }
                                
                                // 7. Melhor avaliação (16)
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAvaliacaoAtivo, label: "Melhor avaliação ★")
                                    Spacer()
                                    Text("Maior nota")
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundColor(Color.textoSecundario)
                                }
                            }
                            
                            // Botão Primário: "Q Aplicar filtros" (Azul UFSM, raio 10 pt)
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Aplicar filtros")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.azulUFSM)
                                .cornerRadius(10)
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.bordaUFSM, lineWidth: 1)
                        )
                    }
                    
                    // Cabeçalho de Resultados
                    HStack {
                        Text("2 resultados para \"\(searchText)\"")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.textoSecundario)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 11))
                            Text("Melhor avaliação")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color.azulUFSM)
                    }
                    .padding(.horizontal, 4)
                    
                    // Lista de Cards de Resultado (Raio de 14 pt)
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            Button(action: {
                                onSelectItem(item)
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(item.tipo == .projeto ? Color.azulProfundo : Color.azulSecundario.opacity(0.85))
                                            .frame(width: 72, height: 72)
                                        
                                        if item.tipo == .projeto {
                                            VStack(spacing: 4) {
                                                Image(systemName: "waveform.path.ecg")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(Color.ambarUFSM)
                                                Text("82 dB")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        } else {
                                            Image(systemName: item.tipo == .trabalho ? "graduationcap.fill" : "checklist")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.tipo.badgeLabel)
                                            .font(.system(size: 9.5, weight: .bold))
                                            .foregroundColor(Color.azulSecundario)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.azulSecundario.opacity(0.12))
                                            .cornerRadius(4)
                                        
                                        Text(item.titulo)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.textoPrincipal)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack(spacing: 4) {
                                            StarRatingView(rating: item.avaliacao, starSize: 11)
                                            
                                            Text(String(format: "%.1f", item.avaliacao).replacingOccurrences(of: ".", with: ","))
                                                .font(.system(size: 11.5, weight: .bold))
                                                .foregroundColor(Color.textoPrincipal)
                                            
                                            Text("(\(item.totalAvaliacoes)) · \(item.ano)")
                                                .font(.system(size: 11.5, weight: .regular))
                                                .foregroundColor(Color.textoTerciario)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.bordaUFSM, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.fundoUFSM)
        }
    }
}
