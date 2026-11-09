//
//  CTIA_Combined.swift
//  CTIA · Repositório Acadêmico do CTISM
//
//  Design das 4 telas do app iOS (SwiftUI) com o design system de ufsm.br
//  HackaTruck MakerSpace · Deploy 26.1
//  Compatível com iOS 16.0+, 17.0+ e 18.0+
//

import SwiftUI

// ==============================================================================
// MARK: - 1. DESIGN SYSTEM & TOKENS UFSM
// ==============================================================================

extension Color {
    /// Azul UFSM #21376B (cabeçalho, títulos, botão primário)
    static let azulUFSM = Color(hex: "21376B")
    
    /// Azul secundário #204C90 (ícones e rótulos do menu)
    static let azulSecundario = Color(hex: "204C90")
    
    /// Azul profundo #142140 (fundos de destaque e cartões IoT)
    static let azulProfundo = Color(hex: "142140")
    
    /// Dourado #CC8F00 (filete do cabeçalho de 2 pt, marcadores de seção)
    static let douradoUFSM = Color(hex: "CC8F00")
    
    /// Âmbar #FFC107 (estrelas de avaliação)
    static let ambarUFSM = Color(hex: "FFC107")
    
    /// Texto #1C1C1C (#4C4C4C e #6C757D nos níveis 2 e 3)
    static let textoPrincipal = Color(hex: "1C1C1C")
    static let textoSecundario = Color(hex: "4C4C4C")
    static let textoTerciario = Color(hex: "6C757D")
    
    /// Fundo #F1F4F9 (bordas #D3D7E1 · superfícies #FFFFFF)
    static let fundoUFSM = Color(hex: "F1F4F9")
    static let bordaUFSM = Color(hex: "D3D7E1")
    static let superficieUFSM = Color.white
    
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// Marcador de seção com filete dourado de 2-3 pt (| SEÇÃO)
struct SectionTitleView: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.douradoUFSM)
                .frame(width: 3, height: 14)
            
            Text(title.uppercased())
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color.textoSecundario)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Checkbox com raio de 5 pt e ativo em azul UFSM #21376B (Bootstrap do site)
struct CTIACheckbox: View {
    @Binding var isChecked: Bool
    let label: String
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isChecked ? Color.azulUFSM : Color.bordaUFSM, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isChecked ? Color.azulUFSM : Color.superficieUFSM)
                        )
                        .frame(width: 20, height: 20)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textoPrincipal)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44) // Área de toque mínima de 44 pt
    }
}

// Estrelas de Avaliação em Âmbar #FFC107
struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var starSize: CGFloat = 13
    var isInteractive: Bool = false
    var onRate: ((Int) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: starSize))
                    .foregroundColor(Double(index) <= rating || Double(index) - 0.5 <= rating ? Color.ambarUFSM : Color.bordaUFSM)
                    .onTapGesture {
                        if isInteractive {
                            onRate?(index)
                        }
                    }
            }
        }
    }
}

// ==============================================================================
// MARK: - 2. MODELOS DE DADOS
// ==============================================================================

enum AcademicType: String, CaseIterable, Identifiable {
    case projeto = "Projeto"
    case trabalho = "Trabalho"
    case prova = "Prova"
    
    var id: String { rawValue }
    
    var badgeLabel: String {
        switch self {
        case .projeto: return "PROJETO"
        case .trabalho: return "TRABALHO ACADÊMICO"
        case .prova: return "BANCO DE PROVAS"
        }
    }
}

struct AcademicItem: Identifiable, Hashable {
    let id: UUID
    var tipo: AcademicType
    var titulo: String
    var resumo: String
    var autores: String
    var area: String
    var materia: String
    var curso: String
    var instituicao: String
    var ano: Int
    var avaliacao: Double
    var totalAvaliacoes: Int
    var imagemUrl: String?
    var linkPublicado: String?
    var linkTipo: String
    var isSaved: Bool
    
    var localTelemetria: String?
    var statusAoVivo: String?
    var limiteDb: Double?
    var dbAtual: Double?
    var sensorChip: String?
    
