# Contratos de publicações

Estes arquivos congelam os três formatos necessários para conectar o Hub Acadêmico ao IBM Cloudant sem alterar o contrato já consumido pelo SwiftUI.

| Arquivo | Uso |
|---|---|
| `projeto-criacao.schema.json` | Corpo enviado pelo app em `POST /hub/projetos`. |
| `projeto-api.schema.json` | Objeto público devolvido pelo GET e pelo POST. |
| `projeto-cloudant.schema.json` | Documento interno persistido em `hubacademico_projetos`. |

## Regras importantes

- O documento Cloudant usa `_id = "projeto:" + id` e `tipoDocumento = "projeto"`.
- `_rev` é gerado pelo Cloudant.
- `usuarioId` é interno e nunca pode sair na API pública.
- `nota`, `quant`, `minhaNota` e `meu` são dados derivados/contextuais da API, não campos persistidos no documento base de projeto.
- `area`, `subarea`, `curso` e `cadeira` são snapshots textuais do catálogo local. Não criam dependência de um banco de catálogo.
- `cadeiraId` é apenas compatibilidade legada opcional. O workflow novo não deve depender de uma coleção de cadeiras para cadastrar publicações.

## Teste

Na raiz do repositório:

```bash
node backend/node-red/testes/testar-contratos-cloudant.js
```

O teste verifica consistência estrutural e separação entre campos públicos e internos. Ele não substitui os testes de integração no Node-RED nem valida conexão real com CloudantPlus.
