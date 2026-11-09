import SwiftUI

// MARK: - Cores Oficiais UFSM / CTIA
// Extraídas dos tokens CSS de ufsm.br (Tema UFSM 2.3.14 sobre Bootstrap 5)
extension Color {
    /// Azul UFSM #21376B - Cabeçalho, títulos principais, botões primários
    static let azulUFSM = Color(hex: "21376B")
    
    /// Azul secundário #204C90 - Ícones e rótulos do menu
    static let azulSecundario = Color(hex: "204C90")
    
    /// Azul profundo #142140 - Fundos de destaque e cards especiais
    static let azulProfundo = Color(hex: "142140")
    
    /// Dourado #CC8F00 - Filete do cabeçalho de 2pt, marcadores de seção
    static let douradoUFSM = Color(hex: "CC8F00")
    
    /// Âmbar #FFC107 - Estrelas de avaliação
    static let ambarUFSM = Color(hex: "FFC107")
    
    /// Texto #1C1C1C - Texto principal
    static let textoPrincipal = Color(hex: "1C1C1C")
    
    /// Texto #4C4C4C - Texto secundário (nível 2)
    static let textoSecundario = Color(hex: "4C4C4C")
    
    /// Texto #6C757D - Rótulos e legendas (nível 3)
    static let textoTerciario = Color(hex: "6C757D")
    
    /// Fundo #F1F4F9 - Fundo da aplicação
    static let fundoUFSM = Color(hex: "F1F4F9")
    
    /// Bordas #D3D7E1 - Bordas de cartões e inputs
    static let bordaUFSM = Color(hex: "D3D7E1")
    
    /// Superfície branca #FFFFFF
    static let superficieUFSM = Color.white
    
    // Inicializador auxiliar para cores Hexadecimais
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Tipografia Rawline / San Francisco
// Fonte oficial: Rawline (ou fallback nativo com mesmos pesos e tamanhos)
extension Font {
    /// Saudação / título de tela: 25 pt · 500
    static let ctiaTituloTela = Font.custom("Rawline-Medium", size: 25).weight(.medium)
    
    /// Título de conteúdo: 21 pt · 500
    static let ctiaTituloConteudo = Font.custom("Rawline-Medium", size: 21).weight(.medium)
    
    /// Item do menu: 17 pt · 500
    static let ctiaItemMenu = Font.custom("Rawline-Medium", size: 17).weight(.medium)
    
    /// Texto corrido: 14-15 pt · 400
    static let ctiaTextoCorrido = Font.custom("Rawline-Regular", size: 14.5).weight(.regular)
    
    /// Título de seção (caixa alta): 12,5 pt · 500
    static let ctiaTituloSecao = Font.custom("Rawline-Medium", size: 12.5).weight(.medium)
    
    /// Legendas e rótulos: 11,5 pt · 400
    static let ctiaLegenda = Font.custom("Rawline-Regular", size: 11.5).weight(.regular)
}

// MARK: - Componentes de Design System

/// Marcador de Seção com Filete Dourado (| SEÇÃO)
struct SectionTitleView: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.douradoUFSM)
                .frame(width: 3, height: 14)
            
            Text(title.uppercased())
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color.textoSecundario)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Checkbox estilo Bootstrap / UFSM com raio de 5 pt e cor Azul UFSM
struct CTIACheckbox: View {
    @Binding var isChecked: Bool
    let label: String
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isChecked ? Color.azulUFSM : Color.bordaUFSM, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isChecked ? Color.azulUFSM : Color.superficieUFSM)
                        )
                        .frame(width: 20, height: 20)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textoPrincipal)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44) // Área mínima de toque de 44 pt
    }
}

/// Avaliação de Estrelas em Âmbar #FFC107
struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var starSize: CGFloat = 13
    var isInteractive: Bool = false
    var onRate: ((Int) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: starSize))
                    .foregroundColor(Double(index) <= rating || Double(index) - 0.5 <= rating ? Color.ambarUFSM : Color.bordaUFSM)
                    .onTapGesture {
                        if isInteractive {
                            onRate?(index)
                        }
                    }
            }
        }
    }
}
