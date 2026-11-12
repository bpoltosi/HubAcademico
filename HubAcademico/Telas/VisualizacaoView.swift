import SwiftUI

/// Tela 3 — Visualização, apresentada como sheet por cima da busca.
/// Abre em 80% da altura (a busca continua visível por trás) e pode ser arrastada até a tela cheia.
struct VisualizacaoView: View {
    let publicacaoID: UUID
    @Environment(PublicacaoStore.self) private var store
    @State private var detente: PresentationDetent = .fraction(0.8)

    var body: some View {
        Group {
            if let publicacao = store.publicacao(id: publicacaoID) {
                ConteudoVisualizacao(publicacao: publicacao)
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

private struct ConteudoVisualizacao: View {
    let publicacao: Publicacao
    @Environment(PublicacaoStore.self) private var store
    @Environment(\.openURL) private var abrirURL
    @Environment(\.dismiss) private var fechar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Chip(texto: publicacao.tipo.nome, estilo: .tipo)
                    Chip(texto: String(publicacao.ano), icone: "calendar")
                    Spacer(minLength: 8)
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

                Text(publicacao.titulo)
                    .font(Tipografia.fonte(21, .medium, relativoA: .title2))
                    .foregroundStyle(UFSM.azul)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)

                Text("\(CursoCTISM.curto(publicacao.curso)) · \(publicacao.instituicao)")
                    .font(Tipografia.fonte(12, relativoA: .caption))
                    .foregroundStyle(UFSM.texto3)
                    .padding(.top, 4)

                ImagemView(link: publicacao.imagemLink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: Raio.card, style: .continuous))
                    .shadow(color: UFSM.azulProfundo.opacity(0.14), radius: 9, y: 6)
                    .padding(.top, 12)
                    .accessibilityLabel("Imagem da publicação")

                autoria
                    .padding(.top, 10)

                SecaoTitulo("Descrição")
                    .padding(.top, 14)
                Text(publicacao.descricao)
                    .font(Tipografia.fonte(14.5, relativoA: .body))
                    .foregroundStyle(UFSM.texto)
                    .lineSpacing(3)
                    .padding(.top, 8)

                SecaoTitulo("Avaliações")
                    .padding(.top, 14)
                CartaoAvaliacao(publicacao: publicacao)
                    .padding(.top, 10)

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 9) {
                        SecaoTitulo("Área")
                        Chip(texto: publicacao.area.nome, icone: "tag.fill", estilo: .destaque)
                    }
                    if let subarea = publicacao.subarea {
                        VStack(alignment: .leading, spacing: 9) {
                            SecaoTitulo("Subárea")
                            Chip(texto: Subarea.legivel(subarea), icone: "square.stack.fill", estilo: .destaque)
                        }
                    }
                }
                .padding(.top, 14)

                VStack(alignment: .leading, spacing: 9) {
                    SecaoTitulo("Disciplina")
                    Chip(texto: publicacao.disciplina, icone: "book.closed.fill")
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
            Label(publicacao.autoresFormatados, systemImage: "person.crop.circle")
                .font(Tipografia.fonte(12.5, relativoA: .footnote))
                .foregroundStyle(UFSM.texto2)
                .lineLimit(2)
            Spacer(minLength: 8)
            if let link = publicacao.link {
                Button {
                    abrirURL(link)
                } label: {
                    Label(publicacao.plataforma.nome, systemImage: "arrow.up.right.square")
                        .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
                        .foregroundStyle(UFSM.info)
                }
                .accessibilityHint("Abre a publicação original")
            }
        }
    }

    private var textoParaCompartilhar: String {
        var texto = "\(publicacao.titulo) — \(publicacao.descricao)"
        if let link = publicacao.link {
            texto += "\n\(link.absoluteString)"
        }
        return texto + "\n\nCompartilhado pelo Hub Acadêmico · CTISM/UFSM"
    }
}

/// Botão redondo do topo da sheet (compartilhar, fechar).
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
    let publicacao: Publicacao
    @Environment(PublicacaoStore.self) private var store
    /// Mensagem quando a nota não chega ao servidor.
    @State private var erro: String?

    var body: some View {
        let media = store.media(publicacao)
        let total = store.totalAvaliacoes(publicacao)
        let minha = store.minhaNota(publicacao) ?? 0
        let totalTexto: String = total == 1 ? "1 avaliação" : "\(total) avaliações"
        let titulo: String = minha == 0 ? publicacao.tipo.conviteAvaliacao : "Sua nota: \(minha) de 5"
        let dica: String = minha == 0 ? "Toque para dar sua nota" : "Obrigado! Toque para alterar"

        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(media.mediaFormatada)
                    .font(Tipografia.fonte(31, .bold, relativoA: .largeTitle))
                    .foregroundStyle(UFSM.azul)
                Estrelas(media: media, tamanho: 14)
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
                                erro = await store.avaliar(publicacao, nota: nota)
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
    let store = PublicacaoStore.previa
    return Color.gray
        .sheet(isPresented: .constant(true)) {
            VisualizacaoView(publicacaoID: store.publicacoes[0].id)
        }
        .environment(store)
}
