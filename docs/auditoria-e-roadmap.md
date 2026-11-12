# Auditoria geral e roadmap de evolução

> **Base da análise:** branch `main`, revisada em 12/11/2026.  
> **Natureza:** auditoria estática do código e da documentação versionados. Este documento registra constatações verificadas e recomendações; não significa que as melhorias propostas já estejam implementadas.

## Objetivo

Consolidar em um único lugar os pontos de evolução do Hub Acadêmico nas frentes de segurança, arquitetura, confiabilidade, experiência de uso e colaboração. O documento serve como referência para transformar melhorias em Issues e PRs menores, revisáveis e com critérios de aceite claros.

## 1. Visão geral da arquitetura atual

O repositório contém:

- **Aplicativo iOS em SwiftUI**, com alvo mínimo iOS 17, telas, modelos, Design System e serviços separados.
- **Camada de comunicação REST** em `HubAcademico/Servicos/APIClient.swift`.
- **Configuração do servidor** em `ServidorConfig.swift`, com endereço padrão no `Config/HubAcademico-Info.plist` e possibilidade de alteração nos Ajustes do iPhone.
- **Persistência local e sincronização** em `PublicacaoStore.swift`, com modo de demonstração local e cópia local dos dados obtidos do servidor.
- **Backend Node-RED + Cloudant**, com o fluxo importável `backend/node-red/NodeRed-Flow-Final.json`, funções compartilhadas e arquivos separados por rota.
- **Catálogos acadêmicos locais**, incluindo áreas, subáreas, cursos e disciplinas.
- **Testes de fluxo em Node.js**, executados pelo script `backend/node-red/testes/testar-fluxo.js`.

A arquitetura já tem separação útil entre interface, modelos, serviços e backend. A recomendação é evoluir esses limites sem introduzir uma segunda camada de rede ou duplicar responsabilidades existentes.

## 2. Segurança

### 2.1. Restringir o tráfego HTTP e a configuração do ATS

**Constatação**

- `Config/HubAcademico-Info.plist` declara `NSAllowsArbitraryLoads = true`, uma exceção ampla do App Transport Security.
- O endereço padrão `HubServidorLink` aponta para um IP privado e porta HTTP do Node-RED.
- `ServidorConfig.swift` permite alterar o endereço e também aceita endereços HTTPS.

**Risco**

A exceção global permite conexões HTTP sem restringi-las ao servidor local de desenvolvimento. Isso é conveniente durante testes na rede do laboratório, mas não é uma configuração adequada para uma versão de produção.

**Recomendação**

1. Separar configuração de desenvolvimento e produção.
2. Usar HTTPS no ambiente publicado, com certificado válido.
3. Remover a exceção global de ATS em produção.
4. Se HTTP local continuar necessário para desenvolvimento, documentar e restringir a exceção ao cenário estritamente necessário, sem ampliar a permissão para todos os destinos.

**Critérios de aceite**

- [ ] O build de produção não depende de `NSAllowsArbitraryLoads = true`.
- [ ] O endereço de produção usa HTTPS.
- [ ] O modo local de desenvolvimento continua documentado e testável.
- [ ] A alteração é validada em iPhone físico e simulador.

### 2.2. Substituir identificação simples por autenticação real

**Constatação**

- O app envia o identificador no cabeçalho `X-Hub-Usuario`.
- O backend obtém esse valor em `usuarioInformado()` e o utiliza para identificar autoria.
- `novoId()`, em `backend/node-red/src/comum.js`, monta UUIDs usando `Math.random()`.
- O cadastro de usuário grava nome, curso e identificador, mas não estabelece uma sessão autenticada.
- A moderação usa `HUB_MODERACAO_TOKEN`, lido de variável de ambiente, por meio do cabeçalho `X-Hub-Moderacao`.

**Risco**

O UUID funciona como identificador, não como prova robusta de identidade. Se um identificador for obtido por terceiros, o cabeçalho pode ser reproduzido. Além disso, `Math.random()` não é um gerador criptograficamente seguro e não deve ser usado para criar credenciais ou identificadores cuja imprevisibilidade seja requisito de segurança.

**Recomendação**

