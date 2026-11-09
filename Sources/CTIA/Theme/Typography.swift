import SwiftUI

// MARK: - Tipografia Oficial Rawline / SF Pro
public extension Font {
    /// Saudação / título de tela: 25 pt · 500
    static let ctiaTituloTela = Font.system(size: 25, weight: .medium)
    
    /// Título de conteúdo: 21 pt · 500
    static let ctiaTituloConteudo = Font.system(size: 21, weight: .medium)
    
    /// Item do menu: 17 pt · 500
    static let ctiaItemMenu = Font.system(size: 17, weight: .medium)
    
    /// Texto corrido: 14-15 pt · 400
    static let ctiaTextoCorrido = Font.system(size: 14.5, weight: .regular)
    
    /// Título de seção (caixa alta): 12,5 pt · 500
    static let ctiaTituloSecao = Font.system(size: 12.5, weight: .medium)
    
    /// Legendas e rótulos: 11,5 pt · 400
    static let ctiaLegenda = Font.system(size: 11.5, weight: .regular)
}
