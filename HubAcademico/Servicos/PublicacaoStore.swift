import Foundation
import Observation

/// Publicações e avaliações do app.
///
/// Funciona de dois jeitos:
/// - **Só no aparelho** (sem servidor configurado): os dados ficam em `hub-dados.json`,
///   começando pelas publicações de `DadosExemplo`.
/// - **Com o Node-RED**: publicações e avaliações vêm da API (`APIClient`) e uma cópia fica
///   em um arquivo próprio do servidor, para o app abrir mesmo sem conexão.
///
/// O link do servidor fica nos Ajustes do iPhone (veja `ServidorConfig`).
@MainActor
@Observable
final class PublicacaoStore {
    private(set) var publicacoes: [Publicacao] = []
    private(set) var minhasNotas: [UUID: Int] = [:]

    /// Link do Node-RED, ou `nil` para usar só os dados do aparelho.
    private(set) var servidorLink: URL?
    private(set) var sincronizando = false
    private(set) var ultimaSincronizacao: Date?
    /// Último problema ao atualizar a lista (`nil` quando a última atualização deu certo).
    private(set) var erroServidor: String?
    /// Aviso quando o link escrito nos Ajustes não é válido (o app passa a usar só o aparelho).
    private(set) var avisoConfiguracao: String?

    /// `false` nas pré-visualizações do Xcode: nada é gravado no aparelho.
    private let gravarNoAparelho: Bool

    init(gravarNoAparelho: Bool = true, servidorLink: URL? = ServidorConfig.link) {
        self.gravarNoAparelho = gravarNoAparelho
        self.servidorLink = servidorLink
        carregar()
    }

    /// Instância para os #Preview do Xcode (dados de exemplo, sem servidor e sem gravar nada).
    static var previa: PublicacaoStore {
        PublicacaoStore(gravarNoAparelho: false, servidorLink: nil)
    }

    var usaServidor: Bool {
        servidorLink != nil
    }

    // MARK: - Consultas

    func publicacao(id: UUID) -> Publicacao? {
        publicacoes.first { $0.id == id }
    }

    var anosDisponiveis: [Int] {
        let atual = Calendar.current.component(.year, from: .now)
        return Array(Set(publicacoes.map(\.ano)).union([atual])).sorted(by: >)
    }

