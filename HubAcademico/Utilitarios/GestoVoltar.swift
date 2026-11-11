import UIKit

/// Mantém o gesto de arrastar a partir da borda esquerda para voltar uma tela.
///
/// O iOS desliga esse gesto quando o botão de voltar padrão é escondido, e o app usa um
/// botão próprio com o texto "Voltar" (veja `barraDePagina`). Aqui o gesto volta a valer
/// sempre que houver uma tela para onde voltar.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
