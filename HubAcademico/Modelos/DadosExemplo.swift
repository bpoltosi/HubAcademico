import Foundation

/// Publicações fictícias para demonstração. Nomes, notas e textos são exemplos;
/// os cursos são os oferecidos pelo CTISM. As imagens estão em Assets.xcassets.
enum DadosExemplo {
    static var publicacoes: [Publicacao] {
        [
        Publicacao(
            tipo: .projeto,
            titulo: "Monitor IoT de ruído nas oficinas do CTISM",
            descricao: "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas.",
            imagemLink: URL(string: "asset://imagem-monitor-ruido"),
            link: URL(string: "https://example.com/hub-academico/monitor-ruido"),
            plataforma: .linkedin,
            area: .engenharias,
            subarea: "Engenharia de Produção",
            disciplina: "Higiene Ocupacional",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Ana Clara Machado", "Lucas Ferreira"],
            notas: notas(media: 4.8, total: 37),
            criadoEm: diasAtras(2)
        ),
        Publicacao(
            tipo: .trabalho,
            titulo: "Dosimetria de ruído na oficina de soldagem",
            descricao: "Medições com dosímetro durante aulas práticas de soldagem, comparadas aos limites da NR-15, com recomendações de protetores auriculares e de rodízio das atividades.",
            imagemLink: URL(string: "asset://imagem-dosimetria"),
            link: URL(string: "https://example.com/hub-academico/dosimetria"),
            plataforma: .blog,
            area: .engenharias,
            subarea: "Engenharia de Produção",
            disciplina: "Higiene Ocupacional",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Bruna Teixeira"],
            notas: notas(media: 4.6, total: 21),
            criadoEm: diasAtras(5)
        ),
        Publicacao(
            tipo: .prova,
            titulo: "Prova de Higiene Ocupacional – 2026/1",
            descricao: "Primeira avaliação do semestre, com questões sobre agentes físicos, limites de tolerância e uso de EPIs. Inclui o gabarito comentado.",
            imagemLink: URL(string: "asset://imagem-prova-higiene"),
            link: nil,
            plataforma: .outro,
            area: .saude,
            subarea: "Saúde Coletiva",
            disciplina: "Higiene Ocupacional",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Turma 2026/1"],
            notas: notas(media: 4.5, total: 12),
            criadoEm: diasAtras(9)
        ),
        Publicacao(
            tipo: .projeto,
            titulo: "Estufa automatizada com ESP32 e sensores de umidade",
            descricao: "Controle de irrigação e ventilação de uma estufa didática com sensores de solo e de ar, painel web em tempo real e alertas pelo celular.",
            imagemLink: URL(string: "asset://imagem-estufa"),
            link: URL(string: "https://example.com/hub-academico/estufa"),
            plataforma: .instagram,
            area: .engenharias,
            subarea: "Engenharia Elétrica",
            disciplina: "Sistemas Embarcados",
            curso: "Técnico em Internet das Coisas Integrado ao Ensino Médio",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Pedro Henrique Lopes", "Júlia Martins"],
            notas: notas(media: 4.7, total: 18),
            criadoEm: diasAtras(40)
        ),
        Publicacao(
            tipo: .trabalho,
            titulo: "Análise de vulnerabilidades em redes Wi-Fi",
            descricao: "Estudo de configurações comuns de roteadores, testes em laboratório isolado e um guia de boas práticas para proteger redes domésticas e de pequenas empresas.",
            imagemLink: URL(string: "asset://imagem-wifi"),
            link: URL(string: "https://example.com/hub-academico/wifi"),
            plataforma: .blog,
            area: .exatas,
            subarea: "Ciência da Computação",
            disciplina: "Segurança de Redes",
            curso: "Curso Superior de Tecnologia em Segurança Cibernética",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Rafael Costa"],
            notas: notas(media: 4.4, total: 9),
            criadoEm: diasAtras(12)
        ),
        Publicacao(
            tipo: .projeto,
            titulo: "Braço robótico didático impresso em 3D",
            descricao: "Braço de quatro eixos impresso em PLA, acionado por servomotores e Arduino, para ensinar cinemática e programação nas aulas de fabricação.",
            imagemLink: URL(string: "asset://imagem-braco-robotico"),
            link: URL(string: "https://example.com/hub-academico/braco-robotico"),
            plataforma: .youtube,
            area: .engenharias,
            subarea: "Engenharia Mecânica",
            disciplina: "Manufatura Aditiva",
            curso: "Curso Superior de Tecnologia em Fabricação Mecânica",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Gabriel Souza", "Larissa Prado"],
            notas: notas(media: 4.9, total: 25),
            criadoEm: diasAtras(60)
        ),
        Publicacao(
            tipo: .prova,
            titulo: "Prova de Eletricidade Básica – 2025/2",
            descricao: "Avaliação com circuitos em série e em paralelo, Lei de Ohm e potência elétrica. Questões objetivas e dissertativas.",
            imagemLink: URL(string: "asset://imagem-prova-eletricidade"),
            link: nil,
            plataforma: .outro,
            area: .engenharias,
            subarea: "Engenharia Elétrica",
            disciplina: "Eletricidade Básica",
            curso: "Técnico em Eletrotécnica",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Turma 2025/2"],
            notas: notas(media: 4.2, total: 15),
            criadoEm: diasAtras(90)
        ),
        Publicacao(
            tipo: .material,
            titulo: "Apostila de segurança em máquinas (NR-12)",
            descricao: "Resumo ilustrado dos requisitos da NR-12, com exemplos de proteções, dispositivos de parada de emergência e uma lista de verificação para as oficinas.",
            imagemLink: URL(string: "asset://imagem-apostila-nr12"),
            link: URL(string: "https://example.com/hub-academico/nr12"),
            plataforma: .blog,
            area: .engenharias,
            subarea: "Engenharia de Produção",
            disciplina: "Prevenção de Riscos em Máquinas",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Monitoria de Segurança do Trabalho"],
            notas: notas(media: 4.8, total: 40),
            criadoEm: diasAtras(20)
        ),
        Publicacao(
            tipo: .material,
            titulo: "Videoaulas de Arduino para iniciantes",
            descricao: "Série de vídeos curtos sobre entradas e saídas digitais, sensores analógicos e comunicação serial, com os códigos usados em aula.",
            imagemLink: URL(string: "asset://imagem-arduino"),
            link: URL(string: "https://example.com/hub-academico/arduino"),
            plataforma: .youtube,
            area: .engenharias,
            subarea: "Engenharia Elétrica",
            disciplina: "Microcontroladores",
            curso: "Técnico em Automação Industrial",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Diego Ramos"],
            notas: notas(media: 4.6, total: 22),
            criadoEm: diasAtras(75)
        ),
        Publicacao(
            tipo: .trabalho,
            titulo: "Ergonomia nos laboratórios de informática",
            descricao: "Avaliação de postura, altura das mesas e iluminação em dois laboratórios, com propostas de ajustes de baixo custo e orientações de pausas.",
            imagemLink: URL(string: "asset://imagem-ergonomia"),
            link: URL(string: "https://example.com/hub-academico/ergonomia"),
            plataforma: .linkedin,
            area: .saude,
            subarea: "Saúde Coletiva",
            disciplina: "Ergonomia",
            curso: "Técnico em Segurança do Trabalho",
            instituicao: "CTISM – UFSM",
            ano: 2025,
            autores: ["Fernanda Alves", "Tiago Nunes"],
            notas: notas(media: 4.3, total: 11),
            criadoEm: diasAtras(100)
        ),
        Publicacao(
            tipo: .projeto,
            titulo: "Site acessível para a biblioteca do colégio",
            descricao: "Catálogo on-line com contraste ajustável, leitura por voz e navegação por teclado, seguindo as recomendações do eMAG e da WCAG.",
            imagemLink: URL(string: "asset://imagem-site-acessivel"),
            link: URL(string: "https://example.com/hub-academico/biblioteca"),
            plataforma: .github,
            area: .exatas,
            subarea: "Ciência da Computação",
            disciplina: "Desenvolvimento Web",
            curso: "Técnico em Informática para Internet Integrado ao Ensino Médio",
            instituicao: "CTISM – UFSM",
            ano: 2026,
            autores: ["Isadora Ribeiro"],
            notas: notas(media: 4.5, total: 14),
            criadoEm: diasAtras(15)
        ),
        Publicacao(
            tipo: .prova,
            titulo: "Prova de Redes de Computadores I – 2026/1",
            descricao: "Questões sobre modelo OSI, endereçamento IPv4, sub-redes e comandos básicos de diagnóstico, com espaço para os cálculos.",
            imagemLink: URL(string: "asset://imagem-prova-redes"),
            link: nil,
            plataforma: .outro,
            area: .exatas,
            subarea: "Ciência da Computação",
            disciplina: "Redes de Computadores I",
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
