import Foundation

/// Problemas de comunicação com a API REST do Hub Acadêmico.
enum ErroAPI: LocalizedError {
    case semConexao(String)
    case servidor(status: Int, mensagem: String)
    case usuarioNaoIdentificado
    case respostaInvalida

    var errorDescription: String? {
        switch self {
        case .semConexao(let detalhe):
            return "Não foi possível falar com o servidor. \(detalhe)"
        case .servidor(_, let mensagem):
            return mensagem
        case .usuarioNaoIdentificado:
            return "O servidor não reconheceu o seu perfil. No cadastro, toque no cartão “Publicando como…” e depois em Concluir."
        case .respostaInvalida:
            return "O servidor respondeu em um formato inesperado. Confira se o fluxo do Hub Acadêmico está implantado no Node-RED."
        }
    }
}

// MARK: - Contratos HTTP

/// Resposta pública de GET /hub/projetos e POST /hub/projetos.
/// Os nomes seguem o contrato camelCase documentado para a API.
/// Metadados internos do Cloudant (_id e _rev) não fazem parte deste DTO.
struct ProjetoDTO: Decodable {
    let id: String
    let tipo: String
    let titulo: String
    let descricao: String
    let imagemURL: String?
    let link: String?
    let plataforma: String?
    let area: String
    let subarea: String?
    let cadeira: String?
    let cadeiraId: String?
    let curso: String?
    let instituicao: String?
    let ano: Int
    let autores: [String]?
    let nota: Double?
    let quant: Int?
    let minhaNota: Int?
    let meu: Bool?
    let criadoEm: Date?

    /// Converte a resposta da API para o modelo usado nas telas.
    var producao: Producao? {
        guard let uuid = UUID(uuidString: id),
              let tipoProducao = TipoProducao(rawValue: tipo),
              let areaConhecimento = AreaConhecimento(rawValue: area) else {
            return nil
        }
        return Producao(
            id: uuid,
            tipo: tipoProducao,
            titulo: titulo,
            descricao: descricao,
            imagemURL: imagemURL.flatMap { URL(string: $0) },
            link: link.flatMap { URL(string: $0) },
            plataforma: plataforma.flatMap { Plataforma(rawValue: $0) } ?? .outro,
            area: areaConhecimento,
            subarea: subarea,
            materia: cadeira ?? "",
            curso: curso ?? "",
            instituicao: instituicao ?? "",
            ano: ano,
            autores: autores ?? [],
            notas: [],
            criadoEm: criadoEm ?? .now,
            notaMedia: nota ?? 0,
            quantidadeAvaliacoes: quant ?? 0
        )
    }
}

/// Corpo de POST /hub/projetos.
/// O servidor gera id, criadoEm e usuarioId; por isso esses campos não são enviados pelo app.
struct NovoProjetoDTO: Encodable {
    let tipo: String
    let titulo: String
    let descricao: String
    let imagemURL: String?
    let link: String?
    let plataforma: String
    let area: String
    let subarea: String?
    let cadeira: String
    let curso: String
    let instituicao: String
    let ano: Int
    let autores: [String]

    init(_ producao: Producao) {
        tipo = producao.tipo.rawValue
        titulo = producao.titulo
        descricao = producao.descricao
        imagemURL = producao.imagemURL?.absoluteString
        link = producao.link?.absoluteString
        plataforma = producao.plataforma.rawValue
        area = producao.area.rawValue
        subarea = producao.subarea
        cadeira = producao.materia
        curso = producao.curso
        instituicao = producao.instituicao
        ano = producao.ano
        autores = producao.autores
    }
}

/// Resposta de POST /hub/avaliacoes. Mantida para compatibilidade com a API atual.
struct ResumoAvaliacaoDTO: Decodable {
    let projetoId: String
    let nota: Double
    let quant: Int
    let minhaNota: Int?
}

/// Resposta de POST /hub/users e PUT /hub/perfil.
struct UsuarioDTO: Decodable {
    let id: String
    let nome: String
    let curso: String?
}

/// Resposta de GET /hub/status.
struct StatusDTO: Decodable {
    struct Totais: Decodable {
        let projetos: Int
        let users: Int
        let avaliacoes: Int
    }

    let ok: Bool
    let totais: Totais?
}

private struct ErroDTO: Decodable {
    let erro: String
    let detalhes: [String]?
}

private struct NotaDTO: Encodable {
    let projetoId: String
    let nota: Int
}

private struct PerfilDTO: Encodable {
    let nome: String
    let curso: String
}

// MARK: - Cliente HTTP

/// Cliente REST do Node-RED. A base deve conter somente o endereço do servidor,
/// por exemplo: http://192.168.0.10:1880. Os caminhos /hub/... são definidos aqui.
struct APIClient {
    let base: URL
    var usuarioID: String?

    private enum Rota {
        static let status = "hub/status"
        static let projetos = "hub/projetos"
        static let avaliacoes = "hub/avaliacoes"
        static let usuarios = "hub/users"
        static let perfil = "hub/perfil"
    }

    func status() async throws -> StatusDTO {
        try await enviar("GET", Rota.status)
    }

    /// Lista as publicações persistidas no backend.
    /// O catálogo acadêmico (áreas, cursos e cadeiras) não é consultado por esta rota.
    func projetos() async throws -> [ProjetoDTO] {
        try await enviar("GET", Rota.projetos)
    }

