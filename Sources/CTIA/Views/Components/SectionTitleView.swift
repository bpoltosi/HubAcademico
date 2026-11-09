import SwiftUI

// MARK: - Marcador de Seção com Filete Dourado (| SEÇÃO)
public struct SectionTitleView: View {
    public let title: String
    
    public init(title: String) {
        self.title = title
    }
    
    public var body: some View {
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
