# AcadHub · Repositório Acadêmico Online
### Design System de ufsm.br · HackaTruck MakerSpace · Deploy 26.1
**Frontend nativo desenvolvido em Swift (SwiftUI) para iOS 16.0+, 17.0+ e 18.0+**

Este repositório contém a implementação completa do aplicativo acadêmico do CTISM/UFSM em **Swift nativo (SwiftUI)** pronto para compilar e rodar no Simulador iPhone do Xcode com 1 clique.

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