    init(
        id: UUID = UUID(),
        tipo: AcademicType,
        titulo: String,
        resumo: String,
        autores: String,
        area: String,
        materia: String,
        curso: String,
        instituicao: String = "CTISM - UFSM",
        ano: Int = 2026,
        avaliacao: Double = 4.8,
        totalAvaliacoes: Int = 37,
        imagemUrl: String? = "https://example.com/monitor-ruido",
        linkPublicado: String? = "https://linkedin.com/posts/ana-clara-machado",
        linkTipo: String = "LinkedIn",
        isSaved: Bool = false,
        localTelemetria: String? = nil,
        statusAoVivo: String? = nil,
        limiteDb: Double? = nil,
        dbAtual: Double? = nil,
        sensorChip: String? = nil
    ) {
        self.id = id
        self.tipo = tipo
        self.titulo = titulo
        self.resumo = resumo
        self.autores = autores
        self.area = area
        self.materia = materia
        self.curso = curso
        self.instituicao = instituicao
        self.ano = ano
        self.avaliacao = avaliacao
        self.totalAvaliacoes = totalAvaliacoes
        self.imagemUrl = imagemUrl
        self.linkPublicado = linkPublicado
        self.linkTipo = linkTipo
        self.isSaved = isSaved
        self.localTelemetria = localTelemetria
        self.statusAoVivo = statusAoVivo
        self.limiteDb = limiteDb
        self.dbAtual = dbAtual
        self.sensorChip = sensorChip
    }
    
    static let mockNoiseMonitor = AcademicItem(
        tipo: .projeto,
        titulo: "Monitor IoT de ruído nas oficinas do CTISM",
        resumo: "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas.",
        autores: "Ana Clara Machado e Lucas Ferreira",
        area: "Engenharias",
        materia: "Higiene Ocupacional",
        curso: "Téc. Segurança do Trabalho",
        instituicao: "CTISM - UFSM",
        ano: 2026,
        avaliacao: 4.8,
        totalAvaliacoes: 37,
        linkPublicado: "https://linkedin.com/posts/ana-clara-machado",
        isSaved: true,
        localTelemetria: "OFICINA DE MECÂNICA",
        statusAoVivo: "AO VIVO",
        limiteDb: 85.0,
        dbAtual: 82.0,
        sensorChip: "ESP32 · Wi-Fi"
    )
    
    static let mockDosimetry = AcademicItem(
        tipo: .trabalho,
        titulo: "Dosimetria de ruído na oficina de soldagem",
        resumo: "Estudo prático comparativo de níveis de pressão sonora contínuos na oficina de soldagem do CTISM, avaliando doses em jornada de trabalho conforme NR-15.",
        autores: "Pedro Henrique Santos",
        area: "Engenharias",
        materia: "Higiene Ocupacional",
        curso: "Téc. Mecânica",
        instituicao: "CTISM - UFSM",
        ano: 2026,
        avaliacao: 4.6,
        totalAvaliacoes: 21,
        linkTipo: "GitHub"
    )
    
    static let mockList: [AcademicItem] = [mockNoiseMonitor, mockDosimetry]
}

// ==============================================================================
// MARK: - 3. REGRAS DE NEGÓCIO E LÓGICA DE CATÁLOGO (AcademicCatalogLogic)
// ==============================================================================

struct SearchFilters: Hashable {
    var termoBusca: String = ""
    var ano: Int? = nil
    var area: String? = nil
    var autor: String? = nil
    var curso: String? = nil
    var titulo: String? = nil
    var materia: String? = nil
    var melhorAvaliacao: Bool = false
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String: String]
    let charCount: Int
}

enum AcademicCatalogLogic {
    /// Regra: Verifica se os rótulos seguem ordem estritamente crescente de caracteres
    static func verifyCharacterOrdering(_ labels: [String]) -> Bool {
        guard labels.count > 1 else { return true }
        for i in 0..<(labels.count - 1) {
            if labels[i].count > labels[i + 1].count {
                return false
            }
        }
        return true
    }
    