1. Substituir a geração de identificadores por `crypto.randomUUID()` ou mecanismo criptograficamente seguro equivalente no runtime utilizado.
2. Definir um mecanismo de autenticação ou token de sessão, validado pelo backend; não confiar apenas em um ID enviado pelo cliente.
3. Guardar credenciais de sessão no Keychain do iOS, não em `UserDefaults`.
4. Manter o token de moderação somente no ambiente do servidor, nunca no app ou em arquivos versionados.
5. Adicionar limites de requisições e controles contra abuso nos endpoints de cadastro, publicação, avaliação e exclusão.

**Critérios de aceite**

- [ ] O backend consegue autenticar a identidade antes de autorizar operações protegidas.
- [ ] A autoria não depende exclusivamente de um identificador arbitrário enviado no cabeçalho.
- [ ] Tokens não são gravados em texto simples em `UserDefaults`.
- [ ] Os testes cobrem usuário ausente, token inválido, usuário tentando alterar conteúdo de outra pessoa e acesso de moderação.

### 2.3. Proteger a instalação do Node-RED

**Constatação**

O repositório documenta a instalação do fluxo, mas não contém a configuração operacional completa do servidor Node-RED. Portanto, não foi possível confirmar, apenas pelo repositório, se o editor administrativo está protegido por autenticação, HTTPS e regras de rede.

**Recomendação**

- Ativar autenticação administrativa do Node-RED.
- Não expor a porta 1880 diretamente à internet.
- Restringir o acesso por firewall ou proxy reverso.
- Publicar a API por HTTPS.
- Manter o Cloudant acessível apenas pelo backend.
- Aplicar uma credencial Cloudant com permissões mínimas necessárias.

**Critérios de aceite**

- [ ] O editor Node-RED exige autenticação.
- [ ] O acesso administrativo não fica aberto publicamente.
- [ ] A API pública e o editor administrativo têm políticas de acesso distintas.
- [ ] O procedimento de implantação documenta essas proteções.

### 2.4. Evitar exposição de detalhes internos em erros

**Constatação**

`backend/node-red/src/rotas/erro.js` inclui o detalhe bruto do erro em `detalhes` na resposta JSON. O `APIClient.swift` pode exibir esse conteúdo ao usuário.

**Risco**

Mensagens internas do Cloudant, da infraestrutura ou do fluxo podem revelar informações desnecessárias para quem consome a API.

**Recomendação**

Retornar mensagens públicas genéricas e um identificador de ocorrência. Manter a causa detalhada somente nos logs protegidos do servidor.

**Critérios de aceite**

- [ ] A resposta pública não contém credenciais, URLs internas, stack traces ou mensagens brutas do provedor.
- [ ] O log do servidor mantém informação suficiente para diagnóstico.
- [ ] O app apresenta uma mensagem compreensível e não técnica.

### 2.5. Formalizar papéis e permissões de publicação

**Constatação**

- Em `Publicacao.swift`, `TipoPublicacao.publicaveis` permite Projeto, Trabalho e Prova; o comentário informa que Material Complementar é destinado a professores.
- O backend declara `material` entre os tipos aceitos.
- O cadastro atual de usuário armazena nome e curso, sem um papel explícito de estudante, professor ou moderador.
- A autorização para publicar provas aparece como aviso na interface, mas não há, no contrato atual de usuário, uma verificação de autorização docente.

**Risco**

Uma regra apresentada apenas na interface pode ser contornada por uma chamada direta à API. A regra de negócio precisa ser aplicada também no backend.

**Recomendação**

Definir formalmente os papéis e permissões antes de implementar funcionalidades exclusivas de professores. O backend deve validar o papel e a autorização em cada operação protegida. A regra para provas deve ser decidida com a instituição e não presumida pelo aplicativo.

**Critérios de aceite**

- [ ] Papéis e permissões estão documentados.
- [ ] O backend valida permissões independentemente da interface.
- [ ] A publicação de Material Complementar e Provas segue a política aprovada.
- [ ] Testes tentam executar operações não permitidas diretamente pela API.

### 2.6. Manter credenciais fora do repositório

**Constatação**

