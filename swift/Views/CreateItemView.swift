import SwiftUI

// MARK: - Tela 4: Cadastro
// Projeto, trabalho ou prova em um só formulário
// Regras do Design System UFSM:
// - Resumo limitado a 200 caracteres, com contador no cadastro (ex: 176/200)
// - Campos e botões com raio de 10 pt
// - Botão primário "Publicar" em Azul UFSM #21376B com ícone paperplane
// - Margens laterais de 16 pt, grade de 8 pt
public struct CreateItemView: View {
    @State private var selectedTipo: AcademicType = .projeto
    @State private var titulo: String = "Monitor IoT de ruído nas oficinas do CTISM"
    @State private var resumo: String = "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas."
    @State private var imagemUrl: String = "https://example.com/monitor-ruido"
    @State private var linkTipo: String = "LinkedIn"
    @State private var linkPublicado: String = "linkedin.com/posts/ana-clara-machado"
    @State private var selectedArea: String = "Engenharias"
    @State private var selectedMateria: String = "Higiene Ocupacional"
    @State private var instituicao: String = "CTISM - UFSM"
    @State private var selectedAno: String = "2026"
    
    @State private var showSuccessAlert: Bool = false
    @State private var errorMessage: String? = nil
    
    var onBack: () -> Void
    var onPublishSuccess: (AcademicItem) -> Void
    
    public init(
        onBack: @escaping () -> Void = {},
        onPublishSuccess: @escaping (AcademicItem) -> Void = { _ in }
    ) {
        self.onBack = onBack
        self.onPublishSuccess = onPublishSuccess
    }
    
    // Contador de caracteres (limite 200)
    private var charCount: Int {
        resumo.count
    }
    
    private var isOverLimit: Bool {
        charCount > 200
    }
    
    private func handlePublish() {
        if titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "O título é obrigatório."
            return
        }
        if isOverLimit {
            errorMessage = "O resumo ultrapassou o limite de 200 caracteres."
            return
        }
        
        let newItem = AcademicItem(
            tipo: selectedTipo,
            titulo: titulo,
            resumo: resumo,
            autores: "Estudante do CTISM",
            area: selectedArea,
            materia: selectedMateria,
            curso: "Téc. Segurança do Trabalho",
            instituicao: instituicao,
            ano: Int(selectedAno) ?? 2026,
            avaliacao: 5.0,
            totalAvaliacoes: 1,
            imagemUrl: imagemUrl,
            linkPublicado: linkPublicado,
            linkTipo: linkTipo
        )
        
        onPublishSuccess(newItem)
        showSuccessAlert = true
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho UFSM
            CTIAHeader(
                searchText: .constant(""),
                onMenuTap: {},
                onAITap: {}
            )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Barra de navegação superior: "< Início" + Título
                    HStack {
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Início")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Color.azulUFSM)
                        }
                        
                        Spacer()
                        
