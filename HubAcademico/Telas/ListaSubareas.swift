import SwiftUI

/// Subáreas da área escolhida, abertas dentro do campo Subárea do cadastro.
/// As da mesma família ("Agronomia/…", "Medicina/…") ficam juntas, sob o nome da família.
struct ListaSubareas: View {
    let area: AreaConhecimento
    let selecionada: String?
    let escolher: (String) -> Void

    private struct Bloco: Identifiable {
        let grupo: String?
        let subareas: [String]
        var id: String { grupo ?? subareas.first ?? "" }
    }

    /// Junta as subáreas seguidas que têm o mesmo grupo, mantendo a ordem da tabela do CNPq.
    private var blocos: [Bloco] {
        var blocos: [Bloco] = []
        for subarea in area.subareas {
            let grupo = Subarea.partes(subarea).grupo
            if let grupo, let ultimo = blocos.last, ultimo.grupo == grupo {
                blocos[blocos.count - 1] = Bloco(grupo: grupo, subareas: ultimo.subareas + [subarea])
            } else {
                blocos.append(Bloco(grupo: grupo, subareas: [subarea]))
            }
        }
        return blocos
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(area.subareas.count) subáreas de \(area.nomeCompleto). Toque para escolher.")
                .font(Tipografia.fonte(11.5, relativoA: .caption))
                .foregroundStyle(UFSM.texto3)
                .padding(.bottom, 4)

            ForEach(blocos) { bloco in
                if let grupo = bloco.grupo {
                    Text(grupo.uppercased())
                        .font(Tipografia.fonte(10.5, .medium, relativoA: .caption2))
                        .tracking(0.6)
                        .foregroundStyle(UFSM.azul)
                        .padding(.top, 10)
                        .padding(.bottom, 2)
                        .accessibilityAddTraits(.isHeader)
                }
                ForEach(bloco.subareas, id: \.self) { subarea in
                    linha(subarea, recuada: bloco.grupo != nil)
                }
            }
        }
        .padding(.top, 2)
    }

    private func linha(_ subarea: String, recuada: Bool) -> some View {
        let marcada = subarea == selecionada
        let partes = Subarea.partes(subarea)

        return Button {
            escolher(subarea)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: marcada ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(marcada ? UFSM.azulSecundario : Color(hex: 0xAEB6C8))
                Text(partes.nome)
                    .font(Tipografia.fonte(14, marcada ? .medium : .regular, relativoA: .body))
                    .foregroundStyle(marcada ? UFSM.azul : UFSM.texto)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.leading, recuada ? 10 : 0)
            .frame(minHeight: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(partes.grupo.map { "\($0), \(partes.nome)" } ?? partes.nome)
        .accessibilityAddTraits(marcada ? .isSelected : [])
    }
}

#Preview {
    ScrollView {
        ListaSubareas(area: .agrarias, selecionada: "Agronomia/Ciência do Solo") { _ in }
            .padding()
    }
}