Nos arquivos de configuração Cloudant revisados, a API key não está embutida no JSON; o fluxo utiliza uma configuração de credencial separada. O `.gitignore` atual, porém, não lista explicitamente arquivos locais comuns como `.env`, `flows_cred.json` e `node_modules/`.

**Recomendação**

- Preservar a configuração de credenciais fora dos arquivos de fluxo versionados.
- Adicionar ao `.gitignore` padrões para credenciais e dependências locais quando aplicáveis.
- Se uma credencial for publicada acidentalmente, revogá-la e gerar outra; apenas apagar o arquivo do commit mais recente não elimina o vazamento do histórico.
- Documentar quais arquivos podem ser versionados e quais são locais.

**Critérios de aceite**

- [ ] Nenhuma API key, token ou senha aparece nos arquivos versionados.
- [ ] Arquivos de credenciais locais são ignorados pelo Git.
- [ ] O README explica como configurar credenciais sem incluí-las no JSON.

## 3. Arquitetura e confiabilidade

### 3.1. Implementar paginação no Cloudant e na API

**Constatação**

`comum.js` define `LIMITE_CONSULTA = 5000` e envia esse limite às consultas Mango. A consulta não implementa navegação por bookmark/página.

**Risco**

A lista pode ficar incompleta quando ultrapassar o limite definido. Buscar milhares de registros em uma única resposta também aumenta o tempo de carregamento e o consumo de memória do app.

**Recomendação**

Implementar paginação ponta a ponta: Cloudant → Node-RED → APIClient → interface. Usar o bookmark do Cloudant ou uma estratégia equivalente e carregar novas páginas conforme a necessidade.

**Critérios de aceite**

- [ ] A API informa se há próxima página e fornece o cursor necessário.
- [ ] O app carrega resultados progressivamente.
- [ ] Ordenação e filtros permanecem consistentes entre páginas.
- [ ] Testes cobrem lista vazia, última página, páginas intermediárias e registros adicionados durante a navegação.

### 3.2. Aproveitar os filtros remotos existentes

**Constatação**

A rota de resposta de publicações já interpreta filtros como tipo, ano, área, subárea, curso, disciplina, título, autor, texto livre, ordenação e limite. O método `publicacoes()` do `APIClient` atualmente chama a listagem sem parâmetros, e a busca do app é feita sobre os dados carregados localmente.

**Recomendação**

Adicionar parâmetros de consulta ao `APIClient` e decidir quais filtros devem ser enviados ao servidor. Preservar a experiência local quando o app estiver em modo demonstração ou sem conexão.

**Critérios de aceite**

- [ ] Os filtros enviados pelo app correspondem aos aceitos pelo backend.
- [ ] Parâmetros são codificados corretamente na URL.
- [ ] O modo local continua funcionando sem API.
- [ ] A busca remota funciona em conjunto com a paginação.

### 3.3. Completar o ciclo de edição e exclusão no aplicativo

**Constatação**

O fluxo Node-RED final possui rotas para atualização e exclusão de publicações (`UPDATEpublicacao` e `DELETEpublicacao`). O `APIClient.swift` atual expõe consulta, criação, avaliação e operações de usuário, mas não métodos de atualização ou exclusão de publicações.

O DTO `PublicacaoDTO` declara o campo `meu`, porém a conversão para o modelo `Publicacao` não preserva essa informação. O modelo também não possui atualmente uma propriedade de autoria equivalente.

**Recomendação**

1. Definir o contrato de edição e exclusão no Swift.
2. Preservar a informação de autoria ou obter a autorização por uma fonte confiável.
3. Exibir ações de editar/excluir somente quando apropriado.
4. Tratar conflitos de revisão do Cloudant e erros de autorização sem perder o conteúdo local do formulário.

**Critérios de aceite**

- [ ] Uma pessoa consegue editar apenas uma publicação própria, conforme a regra do backend.
- [ ] Uma pessoa não consegue excluir publicação de terceiros.
- [ ] A moderação segue o mecanismo autorizado.
- [ ] O app atualiza a lista após a operação e informa falhas de forma clara.

### 3.4. Alinhar testes ao fluxo realmente importado

**Constatação**

