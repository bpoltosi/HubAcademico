import SwiftUI

/// Painel aberto pelo funil: uma caixa de seleção por filtro, na ordem crescente de caracteres.
struct PainelFiltros: View {
    @Environment(BuscaModel.self) private var busca
    @Environment(PublicacaoStore.self) private var store

    var body: some View {
        @Bindable var busca = busca
        let ativos = busca.filtros.quantidadeAtivos
        let contagem: String = ativos == 1 ? "· 1 ativo" : "· \(ativos) ativos"
        let campos = CampoFiltro.ordenados

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(UFSM.azulSecundario)
                Text("Filtrar por")
                    .font(Tipografia.fonte(15, .medium, relativoA: .headline))
                    .foregroundStyle(UFSM.azul)
                Text(contagem)
                    .font(Tipografia.fonte(11.5, relativoA: .caption))
                    .foregroundStyle(UFSM.texto3)
                Spacer()
                Button("Limpar") {
                    withAnimation(.snappy) { busca.limparFiltros() }
                }
                .font(Tipografia.fonte(13, .medium, relativoA: .footnote))
                .tint(UFSM.azulSecundario)
                .disabled(ativos == 0)
            }
            .frame(height: 44)

            Divider().overlay(UFSM.bordaSuave)

            ForEach(campos) { campo in
                LinhaFiltro(
                    campo: campo,
                    filtros: $busca.filtros,
                    anos: store.anosDisponiveis
                )
                if campo != campos.last {
                    Divider().overlay(UFSM.divisoria)
                }
            }

            Button {
                withAnimation(.snappy) { busca.mostrarFiltros = false }
            } label: {
                Label("Aplicar filtros", systemImage: "magnifyingglass")
            }
            .buttonStyle(EstiloBotaoPrimario())
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .cartao(raio: Raio.menu)
        .shadow(color: UFSM.azulProfundo.opacity(0.13), radius: 15, y: 12)
    }
}

/// Uma linha do painel: caixa de seleção + rótulo; quando marcada, mostra o valor do filtro.
struct LinhaFiltro: View {
    let campo: CampoFiltro
    @Binding var filtros: FiltrosBusca
    let anos: [Int]

    private var ativo: Bool {
        filtros.ativos.contains(campo)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    if ativo {
                        _ = filtros.ativos.remove(campo)
                    } else {
                        _ = filtros.ativos.insert(campo)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Checkbox(marcado: ativo)
                    Text(campo.rotulo)
                        .font(Tipografia.fonte(14.5, ativo ? .medium : .regular, relativoA: .subheadline))
                        .foregroundStyle(ativo ? UFSM.azul : UFSM.texto)
                    if campo == .melhorAvaliacao {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(UFSM.ambar)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(ativo ? .isSelected : [])

            Spacer(minLength: 8)

            if ativo {
                controle
            } else {
                Text(campo.dica)
                    .font(Tipografia.fonte(12, relativoA: .caption))
                    .foregroundStyle(UFSM.dica)
                    .lineLimit(1)
            }
        }
        .frame(minHeight: 42)
    }

    @ViewBuilder
    private var controle: some View {
        switch campo {
        case .ano:
            Menu {
                Picker("Ano", selection: $filtros.ano) {
                    ForEach(anos, id: \.self) { ano in
                        Text(String(ano)).tag(ano)
                    }
                }
            } label: {
                Pilula(texto: String(filtros.ano))
            }
        case .area:
            Menu {
                Picker("Área", selection: $filtros.area) {
                    ForEach(AreaConhecimento.allCases) { area in
                        Text(area.nome).tag(area)
                    }
                }
            } label: {
                Pilula(texto: filtros.area.nome)
            }
        case .autor:
            CampoTextoCompacto(placeholder: "Nome do(a) autor(a)", texto: $filtros.autor)
        case .curso:
            Menu {
                Picker("Curso", selection: $filtros.curso) {
                    ForEach(CursoCTISM.todos) { curso in
                        Text(curso.nomeCurto).tag(curso.nome)
                    }
                }
            } label: {
                Pilula(texto: CursoCTISM.curto(filtros.curso))
            }
        case .titulo:
            CampoTextoCompacto(placeholder: "Palavras do título", texto: $filtros.titulo)
        case .disciplina:
            CampoTextoCompacto(placeholder: "Nome da disciplina", texto: $filtros.disciplina)
        case .melhorAvaliacao:
            Pilula(texto: "Melhor avaliação", iconeInicio: "arrow.down", mostrarSeta: false)
        }
    }
}
