# Hub Acadêmico no Node-RED: API e banco no Cloudant

Este fluxo transforma o Node-RED no servidor do Hub Acadêmico. Ele segue o mesmo formato do fluxo da equipe:

- cada rota é **http in → function → cloudantplus → … → http response**;
- as rotas têm o nome no padrão **GET/POST/UPDATE/DELETE + nome**, por exemplo `GETpublicacoes`, `POSTpublicacao`, `UPDATEpublicacao` e `DELETEpublicacao`;
- os dados ficam no banco **`hub-academico-10` do Cloudant**, com a mesma configuração do Cloudant que a equipe já usa.

O app iOS usa essas rotas para listar, publicar e avaliar. Elas também servem para cadastrar e atualizar o usuário.

| Arquivo | O que é |
|---|---|
| `hub-academico-flows.json` | Fluxo para importar no Node-RED |
| `cloudant-config.json` | Só o nó de configuração do Cloudant, para um Node-RED que ainda não o tem (sem a API key) |
| `src/comum.js` | Funções comuns: validação, formato das respostas, lista de subáreas do CNPq |
| `src/exemplos.js` | As 12 publicações de exemplo (as mesmas do app) |
| `src/rotas/*.js` | O código de cada nó **function** |
| `montar-fluxo.js` | Monta os dois arquivos `.json` a partir de `src/` |
| `testes/testar-fluxo.js` | 48 testes que rodam o fluxo com um Cloudant simulado |

---

## Como instalar

### 1. Node-RED com os nós do Cloudant

O fluxo usa só nós do núcleo do Node-RED e os nós **cloudantplus**, os mesmos do fluxo da equipe. Se a paleta ainda não tiver os nós cloudantplus, instale-os em ☰ › **Manage palette** › **Install** › `node-red-contrib-cloudantplus`.

### 2. Importar o fluxo