`backend/node-red/testes/testar-fluxo.js` executa o fluxo gerado `hub-academico-flows.json` e carrega `cloudant-config.json`. O arquivo de importação documentado para implantação é `NodeRed-Flow-Final.json`.

**Risco**

Uma alteração pode passar nos testes do fluxo gerado e ainda assim deixar o JSON final importável divergente.

**Recomendação**

Criar uma validação automatizada que compare o artefato final com o fluxo-fonte esperado, incluindo rotas, nós CloudantPlus, configuração e conexões. Manter os testes de comportamento e adicionar testes específicos de integridade do arquivo final.

**Critérios de aceite**

- [ ] O teste identifica rotas ausentes ou duplicadas.
- [ ] O teste identifica nós CloudantPlus e conexões inválidas.
- [ ] O arquivo final é validado antes de um PR ser considerado pronto.
- [ ] O processo de geração não sobrescreve alterações manuais sem aviso.

### 3.5. Adicionar integração contínua

**Constatação**

Não foi encontrado workflow de GitHub Actions na árvore atual do repositório. Já existe um teste Node.js executável por linha de comando.

**Recomendação**

Adicionar GitHub Actions para executar o teste de fluxo e as verificações estruturais em cada PR. Quando houver um target XCTest e ambiente de build apropriado, acrescentar compilação e testes Swift.

**Critérios de aceite**

- [ ] O workflow executa `node backend/node-red/testes/testar-fluxo.js`.
- [ ] Falhas bloqueiam a aprovação do PR conforme a política do repositório.
- [ ] Os testes Swift são incluídos quando o target estiver disponível no pipeline.
- [ ] O README documenta como executar as mesmas verificações localmente.

## 4. Experiência de uso e apresentação

### 4.1. Tornar o estado de sincronização mais explícito

**Constatação**

`PublicacaoStore` já acompanha `sincronizando`, `ultimaSincronizacao` e `erroServidor`. A tela de busca exibe indicador de carregamento e aviso quando a sincronização falha, mas não apresenta o horário da última sincronização bem-sucedida nem um estado persistente e resumido do modo de dados.

**Recomendação**

Criar um indicador discreto que diferencie:

- Modo local/demonstração.
- Conectado e sincronizado.
- Sincronizando.
- Sem conexão, exibindo a última cópia local.
- Configuração de servidor inválida.

Exibir a última sincronização quando houver uma data disponível, sem confundir cache local com dados atualizados.

**Critérios de aceite**

- [ ] O estado mostrado corresponde ao estado real do `PublicacaoStore`.
- [ ] O modo local não é apresentado como se estivesse sincronizado com a nuvem.
- [ ] A falha de conexão não apaga a última cópia válida.
- [ ] A informação é acessível e não depende apenas de cor.

### 4.2. Preparar tema escuro e respeitar a aparência do sistema

**Constatação**

`HubAcademicoApp.swift` aplica `.preferredColorScheme(.light)`, forçando o tema claro.

**Recomendação**

Preparar as cores semânticas do Design System para tema claro e escuro e permitir acompanhar a configuração do sistema. Manter contraste, hierarquia e identidade institucional nos dois modos.

**Critérios de aceite**

- [ ] O tema pode acompanhar o sistema.
- [ ] Componentes, avisos, cartões, formulários e imagens mantêm contraste adequado.
- [ ] O tema é validado em todas as telas principais.

### 4.3. Planejar suporte a iPad e telas maiores

**Constatação**

O projeto está configurado para a família de dispositivos iPhone (`TARGETED_DEVICE_FAMILY = 1`) e orientação retrato.

**Recomendação**

Se o público-alvo incluir iPad, planejar uma adaptação responsiva com mais espaço para listas, filtros e detalhes, em vez de apenas ampliar a interface do iPhone.

**Critérios de aceite**

- [ ] O alvo de dispositivos é ampliado intencionalmente.
- [ ] Layouts são validados em iPad e em diferentes tamanhos de janela.
- [ ] Navegação e formulários continuam utilizáveis em orientação suportada.

### 4.4. Reforçar acessibilidade e clareza dos resultados

**Recomendação**