    /// Envia uma nova publicação. O Node-RED exige X-Hub-User e gera id/criadoEm.
    func publicar(_ novo: NovoProjetoDTO) async throws -> ProjetoDTO {
        try exigirUsuario()
        return try await enviar("POST", Rota.projetos, corpo: novo)
    }

    /// Mantido para o fluxo atual de avaliações, fora da migração GET/POST de projetos.
    func avaliar(projetoID: UUID, nota: Int) async throws -> ResumoAvaliacaoDTO {
        try exigirUsuario()
        return try await enviar(
            "POST",
            Rota.avaliacoes,
            corpo: NotaDTO(projetoId: projetoID.uuidString, nota: nota)
        )
    }

    func cadastrarUsuario(nome: String, curso: String) async throws -> UsuarioDTO {
        try await enviar("POST", Rota.usuarios, corpo: PerfilDTO(nome: nome, curso: curso))
    }

    func atualizarPerfil(nome: String, curso: String) async throws -> UsuarioDTO {
        try exigirUsuario()
        return try await enviar("PUT", Rota.perfil, corpo: PerfilDTO(nome: nome, curso: curso))
    }

    // MARK: Construção e execução da requisição

    private static let sessao: URLSession = {
        let configuracao = URLSessionConfiguration.default
        configuracao.timeoutIntervalForRequest = 15
        configuracao.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuracao)
    }()

    private static let codificador = JSONEncoder()

    /// Aceita datas ISO 8601 UTC com ou sem milissegundos, como definido no contrato.
    private static let decodificador: JSONDecoder = {
        let decodificador = JSONDecoder()
        decodificador.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let texto = try container.decode(String.self)
            guard let data = DataISO.ler(texto) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Data ISO 8601 inválida: \(texto)"
                )
            }
            return data
        }
        return decodificador
    }()

    /// Impede chamadas protegidas sem X-Hub-User, em vez de enviar uma requisição
    /// que o backend certamente rejeitará com HTTP 401.
    private func exigirUsuario() throws {
        guard let usuarioID, !usuarioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ErroAPI.usuarioNaoIdentificado
        }
    }

    private func enviar<Resposta: Decodable>(
        _ metodo: String,
        _ caminho: String,
        corpo: (any Encodable)? = nil
    ) async throws -> Resposta {
        let url = base.appending(path: caminho)
        var pedido = URLRequest(url: url)
        pedido.httpMethod = metodo
        pedido.setValue("application/json", forHTTPHeaderField: "Accept")

        if let usuarioID, !usuarioID.isEmpty {
            pedido.setValue(usuarioID, forHTTPHeaderField: "X-Hub-User")
        }

        if let corpo {
            pedido.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            pedido.httpBody = try Self.codificador.encode(corpo)
        }

        let (dados, resposta) = try await baixar(pedido)
        guard let http = resposta as? HTTPURLResponse else {
            throw ErroAPI.respostaInvalida
        }

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw ErroAPI.usuarioNaoIdentificado
            }

            let erro = try? JSONDecoder().decode(ErroDTO.self, from: dados)
            let mensagemPadrao: String
            switch http.statusCode {
            case 404:
                mensagemPadrao = "Rota não encontrada (404). Confira se o fluxo do Hub Acadêmico foi implantado no Node-RED."
            case 503:
                mensagemPadrao = "O serviço de publicações está temporariamente indisponível."
            default:
                mensagemPadrao = "O servidor respondeu com o erro HTTP \(http.statusCode)."
            }

            var mensagem = erro?.erro ?? mensagemPadrao
            if let detalhes = erro?.detalhes, !detalhes.isEmpty {
                mensagem += "\n" + detalhes.joined(separator: "\n")
            }
            throw ErroAPI.servidor(status: http.statusCode, mensagem: mensagem)
        }

        do {
            return try Self.decodificador.decode(Resposta.self, from: dados)
        } catch {
            throw ErroAPI.respostaInvalida
        }
    }

    private func baixar(_ pedido: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await Self.sessao.data(for: pedido)
        } catch let erro as URLError where erro.code == .cancelled {
            throw CancellationError()
        } catch let erro as URLError {
            throw ErroAPI.semConexao(Self.dica(para: erro))
        }
    }

    private static func dica(para erro: URLError) -> String {
        switch erro.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return "O aparelho está sem conexão."
        case .timedOut:
            return "O servidor demorou para responder."
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "Confira o endereço e se o Node-RED está ligado na mesma rede."
        case .appTransportSecurityRequiresSecureConnection:
            return "O iOS bloqueou o endereço http://. Veja a configuração do Info.plist no README."
        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            return "Falhou a conexão segura (HTTPS) com o servidor."
        default:
            return erro.localizedDescription
        }
    }
}

/// Datas ISO 8601 UTC retornadas pelo Node-RED.
private enum DataISO {
    private static let simples: ISO8601DateFormatter = {
        let formato = ISO8601DateFormatter()
        formato.formatOptions = [.withInternetDateTime]
        return formato
    }()

    private static let comMilissegundos: ISO8601DateFormatter = {
        let formato = ISO8601DateFormatter()
        formato.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formato
    }()

    static func ler(_ texto: String) -> Date? {
        simples.date(from: texto) ?? comMilissegundos.date(from: texto)
    }
}
