import Foundation

/// Converte o que versões anteriores do app gravaram no aparelho para os nomes padronizados
/// (produção → publicação, matéria → disciplina, perfil → usuário, URL/endereço → link,
/// notaMedia/quantidade → media/totalAvaliacoes, capa → imagem). Sem isso, quem já usava o app
/// perderia as publicações locais, o rascunho, o nome do perfil e o link do servidor.
enum MigracaoDeNomes {
    /// Chaves JSON antigas → novas (arquivo de dados e rascunho).
    private static let chavesJSON: [String: String] = [
        "producoes": "publicacoes",
        "materia": "disciplina",
        "imagemURL": "imagemLink",
        "notaMedia": "media",
        "quantidadeAvaliacoes": "totalAvaliacoes",
    ]

    /// Preferências antigas → novas (UserDefaults).
    private static let preferencias: [String: String] = [
        "perfil.nome": "usuario.nome",
        "perfil.curso": "usuario.curso",
        "cadastro.rascunho": "publicacao.rascunho",
        "servidor.url": "servidor.link",
    ]

    private static let prefixoIdAntigo = "perfil.userId|"
    private static let prefixoIdNovo = "usuario.id|"
    private static let imagemAntiga = "asset://capa-"
    private static let imagemNova = "asset://imagem-"

    /// Devolve o JSON com os nomes novos (ou os mesmos dados, se já estiverem atualizados).
    static func atualizar(_ dados: Data) -> Data {
        guard let objeto = try? JSONSerialization.jsonObject(with: dados, options: [.fragmentsAllowed]),
              let convertido = try? JSONSerialization.data(withJSONObject: converter(objeto), options: [.fragmentsAllowed]) else {
            return dados
        }
        return convertido
    }

    private static func converter(_ valor: Any) -> Any {
        if let dicionario = valor as? [String: Any] {
            var novo: [String: Any] = [:]
            for (chave, conteudo) in dicionario {
                let chaveNova = chavesJSON[chave] ?? chave
                // Se já existir a chave nova, ela vale mais que a antiga.
                if chaveNova == chave || dicionario[chaveNova] == nil {
                    novo[chaveNova] = converter(conteudo)
                }
            }
            return novo
        }
        if let lista = valor as? [Any] {
            return lista.map(converter)
        }
        if let texto = valor as? String, texto.hasPrefix(imagemAntiga) {
            return imagemNova + texto.dropFirst(imagemAntiga.count)
        }
        return valor
    }

    /// Copia as preferências antigas para os nomes novos (só se o nome novo ainda estiver vazio)
    /// e apaga as antigas. Roda na abertura do app, antes de qualquer tela ler as preferências.
    static func atualizarPreferencias(_ padrao: UserDefaults = .standard) {
        var pares = preferencias
        // Ids do usuário, um por servidor: "perfil.userId|<link>" → "usuario.id|<link>".
        for chave in padrao.dictionaryRepresentation().keys where chave.hasPrefix(prefixoIdAntigo) {
            pares[chave] = prefixoIdNovo + chave.dropFirst(prefixoIdAntigo.count)
        }
        for (antiga, nova) in pares {
            guard let valor = padrao.object(forKey: antiga) else { continue }
            if padrao.object(forKey: nova) == nil {
                padrao.set(valor, forKey: nova)
            }
            padrao.removeObject(forKey: antiga)
        }
    }
}