- Revisar VoiceOver, rótulos de controles, ordem de foco e áreas de toque.
- Testar Dynamic Type e fontes maiores.
- Garantir contraste adequado e não depender somente de cores para indicar estados.
- Padronizar estados vazios, erros, carregamento e ausência de resultados por filtros.
- Manter os cartões focados em título, autoria, curso/disciplina, tipo e data, sem sobrecarregar a leitura.

**Critérios de aceite**

- [ ] Fluxos principais podem ser utilizados com VoiceOver.
- [ ] Textos se adaptam a tamanhos maiores.
- [ ] Estados de erro, vazio e carregamento são distinguíveis.
- [ ] Não há cortes ou sobreposições em tamanhos de fonte ampliados.

## 5. Funcionalidades futuras

Estas ideias são propostas de produto, não funcionalidades já existentes nem compromissos de implementação.

### Prioridade funcional sugerida

**Gestão e moderação**
- Edição e exclusão de publicações próprias.
- Denúncia de conteúdo inadequado.
- Ferramentas de moderação.
- Papéis distintos para estudantes, professores e moderadores.

**Experiência acadêmica**
- Favoritos e lista de leitura.
- Histórico de publicações e avaliações.
- Filtros salvos e acompanhamento de disciplinas.
- Notificações sobre novas publicações em áreas acompanhadas.

**Comunidade**
- Comentários e discussões vinculados a publicações.
- Divulgação de oportunidades de pesquisa, extensão, bolsas e iniciação científica.
- Eventos e atividades acadêmicas.
- Recomendações por área de interesse, somente após existir uma base confiável e política de privacidade definida.

Antes de desenvolver qualquer uma dessas funcionalidades, definir escopo, dados necessários, permissões, impacto no Cloudant e critérios de privacidade.

## 6. Colaboração e organização do GitHub

### 6.1. Documentos recomendados

- `CONTRIBUTING.md`: configuração do ambiente, execução dos testes, padrão de commits e fluxo de PR.
- `SECURITY.md`: canal e procedimento para relatar vulnerabilidades sem publicar detalhes sensíveis em Issues.
- `LICENSE`: definir a licença do código. Verificar separadamente direitos de uso de marcas, brasão, imagens e materiais de terceiros.
- Templates de Issues: bug, melhoria, funcionalidade e tarefa técnica.
- Template de Pull Request: contexto, escopo, validação, riscos e checklist.
- `CHANGELOG.md` ou Releases: registrar alterações relevantes por versão.
- Opcionalmente, um código de conduta se o projeto passar a receber contribuições externas com frequência.

A licença não deve ser escolhida automaticamente: precisa refletir a decisão dos responsáveis pelo projeto e a situação dos ativos de terceiros.

### 6.2. Melhorias na apresentação do repositório

O README já contém capturas de tela, vídeo de demonstração, guia de uso, requisitos e instruções de conexão ao Node-RED. A recomendação é preservar esse conteúdo e mantê-lo alinhado às versões reais do aplicativo.

Próximos ajustes:
- Manter imagens e vídeo atualizados com a interface vigente.
- Documentar como executar os testes.
- Apresentar a arquitetura e os limites entre app, Node-RED e Cloudant.
- Explicar como propor uma contribuição e quais alterações exigem validação no Xcode ou no Node-RED.

### 6.3. Higiene dos Pull Requests existentes

Na revisão de 12/11/2026, os PRs #5 a #8 estavam abertos. A comparação de suas branches com `main` indicou estado divergente e 10 commits atrás da branch principal em cada caso.

Isso não significa, por si só, que todo o conteúdo desses PRs esteja incorreto. Significa que cada diff precisa ser reavaliado contra a arquitetura atual antes de qualquer integração, especialmente porque algumas descrições antigas citam contratos, nomes de serviços e cabeçalhos que já mudaram.

**Recomendação:** atualizar ou encerrar cada PR individualmente, preservar as alterações ainda úteis e evitar integrar branches antigas em lote.

## 7. Backlog priorizado

