import Foundation

// MARK: - Modelos de Dados do Repositório Acadêmico CTISM

public enum AcademicType: String, CaseIterable, Identifiable {
    case projeto = "Projeto"
    case trabalho = "Trabalho"
    case prova = "Prova"
    
    public var id: String { rawValue }
    
    public var badgeLabel: String {
        switch self {
        case .projeto: return "PROJETO"
        case .trabalho: return "TRABALHO ACADÊMICO"
        case .prova: return "BANCO DE PROVAS"
        }
    }
}

public struct AcademicItem: Identifiable, Hashable {
    public let id: UUID
    public var tipo: AcademicType
    public var titulo: String
    public var resumo: String
    public var autores: String
    public var area: String
    public var materia: String
    public var curso: String
    public var instituicao: String
    public var ano: Int
    public var avaliacao: Double
    public var totalAvaliacoes: Int
    public var imagemUrl: String?
    public var linkPublicado: String?
    public var linkTipo: String
    public var isSaved: Bool
    
    // Telemetria IoT (específico para projetos de prototipagem como o Monitor de Ruído)
    public var localTelemetria: String?
    public var statusAoVivo: String?
    public var limiteDb: Double?
    public var dbAtual: Double?
    public var sensorChip: String?
    
    public init(
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
}

// MARK: - Dados Mockados Autênticos do CTISM
public extension AcademicItem {
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
        imagemUrl: "https://example.com/monitor-ruido",
        linkPublicado: "https://linkedin.com/posts/ana-clara-machado",
        linkTipo: "LinkedIn",
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
        imagemUrl: "https://example.com/dosimetria",
        linkPublicado: "https://github.com/pedro-ctism/dosimetria",
        linkTipo: "GitHub",
        isSaved: false
    )
    
    static let mockList: [AcademicItem] = [
        mockNoiseMonitor,
        mockDosimetry,
        AcademicItem(
            tipo: .prova,
            titulo: "Avaliação Prática - Circuitos Elétricos I",
            resumo: "Gabarito e roteiro de prova com resolução detalhada para leis de Kirchhoff e simulações com osciloscópio.",
            autores: "Prof. Dr. Marcos Silveira",
            area: "Engenharias",
            materia: "Eletrotécnica",
            curso: "Téc. Eletrotécnica",
            instituicao: "CTISM - UFSM",
            ano: 2025,
            avaliacao: 4.9,
            totalAvaliacoes: 45
        ),
        AcademicItem(
            tipo: .projeto,
            titulo: "Estação Meteorológica Autônoma LoRaWAN",
            resumo: "Sensoriamento de temperatura, umidade e radiação UV para monitoramento microclimático no campus da UFSM com telemetria via rádio.",
            autores: "Gabriela Duarte e Mateus Rosa",
            area: "Tecnologia da Informação",
            materia: "Redes de Comunicação",
            curso: "Téc. Informática para Internet",
            instituicao: "CTISM - UFSM",
            ano: 2026,
            avaliacao: 4.7,
            totalAvaliacoes: 19
        )
    ]
}