    /// Regra: Valida resumo limitado a até 200 caracteres e campos obrigatórios
    static func validateAcademicItem(
        titulo: String,
        resumo: String,
        area: String,
        materia: String
    ) -> ValidationResult {
        var errors: [String: String] = [:]
        let trimmedTitulo = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResumo = resumo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArea = area.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMateria = materia.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let charCount = resumo.count
        
        if trimmedTitulo.isEmpty { errors["titulo"] = "Título é obrigatório" }
        if trimmedResumo.isEmpty {
            errors["resumo"] = "Resumo é obrigatório"
        } else if charCount > 200 {
            errors["resumo"] = "Resumo excede o limite de 200 caracteres (\(charCount)/200)"
        }
        if trimmedArea.isEmpty || trimmedArea == "Todas as áreas" { errors["area"] = "Área é obrigatória" }
        if trimmedMateria.isEmpty || trimmedMateria == "Todas as matérias" { errors["materia"] = "Matéria é obrigatória" }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, charCount: charCount)
    }
    
    /// Regra: Filtra itens acadêmicos conforme busca e critérios ativos
    static func filterAcademicItems(items: [AcademicItem], filters: SearchFilters) -> [AcademicItem] {
        return items.filter { item in
            if !filters.termoBusca.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let query = filters.termoBusca.lowercased()
                let itemText = "\(item.titulo) \(item.resumo) \(item.autores) \(item.area) \(item.materia) \(item.curso)".lowercased()
                if !itemText.contains(query) { return false }
            }
            if let ano = filters.ano, item.ano != ano { return false }
            if let area = filters.area, !area.isEmpty, area != "Todas as áreas", item.area != area { return false }
            if let autor = filters.autor, !autor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !item.autores.lowercased().contains(autor.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) { return false }
            }
            if let curso = filters.curso, !curso.isEmpty, curso != "Todos os cursos", item.curso != curso { return false }
            if let titulo = filters.titulo, !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !item.titulo.lowercased().contains(titulo.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) { return false }
            }
            if let materia = filters.materia, !materia.isEmpty, materia != "Todas as matérias", item.materia != materia { return false }
            if filters.melhorAvaliacao && item.avaliacao < 4.5 { return false }
            return true
        }
    }
    
    /// Regra: Formatação decimal brasileira (ex: 4,8)
    static func formatRatingBR(_ rating: Double) -> String {
        return String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
    }
}

// ==============================================================================
// MARK: - 4. CABEÇALHO OFICIAL (COM BRASÃO E FILETE DOURADO DE 2 PT)
// ==============================================================================

struct CTIAHeader: View {
    @Binding var searchText: String
    var onHomeTap: () -> Void = {} // Função padrão das 3 barras: voltar para a tela inicial
    var onAITap: () -> Void = {}
    var onFilterTap: (() -> Void)? = nil
    var showFilterActive: Bool = false
    
    var body: some View {
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
                
                // Barra de Ações: 3 Barras (Volta ao Início) + Filtro + Campo de Busca + Busca IA
                HStack(spacing: 8) {
                    // Botão 3 barras laterais: volta para a tela inicial por padrão
                    Button(action: onHomeTap) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Voltar para o início")
                    
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
            
            // Filete Dourado de 2 pt obrigatório pelo Design System da UFSM
            Rectangle()
                .fill(Color.douradoUFSM)
                .frame(height: 2)
        }
    }
}

// ==============================================================================
// MARK: - 4. TELA 1: INÍCIO (ORDEM CRESCENTE DE CARACTERES 8 -> 22)
// ==============================================================================

struct HomeView: View {
    @Binding var currentScreen: AppScreen
    @State private var searchText = ""
    
