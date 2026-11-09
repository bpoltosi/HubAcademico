import SwiftUI

// MARK: - Tela 3: Visualização
// Título, imagem da URL / card IoT, resumo, avaliações e área
// Regras do Design System UFSM:
// - Marcadores dourados nas seções (| RESUMO, | AVALIAÇÕES, | ÁREA, | MATÉRIA)
// - Estrelas de avaliação em Âmbar #FFC107
// - Fundo #F1F4F9, superfícies #FFFFFF, bordas #D3D7E1
public struct DetailView: View {
    @State var item: AcademicItem = AcademicItem.mockNoiseMonitor
    @State private var userRating: Int = 0
    @State private var isSaved: Bool = true
    public var onBack: () -> Void
    public var onGoHome: () -> Void
    
    public init(
        item: AcademicItem = AcademicItem.mockNoiseMonitor,
        onBack: @escaping () -> Void = {},
        onGoHome: @escaping () -> Void = {}
    ) {
        self._item = State(initialValue: item)
        self.onBack = onBack
        self.onGoHome = onGoHome
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho UFSM com as 3 barras retornando ao Início por padrão
            CTIAHeader(
                searchText: .constant(""),
                onHomeTap: onGoHome,
                onAITap: {}
            )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Barra de navegação interna: "< Resultados" + Favorito + Compartilhar
                    HStack {
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Resultados")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Color.azulUFSM)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { isSaved.toggle() }) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 16))
                                    .foregroundColor(isSaved ? Color.azulUFSM : Color.textoTerciario)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.textoTerciario)
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    // Metadados do topo: Badge + Ano + Curso
                    HStack(spacing: 8) {
                        Text(item.tipo.badgeLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.azulSecundario)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.azulSecundario.opacity(0.12))
                            .cornerRadius(4)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text("\(item.ano)")
                                .font(.system(size: 11.5))
                        }
                        .foregroundColor(Color.textoTerciario)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.system(size: 11))
                            Text(item.curso)
                                .font(.system(size: 11.5))
                        }
                        .foregroundColor(Color.textoTerciario)
                    }
                    
                    // Título Principal
                    Text(item.titulo)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(Color.textoPrincipal)
                        .lineSpacing(3)
                    
                    // Hero Card: Telemetria IoT ao vivo (Oficina de Mecânica)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("OFICINA DE MECÂNICA · AO VIVO")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text("ESP32 · Wi-Fi")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(4)
                        }
                        
                        // Representação do Gráfico de Ondas Sonoras e Medidor dB
                        HStack(alignment: .center, spacing: 16) {
                            // Gráfico de Barras com Limite
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 3) {
                                    ForEach(0..<18, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(i > 12 ? Color.ambarUFSM : Color.cyan.opacity(0.8))
                                            .frame(width: 5, height: CGFloat([22, 35, 18, 48, 62, 55, 40, 70, 80, 65, 45, 58, 75, 82, 60, 48, 30, 20][i % 18]))
                                    }
                                }
                                .frame(height: 70, alignment: .bottom)
                                
                                Text("Limite 85 dB(A)")
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundColor(Color.ambarUFSM)
                            }
                            
                            Spacer()
                            
                            // Medidor Circular 82 dB
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 5)
                                    .frame(width: 68, height: 68)
                                
                                Circle()
                                    .trim(from: 0.0, to: 0.75)
                                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 68, height: 68)
                                
                                VStack(spacing: 0) {
                                    Text("82")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("dB")
                                        .font(.system(size: 9.5, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.azulProfundo)
                    .cornerRadius(12)
                    
                    // Autores e Link Externo (LinkedIn)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.autores)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.textoPrincipal)
                        }
                        
                        Spacer()
                        
                        Link(destination: URL(string: item.linkPublicado ?? "https://linkedin.com")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11))
                                Text("LinkedIn")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color.azulSecundario)
                        }
                    }
                    
                    // Seção: | RESUMO
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitleView(title: "Resumo")
                        
                        Text(item.resumo)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.textoSecundario)
                            .lineSpacing(4)
                    }
                    
                    // Seção: | AVALIAÇÕES
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitleView(title: "Avaliações")
                        
                        HStack(alignment: .center, spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "%.1f", item.avaliacao).replacingOccurrences(of: ".", with: ","))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color.textoPrincipal)
                                
                                StarRatingView(rating: item.avaliacao, starSize: 13)
                                
                                Text("\(item.totalAvaliacoes) avaliações")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color.textoTerciario)
                            }
                            
                            Divider()
                                .frame(height: 54)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Avalie este projeto")
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(Color.textoPrincipal)
                                
                                StarRatingView(
                                    rating: Double(userRating),
                                    starSize: 18,
                                    isInteractive: true,
                                    onRate: { newRating in
                                        userRating = newRating
                                    }
                                )
                                
                                Text("Toque para dar sua nota")
                                    .font(.system(size: 10.5, weight: .regular))
                                    .foregroundColor(Color.textoTerciario)
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.bordaUFSM, lineWidth: 1)
                        )
                    }
                    
                    // Seções Inferiores: | ÁREA e | MATÉRIA
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitleView(title: "Área")
                            
                            HStack(spacing: 6) {
                                Image(systemName: "graduationcap")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.azulUFSM)
                                Text(item.area)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(Color.textoPrincipal)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.bordaUFSM, lineWidth: 1)
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitleView(title: "Matéria")
                            
                            HStack(spacing: 6) {
                                Image(systemName: "book")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.azulUFSM)
                                Text(item.materia)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(Color.textoPrincipal)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.bordaUFSM, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.fundoUFSM)
        }
    }
}
