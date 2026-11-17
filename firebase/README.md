# Testes locais de segurança

Instale as ferramentas Node do diretório `firebase/tests` com `npm ci`. Java e Firebase CLI são necessários. Na raiz do repositório, execute:

```powershell
firebase emulators:exec --project demo-bolsozen --only firestore "npm --prefix firebase/tests test"
```

O projeto demo não corresponde ao Firebase remoto. Os testes exigem `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` antes de criar clientes e carregam as regras locais. O reset de dados limpa somente o emulador. Não executar com project ID de produção. Não há deploy neste comando.

Consultas: transações usam occurredAt DESC, createdAt DESC e ID ASC, com cursor de valores e páginas de até 100. O índice correspondente está em firestore.indexes.json. Orçamentos usam igualdade de monthKey, atendida pelo índice simples padrão; perfil usa leitura por ID. O emulador não comprova disponibilidade de índices remotos.

Regras e índices estão preparados localmente; publicação remota exige autorização separada. Configuração Firebase cliente não constitui teste de acesso ao banco real.

As dependências de desenvolvimento usam override de `@grpc/grpc-js` para uma versão compatível a partir de 1.13.6, corrigindo vulnerabilidade transitiva apontada pela auditoria inicial. Após a resolução, `npm audit` retornou zero vulnerabilidades. O lockfile registra a versão instalada.

## Publicação futura, somente após autorização

Na raiz do projeto, conferir o destino com `firebase apps:list ANDROID --project bolsozen-f2f35` e consultar os índices atuais com `firebase firestore:indexes --project bolsozen-f2f35 --json`.

```powershell
firebase deploy --project bolsozen-f2f35 --config firebase.json --only firestore:indexes
firebase deploy --project bolsozen-f2f35 --config firebase.json --only firestore:rules
```

Somente firestore.indexes.json e firestore.rules são usados, nos caminhos definidos em firebase.json. Regras locais substituem as remotas vigentes. Não usar --force ou confirmar exclusões de índices existentes. Aguardar o índice pronto antes de validar as consultas no servidor. Esses comandos não foram executados na revisão e não autorizam deploy de outros serviços.
