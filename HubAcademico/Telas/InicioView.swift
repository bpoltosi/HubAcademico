import SwiftUI

/// Para onde um atalho do Início leva.
enum DestinoAtalho {
    /// Abre a Tela 2 (Busca) já filtrada por um tipo.
    case listar(TipoPublicacao)
    /// Abre a Tela 4 (Publicar).
    case publicar(TipoPublicacao)
}

/// Atalho da tela inicial (equivale aos ícones da faixa “Utilidades” do site, na vertical).
struct AtalhoInicio: Identifiable {
    let titulo: String
    let subtitulo: String
    let simbolo: String
    let destino: DestinoAtalho
    var destaque = false

    var id: String { titulo }

    static let todos: [AtalhoInicio] = [
        AtalhoInicio(titulo: "Projetos", subtitulo: "Pesquisa, extensão e inovação",
                     simbolo: TipoPublicacao.projeto.simbolo, destino: .listar(.projeto)),
        AtalhoInicio(titulo: "Trabalhos acadêmicos", subtitulo: "TCCs, artigos e relatórios",
                     simbolo: TipoPublicacao.trabalho.simbolo, destino: .listar(.trabalho)),
        AtalhoInicio(titulo: "Banco de provas", subtitulo: "Provas anteriores por disciplina",
                     simbolo: TipoPublicacao.prova.simbolo, destino: .listar(.prova)),
        AtalhoInicio(titulo: "Material complementar", subtitulo: "Apostilas, vídeos e links",
                     simbolo: TipoPublicacao.material.simbolo, destino: .listar(.material)),
        AtalhoInicio(titulo: "Publique o seu projeto", subtitulo: "Projeto, trabalho ou prova",
                     simbolo: "plus.circle.fill", destino: .publicar(.projeto), destaque: true),
    ]

    /// Regra do app: ordem crescente de caracteres
    /// (Projetos 8, Banco de provas 15, Trabalhos acadêmicos 20,
    /// Material complementar 21, Publique o seu projeto 22).
    static var ordenados: [AtalhoInicio] {
        todos.sorted { ($0.titulo.count, $0.titulo) < ($1.titulo.count, $1.titulo) }
    }
}

/// Tela 1 — Início.
struct InicioView: View {
    @Environment(Router.self) private var router
    @Environment(BuscaModel.self) private var busca
    @AppStorage("usuario.nome") private var nomeUsuario = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(saudacao)
                    .font(Tipografia.fonte(25, .medium, relativoA: .largeTitle))
                    .foregroundStyle(UFSM.azul)
                Text("Explore e compartilhe os seus trabalhos e projetos acadêmicos.")
                    .font(Tipografia.fonte(14, relativoA: .subheadline))
                    .foregroundStyle(UFSM.texto2)
                    .padding(.top, 6)

                SecaoTitulo("Acesso rápido")
                    .padding(.top, 22)
                    .padding(.bottom, 12)

                VStack(spacing: 12) {
                    ForEach(AtalhoInicio.ordenados) { atalho in
                        Button {
                            abrir(atalho)
                        } label: {
                            CartaoAtalho(atalho: atalho)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 28)
        }
        .background(UFSM.fundo)
        .navigationTitle("Início")
        .toolbar(.hidden, for: .navigationBar)
    }

    private func abrir(_ atalho: AtalhoInicio) {
        switch atalho.destino {
        case .listar(let tipo):
            busca.tipo = tipo
            busca.texto = ""
            busca.mostrarFiltros = false
            router.abrirBusca(focar: false)
        case .publicar(let tipo):
            router.abrir(.publicar(tipo))
        }
    }

    private var saudacao: String {
        let primeiroNome = nomeUsuario.aparado.split(separator: " ").first.map(String.init)
        return "Olá, \(primeiroNome ?? "estudante")!"
    }
}

/// Cartão de atalho: ícone em bloco azul-claro, título, subtítulo e seta.
struct CartaoAtalho: View {
    let atalho: AtalhoInicio

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: atalho.simbolo)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(atalho.destaque ? Color.white : UFSM.azulSecundario)
                .frame(width: 54, height: 54)
                .background(
                    atalho.destaque ? Color.white.opacity(0.14) : UFSM.tinta,
                    in: RoundedRectangle(cornerRadius: Raio.card, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(atalho.titulo)
                    .font(Tipografia.fonte(17, .medium, relativoA: .headline))
                    .foregroundStyle(atalho.destaque ? Color.white : UFSM.azulSecundario)
                Text(atalho.subtitulo)
                    .font(Tipografia.fonte(12.5, relativoA: .subheadline))
                    .foregroundStyle(atalho.destaque ? Color.white.opacity(0.8) : UFSM.texto3)
            }
            .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(atalho.destaque ? Color.white.opacity(0.75) : UFSM.apagado)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 86)
        .background(
            atalho.destaque ? UFSM.azul : Color.white,
            in: RoundedRectangle(cornerRadius: Raio.menu, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Raio.menu, style: .continuous)
                .stroke(atalho.destaque ? UFSM.azul : UFSM.bordaSuave, lineWidth: 1)
        }
        .shadow(
            color: atalho.destaque ? UFSM.azul.opacity(0.3) : UFSM.azulProfundo.opacity(0.05),
            radius: atalho.destaque ? 11 : 8,
            y: atalho.destaque ? 8 : 4
        )
        .contentShape(RoundedRectangle(cornerRadius: Raio.menu, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        InicioView()
    }
    .environment(Router())
    .environment(BuscaModel())
}
