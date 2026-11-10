import Foundation
import Observation

/// Repositório das produções, notas e favoritos.
///
/// Funciona de dois jeitos:
/// - **Só no aparelho** (sem servidor configurado): os dados ficam em `ctia-dados.json`,
///   começando pelas publicações de `DadosExemplo`.
/// - **Com o Node-RED**: publicações e avaliações vêm da API (`APIClient`) e uma cópia fica
///   em um arquivo próprio do servidor, para o app abrir mesmo sem conexão.
///
/// Os favoritos ficam sempre só no aparelho.
@MainActor
@Observable
final class ProducaoStore {
    private(set) var producoes: [Producao] = []
    private(set) var minhasNotas: [UUID: Int] = [:]
    private(set) var favoritos: Set<UUID> = []

    /// Endereço do Node-RED, ou `nil` para usar só os dados do aparelho.
    private(set) var servidor: URL?
    private(set) var sincronizando = false
    private(set) var ultimaSincronizacao: Date?
    /// Último problema ao atualizar a lista (`nil` quando a última atualização deu certo).
    private(set) var erroServidor: String?

    /// `false` nas pré-visualizações do Xcode: nada é gravado no aparelho.
    private let gravarNoAparelho: Bool

    init(gravarNoAparelho: Bool = true, servidor: URL? = ServidorConfig.url) {
        self.gravarNoAparelho = gravarNoAparelho
        self.servidor = servidor
        carregar()
    }

    /// Instância para os #Preview do Xcode (dados de exemplo, sem servidor e sem gravar nada).
    static var previa: ProducaoStore {
        ProducaoStore(gravarNoAparelho: false, servidor: nil)
    }

    var usaServidor: Bool {
        servidor != nil
    }

    // MARK: - Consultas

    func producao(id: UUID) -> Producao? {
        producoes.first { $0.id == id }
    }

    var favoritosOrdenados: [Producao] {
        producoes.filter { favoritos.contains($0.id) }
    }

    var anosDisponiveis: [Int] {
        let atual = Calendar.current.component(.year, from: .now)
        return Array(Set(producoes.map(\.ano)).union([atual])).sorted(by: >)
    }