                        Text("Cadastre o seu projeto")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.textoPrincipal)
                        
                        Spacer()
                        
                        // Espaçador invisível para centralizar título
                        Color.clear.frame(width: 44, height: 1)
                    }
                    .padding(.top, 6)
                    
                    // Segmented Control de Tipo (Projeto | Trabalho | Prova)
                    Picker("Tipo", selection: $selectedTipo) {
                        ForEach(AcademicType.allCases) { tipo in
                            Text(tipo.rawValue).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    
                    // Campo: Título *
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Título *")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color.textoSecundario)
                        
                        TextField("Título da produção acadêmica", text: $titulo)
                            .font(.system(size: 13.5))
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.white)
                            .cornerRadius(10) // Raio 10 pt
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.bordaUFSM, lineWidth: 1)
                            )
                    }
                    
                    // Campo: Descrição / Resumo com contador de caracteres (até 200)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Descrição — breve resumo (até 200 caracteres) *")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.textoSecundario)
                            
                            Spacer()
                            
                            // Contador de caracteres ao vivo (ex: 176/200)
                            Text("\(charCount)/200")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isOverLimit ? .red : Color.textoTerciario)
                        }
                        
                        TextEditor(text: $resumo)
                            .font(.system(size: 13))
                            .frame(height: 85)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10) // Raio 10 pt
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isOverLimit ? Color.red : Color.bordaUFSM, lineWidth: 1)
                            )
                    }
                    
                    // Campo: Imagem da descrição (URL)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Imagem da descrição (URL)")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color.textoSecundario)
                        
                        HStack(spacing: 8) {
                            TextField("https://example.com/imagem.png", text: $imagemUrl)
                                .font(.system(size: 13))
                                .padding(.horizontal, 12)
                                .frame(height: 42)
                            
                            Button(action: { /* Visualizar miniatura */ }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.azulUFSM)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "photo")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.trailing, 4)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.bordaUFSM, lineWidth: 1)
                        )
                    }
                    
                    // Campo: Link onde foi publicado (Dropdown + URL)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Link onde foi publicado")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color.textoSecundario)
                        
                        HStack(spacing: 8) {
                            Picker("Rede", selection: $linkTipo) {
                                Text("LinkedIn").tag("LinkedIn")
                                Text("GitHub").tag("GitHub")
                                Text("Lattes").tag("Lattes")
                                Text("Website").tag("Website")
                            }
                            .pickerStyle(.menu)
                            .tint(Color.azulUFSM)
                            .padding(.horizontal, 8)
                            .frame(height: 42)
                            .background(Color.fundoUFSM)
                            .cornerRadius(8)
                            
                            TextField("linkedin.com/posts/...", text: $linkPublicado)
                                .font(.system(size: 13))
                                .padding(.horizontal, 8)
                                .frame(height: 42)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.bordaUFSM, lineWidth: 1)
                        )
                    }
                    
                    // Dropdowns: Área * e Matéria *
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Área *")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color.textoSecundario)
                            
                            Picker("Área", selection: $selectedArea) {
                                Text("Engenharias").tag("Engenharias")
                                Text("Tecnologia da Informação").tag("Tecnologia da Informação")
                                Text("Ciências Exatas").tag("Ciências Exatas")
                            }
                            .pickerStyle(.menu)
                            .tint(Color.textoPrincipal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.bordaUFSM, lineWidth: 1)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Matéria *")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color.textoSecundario)
                            
                            Picker("Matéria", selection: $selectedMateria) {
                                Text("Higiene Ocupacional").tag("Higiene Ocupacional")
                                Text("Segurança do Trabalho").tag("Segurança do Trabalho")
                                Text("Eletrotécnica").tag("Eletrotécnica")
                                Text("Programação para Dispositivos Móveis").tag("Programação para Dispositivos Móveis")
                            }
                            .pickerStyle(.menu)
                            .tint(Color.textoPrincipal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.bordaUFSM, lineWidth: 1)
                            )
                        }
                    }
                    
                    // Linha: Instituição * e Ano *
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Instituição *")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color.textoSecundario)
                            
                            TextField("Instituição", text: $instituicao)
                                .font(.system(size: 13))
                                .padding(.horizontal, 12)
                                .frame(height: 42)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.bordaUFSM, lineWidth: 1)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ano *")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color.textoSecundario)
                            
                            Picker("Ano", selection: $selectedAno) {
                                Text("2026").tag("2026")
                                Text("2025").tag("2025")
                                Text("2024").tag("2024")
                            }
                            .pickerStyle(.menu)
                            .tint(Color.textoPrincipal)
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.bordaUFSM, lineWidth: 1)
                            )
                        }
                        .frame(width: 90)
                    }
                    
                    // Botões Inferiores: Salvar rascunho + Publicar
                    HStack(spacing: 12) {
                        Button(action: {
                            // Salvar rascunho localmente
                        }) {
                            Text("Salvar rascunho")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textoPrincipal)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white)
                                .cornerRadius(10) // Raio de 10 pt
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.bordaUFSM, lineWidth: 1.5)
                                )
                        }
                        
                        Button(action: handlePublish) {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 13))
                                Text("Publicar")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.azulUFSM)
                            .cornerRadius(10) // Raio de 10 pt
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.fundoUFSM)
            .alert("Sucesso!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    onBack()
                }
            } message: {
                Text("Sua produção acadêmica foi cadastrada com sucesso no CTIA!")
            }
        }
    }
}
