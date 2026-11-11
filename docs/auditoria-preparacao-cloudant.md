# Auditoria de preparação — publicações no IBM Cloudant

## Resultado executivo

A integração HTTP do aplicativo já existe parcialmente. O SwiftUI já chama o Node-RED para listar e publicar quando há um servidor configurado. O que ainda não existe é a persistência Cloudant: o backend atual mantém os dados em `global.hub_db`, e o fluxo importável contém um único nó Function que executa a API inteira.

Portanto, esta etapa prepara e congela os contratos para a próxima entrega (JSON importável do Node-RED). Ela **não declara a migração Cloudant concluída** e não troca a persistência do servidor antes de o fluxo Cloudant estar pronto.

## 1. Inventário verificado

### Aplicativo SwiftUI

| Arquivo | Responsabilidade observada |
|---|---|
| `HubAcademico/Servicos/ProducaoStore.swift` | Estado da lista; sincroniza por `APIClient.projetos()`; publica por `APIClient.publicar()`; trata avaliações e perfil. |
| `HubAcademico/Servicos/APIClient.swift` | Cliente HTTP, DTOs de GET/POST, cabeçalho `X-Hub-User`, decodificação de datas e erros. |
| `HubAcademico/Modelos/Producao.swift` | Modelo usado nas telas; contém tipo, área, subárea, matéria/cadeira, curso, autores e metadados. |
| `HubAcademico/Servicos/ServidorConfig.swift` | Lê o endereço do Node-RED nos Ajustes ou no Info.plist. |
| `HubAcademico/App/HubAcademicoApp.swift` | Cria e injeta o `ProducaoStore` compartilhado. |

**Comportamento atual do app:**
- Com URL de servidor válida: GET e POST passam pelo Node-RED. O arquivo local específico do servidor funciona como cache da lista e das notas, não como destino primário de uma publicação bem-sucedida.
- Sem servidor configurado: o app entra no modo local/demonstração, usando `hub-dados.json` e `DadosExemplo`.
- O catálogo acadêmico usado no formulário continua local no SwiftUI. Não deve ser movido para Cloudant.
- A integração já envia `X-Hub-User` após cadastrar/recuperar o perfil local do servidor.

**Conclusão:** não é necessário criar uma segunda camada HTTP no Swift. A camada existente deve ser preservada e testada contra o contrato congelado. A remoção do modo local/demonstração é uma decisão separada; o cache offline pode continuar existindo sem ser fonte primária.

### Node-RED

| Arquivo | Responsabilidade observada |
|---|---|
| `backend/node-red/src/api.js` | Todas as rotas REST; usa `global.get/set('hub_db')`. |
| `backend/node-red/src/seed.js` | Dados de demonstração e inicialização. |
| `backend/node-red/hub-academico-flows.json` | Fluxo importável atual. |
| `backend/node-red/montar-fluxo.js` | Copia `src/api.js` e `src/seed.js` para os Function nodes do JSON e compara rotas/cases. |
| `backend/node-red/testes/testar-fluxo.js` | Testa estrutura, rotas, contratos e persistência em contexto simulado. |
| `backend/node-red/README.md` | Instalação, rotas, filtros, modelo e operação atual. |

**Comportamento atual do backend:**
- A chave global `hub_db` contém `projetos`, `cadeiras`, `users` e `avaliacoes`.
- `GET /hub/projetos` retorna um array JSON, com filtros e ordenação.
- `POST /hub/projetos` exige `X-Hub-User`, valida os dados, cria UUID/data e retorna um objeto com HTTP 201.
- `nota` e `quant` são agregados de avaliações; `minhaNota` e `meu` dependem do usuário da requisição.
- A cadeira é atualmente relacionada por `cadeiraId` e apresentada como texto `cadeira`.
- O fluxo atual usa apenas nós do núcleo do Node-RED. Ainda não usa CloudantPlus.

## 2. Contratos congelados para o app

### GET /hub/projetos

- Método/rota: `GET /hub/projetos`.
- Resposta: array JSON de publicações.
- Filtros já existentes a preservar: `tipo`, `ano`, `area`, `subarea`, `curso`, `cadeira`, `autor`, `q`, `ordem=nota`, `limite`.
- Campos públicos: ver `backend/node-red/contratos/projeto-api.schema.json`.
- Campos derivados de avaliação e usuário não podem desaparecer: `nota`, `quant`, `minhaNota`, `meu`.

### POST /hub/projetos