    private let menuItems = [
        (titulo: "Projetos", subtitulo: "Pesquisa, extensão e inovação", icone: "lightbulb.fill"),
        (titulo: "Banco de provas", subtitulo: "Provas anteriores por matéria", icone: "checklist"),
        (titulo: "Trabalhos acadêmicos", subtitulo: "TCCs, artigos e relatórios", icone: "graduationcap.fill"),
        (titulo: "Material complementar", subtitulo: "Apostilas, vídeos e links", icone: "book.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: $searchText, onAITap: { currentScreen = .buscaFiltros })
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Olá, estudante!")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundColor(Color.textoPrincipal)
                        Text("Explore e compartilhe a produção acadêmica do CTISM.")
                            .font(.system(size: 14.5, weight: .regular))
                            .foregroundColor(Color.textoSecundario)
                    }
                    .padding(.top, 16)
                    
                    SectionTitleView(title: "Acesso Rápido")
                    
                    VStack(spacing: 12) {
                        ForEach(menuItems, id: \.titulo) { item in
                            Button(action: { currentScreen = .buscaFiltros }) {
                                HStack(spacing: 14) {
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
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordaUFSM, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Item 5: Cadastre o seu projeto (22 chars) em Azul UFSM #21376B
                        Button(action: { currentScreen = .cadastro }) {
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
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.azulUFSM)
                            .cornerRadius(16)
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

// ==============================================================================
// MARK: - 5. TELA 2: BUSCA E FILTROS (CHECKBOXES 3 -> 16 CARACTERES)
// ==============================================================================

struct SearchFilterView: View {
    @Binding var currentScreen: AppScreen
    @Binding var selectedItem: AcademicItem
    @State private var searchText = "ruído"
    @State private var isFilterPanelExpanded = true
    
    // Checkboxes dos filtros
    @State private var filtroAno = true
    @State private var filtroArea = true
    @State private var filtroAutor = false
    @State private var filtroCurso = false
    @State private var filtroTitulo = false
    @State private var filtroMateria = false
    @State private var filtroMelhorAvaliacao = true
    
    @State private var selectedAno = "2026"
    @State private var selectedArea = "Engenharias"
    @State private var textAutor = ""
    @State private var selectedCurso = "Téc. Segurança do Trabalho"
    @State private var textTitulo = ""
    @State private var selectedMateria = "Todas as matérias"
    
    var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(
                searchText: $searchText,
                onHomeTap: { currentScreen = .inicio },
                onFilterTap: {
                    withAnimation { isFilterPanelExpanded.toggle() }
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
                                        .foregroundColor(Color.azulUFSM)
                                    Text("Filtrar por")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("· 4 ativos")
                                        .font(.system(size: 12.5))
                                        .foregroundColor(Color.textoTerciario)
                                }
                                Spacer()
                                Button("Limpar") {
                                    filtroAno = false; filtroArea = false; filtroAutor = false
                                    filtroCurso = false; filtroTitulo = false; filtroMateria = false
                                    filtroMelhorAvaliacao = false
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.azulSecundario)
                            }
                            
                            Divider()
                            
                            VStack(spacing: 10) {
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAno, label: "Ano")
                                    Spacer()
                                    Picker("Ano", selection: $selectedAno) {
                                        Text("2026").tag("2026")
                                    }.pickerStyle(.menu).tint(Color.textoSecundario)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroArea, label: "Área")
                                    Spacer()
                                    Picker("Área", selection: $selectedArea) {
                                        Text("Engenharias").tag("Engenharias")
                                    }.pickerStyle(.menu).tint(Color.textoSecundario)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAutor, label: "Autor")
                                    Spacer()
                                    TextField("Nome do(a) autor(a)", text: $textAutor)
                                        .font(.system(size: 12.5)).frame(width: 170)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroCurso, label: "Curso")
                                    Spacer()
                                    Picker("Curso", selection: $selectedCurso) {
                                        Text("Téc. Segurança do Trabalho").tag("Téc. Segurança do Trabalho")
                                    }.pickerStyle(.menu).tint(Color.textoSecundario)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroTitulo, label: "Título")
                                    Spacer()
                                    TextField("Palavras do título", text: $textTitulo)
                                        .font(.system(size: 12.5)).frame(width: 170)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroMateria, label: "Matéria")
                                    Spacer()
                                    Picker("Matéria", selection: $selectedMateria) {
                                        Text("Todas as matérias").tag("Todas as matérias")
                                    }.pickerStyle(.menu).tint(Color.textoSecundario)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroMelhorAvaliacao, label: "Melhor avaliação ★")
                                    Spacer()
                                    Text("Maior nota").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                                }
                            }
                            
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                    Text("Aplicar filtros").font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.azulUFSM)
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    HStack {
                        Text("2 resultados para \"\(searchText)\"")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.textoSecundario)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Melhor avaliação")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.azulUFSM)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(AcademicItem.mockList) { item in
                            Button(action: {
                                selectedItem = item
                                currentScreen = .visualizacao
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(item.tipo == .projeto ? Color.azulProfundo : Color.azulSecundario.opacity(0.85))
                                            .frame(width: 72, height: 72)
                                        if item.tipo == .projeto {
                                            VStack(spacing: 4) {
                                                Image(systemName: "waveform.path.ecg").foregroundColor(Color.ambarUFSM)
                                                Text("82 dB").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                                            }
                                        } else {
                                            Image(systemName: "graduationcap.fill").foregroundColor(.white)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.tipo.badgeLabel)
                                            .font(.system(size: 9.5, weight: .bold))
                                            .foregroundColor(Color.azulSecundario)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.azulSecundario.opacity(0.12))
                                            .cornerRadius(4)
                                        
                                        Text(item.titulo)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.textoPrincipal)
                                            .lineLimit(2)
                                        
                                        HStack(spacing: 4) {
                                            StarRatingView(rating: item.avaliacao, starSize: 11)
                                            Text(String(format: "%.1f", item.avaliacao).replacingOccurrences(of: ".", with: ","))
                                                .font(.system(size: 11.5, weight: .bold))
                                            Text("(\(item.totalAvaliacoes)) · \(item.ano)")
                                                .font(.system(size: 11.5))
                                                .foregroundColor(Color.textoTerciario)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordaUFSM, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.fundoUFSM)
        }
    }
}

