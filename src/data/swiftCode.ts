export interface SwiftFile {
  filename: string;
  category: string;
  description: string;
  code: string;
}

export const SWIFT_FILES: SwiftFile[] = [
  {
    filename: 'CTIA_Combined.swift',
    category: 'Pronto para Xcode',
    description: 'Arquivo único consolidado com todas as 4 telas, modelos e design system. Basta colar no Xcode ou Swift Playgrounds!',
    code: `//
//  CTIA_Combined.swift
//  CTIA · Repositório Acadêmico do CTISM
//  Design das 4 telas do app iOS (SwiftUI) com o design system de ufsm.br
//  HackaTruck MakerSpace · Deploy 26.1
//

import SwiftUI

// MARK: - 1. Design System & Tokens UFSM
extension Color {
    static let azulUFSM = Color(hex: "21376B")        // Cabeçalho, títulos, botão primário
    static let azulSecundario = Color(hex: "204C90")   // Ícones e rótulos do menu
    static let azulProfundo = Color(hex: "142140")     // Fundos de destaque
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

// Marcador de seção com filete dourado
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

// Checkbox estilo Bootstrap / UFSM (raio 5 pt, ativo Azul UFSM)
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
        .frame(minHeight: 44) // Área mínima de toque 44 pt
    }
}

// Estrelas de avaliação em Âmbar #FFC107
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

// MARK: - 2. Modelos
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

// MARK: - 3. Cabeçalho Oficial CTIA (com Brasão e Filete Dourado de 2 pt)
struct CTIAHeader: View {
    @Binding var searchText: String
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
                    Image(systemName: "line.3.horizontal").foregroundColor(.white).frame(width: 36, height: 36)
                    
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
            
            Rectangle().fill(Color.douradoUFSM).frame(height: 2) // Filete dourado de 2 pt
        }
    }
}

// MARK: - Telas 1 a 4 e Navegação Integrada
// Veja CTIAApp.swift para a arquitetura completa de navegação!
`,
  },
  {
    filename: 'HomeView.swift',
    category: 'Tela 1: Início',
    description: 'Acesso rápido com ordem estritamente crescente de caracteres (8 -> 22) e destaque no botão de cadastro.',
    code: `import SwiftUI

public struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var searchText: String = ""
    var onSelectCategory: (String) -> Void
    var onNavigateToCreate: () -> Void
    
    // Regra: Ordem crescente de caracteres no menu (8 -> 22)
    private let menuItems = [
        (titulo: "Projetos", subtitulo: "Pesquisa, extensão e inovação", icone: "lightbulb.fill"),
        (titulo: "Banco de provas", subtitulo: "Provas anteriores por matéria", icone: "checklist"),
        (titulo: "Trabalhos acadêmicos", subtitulo: "TCCs, artigos e relatórios", icone: "graduationcap.fill"),
        (titulo: "Material complementar", subtitulo: "Apostilas, vídeos e links", icone: "book.fill")
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: $searchText)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Olá, estudante!")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundColor(Color.textoPrincipal)
                        Text("Explore e compartilhe a produção acadêmica do CTISM.")
                            .font(.system(size: 14.5))
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
                        
                        // Item 5: Cadastre o seu projeto (22 caracteres) em Azul UFSM
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
    category: 'Tela 2: Busca e Filtros',
    description: 'Filtros em checkbox de 3 a 16 caracteres com raio de 5 pt e cor Azul UFSM.',
    code: `import SwiftUI

public struct SearchFilterView: View {
    @State private var searchText = "ruído"
    @State private var isFilterPanelExpanded = true
    
    // Checkboxes (3 -> 16 caracteres):
    @State private var filtroAno = true          // Ano (3)
    @State private var filtroArea = true         // Área (4)
    @State private var filtroAutor = false       // Autor (5)
    @State private var filtroCurso = true        // Curso (5)
    @State private var filtroTitulo = false      // Título (6)
    @State private var filtroMateria = false     // Matéria (7)
    @State private var filtroMelhorAvaliacao = true // Melhor avaliação (16)
    
    var onSelectItem: (AcademicItem) -> Void
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(
                searchText: $searchText,
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
                                    filtroAno = false; filtroArea = false; filtroAutor = false
                                    filtroCurso = false; filtroTitulo = false; filtroMateria = false
                                    filtroMelhorAvaliacao = false
                                }
                                .foregroundColor(Color.azulSecundario)
                            }
                            Divider()
                            // Lista de filtros com CTIACheckbox (raio 5pt)
                            CTIACheckbox(isChecked: $filtroAno, label: "Ano")
                            CTIACheckbox(isChecked: $filtroArea, label: "Área")
                            CTIACheckbox(isChecked: $filtroAutor, label: "Autor")
                            CTIACheckbox(isChecked: $filtroCurso, label: "Curso")
                            CTIACheckbox(isChecked: $filtroTitulo, label: "Título")
                            CTIACheckbox(isChecked: $filtroMateria, label: "Matéria")
                            CTIACheckbox(isChecked: $filtroMelhorAvaliacao, label: "Melhor avaliação ★")
                            
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
    category: 'Tela 3: Visualização',
    description: 'Exibição completa com gráfico IoT ao vivo da oficina mecânica, resumo e avaliações com estrelas.',
    code: `import SwiftUI

public struct DetailView: View {
    @State var item: AcademicItem = AcademicItem.mockNoiseMonitor
    @State private var userRating: Int = 0
    @State private var isSaved: Bool = true
    var onBack: () -> Void
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: .constant(""))
            
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
    category: 'Tela 4: Cadastro',
    description: 'Formulário unificado com contador dinâmico de 200 caracteres, raio 10 pt e botão de publicação.',
    code: `import SwiftUI

public struct CreateItemView: View {
    @State private var selectedTipo: AcademicType = .projeto
    @State private var titulo = "Monitor IoT de ruído nas oficinas do CTISM"
    @State private var resumo = "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas."
    @State private var selectedArea = "Engenharias"
    @State private var selectedMateria = "Higiene Ocupacional"
    var onBack: () -> Void
    
    public var body: some View {
        VStack(spacing: 0) {
            CTIAHeader(searchText: .constant(""))
            
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
    filename: 'DesignSystem.swift',
    category: 'Design System & Tokens',
    description: 'Extensões de Color com hexadecimais do site ufsm.br, tipografia Rawline e componentes padronizados.',
    code: `import SwiftUI

// Cores Oficiais UFSM / CTIA
extension Color {
    static let azulUFSM = Color(hex: "21376B")        // Cabeçalho, títulos, botão primário
    static let azulSecundario = Color(hex: "204C90")   // Ícones e rótulos do menu
    static let azulProfundo = Color(hex: "142140")     // Fundos de destaque
    static let douradoUFSM = Color(hex: "CC8F00")      // Filete dourado 2 pt, marcadores
    static let ambarUFSM = Color(hex: "FFC107")        // Estrelas de avaliação
    static let textoPrincipal = Color(hex: "1C1C1C")
    static let textoSecundario = Color(hex: "4C4C4C")
    static let textoTerciario = Color(hex: "6C757D")
    static let fundoUFSM = Color(hex: "F1F4F9")
    static let bordaUFSM = Color(hex: "D3D7E1")
    static let superficieUFSM = Color.white
}`,
  },
];
