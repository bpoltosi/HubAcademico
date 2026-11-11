import SwiftUI
import UIKit

extension Color {
    /// Cria uma cor a partir de um hexadecimal no formato 0xRRGGBB.
    init(hex: UInt32, opacidade: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacidade
        )
    }
}

/// Paleta extraída do CSS publicado em www.ufsm.br
/// (tema UFSM 2.3.14, construído sobre o Bootstrap 5).
enum UFSM {
    /// `--bs-primary` do site: cabeçalho, títulos e botão primário.
    static let azul = Color(hex: 0x21376B)
    /// Ícones e rótulos da faixa “Utilidades” do site do CTISM.
    static let azulSecundario = Color(hex: 0x204C90)
    static let azulProfundo = Color(hex: 0x142140)
    /// Filete dourado do cabeçalho do site.
    static let dourado = Color(hex: 0xCC8F00)
    /// Estrelas de avaliação.
    static let ambar = Color(hex: 0xFFC107)
    /// Links externos.
    static let info = Color(hex: 0x007ABB)

    static let texto = Color(hex: 0x1C1C1C)
    static let texto2 = Color(hex: 0x4C4C4C)
    static let texto3 = Color(hex: 0x6C757D)
    static let apagado = Color(hex: 0x909BB5)
    static let dica = Color(hex: 0xA3ABBB)

    static let fundo = Color(hex: 0xF1F4F9)
    static let campo = Color(hex: 0xEEEFF1)
    static let trilho = Color(hex: 0xE4E8EF)
    static let borda = Color(hex: 0xD3D7E1)
    static let bordaSuave = Color(hex: 0xE3E8F0)
    static let divisoria = Color(hex: 0xEEF1F6)
    static let tinta = Color(hex: 0xE8EEF7)
    static let estrelaVazia = Color(hex: 0xD5DAE4)
    static let avisoFundo = Color(hex: 0xFFF6DB)
    static let avisoTexto = Color(hex: 0x7A5600)

    static let perigo = Color(hex: 0xDC3545)
    static let sucesso = Color(hex: 0x198754)
}

/// Raios de canto do design system (em pontos).
enum Raio {
    static let pequeno: CGFloat = 8
    static let campo: CGFloat = 10
    static let card: CGFloat = 14
    static let menu: CGFloat = 16
}

/// Aparência UIKit da barra de navegação: barra branca, título em azul UFSM.
enum Aparencia {
    static func configurar() {
        let barra = UINavigationBarAppearance()
        barra.configureWithOpaqueBackground()
        barra.backgroundColor = .white
        barra.shadowColor = UIColor(UFSM.bordaSuave)
        barra.titleTextAttributes = [
            .foregroundColor: UIColor(UFSM.azul),
            .font: Tipografia.uiFont(16, .medium)
        ]

        let botao = UIBarButtonItemAppearance(style: .plain)
        botao.normal.titleTextAttributes = [.font: Tipografia.uiFont(15, .medium)]
        barra.buttonAppearance = botao
        barra.backButtonAppearance = botao

        let navegacao = UINavigationBar.appearance()
        navegacao.standardAppearance = barra
        navegacao.scrollEdgeAppearance = barra
        navegacao.compactAppearance = barra
    }
}

/// Barra das telas empilhadas: título centralizado e "‹ Voltar", que volta uma tela.
/// (O ☰ do cabeçalho é que volta direto ao Início.) O gesto de arrastar da borda
/// continua funcionando graças a `GestoVoltar.swift`.
private struct BarraDePagina: ViewModifier {
    let titulo: String
    @Environment(\.dismiss) var voltar

    func body(content: Content) -> some View {
        content
            .navigationTitle(titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        voltar()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Voltar")
                                .font(Tipografia.fonte(15, .medium, relativoA: .body))
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Voltar")
                }
            }
    }
}

extension View {
    /// Barra de página das telas internas: título centralizado e botão "‹ Voltar".
    func barraDePagina(_ titulo: String) -> some View {
        modifier(BarraDePagina(titulo: titulo))
    }

    /// Cartão branco com borda suave, usado em listas e painéis.
    func cartao(raio: CGFloat = Raio.card) -> some View {
        background(Color.white, in: RoundedRectangle(cornerRadius: raio, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: raio, style: .continuous)
                    .stroke(UFSM.bordaSuave, lineWidth: 1)
            }
    }
}
