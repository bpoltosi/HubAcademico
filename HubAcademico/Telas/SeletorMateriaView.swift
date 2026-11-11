import SwiftUI

/// Matérias da subárea escolhida no cadastro (currículos da UFSM), com busca por nome ou código.
///
/// Na busca também aparecem as de outras subáreas — escolher uma delas ajusta a área e a subárea
/// do cadastro — e a opção de usar o texto digitado, para matérias que não estão na lista
/// (como as dos cursos técnicos do CTISM).
struct SeletorMateriaView: View {
    @Binding var formulario: FormularioCadastro
    /// Matérias já usadas em publicações do Hub Acadêmico nesta subárea.
    let usadasNoHub: [String]

    @Environment(\.dismiss) private var fechar
    @State private var texto = ""

    init(formulario: Binding<FormularioCadastro>, usadasNoHub: [String]) {
        _formulario = formulario
        self.usadasNoHub = usadasNoHub
    }

    var body: some View {
        let subarea = formulario.subarea
        let digitado = texto.aparado
        let resultado = CatalogoMaterias.ufsm.buscar(digitado, na: subarea)
        let usadas = filtrar(usadasNoHub, por: digitado)
        let chave = digitado.normalizado
        let existeIgual = usadas.contains { $0.normalizado == chave }
            || resultado.daSubarea.contains { $0.nome.normalizado == chave }
            || resultado.outras.contains { $0.nome.normalizado == chave }
        let nadaNaLista = usadas.isEmpty && resultado.daSubarea.isEmpty && resultado.outras.isEmpty

        NavigationStack {
            List {
                if digitado.count >= 2, !existeIgual {
                    Section {
                        Button {
                            escolher(digitado, subarea: subarea)
                        } label: {
                            Label("Usar “\(digitado)”", systemImage: "plus.circle.fill")
                        }
                    } footer: {
                        Text("Para matérias que não estão na lista, como as dos cursos técnicos do CTISM.")
                    }
                }

                if !usadas.isEmpty {
                    Section("Já usadas no Hub Acadêmico") {
                        ForEach(usadas, id: \.self) { nome in
                            linha(nome: nome, detalhe: nil, marcada: nome == formulario.materia) {
                                escolher(nome, subarea: subarea)
                            }
                        }
                    }
                }

                if !resultado.daSubarea.isEmpty {
                    Section {
                        ForEach(resultado.daSubarea) { materia in
                            linha(materia, mostrarSubarea: false)
                        }
                    } header: {
                        Text(subarea.map { "Matérias da UFSM · \(Subarea.legivel($0))" } ?? "Matérias da UFSM")
                    } footer: {
                        if digitado.isEmpty {
                            Text("Fonte: \(CatalogoMaterias.ufsm.fonte).")
                        }
                    }
                }

                if !resultado.outras.isEmpty {
                    Section {
                        ForEach(resultado.outras) { materia in
                            linha(materia, mostrarSubarea: true)
                        }
                    } header: {
                        Text("Em outras subáreas")
                    } footer: {
                        Text("Ao escolher uma destas, a área e a subárea do cadastro passam a ser as dela.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if nadaNaLista, digitado.count < 2 {
                    if digitado.isEmpty {
                        ContentUnavailableView(
                            "Nenhuma matéria da UFSM nesta subárea",
                            systemImage: "books.vertical",
                            description: Text("Digite o nome da matéria na busca acima para usá-la.")
                        )
                    } else {
                        ContentUnavailableView.search(text: digitado)
                    }
                }
            }
            .searchable(text: $texto, placement: .navigationBarDrawer(displayMode: .always), prompt: "Nome ou código da matéria")
            .autocorrectionDisabled()
            .navigationTitle("Matéria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { fechar() }
                }
            }
        }
        .tint(UFSM.azulSecundario)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Linhas

    private func linha(_ materia: MateriaUFSM, mostrarSubarea: Bool) -> some View {
        var detalhes: [String] = []
        if mostrarSubarea {
            detalhes.append(Subarea.legivel(materia.subarea))
        }
        if let codigo = materia.codigos.first {
            detalhes.append(codigo)
        }
        if !materia.cursos.isEmpty {
            detalhes.append(materia.cursosResumidos)
        }
        let marcada = materia.nome == formulario.materia && materia.subarea == formulario.subarea

        return linha(nome: materia.nome, detalhe: detalhes.joined(separator: " · "), marcada: marcada) {
            escolher(materia.nome, subarea: materia.subarea)
        }
    }

    private func linha(nome: String, detalhe: String?, marcada: Bool, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(nome)
                        .font(Tipografia.fonte(14.5, marcada ? .medium : .regular, relativoA: .body))
                        .foregroundStyle(marcada ? UFSM.azul : UFSM.texto)
                    if let detalhe, !detalhe.isEmpty {
                        Text(detalhe)
                            .font(Tipografia.fonte(11.5, relativoA: .caption))
                            .foregroundStyle(UFSM.texto3)
                            .lineLimit(2)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if marcada {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(UFSM.azulSecundario)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(marcada ? .isSelected : [])
    }

    // MARK: - Ações

    private func filtrar(_ nomes: [String], por texto: String) -> [String] {
        let termos = texto.normalizado.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        guard !termos.isEmpty else { return nomes }
        return nomes.filter { nome in
            let chave = nome.normalizado
            return termos.allSatisfy { chave.contains($0) }
        }
    }

    private func escolher(_ nome: String, subarea: String?) {
        formulario.escolherMateria(nome, subarea: subarea)
        fechar()
    }
}

/// Prévia com Engenharias › Engenharia de Produção já escolhidas.
private struct PreviaSeletorMateria: View {
    @State private var formulario: FormularioCadastro = {
        var formulario = FormularioCadastro(tipo: .projeto)
        formulario.escolherArea(.engenharias)
        formulario.escolherSubarea("Engenharia de Produção")
        return formulario
    }()

    var body: some View {
        SeletorMateriaView(formulario: $formulario, usadasNoHub: ["Higiene Ocupacional", "Ergonomia"])
    }
}

#Preview {
    PreviaSeletorMateria()
}