| Prioridade | Entrega | Resultado esperado |
|---|---|---|
| **P0 — antes de exposição pública** | HTTPS e remoção da exceção ATS global | Comunicação protegida em produção |
| **P0 — antes de exposição pública** | Autenticação real, IDs seguros e proteção de sessão | Identidade e autoria verificáveis |
| **P0 — antes de exposição pública** | Proteção do editor Node-RED e credenciais | Menor superfície de ataque |
| **P1 — confiabilidade** | Sanitização de erros e política de permissões | Respostas seguras e regras aplicadas no backend |
| **P1 — confiabilidade** | Paginação Cloudant/API/app | Crescimento sem truncamento de resultados |
| **P1 — funcionalidade** | Edição e exclusão no Swift | Ciclo completo de gestão de publicações |
| **P1 — qualidade** | Testes do JSON final e GitHub Actions | Regressões detectadas antes do merge |
| **P2 — experiência** | Indicador de conexão e última sincronização | Clareza entre dados locais e remotos |
| **P2 — experiência** | Filtros remotos e acessibilidade | Busca mais eficiente e interface inclusiva |
| **P2 — plataforma** | Tema escuro e suporte a iPad | Maior compatibilidade de uso |
| **P3 — produto** | Favoritos, notificações, comentários e oportunidades | Evolução da comunidade acadêmica |
| **P3 — comunidade** | CONTRIBUTING, SECURITY, licença e templates | Contribuições externas mais seguras e organizadas |

## 8. Sequência sugerida de execução

### Fase 0 — Preparação e segurança
1. Definir ambiente de produção e de desenvolvimento.
2. Corrigir política de transporte e configurar HTTPS.
3. Definir autenticação, armazenamento de sessão e permissões.
4. Proteger o Node-RED, credenciais e respostas de erro.

### Fase 1 — Consistência e confiabilidade
1. Formalizar papéis e regras de publicação.
2. Implementar paginação.
3. Completar edição e exclusão no app.
4. Alinhar os testes ao JSON final.
5. Adicionar CI.

### Fase 2 — Experiência
1. Exibir estado de sincronização e última atualização.
2. Implementar filtros remotos.
3. Melhorar acessibilidade.
4. Preparar tema escuro e avaliar suporte a iPad.

### Fase 3 — Expansão do produto e comunidade
1. Implementar favoritos e histórico.
2. Avaliar notificações e acompanhamento de disciplinas.
3. Criar recursos de moderação e interação.
4. Expandir para oportunidades acadêmicas após definir governança e privacidade.

## 9. Limites desta auditoria

Esta revisão foi feita por leitura estática dos arquivos versionados. Não foi realizada:

- Compilação do aplicativo no Xcode.
- Execução dos testes Node.js.
- Importação do JSON em uma instância real do Node-RED.
- Teste de integração com Cloudant.
- Teste de penetração, análise dinâmica de tráfego ou auditoria da infraestrutura hospedada.
- Validação institucional das regras de publicação e dos papéis de usuário.

Portanto, as constatações sobre o código e os arquivos são verificáveis no repositório; as condições de implantação do servidor e os requisitos institucionais precisam ser confirmados no ambiente real.

## 10. Arquivos de referência revisados

- `Config/HubAcademico-Info.plist`
- `HubAcademico/App/HubAcademicoApp.swift`
- `HubAcademico.xcodeproj/project.pbxproj`
- `HubAcademico/Modelos/Publicacao.swift`
- `HubAcademico/Servicos/APIClient.swift`
- `HubAcademico/Servicos/ServidorConfig.swift`
- `HubAcademico/Servicos/PublicacaoStore.swift`
- `HubAcademico/Telas/BuscaView.swift`
- `HubAcademico/Telas/VisualizacaoView.swift`
- `backend/node-red/src/comum.js`
- `backend/node-red/src/rotas/erro.js`
- `backend/node-red/src/rotas/publicacoes-resposta.js`
- `backend/node-red/src/rotas/usuario-cadastrar.js`
- `backend/node-red/src/rotas/remover-validar.js`
- `backend/node-red/NodeRed-Flow-Final.json`
- `backend/node-red/hub-academico-flows.json`
- `backend/node-red/cloudant-config.json`
- `backend/node-red/testes/testar-fluxo.js`
- `.gitignore`
- `README.md`

---

**Este documento é um plano de evolução.** Cada entrega deve ser implementada em PR próprio, com escopo pequeno, validação compatível com a mudança e revisão antes do merge.
