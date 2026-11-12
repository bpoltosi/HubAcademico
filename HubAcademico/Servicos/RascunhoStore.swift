import Foundation

/// Guarda um rascunho da tela Publicar no próprio aparelho (UserDefaults).
enum RascunhoStore {
    private static let chave = "publicacao.rascunho"

    static func carregar() -> FormularioPublicacao? {
        guard let dados = UserDefaults.standard.data(forKey: chave) else { return nil }
        return try? JSONDecoder().decode(FormularioPublicacao.self, from: MigracaoDeNomes.atualizar(dados))
    }

    static func salvar(_ formulario: FormularioPublicacao) {
        if let dados = try? JSONEncoder().encode(formulario) {
            UserDefaults.standard.set(dados, forKey: chave)
        }
    }

    static func apagar() {
        UserDefaults.standard.removeObject(forKey: chave)
    }
}
