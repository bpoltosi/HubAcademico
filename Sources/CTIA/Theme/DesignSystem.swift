import SwiftUI

// MARK: - Design System Oficial CTIA / UFSM
// Tokens visuais baseados no portal institucional ufsm.br

public struct DesignSystem {
    // Raios de curvatura
    public static let cornerRadiusButton: CGFloat = 10
    public static let cornerRadiusInput: CGFloat = 10
    public static let cornerRadiusCard: CGFloat = 14
    public static let cornerRadiusMenu: CGFloat = 16
    public static let cornerRadiusCheckbox: CGFloat = 5
    
    // Espaçamentos
    public static let paddingScreenHorizontal: CGFloat = 16
    public static let minTouchTargetHeight: CGFloat = 44
    public static let headerGoldStripeHeight: CGFloat = 2
}

// Reexportação de componentes de interface
public struct CTIAButtonPrimary: View {
    public let title: String
    public let icon: String?
    public let action: () -> Void
    
    public init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.minTouchTargetHeight)
            .background(Color.azulUFSM)
            .cornerRadius(DesignSystem.cornerRadiusButton)
        }
        .buttonStyle(.plain)
    }
}
