import SwiftUI

/// Meu perfil: nome e curso do usuário, usados como autoria. Abre pelo cartão "Publicando como…"
/// da tela Publicar. Com o Node-RED, vira um documento da coleção "usuario" no Cloudant.
/// No futuro será preenchido pelo login da UFSM/CTISM.
struct PerfilView: View {
    @Environment(\.dismiss) private var fechar
    @Environment(PublicacaoStore.self) private var store
    @AppStorage("usuario.nome") private var nome = ""
    @AppStorage("usuario.curso") private var curso = ""

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
                    // Com o Node-RED, cadastra ou atualiza o usuário no Cloudant em segundo plano.
                    Task { await store.registrarUsuario() }
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
    .environment(PublicacaoStore.previa)
}
