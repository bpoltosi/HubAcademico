import Foundation

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
