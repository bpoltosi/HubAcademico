import SwiftUI

/// Perfil (nome e curso), usado como autoria no cadastro. Abre pelo cartão "Publicando como…"
/// da tela de cadastro. Com o Node-RED, vira um registro da tabela users.
/// No futuro será preenchido pelo login da UFSM/CTISM.
struct PerfilView: View {
    @Environment(\.dismiss) private var fechar
    @Environment(ProducaoStore.self) private var store
    @AppStorage("perfil.nome") private var nome = ""
    @AppStorage("perfil.curso") private var curso = ""

    var body: some View {
        Form {
            Section {
                TextField("Nome completo", text: $nome)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
            } header: {
                Text("Seu nome")
            } footer: {
                Text("Aparece como autoria das suas publicações.")
            }

            Section("Curso no CTISM") {
                Picker("Curso", selection: $curso) {
                    Text("Selecione…").tag("")
                    ForEach(CursoCTISM.Nivel.allCases) { nivel in
                        Section(nivel.rawValue) {
                            ForEach(CursoCTISM.cursos(do: nivel)) { item in
                                Text(item.nomeCurto).tag(item.nome)
                            }
                        }
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                Label("Em breve: entrar com a conta da UFSM ou do CTISM.", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(UFSM.azulSecundario)
        .navigationTitle("Meu perfil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Concluir") {
                    // Com o Node-RED, cadastra ou atualiza o usuário (tabela users) em segundo plano.
                    Task { await store.registrarPerfil() }
                    fechar()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PerfilView()
    }
    .environment(ProducaoStore.previa)
}
