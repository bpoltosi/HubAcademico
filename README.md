# CTIA · Repositório Acadêmico do CTISM
### Design System de ufsm.br · HackaTruck MakerSpace · Deploy 26.1
**Frontend nativo desenvolvido em Swift (SwiftUI) para iOS 16.0+, 17.0+ e 18.0+**

Este repositório contém a implementação completa do aplicativo acadêmico do CTISM/UFSM em **Swift nativo (SwiftUI)** pronto para compilar e rodar no Simulador iPhone do Xcode com 1 clique.

---

## 🚀 Como Executar ("Build and Run") no Xcode e Simulador iPhone

Ao clonar este repositório no seu Mac (`git clone <url>`), você tem 3 maneiras imediatas de rodar:

### Opção 1: Projeto Xcode Completo (Recomendado — 1 Clique)
1. Dê um duplo clique no arquivo **`CTIA.xcodeproj`** (ou execute no terminal: `open CTIA.xcodeproj`).
2. O Xcode abrirá com o Scheme **`CTIA`** e um simulador (ex: **iPhone 16**) já selecionados.
3. Pressione **`Cmd + R`** (ou clique no botão **Play / Run** no topo do Xcode).
4. O Xcode compilará o app, abrirá o Simulador do iPhone e instalará o aplicativo **CTIA** automaticamente.

---

### Opção 2: Automação por Terminal ou Finder (Build & Run Automático)
Se preferir não abrir o Xcode manualmente:
- **Pelo Finder**: Dê um duplo clique no arquivo executável **`RunInSimulator.command`**.
- **Pelo Terminal**: Execute:
  ```bash
  ./run_simulator.sh
  ```
O script verifica o ambiente, inicializa o simulador do iPhone, compila o projeto nativo via `xcodebuild`, instala o pacote `CTIA.app` e abre a tela inicial do aplicativo no simulador.

---

### Opção 3: Como Pacote SPM (Swift Package Manager)
1. No Xcode: selecione **File > Open...** e selecione a pasta raiz do repositório (onde está o `Package.swift`).
2. O Xcode resolverá automaticamente as dependências e o alvo `CTIA`.
3. Pressione **`Cmd + U`** para executar todos os testes unitários do catálogo acadêmico (`AcademicModelsTests.swift`).

---

### Opção 4: Arquivo Consolidado (Single File)
Para prototipagem rápida ou playgrounds: copie o código do arquivo **`CTIA_Combined.swift`** e cole diretamente no arquivo `ContentView.swift` de qualquer projeto SwiftUI no Xcode.

---

## 📁 Estrutura do Repositório

```
├── CTIA.xcodeproj/                              # Projeto oficial nativo do Xcode
│   ├── project.pbxproj                         # Configurações de alvos iOS 16+, bundle id e compilação
│   └── xcshareddata/xcschemes/CTIA.xcscheme    # Scheme compartilhado (Build & Run imediato)
├── CTIA/
│   ├── Info.plist                              # Configurações do app (DisplayName, Orientações, Categoria)
│   └── Assets.xcassets/                        # Catálogo de ativos (AppIcon e AccentColor #21376B)
├── run_simulator.sh                            # Script bash de compilação, instalação e abertura no simulador
├── RunInSimulator.command                      # Atalho para rodar com duplo clique no macOS
├── Package.swift                               # Manifesto oficial do Swift Package Manager
├── CTIA_Combined.swift                         # Arquivo consolidado All-in-One para Xcode
├── Sources/
│   └── CTIA/
│       ├── App/
│       │   └── CTIAApp.swift                   # Entry point @main e container de navegação
│       ├── Logic/
│       │   └── AcademicCatalogLogic.swift      # Validações, ordenação de caracteres (8->22 e 3->16) e filtros
│       ├── Theme/
│       │   ├── Colors.swift                    # Cores oficiais de ufsm.br (#21376B, #204C90, #CC8F00, #FFC107)
│       │   ├── Typography.swift                # Escala tipográfica da fonte Rawline
│       │   └── DesignSystem.swift              # Estilos de botões, raios e constantes de layout
│       ├── Models/
│       │   ├── AcademicType.swift              # Enum (.projeto, .trabalho, .prova)
│       │   ├── AcademicItem.swift              # Struct com telemetria e metadados
│       │   └── MockData.swift                  # Dados mockados oficiais do CTISM
│       └── Views/
│           ├── Components/
│           │   ├── CTIAHeader.swift            # Cabeçalho com brasão e filete dourado de 2 pt
│           │   ├── CTIACheckbox.swift          # Checkbox raio 5 pt e cor Azul UFSM
│           │   ├── StarRatingView.swift        # Estrelas âmbar interativas e estáticas
│           │   └── SectionTitleView.swift      # Marcador dourado (| SEÇÃO)
│           ├── Home/
│           │   └── HomeView.swift              # Tela 1: Início (8 -> 22 caracteres)
│           ├── Search/
│           │   └── SearchFilterView.swift      # Tela 2: Busca e filtros (3 -> 16 caracteres)
│           ├── Detail/
│           │   └── DetailView.swift            # Tela 3: Visualização (IoT 82 dB e Avaliações)
│           └── Create/
│               └── CreateItemView.swift        # Tela 4: Cadastro (Contador 200 chars)
└── Tests/
    └── CTIATests/
        └── AcademicModelsTests.swift           # Testes unitários XCTest das regras de negócio
```

---

## 🛡️ Organização do `.gitignore`

O arquivo `.gitignore` foi rigorosamente estruturado em seções para garantir que os arquivos do aplicativo não se misturem com arquivos auxiliares do ambiente de desenvolvimento:

1. **Artefatos do Xcode e macOS:**
   - `DerivedData/`, `build/`, `.build/`, `.swiftpm/`
   - Configurações locais de usuário (`xcuserdata/`, `*.xcuserdatad`, `*.xcuserstate`)
   - Arquivos do sistema macOS (`.DS_Store`, `._*`)
2. **Ambiente Web / Servidor de Preview:**
   - `node_modules/`, `dist/`, `.cache/`, logs e caches locais
3. **Arquivos temporários e storage:**
   - `.tempmediaStorage/`, variáveis locais `.env*`

---

## 🎨 Especificações do Design System (ufsm.br)

- **Cores Oficiais:**
  - **Azul UFSM:** `#21376B` (cabeçalho, títulos, botões primários)
  - **Azul Secundário:** `#204C90` (ícones e rótulos do menu)
  - **Azul Profundo:** `#142140` (fundos de destaque e IoT)
  - **Dourado:** `#CC8F00` (filete do cabeçalho de 2 pt, marcadores)
  - **Âmbar:** `#FFC107` (estrelas de avaliação)
  - **Fundo:** `#F1F4F9` (bordas `#D3D7E1`, superfícies `#FFFFFF`)
- **Raios de Curvatura:**
  - 10 pt em botões e campos de entrada
  - 14 pt em cartões de conteúdo
  - 16 pt nos cartões do menu de acesso rápido
  - 5 pt em caixas de seleção (checkboxes)
- **Regras de Negócio e Validação:**
  - Ordem estritamente crescente de caracteres no menu: 8 → 22
  - Ordem crescente nos filtros: 3 → 16
  - Resumo de cadastro com contador dinâmico e limite máximo de 200 caracteres.
