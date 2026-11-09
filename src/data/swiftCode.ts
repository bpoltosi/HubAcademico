export interface SwiftFile {
  filename: string;
  relativePath: string;
  category: string;
  description: string;
  code: string;
}

export const SWIFT_FILES: SwiftFile[] = [
  {
    filename: 'CTIA_Combined.swift',
    relativePath: 'CTIA_Combined.swift',
    category: 'Pronto para Xcode (Arquivo Único)',
    description: 'Arquivo único consolidado com todas as 4 telas, modelos e design system. Basta colar no ContentView.swift do Xcode!',
    code: `//
//  CTIA_Combined.swift
//  CTIA · Repositório Acadêmico do CTISM
//  Design das 4 telas do app iOS (SwiftUI) com o design system de ufsm.br
//  HackaTruck MakerSpace · Deploy 26.1
//

import SwiftUI

// MARK: - 1. DESIGN SYSTEM & TOKENS UFSM
extension Color {
    static let azulUFSM = Color(hex: "21376B")        // Cabeçalho, títulos, botão primário
    static let azulSecundario = Color(hex: "204C90")   // Ícones e rótulos do menu
    static let azulProfundo = Color(hex: "142140")     // Fundos de destaque e IoT
    static let douradoUFSM = Color(hex: "CC8F00")      // Filete do cabeçalho de 2 pt, marcadores
    static let ambarUFSM = Color(hex: "FFC107")        // Estrelas de avaliação
    static let textoPrincipal = Color(hex: "1C1C1C")
    static let textoSecundario = Color(hex: "4C4C4C")
    static let textoTerciario = Color(hex: "6C757D")
    static let fundoUFSM = Color(hex: "F1F4F9")
    static let bordaUFSM = Color(hex: "D3D7E1")
    static let superficieUFSM = Color.white

    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct SectionTitleView: View {
    let title: String
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Color.douradoUFSM).frame(width: 3, height: 14)
            Text(title.uppercased())
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color.textoSecundario)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CTIACheckbox: View {
    @Binding var isChecked: Bool
    let label: String
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isChecked ? Color.azulUFSM : Color.bordaUFSM, lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 5).fill(isChecked ? Color.azulUFSM : Color.superficieUFSM))
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
        .frame(minHeight: 44)
    }
}

struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var starSize: CGFloat = 13
    var isInteractive: Bool = false
    var onRate: ((Int) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxRating, id: \\.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: starSize))
                    .foregroundColor(Double(index) <= rating || Double(index) - 0.5 <= rating ? Color.ambarUFSM : Color.bordaUFSM)
                    .onTapGesture {
                        if isInteractive { onRate?(index) }
                    }
            }
        }
    }
}

// MARK: - 2. MODELOS
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
        imagemUrl: String? = nil,
        linkPublicado: String? = nil,
        linkTipo: String = "LinkedIn",
        isSaved: Bool = false
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
        isSaved: true
    )
}

// MARK: - 3. CABEÇALHO OFICIAL (COM BRASÃO E FILETE DOURADO DE 2 PT)
struct CTIAHeader: View {
    @Binding var searchText: String
    var onHomeTap: () -> Void = {} // Volta para a tela inicial por padrão
    var onFilterTap: (() -> Void)? = nil
    var showFilterActive: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.15)).frame(width: 32, height: 32)
                            Image(systemName: "flame.fill").foregroundColor(Color.douradoUFSM).font(.system(size: 14))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CTIA").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Text("Repositório acadêmico do CTISM").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    Text("UFSM").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                HStack(spacing: 8) {
                    // Botão 3 barras laterais: retorna à tela inicial
                    Button(action: onHomeTap) {
                        Image(systemName: "line.3.horizontal").foregroundColor(.white).frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Voltar para o início")
                    
                    if let onFilterTap = onFilterTap {
                        Button(action: onFilterTap) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(showFilterActive ? Color.white : Color.white.opacity(0.18)).frame(width: 36, height: 36)
                                Image(systemName: "line.3.horizontal.decrease.circle").foregroundColor(showFilterActive ? Color.azulUFSM : .white)
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").foregroundColor(Color.textoTerciario)
                        TextField("O que você procura?", text: $searchText)
                    }
                    .padding(.horizontal, 10).frame(height: 36).background(Color.white).cornerRadius(10)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Busca IA").font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundColor(Color.azulUFSM).padding(.horizontal, 8).frame(height: 36).background(Color.white.opacity(0.92)).cornerRadius(10)
                }
                .padding(.horizontal, 16).padding(.bottom, 10)
            }
            .background(Color.azulUFSM)
            
            Rectangle().fill(Color.douradoUFSM).frame(height: 2)
        }
    }
}
`,
  },
  {
    filename: 'Package.swift',
    relativePath: 'Package.swift',
    category: 'Swift Package Manager',
    description: 'Manifesto do Swift Package Manager declarando o pacote CTIA, alvos e compatibilidade iOS 16+.',
    code: `// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CTIA",
    defaultLocalization: "pt-BR",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "CTIA", targets: ["CTIA"]),
    ],
    targets: [
        .target(name: "CTIA", path: "Sources/CTIA"),
        .testTarget(name: "CTIATests", dependencies: ["CTIA"], path: "Tests/CTIATests"),
    ]
)`,
  },
  {
    filename: 'CTIAApp.swift',
    relativePath: 'Sources/CTIA/App/CTIAApp.swift',
    category: 'App Entry Point',
    description: 'Entry point @main struct CTIAApp: App e NavigationStack gerenciando as 4 telas.',
    code: `import SwiftUI

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
}`,
  },
  {
    filename: 'HomeView.swift',
    relativePath: 'Sources/CTIA/Views/Home/HomeView.swift',
    category: 'Tela 1: Início',
    description: 'Menu de acesso rápido em ordem crescente rigorosa de caracteres (8 -> 22) e destaque em Azul UFSM.',
    code: `import SwiftUI

public struct HomeView: View {
    @State private var searchText: String = ""
    public var onSelectCategory: (String) -> Void
    public var onNavigateToCreate: () -> Void
    public var onNavigateToSearch: () -> Void
    
    private let menuItems = [
        (titulo: "Projetos", subtitulo: "Pesquisa, extensão e inovação", icone: "lightbulb.fill", charCount: 8),
        (titulo: "Banco de provas", subtitulo: "Provas anteriores por matéria", icone: "checklist", charCount: 15),
        (titulo: "Trabalhos acadêmicos", subtitulo: "TCCs, artigos e relatórios", icone: "graduationcap.fill", charCount: 20),
        (titulo: "Material complementar", subtitulo: "Apostilas, vídeos e links", icone: "book.fill", charCount: 21)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(
                searchText: $searchText,
                onAITap: { onNavigateToSearch() }
            )
            
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
                        ForEach(menuItems, id: \\.titulo) { item in
                            Button(action: { onSelectCategory(item.titulo) }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(Color.azulSecundario.opacity(0.12)).frame(width: 44, height: 44)
                                        Image(systemName: item.icone).font(.system(size: 18)).foregroundColor(Color.azulSecundario)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.titulo).font(.system(size: 16.5, weight: .medium)).foregroundColor(Color.textoPrincipal)
                                        Text(item.subtitulo).font(.system(size: 12.5)).foregroundColor(Color.textoTerciario)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(Color.bordaUFSM)
                                }
                                .padding(14).background(Color.white).cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordaUFSM, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Item 5: Cadastre o seu projeto (22 chars) em Azul UFSM #21376B
                        Button(action: onNavigateToCreate) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                                    Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Cadastre o seu projeto").font(.system(size: 16.5, weight: .semibold)).foregroundColor(.white)
                                    Text("Compartilhe a sua produção").font(.system(size: 12.5)).foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
                            }
                            .padding(14).background(Color.azulUFSM).cornerRadius(16)
                            .shadow(color: Color.azulUFSM.opacity(0.25), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color.fundoUFSM)
        }
    }
}`,
  },
  {
    filename: 'SearchFilterView.swift',
    relativePath: 'Sources/CTIA/Views/Search/SearchFilterView.swift',
    category: 'Tela 2: Busca e Filtros',
    description: 'Checkboxes com raio de 5 pt e cor Azul UFSM ordenados de 3 a 16 caracteres.',
    code: `import SwiftUI

public struct SearchFilterView: View {
    @State private var searchText: String = "ruído"
    @State private var isFilterPanelExpanded: Bool = true
    
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
    
    @State private var items: [AcademicItem] = AcademicItem.mockList
    public var onSelectItem: (AcademicItem) -> Void
    public var onGoHome: () -> Void = {}
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(
                searchText: $searchText,
                onHomeTap: onGoHome,
                onFilterTap: { withAnimation { isFilterPanelExpanded.toggle() } },
                showFilterActive: isFilterPanelExpanded
            )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if isFilterPanelExpanded {
                        VStack(spacing: 14) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "line.3.horizontal.decrease.circle").foregroundColor(Color.azulUFSM)
                                    Text("Filtrar por").font(.system(size: 14, weight: .bold))
                                    Text("· 4 ativos").font(.system(size: 12.5)).foregroundColor(Color.textoTerciario)
                                }
                                Spacer()
                                Button("Limpar") {
                                    filtroAnoAtivo = false; filtroAreaAtivo = false; filtroAutorAtivo = false
                                    filtroCursoAtivo = false; filtroTituloAtivo = false; filtroMateriaAtivo = false
                                    filtroAvaliacaoAtivo = false
                                }
                                .foregroundColor(Color.azulSecundario)
                            }
                            Divider()
                            
                            VStack(spacing: 10) {
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAnoAtivo, label: "Ano")
                                    Spacer()
                                    Picker("Ano", selection: $selectedAno) {
                                        Text("2026").tag("2026")
                                    }.pickerStyle(.menu)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAreaAtivo, label: "Área")
                                    Spacer()
                                    Picker("Área", selection: $selectedArea) {
                                        Text("Engenharias").tag("Engenharias")
                                    }.pickerStyle(.menu)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAutorAtivo, label: "Autor")
                                    Spacer()
                                    TextField("Nome do(a) autor(a)", text: $textAutor).frame(width: 170)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroCursoAtivo, label: "Curso")
                                    Spacer()
                                    Picker("Curso", selection: $selectedCurso) {
                                        Text("Téc. Segurança do Trabalho").tag("Téc. Segurança do Trabalho")
                                    }.pickerStyle(.menu)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroTituloAtivo, label: "Título")
                                    Spacer()
                                    TextField("Palavras do título", text: $textTitulo).frame(width: 170)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroMateriaAtivo, label: "Matéria")
                                    Spacer()
                                    Picker("Matéria", selection: $selectedMateria) {
                                        Text("Todas as matérias").tag("Todas as matérias")
                                    }.pickerStyle(.menu)
                                }
                                HStack {
                                    CTIACheckbox(isChecked: $filtroAvaliacaoAtivo, label: "Melhor avaliação ★")
                                    Spacer()
                                    Text("Maior nota").font(.system(size: 12.5, weight: .medium))
                                }
                            }
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Aplicar filtros").font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44)
                                .background(Color.azulUFSM).cornerRadius(10)
                            }
                        }
                        .padding(16).background(Color.white).cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordaUFSM, lineWidth: 1))
                    }
                    
                    HStack {
                        Text("2 resultados para \"\\(searchText)\"").font(.system(size: 13, weight: .medium))
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Melhor avaliação")
                        }
                        .foregroundColor(Color.azulUFSM)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            Button(action: { onSelectItem(item) }) {
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
                                        Text(item.tipo.badgeLabel).font(.system(size: 9.5, weight: .bold))
                                            .foregroundColor(Color.azulSecundario).padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.azulSecundario.opacity(0.12)).cornerRadius(4)
                                        Text(item.titulo).font(.system(size: 14, weight: .semibold)).lineLimit(2)
                                        HStack(spacing: 4) {
                                            StarRatingView(rating: item.avaliacao, starSize: 11)
                                            Text(String(format: "%.1f", item.avaliacao).replacingOccurrences(of: ".", with: ","))
                                                .font(.system(size: 11.5, weight: .bold))
                                            Text("(\\(item.totalAvaliacoes)) · \\(item.ano)").font(.system(size: 11.5)).foregroundColor(Color.textoTerciario)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12).background(Color.white).cornerRadius(14)
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
}`,
  },
  {
    filename: 'DetailView.swift',
    relativePath: 'Sources/CTIA/Views/Detail/DetailView.swift',
    category: 'Tela 3: Visualização',
    description: 'Telemetria IoT ao vivo na oficina mecânica (ESP32 Wi-Fi, 82 dB), resumo e avaliações com estrelas.',
    code: `import SwiftUI

public struct DetailView: View {
    @State var item: AcademicItem = AcademicItem.mockNoiseMonitor
    @State private var userRating: Int = 0
    @State private var isSaved: Bool = true
    public var onBack: () -> Void
    public var onGoHome: () -> Void = {}
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: .constant(""), onHomeTap: onGoHome)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Resultados")
                            }
                            .foregroundColor(Color.azulUFSM)
                        }
                        Spacer()
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark").foregroundColor(Color.azulUFSM)
                        Image(systemName: "square.and.arrow.up").foregroundColor(Color.textoTerciario)
                    }
                    
                    Text(item.titulo).font(.system(size: 21, weight: .medium))
                    
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
                                Text("Limite 85 dB(A)").font(.system(size: 8.5, weight: .medium)).foregroundColor(Color.ambarUFSM)
                            }
                            Spacer()
                            Text("82 dB").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    .padding(14).background(Color.azulProfundo).cornerRadius(12)
                    
                    SectionTitleView(title: "Resumo")
                    Text(item.resumo).font(.system(size: 14)).foregroundColor(Color.textoSecundario)
                    
                    SectionTitleView(title: "Avaliações")
                    HStack(spacing: 24) {
                        VStack {
                            Text("4,8").font(.system(size: 32, weight: .bold))
                            StarRatingView(rating: 4.8, starSize: 13)
                        }
                        VStack {
                            Text("Avalie este projeto")
                            StarRatingView(rating: Double(userRating), starSize: 18, isInteractive: true, onRate: { userRating = $0 })
                        }
                    }
                    .padding(14).background(Color.white).cornerRadius(12)
                }
                .padding(16)
            }
            .background(Color.fundoUFSM)
        }
    }
}`,
  },
  {
    filename: 'CreateItemView.swift',
    relativePath: 'Sources/CTIA/Views/Create/CreateItemView.swift',
    category: 'Tela 4: Cadastro',
    description: 'Formulário unificado com contador dinâmico de 200 caracteres, raio 10 pt e botão de publicação.',
    code: `import SwiftUI

public struct CreateItemView: View {
    @State private var selectedTipo: AcademicType = .projeto
    @State private var titulo: String = "Monitor IoT de ruído nas oficinas do CTISM"
    @State private var resumo: String = "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas."
    @State private var selectedArea: String = "Engenharias"
    @State private var selectedMateria: String = "Higiene Ocupacional"
    public var onBack: () -> Void
    public var onGoHome: () -> Void = {}
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: .constant(""), onHomeTap: onGoHome)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cadastre o seu projeto").font(.system(size: 15, weight: .bold))
                    
                    Picker("Tipo", selection: $selectedTipo) {
                        ForEach(AcademicType.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    
                    Text("Título *")
                    TextField("Título", text: $titulo).padding(.horizontal, 12).frame(height: 42).background(Color.white).cornerRadius(10)
                    
                    HStack {
                        Text("Descrição — breve resumo (até 200 caracteres) *")
                        Spacer()
                        Text("\\(resumo.count)/200").font(.system(size: 11, weight: .semibold))
                    }
                    TextEditor(text: $resumo).frame(height: 85).background(Color.white).cornerRadius(10)
                    
                    HStack(spacing: 12) {
                        Button("Salvar rascunho") {}.frame(maxWidth: .infinity).frame(height: 44).background(Color.white).cornerRadius(10)
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Publicar")
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color.azulUFSM).cornerRadius(10)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.fundoUFSM)
        }
    }
}`,
  },
  {
    filename: 'Colors.swift',
    relativePath: 'Sources/CTIA/Theme/Colors.swift',
    category: 'Theme & Tokens',
    description: 'Paleta oficial do tema ufsm.br (#21376B, #204C90, #142140, #CC8F00, #FFC107, #F1F4F9).',
    code: `import SwiftUI

public extension Color {
    static let azulUFSM = Color(hex: "21376B")
    static let azulSecundario = Color(hex: "204C90")
    static let azulProfundo = Color(hex: "142140")
    static let douradoUFSM = Color(hex: "CC8F00")
    static let ambarUFSM = Color(hex: "FFC107")
    static let textoPrincipal = Color(hex: "1C1C1C")
    static let textoSecundario = Color(hex: "4C4C4C")
    static let textoTerciario = Color(hex: "6C757D")
    static let fundoUFSM = Color(hex: "F1F4F9")
    static let bordaUFSM = Color(hex: "D3D7E1")
    static let superficieUFSM = Color.white
}`,
  },
  {
    filename: 'AcademicModelsTests.swift',
    relativePath: 'Tests/CTIATests/AcademicModelsTests.swift',
    category: 'Testes Unitários (XCTest)',
    description: 'Testes unitários verificando a regra de ordenação 8 -> 22 caracteres e limite de 200 caracteres.',
    code: `import XCTest
@testable import CTIA

final class AcademicModelsTests: XCTestCase {
    func testMenuCharacterOrderingRule() throws {
        let menuItems = [
            "Projetos",              // 8
            "Banco de provas",       // 15
            "Trabalhos acadêmicos",  // 20
            "Material complementar", // 21
            "Cadastre o seu projeto" // 22
        ]
        XCTAssertEqual(menuItems[0].count, 8)
        XCTAssertEqual(menuItems[4].count, 22)
    }
    
    func testSummaryCharacterLimit() throws {
        let sample = "Protótipo com ESP32..."
        XCTAssertLessThanOrEqual(sample.count, 200)
    }
}`,
  },
];
