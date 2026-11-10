import Foundation

/// Endereço do servidor Node-RED.
///
/// Sem endereço, o app funciona só com os dados guardados no aparelho (modo demonstração).
/// O endereço pode vir do Info.plist (`CTIAServidorURL`, vale para todos os aparelhos da turma)
/// ou ser digitado em Menu › Servidor, o que tem prioridade.
enum ServidorConfig {
    private static let chave = "servidor.url"

    /// Endereço em uso, ou `nil` para usar só os dados do aparelho.
    static var url: URL? {
        if let salvo = UserDefaults.standard.string(forKey: chave) {
            // Texto vazio salvo = a pessoa escolheu usar só o aparelho.
            return normalizar(salvo)
        }
        let padrao = Bundle.main.object(forInfoDictionaryKey: "CTIAServidorURL") as? String ?? ""
        return normalizar(padrao)
    }

    static func salvar(_ url: URL?) {
        UserDefaults.standard.set(url?.absoluteString ?? "", forKey: chave)
    }

    /// Aceita "192.168.0.10:1880", "localhost:1880" ou "https://meu-node-red.com/api".
    /// Sem esquema, usa `http://` para endereços da rede local e `https://` para os demais.
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
        guard let url = URL(string: limpo), let host = url.host(), !host.isEmpty else { return nil }
        return url
    }

    /// `localhost`, nomes `.local` e endereços IP (ex.: 192.168.0.10).
    static func ehRedeLocal(_ host: String) -> Bool {
        host == "localhost" || host.hasSuffix(".local") || host.allSatisfy { $0.isNumber || $0 == "." }
    }
}
