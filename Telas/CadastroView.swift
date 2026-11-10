import SwiftUI

/// Tela 4 — Cadastro de projeto, trabalho acadêmico ou prova.
struct CadastroView: View {
    @Environment(ProducaoStore.self) private var store
    @Environment(Router.self) private var router
    @AppStorage("perfil.nome") private var nomePerfil = ""
    @AppStorage("perfil.curso") private var cursoPerfil = ""

    @State private var formulario: FormularioCadastro
    @State private var rascunhoRecuperado: Bool
    @State private var mostrarErros = false
    @State private var mostrarPerfil = false
    @State private var avisoRascunhoSalvo = false
    @State private var publicando = false
    @State private var erroPublicacao: String?
    @FocusState private var foco: CampoCadastro?

    init(tipoInicial: TipoProducao) {
        if let rascunho = RascunhoStore.carregar() {
            _formulario = State(initialValue: rascunho)
            _rascunhoRecuperado = State(initialValue: true)
        } else {
            _formulario = State(initialValue: FormularioCadastro(tipo: tipoInicial))
            _rascunhoRecuperado = State(initialValue: false)
        }
    }

    private var erros: [CampoCadastro: String] {
        mostrarErros ? formulario.erros : [:]
    }

    private var perfilCompleto: Bool {
        !nomePerfil.aparado.isEmpty && !cursoPerfil.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if rascunhoRecuperado {
                    avisoRascunhoRecuperado
                }

                SeletorTipo(selecao: $formulario.tipo)
                    .padding(.bottom, 4)

                if formulario.tipo == .prova {
                    Aviso(texto: "Publique provas somente com a autorização do(a) professor(a) da disciplina.")
                }

                campoTitulo
                campoDescricao
                campoImagem
                campoLink
                campoArea
                campoMateria
                HStack(alignment: .top, spacing: 8) {
                    campoInstituicao
                    campoAno
                        .frame(width: 112)
                }
                linhaAutoria
                    .padding(.top, 6)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(UFSM.fundo)
        .barraDePagina(formulario.tipo.tituloCadastro)
        .safeAreaInset(edge: .bottom) {
            barraDeAcoes
        }
        .overlay(alignment: .bottom) {
            if avisoRascunhoSalvo {
                avisoSalvo
            }
        }
        .sheet(isPresented: $mostrarPerfil) {
            NavigationStack {
                PerfilView()
            }
            .environment(store)
        }
        .alert("Não foi possível publicar", isPresented: mostrandoErro) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(erroPublicacao ?? "")
        }
    }

    private var mostrandoErro: Binding<Bool> {
        Binding(
            get: { erroPublicacao != nil },
            set: { if !$0 { erroPublicacao = nil } }
        )
    }

    // MARK: - Campos

    private var campoTitulo: some View {
        CampoRotulado(rotulo: "Título", obrigatorio: true, emFoco: foco == .titulo, erro: erros[.titulo]) {
            TextField("Ex.: Monitor IoT de ruído nas oficinas", text: $formulario.titulo)
                .focused($foco, equals: .titulo)
                .submitLabel(.next)
                .onSubmit { foco = .descricao }
        }
    }

    private var campoDescricao: some View {
        let contador = "\(formulario.descricao.count)/\(Producao.limiteDescricao)"

        return CampoRotulado(
            rotulo: "Descrição — breve resumo (até \(Producao.limiteDescricao) caracteres)",
            obrigatorio: true,
            emFoco: foco == .descricao,
            erro: erros[.descricao]
        ) {
            VStack(alignment: .trailing, spacing: 2) {
                TextField("Conte em poucas linhas o que foi feito e o resultado.", text: $formulario.descricao, axis: .vertical)
                    .font(Tipografia.fonte(13.5, relativoA: .body))
                    .lineLimit(3...6)
                    .focused($foco, equals: .descricao)
                    .onChange(of: formulario.descricao) { _, novo in
                        if novo.count > Producao.limiteDescricao {
                            formulario.descricao = String(novo.prefix(Producao.limiteDescricao))
                        }
                    }
                Text(contador)
                    .font(Tipografia.fonte(11, relativoA: .caption2))
                    .monospacedDigit()
                    .foregroundStyle(formulario.descricao.aparado.count >= 20 ? UFSM.sucesso : UFSM.texto3)
            }
        }
    }

    private var campoImagem: some View {
        CampoRotulado(rotulo: "Imagem da descrição (URL)", emFoco: foco == .imagem, erro: erros[.imagem]) {
            HStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 13))
                    .foregroundStyle(UFSM.texto3)
                TextField("https://…/imagem.jpg", text: $formulario.imagemURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($foco, equals: .imagem)
                if let url = URL.web(formulario.imagemURL) {
                    CapaView(url: url)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous))
                        .accessibilityLabel("Prévia da imagem")
                }
            }
        }
    }

    private var campoLink: some View {
        CampoRotulado(rotulo: "Link onde foi publicado", emFoco: foco == .link, erro: erros[.link]) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Plataforma", selection: $formulario.plataforma) {
                        ForEach(Plataforma.allCases) { plataforma in
                            Text(plataforma.nome).tag(plataforma)
                        }
                    }
                } label: {
                    Pilula(texto: formulario.plataforma.nome)
                }
                .accessibilityLabel("Plataforma: \(formulario.plataforma.nome)")

                TextField("linkedin.com/posts/…", text: $formulario.link)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($foco, equals: .link)
                    .onChange(of: formulario.link) { _, novo in
                        if let detectada = Plataforma.detectar(em: URL.web(novo)) {
                            formulario.plataforma = detectada
                        }
                    }
            }
        }
    }

    private var campoArea: some View {
        CampoRotulado(rotulo: "Área", obrigatorio: true, erro: erros[.area]) {
            Menu {
                Picker("Área", selection: $formulario.area) {
                    Text("Selecione a área").tag(AreaConhecimento?.none)
                    ForEach(AreaConhecimento.allCases) { area in
                        Text(area.nome).tag(Optional(area))
                    }
                }
            } label: {
                LinhaSelecao(
                    texto: formulario.area?.nome ?? "Selecione a área do conhecimento",
                    vazio: formulario.area == nil
                )
            }
        }
    }

    private var campoMateria: some View {
        CampoRotulado(rotulo: "Matéria", obrigatorio: true, emFoco: foco == .materia, erro: erros[.materia]) {
            HStack(spacing: 8) {
                TextField("Ex.: Higiene Ocupacional", text: $formulario.materia)
                    .focused($foco, equals: .materia)
                    .submitLabel(.done)
                if !store.materiasConhecidas.isEmpty {
                    Menu {
                        ForEach(store.materiasConhecidas, id: \.self) { materia in
                            Button(materia) {
                                formulario.materia = materia
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(UFSM.texto3)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Escolher uma matéria já cadastrada")
                }
            }
        }
    }

    private var campoInstituicao: some View {
        CampoRotulado(rotulo: "Instituição", obrigatorio: true, emFoco: foco == .instituicao, erro: erros[.instituicao]) {
            TextField("Instituição", text: $formulario.instituicao)
                .focused($foco, equals: .instituicao)
        }
    }

    private var campoAno: some View {
        CampoRotulado(rotulo: "Ano", obrigatorio: true) {
            Menu {
                Picker("Ano", selection: $formulario.ano) {
                    ForEach(FormularioCadastro.anosPermitidos, id: \.self) { ano in
                        Text(String(ano)).tag(ano)
                    }
                }
            } label: {
                LinhaSelecao(texto: String(formulario.ano))
            }
        }
    }

    // MARK: - Autoria, avisos e ações

    private var linhaAutoria: some View {
        let titulo: String = perfilCompleto ? "Publicando como \(nomePerfil.aparado)" : "Complete seu perfil para publicar"
        let subtitulo: String = perfilCompleto ? CursoCTISM.curto(cursoPerfil) : "Seu nome e curso aparecem como autoria"
        let acao: String = perfilCompleto ? "Alterar" : "Completar"

        return Button {
            mostrarPerfil = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(UFSM.azulSecundario)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo)
                        .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
                        .foregroundStyle(UFSM.azul)
                    Text(subtitulo)
                        .font(Tipografia.fonte(11.5, relativoA: .caption))
                        .foregroundStyle(UFSM.texto3)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Text(acao)
                    .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
                    .foregroundStyle(UFSM.azulSecundario)
            }
            .padding(12)
            .cartao(raio: Raio.campo)
        }
        .buttonStyle(.plain)
    }

    private var avisoRascunhoRecuperado: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(UFSM.dourado)
            Text("Rascunho recuperado")
                .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
                .foregroundStyle(UFSM.avisoTexto)
            Spacer()
            Button("Descartar") {
                RascunhoStore.apagar()
                formulario = FormularioCadastro(tipo: formulario.tipo)
                rascunhoRecuperado = false
                mostrarErros = false
            }
            .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
            .tint(UFSM.azulSecundario)
        }
        .padding(12)
        .background(UFSM.avisoFundo, in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous))
    }

    private var barraDeAcoes: some View {
        HStack(spacing: 10) {
            Button("Salvar rascunho", action: salvarRascunho)
                .buttonStyle(EstiloBotaoSecundario())
                .disabled(publicando)
            Button(action: publicar) {
                if publicando {
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel("Publicando")
                } else {
                    Label("Publicar", systemImage: "paperplane.fill")
                }
            }
            .buttonStyle(EstiloBotaoPrimario())
            .disabled(publicando)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            Color.white
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(UFSM.bordaSuave)
                        .frame(height: 1)
                }
        }
    }

    private var avisoSalvo: some View {
        Label("Rascunho salvo neste aparelho", systemImage: "checkmark.circle.fill")
            .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(UFSM.azulProfundo.opacity(0.92), in: Capsule())
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func salvarRascunho() {
        RascunhoStore.salvar(formulario)
        foco = nil
        withAnimation(.snappy) { avisoRascunhoSalvo = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.snappy) { avisoRascunhoSalvo = false }
        }
    }

    private func publicar() {
        mostrarErros = true
        if let campo = formulario.primeiroCampoComErro {
            foco = campo.focavel ? campo : nil
            return
        }
        guard perfilCompleto else {
            mostrarPerfil = true
            return
        }
        guard let area = formulario.area, !publicando else { return }

        let nova = Producao(
            tipo: formulario.tipo,
            titulo: formulario.titulo.aparado,
            descricao: formulario.descricao.aparado,
            imagemURL: URL.web(formulario.imagemURL),
            link: URL.web(formulario.link),
            plataforma: formulario.plataforma,
            area: area,
            materia: formulario.materia.aparado,
            curso: cursoPerfil,
            instituicao: formulario.instituicao.aparado,
            ano: formulario.ano,
            autores: [nomePerfil.aparado]
        )
        foco = nil
        publicando = true
        Task {
            do {
                // No modo local grava no aparelho; com o Node-RED, envia e usa o id criado pelo servidor.
                let id = try await store.publicar(nova)
                RascunhoStore.apagar()
                router.concluirPublicacao(id)
            } catch is CancellationError {
                // A tela foi fechada antes da resposta.
            } catch {
                erroPublicacao = error.localizedDescription
            }
            publicando = false
        }
    }
}

/// Seletor Projeto / Trabalho / Prova, no estilo de controle segmentado.
struct SeletorTipo: View {
    @Binding var selecao: TipoProducao
    @Namespace private var animacao

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TipoProducao.cadastraveis) { tipo in
                let selecionado = tipo == selecao
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selecao = tipo
                    }
                } label: {
                    Label(tipo.nomeCurto, systemImage: tipo.simbolo)
                        .font(Tipografia.fonte(13.5, selecionado ? .medium : .regular, relativoA: .subheadline))
                        .foregroundStyle(selecionado ? UFSM.azul : UFSM.texto2)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background {
                            if selecionado {
                                RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: UFSM.azulProfundo.opacity(0.16), radius: 1.5, y: 1)
                                    .matchedGeometryEffect(id: "selecao", in: animacao)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selecionado ? .isSelected : [])
            }
        }
        .padding(3)
        .background(UFSM.trilho, in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CadastroView(tipoInicial: .projeto)
    }
    .environment(ProducaoStore.previa)
    .environment(Router())
}
