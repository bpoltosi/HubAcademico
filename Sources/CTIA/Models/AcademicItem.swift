import Foundation

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
    
    // Telemetria IoT
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