- Método/rota: `POST /hub/projetos`.
- Cabeçalho: `Content-Type: application/json` e `X-Hub-User`.
- Corpo: ver `backend/node-red/contratos/projeto-criacao.schema.json`.
- Sucesso: HTTP 201 e um objeto no mesmo formato público do GET.
- O servidor controla `id` e `criadoEm); o app não deve inventá-los.
- O app só deve inserir a publicação na lista depois de receber a resposta de sucesso.

### Documento Cloudant

O formato técnico proposto está em `backend/node-red/contratos/projeto-cloudant.schema.json`:
- Banco: `hubacademico_projetos`.
- Um documento por publicação.
- `_id = "projeto:" + id`.
- `tipoDocumento = "projeto"`.
- `_rev` é controlado pelo Cloudant e nunca vai para o app.
- `usuarioId` é metadado interno para autoria; não deve ser exposto na resposta pública.
- `area`, `subarea`, `curso` e `cadeira` são snapshots textuais escolhidos no catálogo local. Não são foreign keys do catálogo.
- `cadeiraId` pode ser preservado como campo legado opcional, mas não deve obrigar a criação de uma coleção/banco de catálogo.

## 3. Dependências que o próximo workflow precisa resolver

A troca não pode consistir apenas em conectar o GET e POST a nós CloudantPlus e deixar o restante da API intocado:

1. `GET /hub/projetos/:id`, `DELETE /hub/projetos/:id` e `POST /hub/avaliacoes` atualmente consultam `db.projetos`.
2. Se o POST novo gravar somente no Cloudant, essas rotas legadas não encontrarão a publicação recém-criada.
3. `nota`, `quant` e `minhaNota` continuam dependendo da tabela `avaliacoes`; `meu` depende da identificação `X-Hub-User`.
4. `GET /hub/cadeiras` usa a relação atual de cadeiras para contar publicações.

**Regra para a próxima entrega:** preservar as rotas e funcionalidades existentes. O workflow deve definir uma única fonte de verdade para documentos de projeto no Cloudant e adaptar as rotas relacionadas que leem/escrevem projetos para essa fonte, mantendo usuários e avaliações no armazenamento atual nesta fase, se essa for a decisão de escopo. Não manter duas listas independentes de projetos que possam divergir.

## 4. Arquitetura a implementar no próximo JSON Node-RED

### GET /hub/projetos
1. HTTP In recebe query e cabeçalho `X-Hub-User`.
2. Function normaliza filtros, limite e identidade.
3. CloudantPlus consulta somente documentos `tipoDocumento = "projeto"` no banco `hubacademico_projetos`.
4. Function remove `_id`, `_rev` e campos internos; agrega avaliações existentes e calcula `nota`, `quant`, `minhaNota`, `meu`.
5. Function aplica os filtros/ordenação ainda não delegados ao Cloudant.
6. HTTP Response devolve array compatível com `ProjetoDTO`.

### POST /hub/projetos
1. HTTP In recebe JSON e `X-Hub-User`.
2. Function valida usuário e campos conforme o contrato atual.
3. Function gera UUID, `criadoEm`, `_id` e documento Cloudant.
4. CloudantPlus insere o documento.
5. Somente após confirmação da gravação, Function prepara DTO público (sem `_id`, `_rev` ou `usuarioId`).
6. HTTP Response devolve HTTP 201 e o DTO criado.

### Rotas relacionadas
O workflow deve adaptar GET por ID, DELETE, avaliações e contagem de cadeiras para consultar a fonte de verdade Cloudant, sem alterar seus caminhos e formatos públicos. Usuários/perfis continuam fora da migração de banco nesta fase.

## 5. Limites desta entrega

- Não criar banco para áreas, subáreas, cursos ou cadeiras.
- Não migrar CSVs nem catálogo acadêmico.
- Não mudar as telas SwiftUI ou renomear campos públicos.
- Não alterar autenticação/perfis e avaliações para outro modelo de dados sem decisão.
- Não inserir credenciais Cloudant no Git ou no app.
- Não substituir o fluxo existente até que o JSON Cloudant esteja testado e revisado.

## 6. Checklist de aceite para o próximo PR do workflow

- [ ] JSON importável no Node-RED com nós CloudantPlus reais.
- [ ] Configuração de conexão sem credenciais versionadas.
- [ ] GET lista documentos persistidos após reinício do Node-RED.
- [ ] POST só retorna 201 após confirmação de gravação.
- [ ] GET por ID, DELETE, avaliações e cadeiras continuam coerentes com a fonte Cloudant.
- [ ] Filtros, ordenação, limite e campos derivados permanecem compatíveis.
- [ ] Catálogo acadêmico continua local e funciona offline.
- [ ] Testes cobrem sucesso, payload inválido, usuário ausente, Cloudant indisponível e reinício.
- [ ] Fluxo JSON e código-fonte sincronizados.
