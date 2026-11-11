import SwiftUI

/// Cabeçalho presente em todas as telas, como no site da UFSM:
/// brasão + nome do app na primeira linha; botão ☰ (volta ao Início), filtros e busca
/// na segunda; filete dourado na base.
struct CabecalhoInstitucional: View {
    @Environment(Router.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                SeloUFSM()
                Rectangle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 1, height: 34)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hub Acadêmico")
                        .font(Tipografia.fonteFixa(23, .medium))
                        .tracking(0.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Repositório acadêmico do CTISM")
                        .font(Tipografia.fonteFixa(11.5))
                        .opacity(0.84)
                }
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
            }
            .frame(height: 52)

            HStack(spacing: 10) {
                // O ☰ serve só para voltar à tela inicial, de qualquer ponto do app.
                BotaoCabecalho(simbolo: "line.3.horizontal", rotuloAcessivel: "Voltar ao início") {
                    router.voltarAoInicio()
                }
                if router.estaNaBusca {
                    BotaoFiltros()
                        .transition(.scale.combined(with: .opacity))
                }
                CampoBusca()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .background {
            UFSM.azul.ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(UFSM.dourado)
                .frame(height: 2)
        }
        .animation(.snappy, value: router.estaNaBusca)
    }
}

/// Brasão da UFSM com a sigla embaixo, como no cabeçalho do site.
struct SeloUFSM: View {
    var body: some View {
        VStack(spacing: 2) {
            Image("BrasaoUFSM")
                .resizable()
                .scaledToFit()
                .frame(height: 37)
            Text("UFSM")
                .font(Tipografia.fonteFixa(8.5, .medium))
                .tracking(1.4)
                .foregroundStyle(.white)
        }
        .frame(width: 34)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Brasão da UFSM")
    }
}

/// Botão quadrado do cabeçalho (☰ e filtros).
struct BotaoCabecalho: View {
    let simbolo: String
    let rotuloAcessivel: String
    var ativo = false
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ativo ? UFSM.azul : Color.white)
                .frame(width: 40, height: 40)
                .background(
                    ativo ? Color.white : Color.white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous)
                )
        }
        .accessibilityLabel(rotuloAcessivel)
    }
}

/// Botão do funil, visível na tela de busca, com a quantidade de filtros ativos.
struct BotaoFiltros: View {
    @Environment(BuscaModel.self) private var busca

    var body: some View {
        BotaoCabecalho(simbolo: "line.3.horizontal.decrease", rotuloAcessivel: "Filtros", ativo: busca.mostrarFiltros) {
            withAnimation(.snappy) {
                busca.mostrarFiltros.toggle()
            }
        }
        .overlay(alignment: .topTrailing) {
            if busca.filtros.quantidadeAtivos > 0 {
                Text(String(busca.filtros.quantidadeAtivos))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 19, minHeight: 19)
                    .background(UFSM.dourado, in: Capsule())
                    .overlay {
                        Capsule().stroke(UFSM.azul, lineWidth: 2)
                    }
                    .offset(x: 6, y: -6)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Campo de busca do cabeçalho. Fora da tela de busca funciona como atalho para ela;
/// dentro dela vira um campo de texto de verdade.
struct CampoBusca: View {
    @Environment(Router.self) private var router
    @Environment(BuscaModel.self) private var busca
    @FocusState private var focado: Bool

    var body: some View {
        @Bindable var busca = busca

        HStack(spacing: 8) {
            if router.estaNaBusca {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(UFSM.azulSecundario)
                TextField("O que você procura?", text: $busca.texto)
                    .font(Tipografia.fonteFixa(14.5))
                    .foregroundStyle(UFSM.texto)
                    .focused($focado)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onSubmit { focado = false }
                if !busca.texto.isEmpty {
                    Button {
                        busca.texto = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: 0xB4BCCB))
                    }
                    .accessibilityLabel("Limpar busca")
                }
            } else {
                Button {
                    busca.tipo = nil
                    router.abrirBusca()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                        Text("O que você procura?")
                            .font(Tipografia.fonteFixa(14))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(UFSM.texto3)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Buscar")
            }
            BotaoBuscaIA()
        }
        .padding(.leading, 14)
        .padding(.trailing, 5)
        .frame(height: 40)
        .background(Color.white, in: Capsule())
        .overlay {
            Capsule().stroke(UFSM.ambar.opacity(focado ? 0.6 : 0), lineWidth: 3)
        }
        .onChange(of: router.estaNaBusca) { _, naBusca in
            if naBusca, router.pedirFocoNaBusca {
                router.pedirFocoNaBusca = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    focado = true
                }
            } else if !naBusca {
                focado = false
            }
        }
    }
}

/// Liga/desliga a busca semântica (IA no próprio aparelho).
struct BotaoBuscaIA: View {
    @Environment(Router.self) private var router
    @Environment(BuscaModel.self) private var busca

    var body: some View {
        let rotulo: String = router.estaNaBusca ? "IA" : "Busca IA"
        let rotuloAcessivel: String = busca.usarIA ? "Desativar busca com IA" : "Ativar busca com IA"

        Button {
            if router.estaNaBusca {
                busca.usarIA.toggle()
            } else {
                busca.tipo = nil
                busca.usarIA = true
                router.abrirBusca()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 11, weight: .semibold))
                Text(rotulo)
            }
            .font(Tipografia.fonteFixa(11.5, .medium))
            .foregroundStyle(busca.usarIA ? Color.white : UFSM.azulSecundario)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(busca.usarIA ? UFSM.azulSecundario : UFSM.tinta, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rotuloAcessivel)
    }
}