    var materiasConhecidas: [String] {
        Array(Set(producoes.map(\.materia).filter { !$0.isEmpty }))
            .sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    // MARK: - Avaliações

    /// Todas as notas da produção no modo local, incluindo a do(a) usuário(a), se houver.
    func notas(_ producao: Producao) -> [Int] {
        if let minha = minhasNotas[producao.id] {
            return producao.notas + [minha]
        }
        return producao.notas
    }

    func media(_ producao: Producao) -> Double {
        if let media = producao.notaMedia {
            return media
        }
        let todas = notas(producao)
        guard !todas.isEmpty else { return 0 }
        return Double(todas.reduce(0, +)) / Double(todas.count)
    }

    func totalAvaliacoes(_ producao: Producao) -> Int {
        producao.quantidadeAvaliacoes ?? notas(producao).count
    }

    func minhaNota(_ producao: Producao) -> Int? {
        minhasNotas[producao.id]
    }

    /// Registra a nota (1 a 5). Com servidor, devolve a mensagem de erro se não conseguir enviar.
    @discardableResult
    func avaliar(_ producao: Producao, nota: Int) async -> String? {
        let nota = min(max(nota, 1), 5)
        let anterior = minhasNotas[producao.id]
        minhasNotas[producao.id] = nota // as estrelas respondem na hora

        guard let endereco = servidor else {
            salvar()
            return nil
        }
        do {
            let resumo = try await comUsuario(endereco) { cliente in
                try await cliente.avaliar(projetoID: producao.id, nota: nota)
            }
            if let indice = producoes.firstIndex(where: { $0.id == producao.id }) {
                producoes[indice].notaMedia = resumo.nota
                producoes[indice].quantidadeAvaliacoes = resumo.quant
            }
            minhasNotas[producao.id] = resumo.minhaNota ?? nota
            salvar()
            return nil
        } catch is CancellationError {
            minhasNotas[producao.id] = anterior
            return nil
        } catch {
            minhasNotas[producao.id] = anterior
            return error.localizedDescription
        }
    }

    func ordenarPorAvaliacao(_ lista: [Producao]) -> [Producao] {
        lista.sorted { (media($0), totalAvaliacoes($0)) > (media($1), totalAvaliacoes($1)) }
    }

    // MARK: - Favoritos

    func ehFavorito(_ producao: Producao) -> Bool {
        favoritos.contains(producao.id)
    }

    func alternarFavorito(_ producao: Producao) {
        if favoritos.contains(producao.id) {
            favoritos.remove(producao.id)
        } else {
            favoritos.insert(producao.id)
        }
        salvar()
    }

    // MARK: - Cadastro

    /// Publica a produção e devolve o id dela (com servidor, o id é criado pelo Node-RED).
    func publicar(_ nova: Producao) async throws -> UUID {
        guard let endereco = servidor else {
            producoes.insert(nova, at: 0)
            salvar()
            return nova.id
        }
        let resposta = try await comUsuario(endereco) { cliente in
            try await cliente.publicar(NovoProjetoDTO(nova))
        }
        guard let criada = resposta.producao else {
            throw ErroAPI.respostaInvalida
        }
        producoes.removeAll { $0.id == criada.id }
        producoes.insert(criada, at: 0)
        salvar()
        return criada.id
    }

    /// Volta aos exemplos (só no modo local; no servidor quem faz isso é a moderação).
    func restaurarExemplos() {
        guard servidor == nil else { return }
        producoes = DadosExemplo.producoes
        minhasNotas = [:]
        favoritos = []
        salvar()
    }

    // MARK: - Servidor Node-RED

    /// Troca entre o Node-RED e o modo local; cada um guarda os dados no seu próprio arquivo.
    func configurarServidor(_ url: URL?) async {
        ServidorConfig.salvar(url)
        if url != servidor {
            servidor = url
            erroServidor = nil
            carregar()
        }
        await sincronizar()
    }

    /// Busca as publicações no Node-RED. No modo local não faz nada.
    func sincronizar() async {
        guard let endereco = servidor, !sincronizando else { return }
        sincronizando = true
        do {
            let lista = try await cliente(endereco).projetos()
            if endereco == servidor {
                aplicar(lista)
                ultimaSincronizacao = .now
                erroServidor = nil
                salvar()
            }
        } catch is CancellationError {
            // A tela que pediu a atualização foi fechada; fica para a próxima vez.
        } catch {
            if endereco == servidor {
                erroServidor = error.localizedDescription
            }
        }
        sincronizando = false
        if endereco != servidor {
            // O endereço mudou enquanto esperava a resposta: atualiza com o novo.
            await sincronizar()
        }
    }

    /// Envia nome e curso do perfil ao servidor (cadastra na primeira vez; depois, só atualiza).
    func registrarPerfil() async {
        guard let endereco = servidor else { return }
        let perfil = Self.perfilLocal
        guard !perfil.nome.isEmpty else { return }
        do {
            if usuarioID(em: endereco) == nil {
                try await cadastrarUsuario(em: endereco)
            } else {
                do {
                    _ = try await cliente(endereco).atualizarPerfil(nome: perfil.nome, curso: perfil.curso)
                } catch ErroAPI.usuarioNaoIdentificado {
                    try await cadastrarUsuario(em: endereco)
                }
            }
        } catch {
            // O nome no servidor é só informativo; o envio é repetido na próxima publicação ou avaliação.
            print("CTIA: perfil não enviado ao servidor – \(error.localizedDescription)")
        }
    }

    private func aplicar(_ lista: [ProjetoDTO]) {
        producoes = lista.compactMap(\.producao)
        var notas: [UUID: Int] = [:]
        for item in lista {
            if let id = UUID(uuidString: item.id), let nota = item.minhaNota {
                notas[id] = nota
            }
        }
        minhasNotas = notas
    }

    /// Executa uma chamada que exige usuário no servidor: cadastra o perfil na primeira vez
    /// e refaz o cadastro uma vez se o servidor não reconhecer o id (por exemplo, banco zerado).
    private func comUsuario<Resultado>(
        _ endereco: URL,
        _ operacao: (APIClient) async throws -> Resultado
    ) async throws -> Resultado {
        if usuarioID(em: endereco) == nil {
            try await cadastrarUsuario(em: endereco)
        }
        do {
            return try await operacao(cliente(endereco))
        } catch ErroAPI.usuarioNaoIdentificado {
            try await cadastrarUsuario(em: endereco)
            return try await operacao(cliente(endereco))
        }
    }

    private func cadastrarUsuario(em endereco: URL) async throws {
        let perfil = Self.perfilLocal
        let usuario = try await APIClient(base: endereco).cadastrarUsuario(
            nome: perfil.nome.isEmpty ? "Estudante do CTISM" : perfil.nome,
            curso: perfil.curso
        )
        UserDefaults.standard.set(usuario.id, forKey: chaveUsuario(endereco))
    }

    private func cliente(_ endereco: URL) -> APIClient {
        APIClient(base: endereco, usuarioID: usuarioID(em: endereco))
    }

    /// O id do usuário vale só para o servidor em que foi criado.
    private func usuarioID(em endereco: URL) -> String? {
        UserDefaults.standard.string(forKey: chaveUsuario(endereco))
    }

    private func chaveUsuario(_ endereco: URL) -> String {
        "perfil.userId|" + endereco.absoluteString
    }

    /// Nome e curso salvos em Menu › Meu perfil (as mesmas chaves do @AppStorage das telas).
    private static var perfilLocal: (nome: String, curso: String) {
        let padrao = UserDefaults.standard
        return ((padrao.string(forKey: "perfil.nome") ?? "").aparado, padrao.string(forKey: "perfil.curso") ?? "")
    }

    // MARK: - Busca

    /// Aplica o tipo e os filtros, procura o texto (palavras e, se ligada, IA) e ordena o resultado.
    func buscar(texto: String, tipo: TipoProducao?, filtros: FiltrosBusca, usarIA: Bool, motor: BuscaInteligente) -> [Producao] {
        let candidatos = producoes.filter { producao in
            (tipo == nil || producao.tipo == tipo) && atende(producao, filtros: filtros)
        }
        let ordenarPorNota = filtros.estaAtivo(.melhorAvaliacao)
        let consulta = texto.aparado

        guard !consulta.isEmpty else {
            return ordenarPorNota
                ? ordenarPorAvaliacao(candidatos)
                : candidatos.sorted { $0.criadoEm > $1.criadoEm }
        }

        let termos = consulta.termosDeBusca
        var pontos: [UUID: Double] = [:]
        for producao in candidatos {
            pontos[producao.id] = Double(pontuacaoPorPalavras(producao, termos: termos))
        }

        if usarIA, let similares = motor.similaridades(consulta: consulta, itens: candidatos) {
            let melhor = similares.values.max() ?? 0
            let corte = max(melhor - 0.12, 0.3)
            for (id, similaridade) in similares {
                let atual = pontos[id] ?? 0
                if atual > 0 || similaridade >= corte {
                    pontos[id] = atual + max(similaridade, 0) * 5 + 0.01
                }
            }
        }

        let encontrados = candidatos.filter { (pontos[$0.id] ?? 0) > 0 }
        if ordenarPorNota {
            return ordenarPorAvaliacao(encontrados)
        }
        return encontrados.sorted { (pontos[$0.id] ?? 0) > (pontos[$1.id] ?? 0) }
    }

    private func atende(_ producao: Producao, filtros: FiltrosBusca) -> Bool {
        if filtros.estaAtivo(.ano), producao.ano != filtros.ano {
            return false
        }
        if filtros.estaAtivo(.area), producao.area != filtros.area {
            return false
        }
        let autor = filtros.autor.aparado.normalizado
        if filtros.estaAtivo(.autor), !autor.isEmpty,
           !producao.autores.contains(where: { $0.normalizado.contains(autor) }) {
            return false
        }
        if filtros.estaAtivo(.curso), producao.curso != filtros.curso {
            return false
        }
        let titulo = filtros.titulo.aparado.normalizado
        if filtros.estaAtivo(.titulo), !titulo.isEmpty, !producao.titulo.normalizado.contains(titulo) {
            return false
        }
        let materia = filtros.materia.aparado.normalizado
        if filtros.estaAtivo(.materia), !materia.isEmpty, !producao.materia.normalizado.contains(materia) {
            return false
        }
        return true
    }

    /// Título vale mais que matéria/área/curso, que valem mais que resumo e autoria.
    private func pontuacaoPorPalavras(_ producao: Producao, termos: [String]) -> Int {
        guard !termos.isEmpty else { return 0 }
        let titulo = producao.titulo.normalizado
        let metadados = [producao.materia, producao.area.nome, producao.curso,
                         CursoCTISM.curto(producao.curso), producao.tipo.nome]
            .joined(separator: " ").normalizado
        let corpo = ([producao.descricao] + producao.autores).joined(separator: " ").normalizado

        var total = 0
        for termo in termos {
            if titulo.contains(termo) { total += 3 }
            if metadados.contains(termo) { total += 2 }
            if corpo.contains(termo) { total += 1 }
        }
        return total
    }

    // MARK: - Persistência

    private struct ArquivoDados: Codable {
        var producoes: [Producao]
        var minhasNotas: [UUID: Int]
        var favoritos: Set<UUID>
        var ultimaSincronizacao: Date?
    }

    /// Cada modo tem o seu arquivo, para os exemplos não se misturarem com os dados de um servidor.
    private var arquivo: URL? {
        guard gravarNoAparelho else { return nil }
        let nome: String
        if let servidor {
            let seguro = String(servidor.absoluteString.map { (letra: Character) -> Character in
                letra.isLetter || letra.isNumber ? letra : "-"
            })
            nome = "ctia-servidor-\(seguro).json"
        } else {
            nome = "ctia-dados.json"
        }
        return URL.documentsDirectory.appending(path: nome)
    }

    private func carregar() {
        producoes = []
        minhasNotas = [:]
        favoritos = []
        ultimaSincronizacao = nil
        guard let arquivo, FileManager.default.fileExists(atPath: arquivo.path(percentEncoded: false)) else {
            if servidor == nil {
                producoes = DadosExemplo.producoes
            }
            return
        }
        do {
            let salvo = try JSONDecoder().decode(ArquivoDados.self, from: Data(contentsOf: arquivo))
            producoes = salvo.producoes
            minhasNotas = salvo.minhasNotas
            favoritos = salvo.favoritos
            ultimaSincronizacao = salvo.ultimaSincronizacao
        } catch {
            // Arquivo ilegível: guarda uma cópia (.bak) em vez de sobrescrever os dados do(a) usuário(a).
            print("CTIA: não foi possível ler os dados – \(error)")
            let copia = arquivo.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: copia)
            try? FileManager.default.moveItem(at: arquivo, to: copia)
            if servidor == nil {
                producoes = DadosExemplo.producoes
            }
        }
    }

    private func salvar() {
        guard let arquivo else { return }
        let conteudo = ArquivoDados(
            producoes: producoes,
            minhasNotas: minhasNotas,
            favoritos: favoritos,
            ultimaSincronizacao: ultimaSincronizacao
        )
        do {
            let dados = try JSONEncoder().encode(conteudo)
            try dados.write(to: arquivo, options: .atomic)
        } catch {
            print("CTIA: não foi possível salvar os dados – \(error)")
        }
    }
}
