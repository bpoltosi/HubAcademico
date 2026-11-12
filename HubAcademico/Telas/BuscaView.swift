import SwiftUI

/// Tela 2 — Busca. O texto é digitado no cabeçalho; o funil abre o painel de filtros.
/// Também é a lista de Projetos, Trabalhos, Provas e Materiais quando se entra por um atalho do Início.
/// Tocar em um resultado abre a Tela 3 como sheet por cima desta tela.
struct BuscaView: View {
    @Environment(PublicacaoStore.self) private var store
    @Environment(BuscaModel.self) private var busca
    @Environment(Router.self) private var router

    var body: some View {
        let resultados = store.buscar(
            texto: busca.texto,
            tipo: busca.tipo,
            filtros: busca.filtros
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if busca.mostrarFiltros {
                    PainelFiltros()
                        .padding(.horizontal, 16)
                        .padding(.top, 13)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let aviso = store.avisoConfiguracao {
                    Aviso(texto: aviso, icone: "gearshape")
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if store.usaServidor, let erro = store.erroServidor {
                    Aviso(texto: erro + " Mostrando a última cópia salva; puxe a lista para tentar de novo.",
                          icone: "wifi.exclamationmark")
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if busca.tipo == .prova {
                    Aviso(texto: "Provas compartilhadas com autorização dos(as) professores(as). Use para estudar.")
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                cabecalhoResultados(quantidade: resultados.count)

                LazyVStack(spacing: 8) {
                    ForEach(resultados) { publicacao in
                        Button {
                            router.abrirVisualizacao(publicacao.id)
                        } label: {
                            LinhaResultado(publicacao: publicacao)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if resultados.isEmpty, store.sincronizando, store.publicacoes.isEmpty {
                    ProgressView("Carregando publicações…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if resultados.isEmpty {
                    EstadoVazio(
                        icone: busca.tipo?.simbolo ?? "magnifyingglass",
                        titulo: "Nada encontrado",
                        mensagem: "Tente outras palavras ou desmarque alguns filtros."
                    )
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            await store.sincronizar()
        }
        .scrollDismissesKeyboard(.immediately)
        .background(UFSM.fundo)
        .barraDePagina(busca.tipo?.tituloLista ?? "Busca")
        .toolbar {
            if let tipo = busca.tipo, TipoPublicacao.publicaveis.contains(tipo) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.abrir(.publicar(tipo))
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Publicar")
                }
            }
        }
    }

    private func cabecalhoResultados(quantidade: Int) -> some View {
        let total: String = quantidade == 1 ? "1 resultado" : "\(quantidade) resultados"
        let consulta = busca.texto.aparado
        let ordem: String
        if busca.filtros.estaAtivo(.melhorAvaliacao) {
            ordem = "Melhor avaliação"
        } else if consulta.isEmpty {
            ordem = "Mais recentes"
        } else {
            ordem = "Relevância"
        }

        return HStack(spacing: 6) {
            Text(total)
                .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
                .foregroundStyle(UFSM.azul)
            if let tipo = busca.tipo {
                Button {
                    withAnimation(.snappy) { busca.tipo = nil }
                } label: {
                    Chip(texto: tipo.tituloLista, icone: "xmark", estilo: .destaque)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mostrar todos os tipos")
            } else if !consulta.isEmpty {
                Text("para “\(consulta)”")
                    .font(Tipografia.fonte(13, relativoA: .footnote))
                    .foregroundStyle(UFSM.texto2)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Label(ordem, systemImage: "arrow.down")
                .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
                .foregroundStyle(UFSM.azulSecundario)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 9)
    }
}

#Preview {
    NavigationStack {
        BuscaView()
    }
    .environment(PublicacaoStore.previa)
    .environment(BuscaModel())
    .environment(Router())
}
