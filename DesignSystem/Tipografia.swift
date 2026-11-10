import SwiftUI
import UIKit
import CoreText

/// Registra as fontes .ttf/.otf incluídas no app e descobre os nomes PostScript da Rawline,
/// a fonte oficial do site da UFSM.
///
/// Sem os arquivos da Rawline no projeto, o app usa a fonte do sistema (o layout não muda).
/// Veja o README para incluir a Rawline.
enum FontRegistry {
    /// Peso CSS (400, 500, 600, 700…) → nome PostScript da Rawline registrada.
    static let rawline: [Int: String] = registrar()

    /// Força o registro das fontes na abertura do app.
    static func registrarFontes() {
        _ = rawline
    }

    /// Nome PostScript da Rawline mais próximo do peso pedido, ou `nil` se a fonte não estiver no app.
    static func nome(para peso: Font.Weight) -> String? {
        guard !rawline.isEmpty else { return nil }
        let alvo: Int
        switch peso {
        case .medium: alvo = 500
        case .semibold: alvo = 600
        case .bold, .heavy, .black: alvo = 700
        default: alvo = 400
        }
        if let exato = rawline[alvo] { return exato }
        let maisProximo = rawline.keys.min { abs($0 - alvo) < abs($1 - alvo) }
        return maisProximo.flatMap { rawline[$0] }
    }

    private static func registrar() -> [Int: String] {
        guard let raiz = Bundle.main.resourceURL,
              let arquivos = FileManager.default.enumerator(at: raiz, includingPropertiesForKeys: nil) else {
            return [:]
        }

        var mapa: [Int: String] = [:]
        for case let url as URL in arquivos where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            guard let descritores = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] else {
                continue
            }
            for descritor in descritores {
                guard let nome = CTFontDescriptorCopyAttribute(descritor, kCTFontNameAttribute) as? String else {
                    continue
                }
                let minusculo = nome.lowercased()
                guard minusculo.contains("rawline"), !minusculo.contains("italic") else { continue }
                mapa[pesoCSS(nome: minusculo, descritor: descritor)] = nome
            }
        }
        return mapa
    }

    private static func pesoCSS(nome: String, descritor: CTFontDescriptor) -> Int {
        if nome.contains("semibold") || nome.contains("demibold") { return 600 }
        if nome.contains("extrabold") || nome.contains("black") || nome.contains("heavy") { return 800 }
        if nome.contains("bold") { return 700 }
        if nome.contains("medium") { return 500 }
        if nome.contains("extralight") || nome.contains("thin") { return 200 }
        if nome.contains("light") { return 300 }
        if nome.contains("regular") || nome.contains("book") { return 400 }

        // Nome sem indicação de peso: usa o traço de peso da própria fonte.
        if let tracos = CTFontDescriptorCopyAttribute(descritor, kCTFontTraitsAttribute) as? [String: Any],
           let peso = tracos[kCTFontWeightTrait as String] as? Double {
            switch peso {
            case ..<(-0.3): return 300
            case ..<0.15: return 400
            case ..<0.27: return 500
            case ..<0.35: return 600
            default: return 700
            }
        }
        return 400
    }
}

/// Fontes do design system.
enum Tipografia {
    /// Fonte que acompanha o tamanho de texto escolhido no iPhone (Dynamic Type).
    static func fonte(_ tamanho: CGFloat, _ peso: Font.Weight = .regular, relativoA estilo: Font.TextStyle = .body) -> Font {
        if let nome = FontRegistry.nome(para: peso) {
            return .custom(nome, size: tamanho, relativeTo: estilo)
        }
        // Sem a Rawline: fonte do sistema, escalada conforme o tamanho de texto do iPhone.
        let escalado = UIFontMetrics(forTextStyle: estilo.estiloUIKit).scaledValue(for: tamanho)
        return .system(size: escalado, weight: peso)
    }

    /// Fonte de tamanho fixo, usada no cabeçalho institucional.
    static func fonteFixa(_ tamanho: CGFloat, _ peso: Font.Weight = .regular) -> Font {
        if let nome = FontRegistry.nome(para: peso) {
            return .custom(nome, fixedSize: tamanho)
        }
        return .system(size: tamanho, weight: peso)
    }

    /// Versão UIKit, usada na aparência da barra de navegação.
    static func uiFont(_ tamanho: CGFloat, _ peso: UIFont.Weight = .regular) -> UIFont {
        let pesoSwiftUI: Font.Weight
        switch peso {
        case .medium: pesoSwiftUI = .medium
        case .semibold: pesoSwiftUI = .semibold
        case .bold, .heavy, .black: pesoSwiftUI = .bold
        default: pesoSwiftUI = .regular
        }
        if let nome = FontRegistry.nome(para: pesoSwiftUI), let fonte = UIFont(name: nome, size: tamanho) {
            return fonte
        }
        return .systemFont(ofSize: tamanho, weight: peso)
    }
}

private extension Font.TextStyle {
    /// Estilo equivalente do UIKit, usado para escalar a fonte do sistema (Dynamic Type).
    var estiloUIKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
