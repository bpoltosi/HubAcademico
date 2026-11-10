import Foundation

/// Publicações fictícias para demonstração. Nomes, notas e textos são exemplos;
/// os cursos são os oferecidos pelo CTISM. As capas estão em Assets.xcassets.
enum DadosExemplo {
    static var producoes: [Producao] {
        [
        Producao(
            tipo: .projeto,
            titulo: "Monitor IoT de ruído nas oficinas do CTISM",
            descricao: "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas.",
            imagemURL: URL(string: "asset://capa-monitor-ruido"),
            link: URL(string: "https://example.com/ctia/monitor-ruido"),
            plataforma: .linkedin,
            area: .engenharias,
            materia: "Higiene Ocupacional",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Ana Clara Machado", "Lucas Ferreira"],
            notas: notas(media: 4.8, total: 37),
            criadoEm: diasAtras(2)
        ),
        Producao(
            tipo: .trabalho,
            titulo: "Dosimetria de ruído na oficina de soldagem",
            descricao: "Medições com dosímetro durante aulas práticas de soldagem, comparadas aos limites da NR-15, com recomendações de protetores auriculares e de rodízio das atividades.",
            imagemURL: URL(string: "asset://capa-dosimetria"),
            link: URL(string: "https://example.com/ctia/dosimetria"),
            plataforma: .blog,
            area: .engenharias,
            materia: "Higiene Ocupacional",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Bruna Teixeira"],
            notas: notas(media: 4.6, total: 21),
            criadoEm: diasAtras(5)
        ),
        Producao(
            tipo: .prova,
            titulo: "Prova de Higiene Ocupacional – 2026/1",
            descricao: "Primeira avaliação do semestre, com questões sobre agentes físicos, limites de tolerância e uso de EPIs. Inclui o gabarito comentado.",
            imagemURL: URL(string: "asset://capa-prova-higiene"),
            link: nil,
            plataforma: .outro,
            area: .saude,
            materia: "Higiene Ocupacional",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Turma 2026/1"],
            notas: notas(media: 4.5, total: 12),
            criadoEm: diasAtras(9)
        ),
        Producao(
            tipo: .projeto,
            titulo: "Estufa automatizada com ESP32 e sensores de umidade",
            descricao: "Controle de irrigação e ventilação de uma estufa didática com sensores de solo e de ar, painel web em tempo real e alertas pelo celular.",
            imagemURL: URL(string: "asset://capa-estufa"),
            link: URL(string: "https://example.com/ctia/estufa"),
            plataforma: .instagram,
            area: .engenharias,
            materia: "Sistemas Embarcados",
            curso: "Técnico em Internet das Coisas Integrado ao Ensino Médio",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Pedro Henrique Lopes", "Júlia Martins"],
            notas: notas(media: 4.7, total: 18),
            criadoEm: diasAtras(40)
        ),
        Producao(
            tipo: .trabalho,
            titulo: "Análise de vulnerabilidades em redes Wi-Fi",
            descricao: "Estudo de configurações comuns de roteadores, testes em laboratório isolado e um guia de boas práticas para proteger redes domésticas e de pequenas empresas.",
            imagemURL: URL(string: "asset://capa-wifi"),
            link: URL(string: "https://example.com/ctia/wifi"),
            plataforma: .blog,
            area: .exatas,
            materia: "Segurança de Redes",
            curso: "Curso Superior de Tecnologia em Segurança Cibernética",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Rafael Costa"],
            notas: notas(media: 4.4, total: 9),
            criadoEm: diasAtras(12)
        ),
        Producao(
            tipo: .projeto,
            titulo: "Braço robótico didático impresso em 3D",
            descricao: "Braço de quatro eixos impresso em PLA, acionado por servomotores e Arduino, para ensinar cinemática e programação nas aulas de fabricação.",
            imagemURL: URL(string: "asset://capa-braco-robotico"),
            link: URL(string: "https://example.com/ctia/braco-robotico"),
            plataforma: .youtube,
            area: .engenharias,
            materia: "Manufatura Aditiva",
            curso: "Curso Superior de Tecnologia em Fabricação Mecânica",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Gabriel Souza", "Larissa Prado"],
            notas: notas(media: 4.9, total: 25),
            criadoEm: diasAtras(60)
        ),
        Producao(
            tipo: .prova,
            titulo: "Prova de Eletricidade Básica – 2025/2",
            descricao: "Avaliação com circuitos em série e em paralelo, Lei de Ohm e potência elétrica. Questões objetivas e dissertativas.",
            imagemURL: URL(string: "asset://capa-prova-eletricidade"),
            link: nil,
            plataforma: .outro,
            area: .engenharias,
            materia: "Eletricidade Básica",
            curso: "Técnico em Eletrotécnica",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Turma 2025/2"],
            notas: notas(media: 4.2, total: 15),
            criadoEm: diasAtras(90)
        ),
        Producao(
            tipo: .material,
            titulo: "Apostila de segurança em máquinas (NR-12)",
            descricao: "Resumo ilustrado dos requisitos da NR-12, com exemplos de proteções, dispositivos de parada de emergência e uma lista de verificação para as oficinas.",
            imagemURL: URL(string: "asset://capa-apostila-nr12"),
            link: URL(string: "https://example.com/ctia/nr12"),
            plataforma: .blog,
            area: .engenharias,
            materia: "Prevenção de Riscos em Máquinas",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Monitoria de Segurança do Trabalho"],
            notas: notas(media: 4.8, total: 40),
            criadoEm: diasAtras(20)
        ),
        Producao(
            tipo: .material,
            titulo: "Videoaulas de Arduino para iniciantes",
            descricao: "Série de vídeos curtos sobre entradas e saídas digitais, sensores analógicos e comunicação serial, com os códigos usados em aula.",
            imagemURL: URL(string: "asset://capa-arduino"),
            link: URL(string: "https://example.com/ctia/arduino"),
            plataforma: .youtube,
            area: .engenharias,
            materia: "Microcontroladores",
            curso: "Técnico em Automação Industrial",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Diego Ramos"],
            notas: notas(media: 4.6, total: 22),
            criadoEm: diasAtras(75)
        ),
        Producao(
            tipo: .trabalho,
            titulo: "Ergonomia nos laboratórios de informática",
            descricao: "Avaliação de postura, altura das mesas e iluminação em dois laboratórios, com propostas de ajustes de baixo custo e orientações de pausas.",
            imagemURL: URL(string: "asset://capa-ergonomia"),
            link: URL(string: "https://example.com/ctia/ergonomia"),
            plataforma: .linkedin,
            area: .saude,
            materia: "Ergonomia",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Fernanda Alves", "Tiago Nunes"],
            notas: notas(media: 4.3, total: 11),
            criadoEm: diasAtras(100)
        ),
        Producao(
            tipo: .projeto,
            titulo: "Site acessível para a biblioteca do colégio",
            descricao: "Catálogo on-line com contraste ajustável, leitura por voz e navegação por teclado, seguindo as recomendações do eMAG e da WCAG.",
            imagemURL: URL(string: "asset://capa-site-acessivel"),
            link: URL(string: "https://example.com/ctia/biblioteca"),
            plataforma: .github,
            area: .exatas,
            materia: "Desenvolvimento Web",
            curso: "Técnico em Informática para Internet Integrado ao Ensino Médio",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Isadora Ribeiro"],
            notas: notas(media: 4.5, total: 14),
            criadoEm: diasAtras(15)
        ),
        Producao(
            tipo: .prova,
            titulo: "Prova de Redes de Computadores I – 2026/1",
            descricao: "Questões sobre modelo OSI, endereçamento IPv4, sub-redes e comandos básicos de diagnóstico, com espaço para os cálculos.",
            imagemURL: URL(string: "asset://capa-prova-redes"),
            link: nil,
            plataforma: .outro,
            area: .exatas,
            materia: "Redes de Computadores I",
            curso: "Curso Superior de Tecnologia em Redes de Computadores",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Turma 2026/1"],
            notas: notas(media: 4.1, total: 8),
            criadoEm: diasAtras(7)
        ),
        ]
    }

    /// Gera notas (4 e 5) cuja média se aproxima do valor pedido.
    static func notas(media: Double, total: Int) -> [Int] {
        let cincos = max(0, min(total, Int(((media - 4) * Double(total)).rounded())))
        return Array(repeating: 5, count: cincos) + Array(repeating: 4, count: total - cincos)
    }

    private static func diasAtras(_ dias: Int) -> Date {
        Date().addingTimeInterval(-Double(dias) * 86_400)
    }
}
