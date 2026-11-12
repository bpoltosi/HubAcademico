import SwiftUI

/// Tela 4 — Publicar projeto, trabalho acadêmico ou prova.
///
/// Classificação em cascata: escolhida a área, as subáreas dela abrem logo abaixo, no próprio
/// campo Subárea; escolhida a subárea, a lista de disciplinas passa a mostrar só as dela
/// (currículos da UFSM, veja `CatalogoDisciplinas`).
struct PublicarView: View {
    @Environment(PublicacaoStore.self) private var store
    @Environment(Router.self) private var router
    @AppStorage("usuario.nome") private var nomeUsuario = ""
    @AppStorage("usuario.curso") private var cursoUsuario = ""

    @State private var formulario: FormularioPublicacao
    @State private var rascunhoRecuperado: Bool
    @State private var mostrarErros = false
    @State private var mostrarPerfil = false
    /// Lista de subáreas aberta de novo pelo botão "Trocar".
    @State private var trocandoSubarea = false
    @State private var mostrarDisciplinas = false
    /// Campo para onde a tela rola ao tentar publicar com erro.
    @State private var rolarPara: CampoPublicacao?
    @State private var avisoRascunhoSalvo = false
    @State private var publicando = false
    @State private var erroPublicacao: String?
    @FocusState private var foco: CampoPublicacao?

    init(tipoInicial: TipoPublicacao) {
        if let rascunho = RascunhoStore.carregar() {
            _formulario = State(initialValue: rascunho)
            _rascunhoRecuperado = State(initialValue: true)
        } else {
            _formulario = State(initialValue: FormularioPublicacao(tipo: tipoInicial))
            _rascunhoRecuperado = State(initialValue: false)
        }
    }

    private var erros: [CampoPublicacao: String] {
        mostrarErros ? formulario.erros : [:]
    }

    private var perfilCompleto: Bool {
        !nomeUsuario.aparado.isEmpty && !cursoUsuario.isEmpty
    }

