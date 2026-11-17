> Atualiza??o: valida??o Dart/Android adicional autorizada e conclu?da em 17/11/2026, 1 teste com 16 verifica??es aprovadas. Ver DART_ANDROID_TEST_PLAN.md e docs/PROGRESSO.md. Conta C e perfil retidos, documentos financeiros removidos. Os trechos abaixo descrevem o hist?rico anterior; n?o executar os comandos hist?ricos nem repetir cria??o de A/B/C.

# M3 — Plano de execução remota controlada

Estado: variante JavaScript autorizada e executada em 17/11/2026, com 28/28 verificações aprovadas e limpeza financeira confirmada. A rotina Dart/Android não foi executada com sucesso contra o Firebase remoto. Não repetir a execução: contas e perfil foram retidos conforme autorização.

## Resultado da variante leve JavaScript

Runner isolado: firebase/tests/m3_remote_client.mjs, usando firebase/app, firebase/auth e firebase/firestore (SDK cliente 12.19.0) no Node.js. Sem Admin SDK ou operações financeiras com credenciais de gerenciamento. Os contratos/repositórios Dart NÃO foram exercitados nesta variante.

Comando padrão `npm --prefix firebase/tests run test:remote:client` apenas informa que está desabilitado, sem rede. A execução autorizada usou `-- --execute-approved --allow-profile-remainder`. Há bloqueio por journal existente para impedir repetição automática. Não apagar o journal para contornar essa proteção.

O helper firebase/remote_client_preflight.cjs conferiu regras iguais às locais, índice READY e ausência das duas contas imediatamente antes de criar dados. Leu a configuração do app Web já registrado, sem gerar outro app/projeto. As opções cliente ficaram em memória; API keys, senhas e tokens não aparecem nos relatórios.

Resultado em 2026-11-17T15:43:16Z–15:43:26Z: 28 verificações agrupadas, 28 aprovadas, 0 falhas. Autenticação A/B com logout/login e mesmo UID, sessões isoladas, perfil, CRUD das receitas e orçamento, auditoria e paginação 2+1+0 aprovados. Doze tentativas indevidas (seis de B e seis sem autenticação) responderam permission-denied. Não houve falha de segurança. Memória residente ao final: aproximadamente 121 MiB, não uma medição de pico.

Perfil retido: users/CdQnPRoT1PM2CfrZewhsrfb1hzX2. Conta A: UID CdQnPRoT1PM2CfrZewhsrfb1hzX2, bolsozen-m3r20261117a01-a@example.com. Conta B: UID RWBAcI9r0nZ5x6eJ7JVwFcKTjBF3, bolsozen-m3r20261117a01-b@example.com. Não houve tentativa de excluir perfil ou contas. Senhas foram descartadas; contas foram deslogadas.

Removidos e conferidos por leitura do servidor, sob users/CdQnPRoT1PM2CfrZewhsrfb1hzX2/:

- transactions/BDZlwKMnJLFGy3fYQjQB
- transactions/Y77XhxcMwjM1l8biwALr
- transactions/YXs8Ppmwx9jUiSBUi4mC
- budgets/2099-12_food

As tentativas transactions/m3r20261117a01-probe-b e transactions/m3r20261117a01-probe-guest foram negadas, e sua ausência foi conferida como A. Nenhum documento financeiro temporário permaneceu.

Evidências sanitizadas, sem credenciais: build/m3r20261117a01-js-events.jsonl e build/m3r20261117a01-js-report.json (ignorados pelo Git). O journal registra caminhos antes das escritas para facilitar recuperação. Houve um erro no helper de pré-verificação antes de qualquer mutação, corrigido separando objetos de opções GET/POST da CLI; a execução de dados começou somente após pré-verificação bem-sucedida.

Pendente: integração real dos repositórios Dart no Flutter/MSI App Player, sob estratégia e autorização próprias; limpeza posterior do perfil/contas por UID com autorização específica. A variante JavaScript valida o backend e as regras, não os mapeadores/repositórios Flutter nem a renderização Android. Não houve compilação Android nesta etapa.

## Diagnóstico somente de leitura

Projeto fixo: bolsozen-f2f35, database (default), região southamerica-east1. Android com package com.bolsozen.bolsozen e App ID já existente. firebase/remote_preflight.cjs usa autenticação da CLI somente em GETs das APIs de gerenciamento: lê estado de índice e conteúdo da release de regras. Não lê documentos financeiros, não cria recursos, não usa Admin SDK e não imprime tokens. Depende da instalação local da CLI no Windows.

Pré-verificação realizada: release cloud.firestore publicada em 2026-11-17T15:01:28.070215Z; fonte remota corresponde ao firestore.rules local após normalização de BOM/finais de linha. Índice transactions CICAgOjXh4EK está READY, com occurredAt DESC, createdAt DESC e __name__ ASC. Repetir imediatamente antes da execução; se não estiver READY, manter M3_INDEX_READY=false e não consultar via fetchPage.

## Identificadores e limites da execução

