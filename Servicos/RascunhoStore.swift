import Foundation

/// Guarda um rascunho do cadastro no próprio aparelho (UserDefaults).
enum RascunhoStore {
    private static let chave = "cadastro.rascunho"

    static func carregar() -> FormularioCadastro? {
        guard let dados = UserDefaults.standard.data(forKey: chave) else { return nil }
        return try? JSONDecoder().decode(FormularioCadastro.self, from: dados)
    }

    static func salvar(_ formulario: FormularioCadastro) {
        if let dados = try? JSONEncoder().encode(formulario) {
            UserDefaults.standard.set(dados, forKey: chave)
        }
    }

    static func apagar() {
        UserDefaults.standard.removeObject(forKey: chave)
    }
}
