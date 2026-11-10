import SwiftUI

/// Tela 3 — Visualização, apresentada como sheet por cima da busca.
/// Abre em 80% da altura (a busca continua visível por trás) e pode ser arrastada até a tela cheia.
struct DetalheView: View {
    let producaoID: UUID
    @Environment(ProducaoStore.self) private var store
    @State private var detente: PresentationDetent = .fraction(0.8)

    var body: some View {
        Group {
            if let producao = store.producao(id: producaoID) {
                ConteudoDetalhe(producao: producao)
            } else {
                ContentUnavailableView(
                    "Publicação não encontrada",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Ela pode ter sido removida.")
                )
            }
        }
        .presentationDetents([.fraction(0.8), .large], selection: $detente)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
        .presentationBackground(UFSM.fundo)
    }
}

private struct ConteudoDetalhe: View {
    let producao: Producao
    @Environment(ProducaoStore.self) private var store
    @Environment(\.openURL) private var abrirURL
    @Environment(\.dismiss) private var fechar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Chip(texto: producao.tipo.nome, estilo: .tipo)
                    Chip(texto: String(producao.ano), icone: "calendar")
                    Spacer(minLength: 8)
                    Button {
                        store.alternarFavorito(producao)
                    } label: {
                        IconeCircular(simbolo: store.ehFavorito(producao) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(rotuloFavorito)

                    ShareLink(item: textoParaCompartilhar) {
                        IconeCircular(simbolo: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Compartilhar")

                    Button {
                        fechar()
                    } label: {
                        IconeCircular(simbolo: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fechar")
                }

                Text(producao.titulo)
                    .font(Tipografia.fonte(21, .medium, relativoA: .title2))
                    .foregroundStyle(UFSM.azul)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)

                Text("\(CursoCTISM.curto(producao.curso)) · \(producao.instituicao)")
                    .font(Tipografia.fonte(12, relativoA: .caption))
                    .foregroundStyle(UFSM.texto3)
                    .padding(.top, 4)

                CapaView(url: producao.imagemURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: Raio.card, style: .continuous))
                    .shadow(color: UFSM.azulProfundo.opacity(0.14), radius: 9, y: 6)
                    .padding(.top, 12)
                    .accessibilityLabel("Imagem da publicação")

                autoria
                    .padding(.top, 10)

                SecaoTitulo("Resumo")
                    .padding(.top, 14)
                Text(producao.descricao)
                    .font(Tipografia.fonte(14.5, relativoA: .body))
                    .foregroundStyle(UFSM.texto)
                    .lineSpacing(3)
                    .padding(.top, 8)

                SecaoTitulo("Avaliações")
                    .padding(.top, 14)
                CartaoAvaliacao(producao: producao)
                    .padding(.top, 10)

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 9) {
                        SecaoTitulo("Área")
                        Chip(texto: producao.area.nome, icone: "tag.fill", estilo: .destaque)
                    }
                    VStack(alignment: .leading, spacing: 9) {
                        SecaoTitulo("Matéria")
                        Chip(texto: producao.materia, icone: "book.closed.fill")
                    }
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 28)
        }
    }

    private var autoria: some View {
        HStack(spacing: 10) {
            Label(producao.autoresFormatados, systemImage: "person.crop.circle")
                .font(Tipografia.fonte(12.5, relativoA: .footnote))
                .foregroundStyle(UFSM.texto2)
                .lineLimit(2)
            Spacer(minLength: 8)
            if let link = producao.link {
                Button {
                    abrirURL(link)
                } label: {
                    Label(producao.plataforma.nome, systemImage: "arrow.up.right.square")
                        .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
                        .foregroundStyle(UFSM.info)
                }
                .accessibilityHint("Abre a publicação original")
            }
        }
    }

    private var rotuloFavorito: String {
        store.ehFavorito(producao) ? "Remover dos favoritos" : "Salvar nos favoritos"
    }

    private var textoParaCompartilhar: String {
        var texto = "\(producao.titulo) — \(producao.descricao)"
        if let link = producao.link {
            texto += "\n\(link.absoluteString)"
        }
        return texto + "\n\nCompartilhado pelo CTIA · CTISM/UFSM"
    }
}

/// Botão redondo do topo da sheet (favoritar, compartilhar, fechar).
private struct IconeCircular: View {
    let simbolo: String

    var body: some View {
        Image(systemName: simbolo)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(UFSM.azulSecundario)
            .frame(width: 32, height: 32)
            .background(UFSM.tinta, in: Circle())
    }
}

/// Média, total de avaliações e as estrelas para o(a) estudante dar a sua nota.
struct CartaoAvaliacao: View {
    let producao: Producao
    @Environment(ProducaoStore.self) private var store
    /// Mensagem quando a nota não chega ao servidor.
    @State private var erro: String?

    var body: some View {
        let media = store.media(producao)
        let total = store.totalAvaliacoes(producao)
        let minha = store.minhaNota(producao) ?? 0
        let totalTexto: String = total == 1 ? "1 avaliação" : "\(total) avaliações"
        let titulo: String = minha == 0 ? producao.tipo.conviteAvaliacao : "Sua nota: \(minha) de 5"
        let dica: String = minha == 0 ? "Toque para dar sua nota" : "Obrigado! Toque para alterar"

        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(media.notaFormatada)
                    .font(Tipografia.fonte(31, .bold, relativoA: .largeTitle))
                    .foregroundStyle(UFSM.azul)
                Estrelas(nota: media, tamanho: 14)
                Text(totalTexto)
                    .font(Tipografia.fonte(11, relativoA: .caption2))
                    .foregroundStyle(UFSM.texto3)
            }
            .frame(minWidth: 96, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(titulo)
                    .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
                    .foregroundStyle(UFSM.azul)
                HStack(spacing: 7) {
                    ForEach(1...5, id: \.self) { nota in
                        let rotuloEstrela: String = nota == 1 ? "1 estrela" : "\(nota) estrelas"
                        Button {
                            erro = nil
                            Task {
                                erro = await store.avaliar(producao, nota: nota)
                            }
                        } label: {
                            Image(systemName: nota <= minha ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundStyle(nota <= minha ? UFSM.ambar : Color(hex: 0xB9C1D1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(rotuloEstrela)
                    }
                }
                Text(erro ?? dica)
                    .font(Tipografia.fonte(10.5, relativoA: .caption2))
                    .foregroundStyle(erro == nil ? UFSM.texto3 : UFSM.perigo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .cartao()
    }
}

#Preview {
    let store = ProducaoStore.previa
    return Color.gray
        .sheet(isPresented: .constant(true)) {
            DetalheView(producaoID: store.producoes[0].id)
        }
        .environment(store)
}
