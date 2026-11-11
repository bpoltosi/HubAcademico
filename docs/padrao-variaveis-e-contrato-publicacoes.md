# Padrão de nomenclatura e contrato de publicação

## Escopo desta etapa

Esta convenção prepara a migração da leitura e criação de publicações para IBM Cloudant. O catálogo acadêmico (áreas, subáreas, cursos e cadeiras) permanece mockado no código SwiftUI. Não criar banco de catálogo, endpoint de catálogo ou sincronização do catálogo nesta etapa.

## Convenções

| Camada | Convenção | Exemplos |
|---|---|---|
| Swift: tipos | PascalCase, singular | `Projeto`, `ProjetoService`, `ProjetosViewModel` |
| Swift: propriedades e funções | camelCase, português | `criadoEm`, `buscarProjetos()`, `publicarProjeto()` |
| JavaScript: variáveis/funções | camelCase, português | `projetoId`, `usuarioAtual`, `validarProjeto()` |
| JavaScript: constantes | UPPER_SNAKE_CASE | `LIMITE_PAGINA`, `NOME_BANCO_PROJETOS` |
| JSON/API | camelCase, português | `projetoId`, `imagemURL`, `criadoEm` |
| Banco Cloudant | um banco para conteúdo dinâmico | `hubacademico_projetos` |
| Documento Cloudant | prefixo + UUID estável | `projeto:<UUID>`, `avaliacao:<projetoId>:<usuarioId>` |
| Datas | ISO 8601 UTC | `2026-11-11T18:00:00Z` |

Evitar abreviações semânticas (`usr`, `proj`, `qtd`, `tmp`) e misturar português/inglês. Não renomear em massa o catálogo mockado nem os identificadores públicos existentes nesta etapa.

## Vocabulário canônico

| Conceito | Nome canônico |
|---|---|
| Publicação | `projeto` |
| Publicações | `projetos` |
| Usuário | `usuario` |
| Identificador do usuário | `usuarioId` |
| Avaliação | `avaliacao` |
| Identificador do projeto | `projetoId` |
| Catálogo acadêmico local | `CatalogoAreas` / modelos atuais do catálogo, sem migração |

## Contrato de publicação

O contrato REST existente em `/hub/projetos` deve ser preservado durante a transição. Campos já utilizados pelo app continuam com os nomes atuais: `id`, `tipo`, `titulo`, `descricao`, `autores`, `ano`, `area`, `subarea`, `curso`, `cadeira`, `instituicao`, `imagemURL`, `link`, `plataforma` e `criadoEm`. Campos adicionais existentes na resposta, como `nota`, `quant`, `minhaNota` e `meu`, não devem ser removidos sem uma alteração coordenada no Swift.

O identificador técnico Cloudant `_id` e a revisão `_rev` são detalhes internos. Não substituir o `id` de domínio no JSON público nem expor `_rev) ao aplicativo.

## Regras de mapeamento

- O app envia os dados da publicação selecionados a partir do catálogo local; não envia documentos do catálogo.
- O Node-RED gera o UUID e os campos controlados pelo servidor, como `criadoEm) e `usuarioId).
- O documento Cloudant recebe `_id = "projeto:" + id` e `tipoDocumento = "projeto"`.
- A resposta da API continua no formato que o Swift já decodifica.
- `area`, `subarea`, `curso` e `cadeira` são valores descritivos capturados no momento da publicação. Não são referências a documentos do Cloudant nesta arquitetura.

## Compatibilidade e evolução

Os caminhos REST existentes são contratos públicos. Não renomear `/hub/users` para `/hub/usuarios` nem `userId` para `usuarioId` em payloads legados sem versionamento. Internamente, preferir `usuario` e `usuarioId`; fazer o mapeamento em um único ponto.

Antes de acrescentar ou renomear um campo:
1. localizar todos os usos no Swift e no Node-RED;
2. definir o nome canônico e eventual alias de compatibilidade;
3. atualizar codificação/decodificação e validações;
4. atualizar testes de API e previews;
5. preservar o contrato das telas existentes.