1. No editor (http://localhost:1880), abra ☰ › **Import** e escolha `hub-academico-flows.json`.
2. Clique em **Import** e depois em **Deploy**.
3. Vai aparecer a aba **Hub Acadêmico – Cloudant**. Na barra de depuração (🐞) deve surgir a mensagem *“Cloudant conectado: …”*.
4. Se o banco não tiver nenhuma publicação, as 12 publicações de exemplo são criadas em seguida, em uns 3 segundos.

Se os nós do Cloudant aparecerem com um **triângulo vermelho**, este Node-RED não tem a configuração do Cloudant da equipe (é o caso de outro computador):

1. Importe também `cloudant-config.json`.
2. Abra ☰ › **Configuration nodes** › **cloudantplus**.
3. Cole a **API key**: IBM Cloud › Resource list › Cloudant › **Service credentials** › `apikey`.
4. Clique em **Update** e em **Deploy**.

**Fluxos antigos:** a versão anterior do Hub Acadêmico (rotas `/hub/...`, dados no contexto do Node-RED) pode ser apagada. As publicações gravadas nela não passam sozinhas para o Cloudant. O fluxo de rascunho da equipe (`GETprojetos`…) também pode ficar ou sair: as rotas não se misturam.

### 3. Testar no navegador

Abra **http://localhost:1880/GETstatus**. A resposta deve ser parecida com:

```json
{ "ok": true, "servico": "Hub Acadêmico", "banco": "Cloudant", "totais": { "publicacoes": 12, "disciplinas": 10, "usuarios": 0, "avaliacoes": 0 } }
```

### 4. Ligar o app

O link do servidor fica nos **Ajustes do iPhone**: **Ajustes › Apps › Hub Acadêmico › Link do servidor**. No iOS 17, o caminho é **Ajustes › Hub Acadêmico**. Digite o link e volte ao app: a lista é atualizada na hora.

| Onde o app roda | Link do servidor |
|---|---|
| Simulador do Xcode, no mesmo Mac | `localhost:1880` |
| iPhone na mesma rede Wi-Fi | `IP-DO-MAC:1880` (veja o IP com `ipconfig getifaddr en0`) |
| Node-RED na nuvem | `https://seu-node-red` |

Para que todos os aparelhos da turma já abram ligados ao servidor, preencha a chave **`HubServidorLink`** em `Config/HubAcademico-Info.plist` antes de compilar. Na primeira abertura, ela é copiada para o campo dos Ajustes.

No dia da apresentação, o computador do Node-RED **não pode hibernar** (`caffeinate -di` no Terminal) e precisa de internet para falar com o Cloudant.

---

## O banco no Cloudant

Um banco só, `hub-academico-10`, como no fluxo da equipe. O campo **`colecao`** diz o que cada documento guarda:

| colecao | Campos | Observação |
|---|---|---|
| `publicacao` | `_id`, `tipo`, `titulo`, `descricao`, `autores`, `ano`, `area`, `subarea`, `disciplina`, `curso`, `instituicao`, `link`, `plataforma`, `imagemLink`, `usuarioId`, `criadoEm` | `_id` no formato UUID. `usuarioId` nunca sai nas respostas. |
| `avaliacao` | `_id` = `avaliacao:<publicação>:<usuário>`, `publicacaoId`, `usuarioId`, `nota` | O `_id` fixo garante **uma avaliação por pessoa**; avaliar de novo troca a nota. |
| `usuario` | `_id`, `nome`, `curso`, `criadoEm` | O `_id` é a chave do aparelho (cabeçalho `X-Hub-Usuario`). |

- **Média e total:** `media` e `totalAvaliacoes` são calculados a cada consulta, a partir das avaliações. As publicações de exemplo trazem `avaliacoesBase` (soma e total), que entram na conta junto com as avaliações reais. Assim os exemplos mostram as mesmas médias do app.
- **Documentos sem `colecao`:** documentos do rascunho da equipe (com `cadeira`, sem `colecao`) e outros testes não aparecem no app.
- **Índices:** as consultas não usam `sort`, que no Cloudant exige um índice criado antes. A ordem é feita no Node-RED. Todas as consultas informam o limite, porque sem ele o Cloudant devolve só 25 documentos.

Diagrama para a apresentação: [`docs/banco-de-dados.png`](../../docs/banco-de-dados.png).

| No rascunho da equipe | Agora |
|---|---|
| `GETprojetos`, `POSTprojeto`, `UPDATEprojeto`, `DELETEprojeto` | `GETpublicacoes`, `POSTpublicacao`, `UPDATEpublicacao`, `DELETEpublicacao` |
| filtro `cadeira` | filtro `disciplina` (`cadeira` continua aceito) |
| `sort: [{ ano: "desc" }]` na consulta | ordem feita no Node-RED (sem índice no Cloudant) |
| `limit: 100` | limite de 5.000 por consulta |

---

## Rotas da API

Todas as respostas são JSON. Os erros vêm como `{ "erro": "…", "detalhes": ["campo: motivo"] }`.

| Método | Rota | Para quê | Precisa de |
|---|---|---|---|
| GET | `/GETstatus` | Testar a conexão e ver os totais | — |
| GET | `/GETpublicacoes` | Listar (filtros abaixo) | — |
| POST | `/POSTpublicacao` | Publicar | `X-Hub-Usuario` |
| PUT | `/UPDATEpublicacao?id=…` | Alterar campos de uma publicação | quem publicou ou `X-Hub-Moderacao` |
| DELETE | `/DELETEpublicacao?id=…` | Remover | quem publicou ou `X-Hub-Moderacao` |
| POST | `/POSTavaliacao` | Dar nota de 1 a 5; avaliar de novo troca a nota | `X-Hub-Usuario` |
| POST | `/POSTusuario` | Cadastrar usuário (devolve o `id`) | — |
| GET | `/GETusuario` | Ver o próprio usuário | `X-Hub-Usuario` |
| PUT | `/UPDATEusuario` | Trocar nome e curso | `X-Hub-Usuario` |
| GET | `/GETdisciplinas` | Disciplinas usadas, com o total de publicações | — |
| GET | `/GETsubareas` | Subáreas de cada área (tabela do CNPq) | — |

**Filtros de `GET /GETpublicacoes`** (todos opcionais):
- `tipo`, `ano`, `area`, `subarea`, `curso`;
- `disciplina` (ou `cadeira`), `titulo` e `autor`: trechos do nome, sem diferenciar acentos;
- `q`: texto livre;
- `ordem=media`: mais bem avaliadas primeiro;
- `limite`.

**Ao publicar:**
- `area` é obrigatória, e `subarea` precisa ser uma das subáreas dela. A comparação não diferencia acentos nem maiúsculas, e o banco guarda a grafia oficial.
- `disciplina` aceita de 2 a 150 caracteres.

Cada publicação vem assim:

```json
{
  "id": "3C657F19-D52A-5F45-AE46-BC31046D13C3",
  "tipo": "projeto",
  "titulo": "Monitor IoT de ruído nas oficinas do CTISM",
  "descricao": "Protótipo com ESP32 e sensor de som…",
  "imagemLink": "asset://imagem-monitor-ruido",
  "link": "https://example.com/hub-academico/monitor-ruido",
  "plataforma": "linkedin",
  "area": "engenharias",
  "subarea": "Engenharia de Produção",
  "disciplina": "Higiene Ocupacional",
  "curso": "Técnico em Segurança do Trabalho",
  "instituicao": "CTISM – UFSM",
  "ano": 2026,
  "autores": ["Ana Clara Machado", "Lucas Ferreira"],
  "media": 4.81,
  "totalAvaliacoes": 37,
  "minhaNota": null,
  "meu": false,
  "criadoEm": "2026-11-09T16:02:00Z"
}
```

`minhaNota` e `meu` só são preenchidos quando a requisição traz o cabeçalho `X-Hub-Usuario`.

### Exemplos com curl

```bash
BASE=http://localhost:1880

# 1. Cadastrar um usuário e guardar o "id" da resposta
curl -s -X POST $BASE/POSTusuario -H 'Content-Type: application/json' \
  -d '{"nome":"Ana Clara Machado","curso":"Técnico em Segurança do Trabalho"}'
USUARIO=cole-aqui-o-id

# 2. Publicar
curl -s -X POST $BASE/POSTpublicacao -H 'Content-Type: application/json' -H "X-Hub-Usuario: $USUARIO" \
  -d '{"tipo":"projeto","titulo":"Sensor de gás com alerta no celular",
       "descricao":"Protótipo com sensor MQ-2 e ESP32 que avisa no celular quando detecta vazamento de gás.",
       "area":"engenharias","subarea":"Engenharia Elétrica","disciplina":"Sistemas Embarcados","ano":2026,
       "curso":"Técnico em Segurança do Trabalho","autores":["Ana Clara Machado"],
       "link":"https://www.linkedin.com/posts/exemplo","plataforma":"linkedin"}'

# 3. Avaliar (troque PUBLICACAO pelo id de uma publicação)
curl -s -X POST $BASE/POSTavaliacao -H 'Content-Type: application/json' -H "X-Hub-Usuario: $USUARIO" \
  -d '{"publicacaoId":"PUBLICACAO","nota":5}'

# 4. Listar as provas, das mais bem avaliadas para as menos
curl -s "$BASE/GETpublicacoes?tipo=prova&ordem=media"

# 5. Alterar o título da própria publicação
curl -s -X PUT "$BASE/UPDATEpublicacao?id=PUBLICACAO" -H 'Content-Type: application/json' -H "X-Hub-Usuario: $USUARIO" \
  -d '{"titulo":"Sensor de gás com alerta no celular (versão 2)"}'
```

### Botões do fluxo (nós inject)

| Botão | O que faz |
|---|---|
| **Ao implantar: testa a conexão** | Roda sozinho a cada Deploy e mostra os totais na depuração. Se o banco não tiver nenhuma publicação, cria os exemplos. |
| **Criar ou restaurar exemplos** | Grava de novo as 12 publicações de exemplo, com as médias originais. Grava 4 por segundo, por causa do limite de gravações do plano Lite do Cloudant. |
| **Remover exemplos** | Apaga só as publicações de exemplo; as publicadas pela turma ficam. Com o banco sem nenhuma publicação, os exemplos voltam no próximo Deploy. |

---

## Erros

Qualquer erro do Cloudant ou do fluxo cai no nó **catch**. O app recebe uma resposta JSON, nunca uma requisição sem resposta. O detalhe também aparece na depuração.

| Situação | Resposta | Mensagem no app |
|---|---|---|
| API key errada ou sem permissão | 502 | “O Cloudant recusou o acesso. Confira a API key…” |
| Limite de requisições do plano Lite | 503 | “O Cloudant pediu para esperar… Tente de novo em alguns segundos.” |
| Duas gravações ao mesmo tempo | 409 | “Outra pessoa alterou este registro ao mesmo tempo. Tente de novo.” |
| Computador do Node-RED sem internet | 502 | “Sem conexão com o Cloudant…” |

O plano Lite do Cloudant limita leituras, gravações e consultas por segundo. Cada atualização da lista no app faz 2 consultas, e publicar ou avaliar faz 2 consultas e 1 gravação. Isso dá folga para a turma usar o app ao mesmo tempo.

---

## Segurança e privacidade

- **API key:** fica só no Node-RED, no arquivo de credenciais (`flows_cred.json`), e nunca vai para o app nem para o fluxo exportado. Não publiquem esse arquivo no GitHub.
- **Quem é quem:** não há login nesta versão. O app cadastra o usuário em `POST /POSTusuario` e guarda o `id` recebido, que funciona como a chave daquele aparelho. Por isso o `id` dos usuários **nunca aparece nas listas**: no lugar dele vai o campo `meu`.
- **Moderação:** defina a variável de ambiente `HUB_MODERACAO_TOKEN` com uma chave longa ao iniciar o Node-RED (`HUB_MODERACAO_TOKEN=uma-chave-longa node-red`) e envie o mesmo valor no cabeçalho `X-Hub-Moderacao`. Sem a variável, a moderação fica desligada.
- **Editor protegido:** em uma rede compartilhada, ative a senha do editor no `settings.js` (opção `adminAuth` do Node-RED) para que ninguém altere o fluxo.
- **HTTPS:** o `Config/HubAcademico-Info.plist` libera `http://` para o laboratório. Em produção, use HTTPS e retire essa exceção.
- **LGPD:** o banco guarda nome, curso e as autorias informadas. Avisem os(as) estudantes sobre isso no app e combinem com a coordenação quem atende pedidos de remoção (a rota `DELETEpublicacao` já existe).

---

## Testes

```bash
node backend/node-red/testes/testar-fluxo.js
```

O teste roda o fluxo como o Node-RED, sem precisar dele nem do Cloudant:
- entrega as mensagens pelas ligações;
- executa o código dos nós **function**;
- manda os erros para o nó **catch**;
- responde pelos nós **http response**.

Os nós **cloudantplus** usam um Cloudant em memória, com as mesmas regras:
- limite padrão de 25 documentos por consulta;
- `sort` só com índice;
- conflito ao gravar sem a `_rev`;
- `_id` e `_rev` obrigatórios para apagar.

A consulta é testada nas duas formas de resposta do nó: `{ docs: [...] }` e a lista de documentos. O teste também confere se alguma requisição ficou sem resposta.

**Ao alterar o código:**
1. Edite os arquivos em `src/`.
2. Rode `node backend/node-red/montar-fluxo.js`.
3. Reimporte o fluxo no Node-RED.

O teste avisa se o `hub-academico-flows.json` estiver desatualizado em relação a `src/`.

Cada nó **function** recebe só as declarações de `src/comum.js` que usa (e as que elas usam). Assim, o fluxo fica com cerca de 180 KB, e cada nó mostra no editor só o código que importa. Escreva cada nova declaração começando na coluna 0, com o comentário logo acima dela.

A lista `SUBAREAS` de `src/comum.js` é gerada junto com o catálogo do app: rode `python3 ferramentas/catalogo/gerar_catalogo.py` na raiz do repositório. Não a edite à mão.