- Identificador fixo desta execução: m3r20261117a01. Não reutilizar a execução para tentar entrar em contas já existentes.
- Conta A: bolsozen-m3r20261117a01-a@example.com.
- Conta B: bolsozen-m3r20261117a01-b@example.com.
- Endereços de exemplo descartáveis, sem vínculo com contas pessoais. Não enviar verificação/recuperação de e-mail.
- UIDs são gerados pelo Firebase Authentication e só poderão ser informados após a criação autorizada. Serão registrados sem credenciais.
- Cada senha será aleatória, gerada em memória e nunca gravada em arquivo ou log.
- Três instâncias nomeadas do SDK (a/b/guest), sem usar a sessão padrão do app. Guest não cria conta e permanece desautenticado. Se existir sessão na instância nomeada, abortar antes de reutilizá-la.
- Perfil somente A: users/{UID_A}, nome TESTE M3 A m3r20261117a01.
- Três receitas de teste: users/{UID_A}/transactions/{ID_gerado_pelo_repositório}, valores 101, 202 e 303 centavos, categoria salary, data 2099-12-10, descrição iniciada por TESTE_M3 m3r20261117a01. A primeira muda para 111 centavos e descrição de atualização.
- Um orçamento: users/{UID_A}/budgets/2099-12_food, limite inicial 1000 centavos, alterado para 1200. Nenhum valor representa finanças reais.
- Tentativas indevidas de criação, que deverão ser negadas: users/{UID_A}/transactions/m3r20261117a01-probe-b e users/{UID_A}/transactions/m3r20261117a01-probe-guest. Caminhos incluídos no registro de limpeza caso sejam indevidamente aceitos.
- Conta B não recebe perfil ou dados financeiros próprios.

## Roteiro funcional original (Dart) e correspondência da variante JavaScript

Os nomes de classes abaixo descrevem o roteiro Dart preservado. Na execução JavaScript aprovada, as operações equivalentes foram feitas diretamente pelo SDK cliente JS, incluindo os mesmos campos, transações com timestamps de servidor, ordem e cursor; nenhuma dessas operações deve ser contabilizada como teste de repositório Dart.

1. Confirmar novamente projeto, regras e índice por leitura. Nenhuma publicação.
2. Criar A e B por FirebaseAuth.createUserWithEmailAndPassword; fazer logout/login normal de cada conta e conferir o mesmo UID, sessões independentes e guest sem usuário.
3. Em A, verificar ausência de perfil, criar por FirestoreUserRepository.ensureProfile e ler por fetch.
4. Criar as três receitas por FirestoreTransactionRepository.create. Ler por fetchPage se READY; caso contrário, por referência de documento Source.server e mapper, registrando essa diferença.
5. Atualizar a primeira receita por update e confirmar conteúdo/auditoria em nova leitura.
6. Somente se índice READY, testar paginação por fetchPage(limit:2), cursor para a segunda página de um item e terceira página vazia; confirmar três IDs sem repetição.
7. Criar, consultar e atualizar orçamento por FirestoreBudgetRepository.save/fetchMonth.
8. Com B e guest, usar SDK cliente diretamente no caminho de A para tentar ler, criar documento de probe, alterar receita e excluir receita. Também tentar ler perfil e orçamento de A. Cada tentativa deve retornar exatamente permission-denied; rede/timeout não contam como segurança aprovada. Os repositórios por sessão não permitem selecionar UID de terceiros, por isso o SDK direto é necessário nesses testes.
9. Com A, verificar que a receita não mudou após tentativas indevidas. Remover orçamento por remove e receitas por delete; confirmar ausência por leituras Source.server. Orçamento também deve retornar lista vazia em fetchMonth.
10. Em finally, revisar somente caminhos rastreados nesta execução, remover remanescentes permitidos e verificar ausência. Nenhuma exclusão global/de coleção ou modificação de documentos preexistentes.
11. Registrar relatório sanitizado de operações, UIDs, caminhos removidos/pendentes e resultados. Fazer logout das contas criadas e descartar instâncias locais do SDK. NÃO excluir contas Authentication.

## Limitação obrigatória de limpeza do perfil

As regras publicadas contêm allow delete: if false para users/{uid}. Portanto, o cliente não pode excluir o perfil de A. A execução depende de aprovação explícita dessa limitação: o único perfil criado ficará registrado como remanescente para exclusão manual específica pelo proprietário no Console, após informar o UID real.

Não alterar regras, usar credenciais administrativas, Admin SDK ou operações globais para contornar essa restrição. Se a retenção temporária do perfil não for aceita, não executar o cenário de criação de perfil nem declarar o roteiro integralmente validado.

As duas contas Authentication permanecerão até autorização específica posterior para removê-las. Não há chamada User.delete ou exclusão de contas pela CLI nesta rotina. Como as senhas não serão guardadas, a limpeza posterior das contas deverá ser feita pelo proprietário no Console pelos UIDs informados.

Se houver falha de limpeza de transação/orçamento/probe, registrar os caminhos exatos em cleanup_report. Um teste com cleanup pendente adicional ao perfil acordado falha. Falhas do processo/dispositivo podem interromper finally; usar os eventos account_created/transaction_created/profile_created e os caminhos deste plano para revisão manual, sem varrer dados de outros usuários.

## Rotina Dart preservada — execução remota ainda pendente

Arquivo separado da UI: integration_test/m3_remote_test.dart. Por padrão o teste fica skipped, antes de inicializar Firebase ou criar dados. Essa rotina específica usa SDKs cliente FlutterFire e repositórios Dart reais; não foi a rotina utilizada na validação JavaScript. integration_test é dependência de desenvolvimento oficial do SDK Flutter. A tentativa Android anterior falhou por memória durante compilação, antes de criar contas. Não executar agora os comandos históricos abaixo: as contas já existem após a variante JS, e as senhas não foram retidas.

Somente após aprovação expressa das contas, operações e remanescente do perfil, e após confirmar índice READY:

```powershell
node firebase/remote_preflight.cjs
flutter test integration_test/m3_remote_test.dart -d 127.0.0.1:5556 --dart-define=M3_REMOTE_APPROVED=true --dart-define=M3_ALLOW_PROFILE_REMAINDER=true --dart-define=M3_INDEX_READY=true
```

Se o índice não estiver READY, o último define será false. Não executar com true nesse caso. Não há deploy, registro de app/projeto ou habilitação de serviço no roteiro. A etapa de preparação para antes da primeira chamada de criação de conta; execução exige nova aprovação.