    var body: some View {
        ScrollViewReader { leitor in
            formularioRolavel
                .onChange(of: rolarPara) { _, campo in
                    guard let campo else { return }
                    withAnimation(.snappy) {
                        leitor.scrollTo(campo, anchor: .center)
                    }
                    rolarPara = nil
                }
        }
        .sheet(isPresented: $mostrarPerfil) {
            NavigationStack {
                PerfilView()
            }
            .environment(store)
        }
        .sheet(isPresented: $mostrarDisciplinas) {
            SeletorDisciplinaView(
                formulario: $formulario,
                usadasNoHub: formulario.subarea.map { store.disciplinasUsadas(na: $0) } ?? []
            )
        }
        .alert("Não foi possível publicar", isPresented: mostrandoErro) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(erroPublicacao ?? "")
        }
        .task {
            // Lê a lista de disciplinas em segundo plano enquanto o formulário é preenchido.
            await Task.detached(priority: .utility) {
                _ = CatalogoDisciplinas.ufsm.fonte
            }.value
        }
    }

    private var formularioRolavel: some View {
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
                    .id(CampoPublicacao.titulo)
                campoDescricao
                    .id(CampoPublicacao.descricao)
                campoImagem
                    .id(CampoPublicacao.imagem)
                campoLink
                    .id(CampoPublicacao.link)
                campoArea
                    .id(CampoPublicacao.area)
                campoSubarea
                    .id(CampoPublicacao.subarea)
                campoDisciplina
                    .id(CampoPublicacao.disciplina)
                HStack(alignment: .top, spacing: 8) {
                    campoInstituicao
                    campoAno
                        .frame(width: 112)
                }
                .id(CampoPublicacao.instituicao)
                linhaAutoria
                    .padding(.top, 6)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(UFSM.fundo)
        .barraDePagina(formulario.tipo.tituloPublicar)
        .safeAreaInset(edge: .bottom) {
            barraDeAcoes
        }
        .overlay(alignment: .bottom) {
            if avisoRascunhoSalvo {
                avisoSalvo
            }
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
        let contador = "\(formulario.descricao.count)/\(Publicacao.limiteDescricao)"

        return CampoRotulado(
            rotulo: "Descrição (até \(Publicacao.limiteDescricao) caracteres)",
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
                        if novo.count > Publicacao.limiteDescricao {
                            formulario.descricao = String(novo.prefix(Publicacao.limiteDescricao))
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
        CampoRotulado(rotulo: "Link da imagem", emFoco: foco == .imagem, erro: erros[.imagem]) {
            HStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 13))
                    .foregroundStyle(UFSM.texto3)
                TextField("https://…/imagem.jpg", text: $formulario.imagemLink)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($foco, equals: .imagem)
                if let link = URL.web(formulario.imagemLink) {
                    ImagemView(link: link)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous))
                        .accessibilityLabel("Prévia da imagem")
                }
            }
        }
    }

    private var campoLink: some View {
        CampoRotulado(rotulo: "Link da publicação", emFoco: foco == .link, erro: erros[.link]) {
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

    // MARK: Área → subárea → disciplina

    private var campoArea: some View {
        // Trocar a área limpa a subárea e a disciplina (veja `FormularioPublicacao.escolherArea`).
        let selecao = Binding<AreaConhecimento?>(
            get: { formulario.area },
            set: { nova in
                withAnimation(.snappy) {
                    formulario.escolherArea(nova)
                    trocandoSubarea = false
                }
            }
        )

        return CampoRotulado(rotulo: "Área", obrigatorio: true, erro: erros[.area]) {
            Menu {
                Picker("Área", selection: selecao) {
                    Text("Selecione a área").tag(AreaConhecimento?.none)
                    ForEach(AreaConhecimento.naOrdemDoCNPq) { area in
                        Text(area.nomeCompleto).tag(Optional(area))
                    }
                }
            } label: {
                LinhaSelecao(
                    texto: formulario.area?.nomeCompleto ?? "Selecione a área do conhecimento",
                    vazio: formulario.area == nil
                )
            }
        }
    }

    /// Escolhida a área, as subáreas dela abrem aqui mesmo, abaixo; escolhida a subárea, a lista
    /// fecha e mostra só a escolhida, com "Trocar" para abrir de novo.
    private var campoSubarea: some View {
        let listaAberta = formulario.area != nil && (formulario.subarea == nil || trocandoSubarea)

        return CampoRotulado(rotulo: "Subárea", obrigatorio: true, erro: erros[.subarea]) {
            if let area = formulario.area, listaAberta {
                ListaSubareas(area: area, selecionada: formulario.subarea) { escolhida in
                    withAnimation(.snappy) {
                        formulario.escolherSubarea(escolhida)
                        trocandoSubarea = false
                    }
                }
                .transition(.opacity)
            } else if let subarea = formulario.subarea {
                Button {
                    withAnimation(.snappy) { trocandoSubarea = true }
                } label: {
                    HStack(spacing: 8) {
                        Text(Subarea.legivel(subarea))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 6)
                        Text("Trocar")
                            .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
                            .foregroundStyle(UFSM.azulSecundario)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Subárea: \(Subarea.legivel(subarea))")
                .accessibilityHint("Toque para trocar a subárea")
            } else {
                Text("Escolha a área primeiro")
                    .foregroundStyle(UFSM.dica)
            }
        }
    }

    /// Abre a lista de disciplinas da subárea escolhida (sheet com busca).
    private var campoDisciplina: some View {
        let subarea = formulario.subarea
        let quantidade = subarea.map { CatalogoDisciplinas.ufsm.disciplinas(da: $0).count } ?? 0
        let vazio = formulario.disciplina.aparado.isEmpty
        let texto: String = if !vazio {
            formulario.disciplina
        } else if subarea == nil {
            "Escolha a subárea primeiro"
        } else if quantidade > 0 {
            "Selecione entre \(quantidade) disciplinas da subárea"
        } else {
            "Digite o nome da disciplina"
        }

        return CampoRotulado(rotulo: "Disciplina", obrigatorio: true, erro: erros[.disciplina]) {
            Button {
                foco = nil
                mostrarDisciplinas = true
            } label: {
                HStack(spacing: 8) {
                    Text(texto)
                        .foregroundStyle(vazio ? UFSM.dica : UFSM.texto)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 6)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(UFSM.texto3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(subarea == nil)
            .accessibilityLabel("Disciplina: \(texto)")
            .accessibilityHint("Abre a lista de disciplinas da subárea")
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
                    ForEach(FormularioPublicacao.anosPermitidos, id: \.self) { ano in
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
        let titulo: String = perfilCompleto ? "Publicando como \(nomeUsuario.aparado)" : "Complete seu perfil para publicar"
        let subtitulo: String = perfilCompleto ? CursoCTISM.curto(cursoUsuario) : "Seu nome e curso aparecem como autoria"
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
                formulario = FormularioPublicacao(tipo: formulario.tipo)
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
            rolarPara = campo
            return
        }
        guard perfilCompleto else {
            mostrarPerfil = true
            return
        }
        guard let area = formulario.area, !publicando else { return }

        let nova = Publicacao(
            tipo: formulario.tipo,
            titulo: formulario.titulo.aparado,
            descricao: formulario.descricao.aparado,
            imagemLink: URL.web(formulario.imagemLink),
            link: URL.web(formulario.link),
            plataforma: formulario.plataforma,
            area: area,
            subarea: formulario.subarea,
            disciplina: formulario.disciplina.aparado,
            curso: cursoUsuario,
            instituicao: formulario.instituicao.aparado,
            ano: formulario.ano,
            autores: [nomeUsuario.aparado]
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
    @Binding var selecao: TipoPublicacao
    @Namespace private var animacao

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TipoPublicacao.publicaveis) { tipo in
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
        PublicarView(tipoInicial: .projeto)
    }
    .environment(PublicacaoStore.previa)
    .environment(Router())
}
