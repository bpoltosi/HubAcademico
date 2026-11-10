import SwiftUI

/// Menu › Servidor Node-RED: endereço, teste de conexão e atualização dos dados.
struct ServidorView: View {
    @Environment(ProducaoStore.self) private var store
    @State private var endereco = ""
    @State private var testando = false
    @State private var resultadoTeste: String?
    @State private var testeDeuCerto = false

    private var urlDigitada: URL? {
        ServidorConfig.normalizar(endereco)
    }

    private var campoVazio: Bool {
        endereco.aparado.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("http://192.168.0.10:1880", text: $endereco)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            } header: {
                Text("Endereço do Node-RED")
            } footer: {
                Text("No simulador, use http://localhost:1880. No iPhone, use o IP do computador que roda o Node-RED, na mesma rede Wi-Fi. Deixe em branco para usar só os dados deste aparelho.")
            }

            Section {
                Button {
                    Task { await testar() }
                } label: {
                    HStack {
                        Label("Testar conexão", systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                        if testando {
                            ProgressView()
                        }
                    }
                }
                .disabled(urlDigitada == nil || testando)

                if let resultadoTeste {
                    Label(resultadoTeste, systemImage: testeDeuCerto ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(testeDeuCerto ? UFSM.sucesso : UFSM.perigo)
                }

                Button {
                    Task { await store.configurarServidor(urlDigitada) }
                } label: {
                    Label(campoVazio ? "Usar só este aparelho" : "Salvar e atualizar",
                          systemImage: campoVazio ? "iphone" : "arrow.triangle.2.circlepath")
                }
                .disabled(!campoVazio && urlDigitada == nil)
            }

            Section("Situação") {
                LabeledContent("Dados", value: store.usaServidor ? "Servidor Node-RED" : "Só neste aparelho")
                if let servidor = store.servidor {
                    LabeledContent("Endereço", value: servidor.absoluteString)
                }
                if let data = store.ultimaSincronizacao {
                    LabeledContent("Atualizado em", value: data.formatted(date: .abbreviated, time: .shortened))
                }
                if store.sincronizando {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Atualizando…")
                            .foregroundStyle(.secondary)
                    }
                } else if store.usaServidor {
                    Button("Atualizar agora") {
                        Task { await store.sincronizar() }
                    }
                }
                if let erro = store.erroServidor {
                    Text(erro)
                        .font(.footnote)
                        .foregroundStyle(UFSM.perigo)
                }
            }
        }
        .tint(UFSM.azulSecundario)
        .navigationTitle("Servidor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            endereco = store.servidor?.absoluteString ?? ""
        }
        .onChange(of: endereco) {
            resultadoTeste = nil
        }
    }

    private func testar() async {
        guard let url = urlDigitada else { return }
        testando = true
        do {
            let status = try await APIClient(base: url).status()
            let total = status.totais?.projetos ?? 0
            testeDeuCerto = status.ok
            resultadoTeste = status.ok
                ? "Conectado! O servidor tem \(total) \(total == 1 ? "publicação" : "publicações")."
                : "O servidor respondeu, mas não está pronto."
        } catch {
            testeDeuCerto = false
            resultadoTeste = error.localizedDescription
        }
        testando = false
    }
}

#Preview {
    NavigationStack {
        ServidorView()
    }
    .environment(ProducaoStore.previa)
}
