import SwiftUI

// MARK: - Cores Oficiais UFSM / CTIA
// Extraídas dos tokens CSS de ufsm.br (Tema UFSM 2.3.14 sobre Bootstrap 5)
public extension Color {
    /// Azul UFSM #21376B - Cabeçalho, títulos principais, botões primários
    static let azulUFSM = Color(hex: "21376B")
    
    /// Azul secundário #204C90 - Ícones e rótulos do menu
    static let azulSecundario = Color(hex: "204C90")
    
    /// Azul profundo #142140 - Fundos de destaque e cards IoT
    static let azulProfundo = Color(hex: "142140")
    
    /// Dourado #CC8F00 - Filete do cabeçalho de 2 pt, marcadores de seção
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
    
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
