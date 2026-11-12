import Foundation

/// Link do servidor Node-RED.
///
/// Fica nos **Ajustes do iPhone › Hub Acadêmico › Link do servidor** (`Settings.bundle`), fora do app,
/// já que o ☰ do cabeçalho agora só volta ao Início. Com o campo vazio, o app usa só os dados
/// guardados no aparelho (modo demonstração).
///
/// O link padrão da turma pode vir do Info.plist (`HubServidorLink`): ele é copiado para o
/// campo dos Ajustes na primeira abertura (e de novo se mudar no Info.plist), a não ser que a
/// pessoa já tenha escrito outro link lá. Assim, o que aparece nos Ajustes é o que o app usa.
enum ServidorConfig {
    /// Mesma chave do campo de texto em `Settings.bundle/Root.plist`.
    static let chave = "servidor.link"
    /// Último link do Info.plist copiado para os Ajustes.
    private static let chavePadraoCopiado = "servidor.padraoCopiado"

    /// Link em uso, ou `nil` para usar só os dados do aparelho.
    static var link: URL? {
        normalizar(textoNosAjustes)
    }

    /// Há texto no campo dos Ajustes, mas ele não forma um link (ex.: tem espaços).
    static var linkInvalido: Bool {
        let texto = textoNosAjustes
        return !texto.aparado.isEmpty && normalizar(texto) == nil
    }

    /// Texto do campo dos Ajustes (vazio = só os dados do aparelho).
    private static var textoNosAjustes: String {
        let preferencias = UserDefaults.standard
        let daTurma = (Bundle.main.object(forInfoDictionaryKey: "HubServidorLink") as? String ?? "").aparado
        let copiado = preferencias.string(forKey: chavePadraoCopiado)
        let digitado = preferencias.string(forKey: chave)

        // Padrão novo no Info.plist e a pessoa não escreveu outro link: o campo passa a mostrá-lo.
        if daTurma != (copiado ?? ""), digitado == nil || digitado == copiado {
            preferencias.set(daTurma, forKey: chave)
            preferencias.set(daTurma, forKey: chavePadraoCopiado)
            return daTurma
        }
        return digitado ?? daTurma
    }

    /// Aceita "192.168.0.10:1880", "localhost:1880" ou "https://meu-node-red.com/api".
    /// Sem esquema, usa `http://` na rede local e `https://` nos demais casos.
    static func normalizar(_ texto: String) -> URL? {
        var limpo = texto.aparado
        guard !limpo.isEmpty, !limpo.contains(" ") else { return nil }
        while limpo.hasSuffix("/") {
            limpo.removeLast()
        }
        let minusculo = limpo.lowercased()
        if !minusculo.hasPrefix("http://"), !minusculo.hasPrefix("https://") {
            let host = minusculo.split(separator: "/").first.map(String.init) ?? minusculo
            let semPorta = host.split(separator: ":").first.map(String.init) ?? host
            limpo = (ehRedeLocal(semPorta) ? "http://" : "https://") + limpo
        }
        guard let link = URL(string: limpo), let host = link.host(), !host.isEmpty else { return nil }
        return link
    }

    /// `localhost`, nomes `.local` e endereços IP (ex.: 192.168.0.10).
    static func ehRedeLocal(_ host: String) -> Bool {
        host == "localhost" || host.hasSuffix(".local") || host.allSatisfy { $0.isNumber || $0 == "." }
    }
}