// ==============================================================================
// MARK: - 6. TELA 3: VISUALIZAÇÃO (DETALHES DO PROJETO E TELEMETRIA)
// ==============================================================================

struct DetailView: View {
    @Binding var currentScreen: AppScreen
    @Binding var item: AcademicItem
    @State private var userRating = 0
    @State private var isSaved = true
    
    var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: .constant(""), onHomeTap: { currentScreen = .inicio })
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button(action: { currentScreen = .buscaFiltros }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Resultados")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.azulUFSM)
                        }
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: { isSaved.toggle() }) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(isSaved ? Color.azulUFSM : Color.textoTerciario)
                            }
                            Image(systemName: "square.and.arrow.up").foregroundColor(Color.textoTerciario)
                        }
                    }
                    .padding(.top, 8)
                    
                    HStack(spacing: 8) {
                        Text(item.tipo.badgeLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.azulSecundario)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.azulSecundario.opacity(0.12)).cornerRadius(4)
                        
                        Text("📅 \(item.ano)").font(.system(size: 11.5)).foregroundColor(Color.textoTerciario)
                        Text("🏛 \(item.curso)").font(.system(size: 11.5)).foregroundColor(Color.textoTerciario)
                    }
                    
                    Text(item.titulo)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(Color.textoPrincipal)
                    
                    // Card IoT Telemetria
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Circle().fill(Color.red).frame(width: 8, height: 8)
                            Text("OFICINA DE MECÂNICA · AO VIVO").font(.system(size: 10.5, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text("ESP32 · Wi-Fi").font(.system(size: 9.5, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 3) {
                                    ForEach(0..<18, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(i > 12 ? Color.ambarUFSM : Color.cyan.opacity(0.8))
                                            .frame(width: 5, height: CGFloat([22, 35, 18, 48, 62, 55, 40, 70, 80, 65, 45, 58, 75, 82, 60, 48, 30, 20][i % 18]))
                                    }
                                }
                                .frame(height: 70, alignment: .bottom)
                                Text("Limite 85 dB(A)").font(.system(size: 8.5, weight: .medium)).foregroundColor(Color.ambarUFSM)
                            }
                            Spacer()
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.15), lineWidth: 5).frame(width: 68, height: 68)
                                Circle().trim(from: 0, to: 0.75).stroke(Color.cyan, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 68, height: 68)
                                VStack(spacing: 0) {
                                    Text("82").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    Text("dB").font(.system(size: 9.5)).foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(14).background(Color.azulProfundo).cornerRadius(12)
                    
                    HStack {
                        Text(item.autores).font(.system(size: 13, weight: .medium)).foregroundColor(Color.textoPrincipal)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                            Text("LinkedIn")
                        }
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Color.azulSecundario)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitleView(title: "Resumo")
                        Text(item.resumo).font(.system(size: 14)).foregroundColor(Color.textoSecundario).lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitleView(title: "Avaliações")
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "%.1f", item.avaliacao).replacingOccurrences(of: ".", with: ","))
                                    .font(.system(size: 32, weight: .bold))
                                StarRatingView(rating: item.avaliacao, starSize: 13)
                                Text("\(item.totalAvaliacoes) avaliações").font(.system(size: 11)).foregroundColor(Color.textoTerciario)
                            }
                            Divider().frame(height: 54)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Avalie este projeto").font(.system(size: 12.5, weight: .semibold))
                                StarRatingView(rating: Double(userRating), starSize: 18, isInteractive: true, onRate: { userRating = $0 })
                                Text("Toque para dar sua nota").font(.system(size: 10.5)).foregroundColor(Color.textoTerciario)
                            }
                        }
                        .padding(14).background(Color.white).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitleView(title: "Área")
                            Text(item.area).font(.system(size: 12.5, weight: .medium))
                        }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.white).cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitleView(title: "Matéria")
                            Text(item.materia).font(.system(size: 12.5, weight: .medium))
                        }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.white).cornerRadius(10)
                    }
                }
                .padding(16)
            }
            .background(Color.fundoUFSM)
        }
    }
}

