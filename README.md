# CTIA · Repositório Acadêmico do CTISM
### Design System de ufsm.br · HackaTruck MakerSpace · Deploy 26.1
**Frontend nativo desenvolvido em Swift (SwiftUI) para iOS 16.0+, 17.0+ e 18.0+**

Este repositório contém a implementação completa do frontend em **Swift (SwiftUI)** das 4 telas do aplicativo acadêmico do CTISM/UFSM:

1. **Início (`HomeView.swift`)**: Menu de acesso rápido com ordenação estritamente crescente de caracteres (8 → 22) e destaque no botão de cadastro.
2. **Busca e filtros (`SearchFilterView.swift`)**: Campo de busca ativo para "ruído", funil de filtros em checkbox (3 → 16 caracteres) com raio de 5 pt e ativo em Azul UFSM `#21376B`.
3. **Visualização (`DetailView.swift`)**: Detalhes do projeto com telemetria IoT ao vivo da Oficina Mecânica (gráfico sonoro, limite 85 dB(A), 82 dB), resumo, marcadores dourados e avaliação interativa.
4. **Cadastro (`CreateItemView.swift`)**: Formulário unificado (Projeto, Trabalho ou Prova) com contador dinâmico limitado a 200 caracteres (`176/200`) e botões de ação.

---

## 📁 Estrutura de Arquivos Swift (Swift Package Manager / Xcode)

```
├── Package.swift                                # Manifesto oficial do Swift Package Manager
├── CTIA_Combined.swift                          # Arquivo único consolidado (Drop-in para Xcode)
├── Sources/
│   └── CTIA/
│       ├── App/
│       │   └── CTIAApp.swift                    # Entry point @main e container de navegação
│       ├── Theme/
│       │   ├── Colors.swift                     # Tokens de cores de ufsm.br (#21376B, #204C90, #CC8F00, #FFC107)
│       │   ├── Typography.swift                 # Escala tipográfica da fonte Rawline
│       │   └── DesignSystem.swift               # Estilos de botões, raios e constantes
│       ├── Models/
│       │   ├── AcademicType.swift               # Enum (.projeto, .trabalho, .prova)
│       │   ├── AcademicItem.swift               # Struct com telemetria e metadados
│       │   └── MockData.swift                   # Dados mockados oficiais do CTISM
│       └── Views/
│           ├── Components/
│           │   ├── CTIAHeader.swift             # Cabeçalho com brasão e filete dourado de 2 pt
│           │   ├── CTIACheckbox.swift           # Checkbox raio 5 pt e cor Azul UFSM
│           │   ├── StarRatingView.swift         # Estrelas âmbar interativas e estáticas
│           │   └── SectionTitleView.swift       # Marcador dourado (| SEÇÃO)
│           ├── Home/
│           │   └── HomeView.swift               # Tela 1: Início (8 -> 22 caracteres)
│           ├── Search/
│           │   └── SearchFilterView.swift       # Tela 2: Busca e filtros (3 -> 16 caracteres)
│           ├── Detail/
│           │   └── DetailView.swift             # Tela 3: Visualização (IoT 82 dB e Avaliações)
│           └── Create/
│               └── CreateItemView.swift         # Tela 4: Cadastro (Contador 200 chars)
└── Tests/
    └── CTIATests/
        └── AcademicModelsTests.swift            # Testes unitários XCTest das regras de negócio
```

---

## 🚀 Como Executar no Xcode

### Opção 1: Arquivo Único (Mais Rápido)
1. Abra o **Xcode** no macOS e crie um novo projeto: **iOS > App** (Interface: **SwiftUI**, Language: **Swift**).
2. Abra o arquivo `ContentView.swift` criado pelo Xcode.
3. Substitua todo o conteúdo pelo arquivo `CTIA_Combined.swift` deste repositório.
4. Execute no Simulador iPhone 15/16 (`Cmd + R`) ou veja instantaneamente no Canvas Preview (`Opt + Cmd + Enter`).

### Opção 2: Como Pacote SPM (Modular)
1. No Xcode, selecione **File > Open...** e abra a pasta do repositório (contendo o `Package.swift`).
2. O Xcode resolverá automaticamente o pacote `CTIA` com todas as Views e Testes prontos.
3. Execute os testes unitários com `Cmd + U`.

---

## 🎨 Especificações do Design System (ufsm.br)

- **Cores:**
  - Azul UFSM: `#21376B` (cabeçalho, títulos, botões primários)
  - Azul Secundário: `#204C90` (ícones e rótulos do menu)
  - Azul Profundo: `#142140` (fundos de destaque)
  - Dourado: `#CC8F00` (filete do cabeçalho de 2 pt, marcadores)
  - Âmbar: `#FFC107` (estrelas de avaliação)
  - Fundo: `#F1F4F9` (bordas `#D3D7E1`, superfícies `#FFFFFF`)
- **Raios de Curvatura:** 10 pt em botões e campos, 14 pt em cards, 16 pt no menu, 5 pt em checkboxes.
- **Margens:** Margem lateral de 16 pt, grade de 8 pt e área de toque mínima de 44 pt.
