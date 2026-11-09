import SwiftUI

// MARK: - Checkbox com raio de 5 pt e ativo em Azul UFSM #21376B (Bootstrap do site)
public struct CTIACheckbox: View {
    @Binding var isChecked: Bool
    let label: String
    
    public init(isChecked: Binding<Bool>, label: String) {
        self._isChecked = isChecked
        self.label = label
    }
    
    public var body: some View {
        Button(action: { isChecked.toggle() }) {
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
        .frame(minHeight: 44) // Área de toque mínima de 44 pt
    }
}
