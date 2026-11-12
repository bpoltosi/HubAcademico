import SwiftUI

// MARK: - Títulos

/// Título de seção com o marcador dourado do cabeçalho do site.
struct SecaoTitulo: View {
    let texto: String

    init(_ texto: String) {
        self.texto = texto
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(UFSM.dourado)
                .frame(width: 4, height: 15)
            Text(texto.uppercased())
                .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
                .tracking(0.9)
                .foregroundStyle(UFSM.azul)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Chips e pílulas

/// Etiqueta arredondada (tipo da publicação, área, disciplina, ano…).
struct Chip: View {
    enum Estilo {
        case tipo, destaque, neutro
    }

    let texto: String
    var icone: String? = nil
    var estilo: Estilo = .neutro

    var body: some View {
        HStack(spacing: 5) {
            if let icone {
                Image(systemName: icone)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(estilo == .tipo ? texto.uppercased() : texto)
                .lineLimit(1)
        }
        .font(Tipografia.fonte(estilo == .tipo ? 10.5 : 12, estilo == .neutro ? .regular : .medium, relativoA: .caption))
        .tracking(estilo == .tipo ? 0.7 : 0)
        .foregroundStyle(estilo == .neutro ? UFSM.texto2 : UFSM.azulSecundario)
        .padding(.horizontal, 10)
        .frame(height: estilo == .tipo ? 24 : 28)
        .background(estilo == .neutro ? Color.white : UFSM.tinta, in: Capsule())
        .overlay {
            Capsule().stroke(estilo == .neutro ? UFSM.bordaSuave : Color.clear, lineWidth: 1)
        }
    }
}

/// Valor escolhido em um filtro ou seletor (ex.: “2026 ⌄”).
struct Pilula: View {
    let texto: String
    var iconeInicio: String? = nil
    var mostrarSeta = true

    var body: some View {
        HStack(spacing: 6) {
            if let iconeInicio {
                Image(systemName: iconeInicio)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(UFSM.texto3)
            }
            Text(texto)
                .lineLimit(1)
            if mostrarSeta {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(UFSM.texto3)
            }
        }
        .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
        .foregroundStyle(UFSM.azul)
        .padding(.horizontal, 10)
        .frame(height: 29)
        .background(UFSM.fundo, in: RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous)
                .stroke(UFSM.bordaSuave, lineWidth: 1)
        }
    }
}

// MARK: - Controles

/// Caixa de seleção no estilo do Bootstrap do site (raio 5, ativa em azul UFSM).
struct Checkbox: View {
    let marcado: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(marcado ? UFSM.azul : Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(marcado ? UFSM.azul : Color(hex: 0xAEB6C8), lineWidth: 1.6)
            }
            .overlay {
                if marcado {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 21, height: 21)
    }
}

/// Exibe a média de 0 a 5 com preenchimento parcial da última estrela.
struct Estrelas: View {
    let media: Double
    var tamanho: CGFloat = 12
    var espaco: CGFloat = 2

    var body: some View {
        HStack(spacing: espaco) {
            ForEach(0..<5, id: \.self) { indice in
                estrela(preenchimento: min(max(media - Double(indice), 0), 1))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Média \(media.mediaFormatada) de 5")
    }

    private func estrela(preenchimento: Double) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: tamanho))
            .foregroundStyle(UFSM.estrelaVazia)
            .overlay {
                GeometryReader { geo in
                    Image(systemName: "star.fill")
                        .font(.system(size: tamanho))
                        .foregroundStyle(UFSM.ambar)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: geo.size.width * preenchimento)
                        }
                }
            }
    }
}

// MARK: - Botões

struct EstiloBotaoPrimario: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tipografia.fonte(15, .medium, relativoA: .headline))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                UFSM.azul.opacity(configuration.isPressed ? 0.85 : 1),
                in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous)
            )
            .shadow(color: UFSM.azul.opacity(0.22), radius: 7, y: 5)
    }
}

struct EstiloBotaoSecundario: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tipografia.fonte(14.5, .medium, relativoA: .headline))
            .foregroundStyle(UFSM.azul)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                UFSM.campo.opacity(configuration.isPressed ? 0.7 : 1),
                in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous)
            )
    }
}

// MARK: - Campos de formulário

