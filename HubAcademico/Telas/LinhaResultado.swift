import SwiftUI

/// Cartão de uma publicação nas listas e nos resultados da busca.
struct LinhaResultado: View {
    let publicacao: Publicacao
    @Environment(PublicacaoStore.self) private var store

    var body: some View {
        let media = store.media(publicacao)
        let legenda = "(\(store.totalAvaliacoes(publicacao))) · \(String(publicacao.ano))"

        HStack(alignment: .top, spacing: 12) {
            ImagemView(link: publicacao.imagemLink)
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: Raio.campo, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Chip(texto: publicacao.tipo.nome, estilo: .tipo)
                Text(publicacao.titulo)
                    .font(Tipografia.fonte(14, .medium, relativoA: .subheadline))
                    .foregroundStyle(UFSM.azul)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    Estrelas(media: media, tamanho: 11, espaco: 1)
                    Text(media.mediaFormatada)
                        .font(Tipografia.fonte(11.5, .medium, relativoA: .caption))
                        .foregroundStyle(UFSM.texto)
                    Text(legenda)
                        .font(Tipografia.fonte(11.5, relativoA: .caption))
                        .foregroundStyle(UFSM.texto3)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .cartao()
        .contentShape(RoundedRectangle(cornerRadius: Raio.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
