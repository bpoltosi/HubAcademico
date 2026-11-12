import Foundation

extension String {
    /// Texto sem espaços nem quebras de linha nas pontas.
    var aparado: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Minúsculas e sem acentos, para comparar “Ruído” com “ruido”.
    var normalizado: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
    }

    /// Palavras relevantes da busca (sem artigos, preposições etc.).
    var termosDeBusca: [String] {
        normalizado
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 2 && !String.palavrasVazias.contains($0) }
    }

    static let palavrasVazias: Set<String> = [
        "de", "da", "do", "das", "dos", "e", "o", "a", "os", "as", "em", "no", "na", "nos", "nas",
        "para", "pra", "com", "um", "uma", "por", "que", "sobre", "ao", "aos", "se",
    ]
}

extension Double {
    /// Média com uma casa decimal e vírgula (ex.: 4,8).
    var mediaFormatada: String {
        formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "pt_BR")))
    }
}

extension URL {
    /// Converte o texto digitado em um link válido (acrescenta https:// se faltar).
    static func web(_ texto: String) -> URL? {
        let limpo = texto.aparado
        guard !limpo.isEmpty, !limpo.contains(" ") else { return nil }
        let minusculo = limpo.lowercased()
        let completo = (minusculo.hasPrefix("http://") || minusculo.hasPrefix("https://")) ? limpo : "https://" + limpo
        guard let link = URL(string: completo),
              let host = link.host(),
              host.contains("."),
              !host.hasSuffix(".") else {
            return nil
        }
        return link
    }
}
