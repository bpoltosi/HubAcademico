import SwiftUI

/// Menu (☰): perfil, atalhos, favoritos e informações do app.
struct MenuView: View {
    @Environment(\.dismiss) private var fechar
    @Environment(ProducaoStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(BuscaModel.self) private var busca
    @State private var confirmarRestauracao = false

    private var versao: String {
        let versao = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(versao) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PerfilView()
                    } label: {
                        Label("Meu perfil", systemImage: "person.crop.circle")
                    }
                    Button {
                        ir(para: .cadastro(.projeto))
                    } label: {
                        Label("Cadastrar publicação", systemImage: "plus.circle")
                    }
                    Button {
                        fechar()
                        busca.tipo = nil
                        router.abrirBusca()
                    } label: {
                        Label("Buscar", systemImage: "magnifyingglass")
                    }
                    Button {
                        fechar()
                        router.voltarAoInicio()
                    } label: {
                        Label("Início", systemImage: "house")
                    }
                }

                Section("Favoritos") {
                    let favoritos = store.favoritosOrdenados
                    if favoritos.isEmpty {
                        Text("Toque no marcador de uma publicação para guardá-la aqui.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(favoritos) { producao in
                        Button {
                            router.detalhePendente = producao.id
                            fechar()
                        } label: {
                            Label(producao.titulo, systemImage: producao.tipo.simbolo)
                                .lineLimit(2)
                        }
                    }
                }

                Section("Dados") {
                    NavigationLink {
                        ServidorView()
                    } label: {
                        LabeledContent {
                            Text(store.servidor?.host() ?? "Só neste aparelho")
                                .lineLimit(1)
                        } label: {
                            Label("Servidor Node-RED", systemImage: "server.rack")
                        }
                    }
                    if !store.usaServidor {
                        Button("Restaurar dados de exemplo", role: .destructive) {
                            confirmarRestauracao = true
                        }
                    }
                }

                Section("Sobre") {
                    LabeledContent("Versão", value: versao)
                    Text(textoSobre)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(UFSM.azulSecundario)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { fechar() }
                }
            }
            .confirmationDialog(
                "Apagar as publicações deste aparelho e restaurar os exemplos?",
                isPresented: $confirmarRestauracao,
                titleVisibility: .visible
            ) {
                Button("Restaurar exemplos", role: .destructive) {
                    store.restaurarExemplos()
                    router.voltarAoInicio()
                }
            }
        }
    }

    private var textoSobre: String {
        let origem = store.usaServidor
            ? "As publicações e avaliações ficam no servidor Node-RED; os favoritos, só neste aparelho."
            : "Os dados ficam somente neste aparelho. Para compartilhar com a turma, configure o servidor Node-RED."
        return "Repositório acadêmico do CTISM/UFSM, desenvolvido no HackaTruck MakerSpace. " + origem
    }

    private func ir(para rota: Rota) {
        fechar()
        router.caminho = [rota]
    }
}

/// Perfil (nome e curso), usado como autoria no cadastro. Com o Node-RED, vira um registro
/// da tabela users. No futuro será preenchido pelo login da UFSM/CTISM.
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
    MenuView()
        .environment(ProducaoStore.previa)
        .environment(Router())
        .environment(BuscaModel())
}
