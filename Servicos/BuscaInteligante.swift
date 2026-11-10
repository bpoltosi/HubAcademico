import Foundation
import NaturalLanguage

/// “Busca IA”: compara o significado da pergunta com o de cada publicação usando os
/// embeddings em português do framework NaturalLanguage, que rodam no próprio iPhone
/// (sem internet, sem chave de API e sem enviar dados para fora do aparelho).
///
/// Ordem de tentativa: embedding de frases → média dos embeddings de palavras.
/// Se nenhum estiver disponível no aparelho, `similaridades` devolve `nil`
/// e a busca continua apenas por palavras.
final class BuscaInteligente {
    private lazy var embeddingFrases: NLEmbedding? = NLEmbedding.sentenceEmbedding(for: .portuguese)
    private lazy var embeddingPalavras: NLEmbedding? = NLEmbedding.wordEmbedding(for: .portuguese)
    private var cache: [String: [Double]] = [:]

    var disponivel: Bool {
        embeddingFrases != nil || embeddingPalavras != nil
    }

    /// Similaridade de cosseno (−1 a 1) entre a consulta e cada item.
    func similaridades(consulta: String, itens: [Producao]) -> [UUID: Double]? {
        guard disponivel, let alvo = vetor(para: consulta) else { return nil }
        var resultado: [UUID: Double] = [:]
        for item in itens {
            guard let vetorItem = vetor(para: item.textoSemantico) else { continue }
            resultado[item.id] = cosseno(alvo, vetorItem)
        }
        return resultado
    }

    private func vetor(para texto: String) -> [Double]? {
        if let salvo = cache[texto] {
            return salvo
        }
        var vetor: [Double]?
        if let embeddingFrases {
            vetor = embeddingFrases.vector(for: texto)
        }
        if vetor == nil, let embeddingPalavras {
            vetor = mediaDasPalavras(texto, embedding: embeddingPalavras)
        }
        if let vetor {
            cache[texto] = vetor
        }
        return vetor
    }

    private func mediaDasPalavras(_ texto: String, embedding: NLEmbedding) -> [Double]? {
        let tokenizador = NLTokenizer(unit: .word)
        tokenizador.string = texto
        var soma: [Double] = []
        var quantidade = 0
        tokenizador.enumerateTokens(in: texto.startIndex..<texto.endIndex) { intervalo, _ in
            let palavra = texto[intervalo].lowercased()
            if let vetorPalavra = embedding.vector(for: palavra) {
                if soma.isEmpty {
                    soma = vetorPalavra
                } else {
                    for indice in soma.indices where indice < vetorPalavra.count {
                        soma[indice] += vetorPalavra[indice]
                    }
                }
                quantidade += 1
            }
            return true
        }
        guard quantidade > 0 else { return nil }
        return soma.map { $0 / Double(quantidade) }
    }

    private func cosseno(_ a: [Double], _ b: [Double]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 0 }
        var produto = 0.0
        var normaA = 0.0
        var normaB = 0.0
        for indice in 0..<n {
            produto += a[indice] * b[indice]
            normaA += a[indice] * a[indice]
            normaB += b[indice] * b[indice]
        }
        let denominador = normaA.squareRoot() * normaB.squareRoot()
        return denominador > 0 ? produto / denominador : 0
    }
}
