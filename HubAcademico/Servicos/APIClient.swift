import Foundation

/// Problemas de comunicação com o Node-RED, já com mensagens para mostrar na tela.
enum ErroAPI: LocalizedError {
    case semConexao(String)
    case servidor(status: Int, mensagem: String)
    case usuarioNaoIdentificado
    case recursoNaoSuportado(String)
    case respostaInvalida

    var errorDescription: String? {
        switch self {
        case .semConexao(let detalhe):
            return "Não foi possível falar com o servidor. \(detalhe)"
        case .servidor(_, let mensagem):
            return mensagem
        case .usuarioNaoIdentificado:
            return "O servidor não reconheceu o seu perfil. No cadastro, toque no cartão “Publicando como…” e depois em Concluir."
        case .recursoNaoSuportado(let detalhe):
            return detalhe
        case .respostaInvalida:
            return "O servidor respondeu em um formato inesperado. Confira se o fluxo do Hub Acadêmico está implantado no Node-RED."
        }
    }
}

// MARK: - Formatos da API CloudantPlus

/// Projeto como vem do Node-RED. A coluna "cadeira" do banco é a "matéria" do app.
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
    let curso: String?
    let instituicao: String?
    let ano: Int
    let autores: [String]?
    let nota: Double?
    let quant: Int?
    let minhaNota: Int?
    let meu: Bool?
    let criadoEm: Date?

    /// Converte para o modelo do app; devolve nil se o tipo, a área ou o id não forem reconhecidos.
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

/// Corpo enviado para POSTprojeto.
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

/// Resposta de UPDATEprojeto quando a operação é uma avaliação.
struct ResumoAvaliacaoDTO: Decodable {
    let projetoId: String
    let nota: Double
    let quant: Int
    let minhaNota: Int?
}

/// Resposta de DELETEprojeto.
struct ExclusaoProjetoDTO: Decodable {
    let ok: Bool
    let removido: String?
}

/// Usuário lógico deste aparelho. O fluxo atual devolve o UUID; não mantém perfil no Cloudant.
struct UsuarioDTO: Decodable {
    let id: String
    let nome: String
    let curso: String?
}

/// Resposta do GET /hub/status. A rota não existe no fluxo CloudantPlus atual.
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

// MARK: - Cliente

/// Cliente REST do fluxo Node-RED baseado nos nós cloudantplus in/out.
/// Os caminhos abaixo correspondem aos nós HTTP do flows.json real.
struct APIClient {
    /// Endereço-base padrão do Node-RED: http://127.0.0.1:1880/.
    let base: URL
    /// UUID do usuário lógico, enviado no cabeçalho X-Hub-User.
    var usuarioID: String?

    /// O fluxo fornecido não declara uma rota de status.
    func status() async throws -> StatusDTO {
        throw ErroAPI.recursoNaoSuportado(
            "O fluxo CloudantPlus atual não disponibiliza GET /hub/status."
        )
    }

    /// GETprojetos consulta os documentos do banco hub-academico-10.
    func projetos() async throws -> [ProjetoDTO] {
        try await enviar("GET", "GETprojetos")
    }

    /// POSTprojeto insere um documento com _id UUID e campos compatíveis com ProjetoDTO.
    func publicar(_ novo: NovoProjetoDTO) async throws -> ProjetoDTO {
        try await enviar("POST", "POSTprojeto", corpo: novo)
    }

    /// UPDATEprojeto recebe projetoId + nota e atualiza votos no documento existente.
    func avaliar(projetoID: UUID, nota: Int) async throws -> ResumoAvaliacaoDTO {
        try await enviar(
            "PUT",
            "UPDATEprojeto",
            corpo: NotaDTO(projetoId: projetoID.uuidString, nota: nota)
        )
    }

    /// DELETEprojeto recebe o identificador pela query string.
    func excluirProjeto(projetoID: UUID) async throws -> ExclusaoProjetoDTO {
        guard var componentes = URLComponents(
            url: base.appending(path: "DELETEprojeto"),
            resolvingAgainstBaseURL: false
        ) else {
            throw ErroAPI.respostaInvalida
        }
        componentes.queryItems = [URLQueryItem(name: "id", value: projetoID.uuidString)]
        guard let url = componentes.url else {
            throw ErroAPI.respostaInvalida
        }
        return try await enviar("DELETE", url: url)
    }

    /// O fluxo cria um UUID lógico em POST /hub/users, mas não armazena nome/curso.
    /// Como não existe PUT /hub/perfil nesse fluxo, mantém o perfil local sem enviar uma rota inexistente.
    func atualizarPerfil(nome: String, curso: String) async throws -> UsuarioDTO {
        guard let usuarioID else {
            throw ErroAPI.usuarioNaoIdentificado
        }
        return UsuarioDTO(id: usuarioID, nome: nome, curso: curso)
    }

    func cadastrarUsuario(nome: String, curso: String) async throws -> UsuarioDTO {
        try await enviar("POST", "hub/users", corpo: PerfilDTO(nome: nome, curso: curso))
    }

    // MARK: Requisição

    private static let sessao: URLSession = {
        let configuracao = URLSessionConfiguration.default
        configuracao.timeoutIntervalForRequest = 15
        configuracao.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuracao)
    }()

    /// Lê datas ISO 8601 do Node-RED, com ou sem milissegundos.
    private static let decodificador: JSONDecoder = {
        let decodificador = JSONDecoder()
        decodificador.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let texto = try container.decode(String.self)
            if let data = DataISO.ler(texto) {
                return data
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Data inválida: \(texto)"
            )
        }
        return decodificador
    }()

    private func enviar<Resposta: Decodable>(
        _ metodo: String,
        _ caminho: String,
        corpo: (any Encodable)? = nil
    ) async throws -> Resposta {
        try await enviar(metodo, url: base.appending(path: caminho), corpo: corpo)
    }

    private func enviar<Resposta: Decodable>(
        _ metodo: String,
        url: URL,
        corpo: (any Encodable)? = nil
    ) async throws -> Resposta {
        var pedido = URLRequest(url: url)
        pedido.httpMethod = metodo
        pedido.setValue("application/json", forHTTPHeaderField: "Accept")
        if let usuarioID {
            pedido.setValue(usuarioID, forHTTPHeaderField: "X-Hub-User")
        }
        if let corpo {
            pedido.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            pedido.httpBody = try JSONEncoder().encode(corpo)
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
            let padrao = http.statusCode == 404
                ? "Rota ou documento não encontrado (404). Confira se o fluxo CloudantPlus está implantado no Node-RED."
                : "O servidor respondeu com o erro \(http.statusCode)."
            var mensagem = erro?.erro ?? padrao
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

    /// Explica as falhas de rede mais comuns no laboratório.
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

/// Datas ISO 8601 do Node-RED.
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