    /// Disciplinas já usadas em publicações desta subárea (inclui as digitadas, fora da lista da UFSM).
    func disciplinasUsadas(na subarea: String) -> [String] {
        let nomes = publicacoes
            .filter { $0.subarea == subarea }
            .map(\.disciplina.aparado)
            .filter { !$0.isEmpty }
        return Array(Set(nomes)).sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    // MARK: - Avaliações

    /// Todas as notas da publicação no modo local, incluindo a do(a) usuário(a), se houver.
    func notas(_ publicacao: Publicacao) -> [Int] {
        if let minha = minhasNotas[publicacao.id] {
            return publicacao.notas + [minha]
        }
        return publicacao.notas
    }

    func media(_ publicacao: Publicacao) -> Double {
        if let media = publicacao.media {
            return media
        }
        let todas = notas(publicacao)
        guard !todas.isEmpty else { return 0 }
        return Double(todas.reduce(0, +)) / Double(todas.count)
    }

    func totalAvaliacoes(_ publicacao: Publicacao) -> Int {
        publicacao.totalAvaliacoes ?? notas(publicacao).count
    }

    func minhaNota(_ publicacao: Publicacao) -> Int? {
        minhasNotas[publicacao.id]
    }

    /// Registra a nota (1 a 5). Com servidor, devolve a mensagem de erro se não conseguir enviar.
    @discardableResult
    func avaliar(_ publicacao: Publicacao, nota: Int) async -> String? {
        let nota = min(max(nota, 1), 5)
        let anterior = minhasNotas[publicacao.id]
        minhasNotas[publicacao.id] = nota // as estrelas respondem na hora

        guard let link = servidorLink else {
            salvar()
            return nil
        }
        do {
            let resultado = try await comUsuario(link) { cliente in
                try await cliente.avaliar(publicacaoID: publicacao.id, nota: nota)
            }
            if let indice = publicacoes.firstIndex(where: { $0.id == publicacao.id }) {
                publicacoes[indice].media = resultado.media
                publicacoes[indice].totalAvaliacoes = resultado.totalAvaliacoes
            }
            minhasNotas[publicacao.id] = resultado.minhaNota ?? nota
            salvar()
            return nil
        } catch is CancellationError {
            minhasNotas[publicacao.id] = anterior
            return nil
        } catch {
            minhasNotas[publicacao.id] = anterior
            return error.localizedDescription
        }
    }

    func ordenarPorAvaliacao(_ lista: [Publicacao]) -> [Publicacao] {
        lista.sorted { (media($0), totalAvaliacoes($0)) > (media($1), totalAvaliacoes($1)) }
    }

    // MARK: - Publicar

    /// Publica e devolve o id da publicação (com servidor, o id é criado pelo Node-RED).
    func publicar(_ nova: Publicacao) async throws -> UUID {
        guard let link = servidorLink else {
            publicacoes.insert(nova, at: 0)
            salvar()
            return nova.id
        }
        let resposta = try await comUsuario(link) { cliente in
            try await cliente.publicar(NovaPublicacaoDTO(nova))
        }
        guard let criada = resposta.publicacao else {
            throw ErroAPI.respostaInvalida
        }
        publicacoes.removeAll { $0.id == criada.id }
        publicacoes.insert(criada, at: 0)
        salvar()
        return criada.id
    }

    // MARK: - Servidor Node-RED

    /// Relê o link do servidor nos Ajustes do iPhone e atualiza a lista. Chamado ao abrir o app e sempre que
    /// ele volta à tela (por exemplo, depois de trocar o servidor nos Ajustes).
    /// Trocar entre o Node-RED e o modo local muda também o arquivo: cada modo guarda os seus dados.
    func atualizarConfiguracao() async {
        guard gravarNoAparelho else { return } // pré-visualizações do Xcode: nada muda
        let link = ServidorConfig.link
        if link != servidorLink {
            servidorLink = link
            erroServidor = nil
            carregar()
        }
        avisoConfiguracao = ServidorConfig.linkInvalido
            ? "O link do servidor nos Ajustes do iPhone (Hub Acadêmico) não é válido. Por enquanto, o app usa só os dados do aparelho."
            : nil
        await sincronizar()
    }

    /// Busca as publicações no Node-RED. No modo local não faz nada.
    func sincronizar() async {
        guard let link = servidorLink, !sincronizando else { return }
        sincronizando = true
        do {
            let lista = try await cliente(link).publicacoes()
            if link == servidorLink {
                aplicar(lista)
                ultimaSincronizacao = .now
                erroServidor = nil
                salvar()
            }
        } catch is CancellationError {
            // A tela que pediu a atualização foi fechada; fica para a próxima vez.
        } catch {
            if link == servidorLink {
                erroServidor = error.localizedDescription
            }
        }
        sincronizando = false
        if link != servidorLink {
            // O link mudou enquanto esperava a resposta: atualiza com o novo.
            await sincronizar()
        }
    }

    /// Envia nome e curso do usuário ao servidor (cadastra na primeira vez; depois, só atualiza).
    func registrarUsuario() async {
        guard let link = servidorLink else { return }
        let dados = Self.usuarioLocal
        guard !dados.nome.isEmpty else { return }
        do {
            if usuarioID(em: link) == nil {
                try await cadastrarUsuario(em: link)
            } else {
                do {
                    _ = try await cliente(link).atualizarUsuario(nome: dados.nome, curso: dados.curso)
                } catch ErroAPI.usuarioNaoIdentificado {
                    try await cadastrarUsuario(em: link)
                }
            }
        } catch {
            // O nome no servidor é só informativo; o envio é repetido na próxima publicação ou avaliação.
            print("Hub Acadêmico: usuário não enviado ao servidor – \(error.localizedDescription)")
        }
    }

    private func aplicar(_ lista: [PublicacaoDTO]) {
        publicacoes = lista.compactMap(\.publicacao)
        var notas: [UUID: Int] = [:]
        for item in lista {
            if let id = UUID(uuidString: item.id), let nota = item.minhaNota {
                notas[id] = nota
            }
        }
        minhasNotas = notas
    }

    /// Executa uma chamada que exige usuário no servidor: cadastra o usuário na primeira vez
    /// e refaz o cadastro uma vez se o servidor não reconhecer o id (por exemplo, banco zerado).
    private func comUsuario<Resultado>(
        _ link: URL,
        _ operacao: (APIClient) async throws -> Resultado
    ) async throws -> Resultado {
        if usuarioID(em: link) == nil {
            try await cadastrarUsuario(em: link)
        }
        do {
            return try await operacao(cliente(link))
        } catch ErroAPI.usuarioNaoIdentificado {
            try await cadastrarUsuario(em: link)
            return try await operacao(cliente(link))
        }
    }

    private func cadastrarUsuario(em link: URL) async throws {
        let dados = Self.usuarioLocal
        let usuario = try await APIClient(servidorLink: link).cadastrarUsuario(
            nome: dados.nome.isEmpty ? "Estudante do CTISM" : dados.nome,
            curso: dados.curso
        )
        UserDefaults.standard.set(usuario.id, forKey: chaveUsuario(link))
    }

    private func cliente(_ link: URL) -> APIClient {
        APIClient(servidorLink: link, usuarioID: usuarioID(em: link))
    }

    /// O id do usuário vale só para o servidor em que foi criado.
    private func usuarioID(em link: URL) -> String? {
        UserDefaults.standard.string(forKey: chaveUsuario(link))
    }

    private func chaveUsuario(_ link: URL) -> String {
        "usuario.id|" + link.absoluteString
    }

    /// Nome e curso salvos em Meu perfil, aberto pelo cartão "Publicando como…" da tela Publicar
    /// (as mesmas chaves do @AppStorage das telas).
    private static var usuarioLocal: (nome: String, curso: String) {
        let padrao = UserDefaults.standard
        return ((padrao.string(forKey: "usuario.nome") ?? "").aparado, padrao.string(forKey: "usuario.curso") ?? "")
    }

    // MARK: - Busca

    /// Aplica o tipo e os filtros, procura as palavras do texto e ordena o resultado.
    func buscar(texto: String, tipo: TipoPublicacao?, filtros: FiltrosBusca) -> [Publicacao] {
        let candidatos = publicacoes.filter { publicacao in
            (tipo == nil || publicacao.tipo == tipo) && atende(publicacao, filtros: filtros)
        }
        let ordenarPorMedia = filtros.estaAtivo(.melhorAvaliacao)
        let consulta = texto.aparado

        guard !consulta.isEmpty else {
            return ordenarPorMedia
                ? ordenarPorAvaliacao(candidatos)
                : candidatos.sorted { $0.criadoEm > $1.criadoEm }
        }

        let termos = consulta.termosDeBusca
        var pontos: [UUID: Double] = [:]
        for publicacao in candidatos {
            pontos[publicacao.id] = Double(pontuacaoPorPalavras(publicacao, termos: termos))
        }

        let encontrados = candidatos.filter { (pontos[$0.id] ?? 0) > 0 }
        if ordenarPorMedia {
            return ordenarPorAvaliacao(encontrados)
        }
        return encontrados.sorted { (pontos[$0.id] ?? 0) > (pontos[$1.id] ?? 0) }
    }

    private func atende(_ publicacao: Publicacao, filtros: FiltrosBusca) -> Bool {
        if filtros.estaAtivo(.ano), publicacao.ano != filtros.ano {
            return false
        }
        if filtros.estaAtivo(.area), publicacao.area != filtros.area {
            return false
        }
        let autor = filtros.autor.aparado.normalizado
        if filtros.estaAtivo(.autor), !autor.isEmpty,
           !publicacao.autores.contains(where: { $0.normalizado.contains(autor) }) {
            return false
        }
        if filtros.estaAtivo(.curso), publicacao.curso != filtros.curso {
            return false
        }
        let titulo = filtros.titulo.aparado.normalizado
        if filtros.estaAtivo(.titulo), !titulo.isEmpty, !publicacao.titulo.normalizado.contains(titulo) {
            return false
        }
        let disciplina = filtros.disciplina.aparado.normalizado
        if filtros.estaAtivo(.disciplina), !disciplina.isEmpty, !publicacao.disciplina.normalizado.contains(disciplina) {
            return false
        }
        return true
    }

    /// Título vale mais que disciplina/subárea/área/curso, que valem mais que descrição e autoria.
    private func pontuacaoPorPalavras(_ publicacao: Publicacao, termos: [String]) -> Int {
        guard !termos.isEmpty else { return 0 }
        let titulo = publicacao.titulo.normalizado
        let metadados = [publicacao.disciplina, publicacao.subarea ?? "", publicacao.area.nome, publicacao.area.nomeCompleto,
                         publicacao.curso, CursoCTISM.curto(publicacao.curso), publicacao.tipo.nome]
            .joined(separator: " ").normalizado
        let corpo = ([publicacao.descricao] + publicacao.autores).joined(separator: " ").normalizado

        var total = 0
        for termo in termos {
            if titulo.contains(termo) { total += 3 }
            if metadados.contains(termo) { total += 2 }
            if corpo.contains(termo) { total += 1 }
        }
        return total
    }

    // MARK: - Persistência

    /// Arquivos de versões anteriores continuam abrindo: os favoritos são ignorados e os nomes antigos
    /// ("producoes", "materia", "imagemURL"…) são convertidos por `MigracaoDeNomes`.
    private struct ArquivoDados: Codable {
        var publicacoes: [Publicacao]
        var minhasNotas: [UUID: Int]
        var ultimaSincronizacao: Date?
    }

    /// Cada modo tem o seu arquivo, para os exemplos não se misturarem com os dados de um servidor.
    private var arquivo: URL? {
        guard gravarNoAparelho else { return nil }
        let nome: String
        if let servidorLink {
            let seguro = String(servidorLink.absoluteString.map { (letra: Character) -> Character in
                letra.isLetter || letra.isNumber ? letra : "-"
            })
            nome = "hub-servidor-\(seguro).json"
        } else {
            nome = "hub-dados.json"
        }
        return URL.documentsDirectory.appending(path: nome)
    }

    private func carregar() {
        publicacoes = []
        minhasNotas = [:]
        ultimaSincronizacao = nil
        guard let arquivo, FileManager.default.fileExists(atPath: arquivo.path(percentEncoded: false)) else {
            if servidorLink == nil {
                publicacoes = DadosExemplo.publicacoes
            }
            return
        }
        do {
            let dados = try MigracaoDeNomes.atualizar(Data(contentsOf: arquivo))
            let salvo = try JSONDecoder().decode(ArquivoDados.self, from: dados)
            publicacoes = salvo.publicacoes
            minhasNotas = salvo.minhasNotas
            ultimaSincronizacao = salvo.ultimaSincronizacao
        } catch {
            // Arquivo ilegível: guarda uma cópia (.bak) em vez de sobrescrever os dados do(a) usuário(a).
            print("Hub Acadêmico: não foi possível ler os dados – \(error)")
            let copia = arquivo.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: copia)
            try? FileManager.default.moveItem(at: arquivo, to: copia)
            if servidorLink == nil {
                publicacoes = DadosExemplo.publicacoes
            }
        }
    }

    private func salvar() {
        guard let arquivo else { return }
        let conteudo = ArquivoDados(
            publicacoes: publicacoes,
            minhasNotas: minhasNotas,
            ultimaSincronizacao: ultimaSincronizacao
        )
        do {
            let dados = try JSONEncoder().encode(conteudo)
            try dados.write(to: arquivo, options: .atomic)
        } catch {
            print("Hub Acadêmico: não foi possível salvar os dados – \(error)")
        }
    }
}