// ==============================================================================
// MARK: - 7. TELA 4: CADASTRO (FORMULÁRIO UNIFICADO COM CONTADOR 200 CHARS)
// ==============================================================================

struct CreateItemView: View {
    @Binding var currentScreen: AppScreen
    @Binding var academicItems: [AcademicItem]
    
    @State private var selectedTipo: AcademicType = .projeto
    @State private var titulo = "Monitor IoT de ruído nas oficinas do CTISM"
    @State private var resumo = "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas."
    @State private var imagemUrl = "https://example.com/monitor-ruido"
    @State private var linkTipo = "LinkedIn"
    @State private var linkPublicado = "linkedin.com/posts/ana-clara-machado"
    @State private var selectedArea = "Engenharias"
    @State private var selectedMateria = "Higiene Ocupacional"
    @State private var instituicao = "CTISM - UFSM"
    @State private var selectedAno = "2026"
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: .constant(""), onHomeTap: { currentScreen = .inicio })
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button(action: { currentScreen = .inicio }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Início")
                            }
                            .foregroundColor(Color.azulUFSM)
                        }
                        Spacer()
                        Text("Cadastre o seu projeto").font(.system(size: 15, weight: .bold))
                        Spacer()
                        Color.clear.frame(width: 44, height: 1)
                    }
                    .padding(.top, 6)
                    
                    Picker("Tipo", selection: $selectedTipo) {
                        ForEach(AcademicType.allCases) { tipo in
                            Text(tipo.rawValue).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Título *").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                        TextField("Título da produção acadêmica", text: $titulo)
                            .padding(.horizontal, 12).frame(height: 42).background(Color.white).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Descrição — breve resumo (até 200 caracteres) *")
                                .font(.system(size: 12, weight: .medium)).foregroundColor(Color.textoSecundario)
                            Spacer()
                            Text("\(resumo.count)/200")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(resumo.count > 200 ? .red : Color.textoTerciario)
                        }
                        TextEditor(text: $resumo)
                            .frame(height: 85).padding(8).background(Color.white).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(resumo.count > 200 ? Color.red : Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Imagem da descrição (URL)").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                        HStack {
                            TextField("https://...", text: $imagemUrl).padding(.horizontal, 12).frame(height: 42)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Color.azulUFSM).frame(width: 36, height: 36)
                                Image(systemName: "photo").foregroundColor(.white)
                            }.padding(.trailing, 4)
                        }
                        .background(Color.white).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Link onde foi publicado").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                        HStack {
                            Picker("Rede", selection: $linkTipo) {
                                Text("LinkedIn").tag("LinkedIn")
                                Text("GitHub").tag("GitHub")
                            }.pickerStyle(.menu).tint(Color.azulUFSM).frame(height: 42).padding(.horizontal, 8).background(Color.fundoUFSM).cornerRadius(8)
                            TextField("link...", text: $linkPublicado).padding(.horizontal, 8).frame(height: 42)
                        }
                        .background(Color.white).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Área *").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                        Picker("Área", selection: $selectedArea) {
                            Text("Engenharias").tag("Engenharias")
                        }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).frame(height: 42).background(Color.white).cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Matéria *").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                        Picker("Matéria", selection: $selectedMateria) {
                            Text("Higiene Ocupacional").tag("Higiene Ocupacional")
                        }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).frame(height: 42).background(Color.white).cornerRadius(10)
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Instituição *").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                            TextField("Instituição", text: $instituicao).padding(.horizontal, 12).frame(height: 42).background(Color.white).cornerRadius(10)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ano *").font(.system(size: 12.5, weight: .medium)).foregroundColor(Color.textoSecundario)
                            Picker("Ano", selection: $selectedAno) {
                                Text("2026").tag("2026")
                            }.pickerStyle(.menu).padding(.horizontal, 12).frame(height: 42).background(Color.white).cornerRadius(10)
                        }.frame(width: 90)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Salvar rascunho") {}
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textoPrincipal)
                            .frame(maxWidth: .infinity).frame(height: 44).background(Color.white).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordaUFSM, lineWidth: 1.5))
                        
                        Button(action: {
                            let newItem = AcademicItem(
                                tipo: selectedTipo,
                                titulo: titulo,
                                resumo: resumo,
                                autores: "Estudante do CTISM",
                                area: selectedArea,
                                materia: selectedMateria,
                                curso: "Téc. Segurança do Trabalho",
                                ano: Int(selectedAno) ?? 2026,
                                avaliacao: 5.0,
                                totalAvaliacoes: 1
                            )
                            academicItems.insert(newItem, at: 0)
                            showSuccess = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                Text("Publicar").font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 44).background(Color.azulUFSM).cornerRadius(10)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Color.fundoUFSM)
            .alert("Sucesso!", isPresented: $showSuccess) {
                Button("OK") { currentScreen = .inicio }
            } message: {
                Text("Item publicado com sucesso no CTIA!")
            }
        }
    }
}

// ==============================================================================
// MARK: - 8. NAVEGAÇÃO E PREVIEW NO XCODE
// ==============================================================================

enum AppScreen {
    case inicio
    case buscaFiltros
    case visualizacao
    case cadastro
}

struct ContentView: View {
    @State private var currentScreen: AppScreen = .inicio
    @State private var selectedItem = AcademicItem.mockNoiseMonitor
    @State private var academicItems = AcademicItem.mockList
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .inicio:
                HomeView(currentScreen: $currentScreen)
            case .buscaFiltros:
                SearchFilterView(currentScreen: $currentScreen, selectedItem: $selectedItem)
            case .visualizacao:
                DetailView(currentScreen: $currentScreen, item: $selectedItem)
            case .cadastro:
                CreateItemView(currentScreen: $currentScreen, academicItems: $academicItems)
            }
        }
    }
}

#Preview {
    ContentView()
}