/// Caixa de campo com rótulo flutuante (padrão da tela Publicar).
struct CampoRotulado<Conteudo: View>: View {
    let rotulo: String
    var obrigatorio = false
    var emFoco = false
    var erro: String? = nil
    @ViewBuilder var conteudo: Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Text(rotulo)
                    if obrigatorio {
                        Text("*").foregroundStyle(UFSM.perigo)
                    }
                }
                .font(Tipografia.fonte(10.5, .medium, relativoA: .caption2))
                .foregroundStyle(emFoco ? UFSM.azulSecundario : UFSM.texto3)

                conteudo
                    .font(Tipografia.fonte(14.5, relativoA: .body))
                    .foregroundStyle(UFSM.texto)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 49, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Raio.campo, style: .continuous)
                    .stroke(corDaBorda, lineWidth: emFoco ? 2 : 1)
            }

            if let erro {
                Label(erro, systemImage: "exclamationmark.circle.fill")
                    .font(Tipografia.fonte(11, relativoA: .caption2))
                    .foregroundStyle(UFSM.perigo)
                    .padding(.leading, 4)
            }
        }
    }

    private var corDaBorda: Color {
        if erro != nil { return UFSM.perigo }
        return emFoco ? UFSM.azulSecundario : UFSM.borda
    }
}

/// Conteúdo de um seletor (texto + seta para baixo).
struct LinhaSelecao: View {
    let texto: String
    var vazio = false

    var body: some View {
        HStack {
            Text(texto)
                .foregroundStyle(vazio ? UFSM.dica : UFSM.texto)
                .lineLimit(1)
            Spacer(minLength: 6)
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(UFSM.texto3)
        }
        .contentShape(Rectangle())
    }
}

/// Campo de texto pequeno usado dentro do painel de filtros.
struct CampoTextoCompacto: View {
    let placeholder: String
    @Binding var texto: String

    var body: some View {
        TextField(placeholder, text: $texto)
            .font(Tipografia.fonte(12.5, .medium, relativoA: .footnote))
            .foregroundStyle(UFSM.azul)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .padding(.horizontal, 10)
            .frame(height: 29)
            .frame(maxWidth: 190)
            .background(UFSM.fundo, in: RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Raio.pequeno, style: .continuous)
                    .stroke(UFSM.bordaSuave, lineWidth: 1)
            }
    }
}

// MARK: - Imagens

/// Imagem da publicação. Aceita links da web (carregados com AsyncImage)
/// e imagens do próprio app no formato `asset://nome-da-imagem` (dados de exemplo).
struct ImagemView: View {
    let link: URL?

    var body: some View {
        Group {
            if let link, link.scheme == "asset", let nome = link.host() {
                Image(nome)
                    .resizable()
                    .scaledToFill()
            } else if let link {
                AsyncImage(url: link) { fase in
                    switch fase {
                    case .success(let imagem):
                        imagem
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        PlaceholderImagem(icone: "photo", texto: "Imagem indisponível")
                    default:
                        PlaceholderImagem(icone: nil, texto: nil)
                            .overlay {
                                ProgressView().tint(.white)
                            }
                    }
                }
            } else {
                PlaceholderImagem(icone: "photo", texto: nil)
            }
        }
    }
}

struct PlaceholderImagem: View {
    let icone: String?
    let texto: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [UFSM.azulProfundo, UFSM.azulSecundario],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 6) {
                if let icone {
                    Image(systemName: icone)
                        .font(.system(size: 22, weight: .semibold))
                }
                if let texto {
                    Text(texto)
                        .font(Tipografia.fonte(11, relativoA: .caption2))
                }
            }
            .foregroundStyle(Color.white.opacity(0.75))
        }
    }
}

// MARK: - Estados e avisos

struct EstadoVazio: View {
    let icone: String
    let titulo: String
    let mensagem: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icone)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(UFSM.apagado)
            Text(titulo)
                .font(Tipografia.fonte(16, .medium, relativoA: .headline))
                .foregroundStyle(UFSM.azul)
            Text(mensagem)
                .font(Tipografia.fonte(13.5, relativoA: .subheadline))
                .foregroundStyle(UFSM.texto3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
    }
}

/// Faixa de aviso amarela (orientações e alertas suaves).
struct Aviso: View {
    let texto: String
    var icone = "info.circle.fill"

    var body: some View {
        Label(texto, systemImage: icone)
            .font(Tipografia.fonte(12, relativoA: .footnote))
            .foregroundStyle(UFSM.avisoTexto)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(UFSM.avisoFundo, in: RoundedRectangle(cornerRadius: Raio.campo, style: .continuous))
    }
}
