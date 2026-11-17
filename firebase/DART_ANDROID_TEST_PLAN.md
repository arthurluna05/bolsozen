# M3 — Proposta de validação Dart/Android

Estado: preparação em 17/11/2026; execução e novas contas aguardam autorização específica. Não repetir os 28 testes JavaScript. M3 continua pendente.

## Runner e ambiente

Preparar `integration_test/m3_dart_repositories_test.dart`, baseado na infraestrutura do runner anterior, mas independente de seus identificadores A/B. O arquivo novo ainda não foi implementado nesta preparação. Não executar `m3_remote_test.dart`: ele tenta recriar contas já existentes.

Usar integration_test e FlutterFire reais no MSI App Player, sem importar main.dart, montar telas ou alterar a experiência normal. Teste skipped por padrão, antes de inicializar Firebase. Exigir três flags explícitas: M3_DART_REMOTE_APPROVED, M3_ALLOW_PROFILE_REMAINDER e M3_INDEX_READY. Instâncias Firebase nomeadas exclusivas para C e guest; abortar se houver sessão preexistente. Guest não cria conta. Conferir plataforma Android, projeto bolsozen-f2f35 e App ID Android existente antes de qualquer mutação. Não usar emuladores Firebase nesta execução.

Preservar android/gradle.properties: heap 1536 MiB, metaspace 512 MiB, code cache 256 MiB, parallel=false e workers.max=2. Uma compilação/execução por vez; não executar JavaScript, navegador ou build paralelo para esta validação. Não apagar caches, executar flutter clean ou modificar memória. Se houver OOM, interromper e diagnosticar antes de nova tentativa. O APK normal existente não contém este entrypoint de testes e não substitui sua compilação.

## Identificadores propostos — ainda não autorizados

- Execução: `m3dart20261117c01`.
- Única conta nova C: `bolsozen-m3dart20261117c01-c@example.com`.
- Senha aleatória em memória, sem argumentos de linha de comando, arquivos ou logs; login/logout/login para confirmar UID. Não recuperar/resetar senhas de A/B, nem alterar essas contas.
- Perfil: `users/{UID_C}`, nome `TESTE M3 DART m3dart20261117c01`.
- Três receitas: `users/{UID_C}/transactions/{ID_gerado_pelo_repositorio}`, salary, 101/202/303 centavos, occurredAt em 10/12/2099, descrições prefixadas `TESTE_M3_DART m3dart20261117c01`. Atualizar a primeira para 111 centavos.
- Orçamento: `users/{UID_C}/budgets/2099-12_food`, limite 1000 e depois 1200 centavos.
- UID e IDs serão conhecidos somente após criação autorizada; registrar eventos sanitizados imediatamente após retorno dos repositórios. Se ocorrer interrupção entre commit e retorno do ID, não reiniciar automaticamente: investigar a sessão e os caminhos da nova conta antes de retomar.

## Pré-verificação somente de leitura, antes da execução autorizada

Conferir projeto/configuração Android, regras remotas correspondentes às locais e índice transactions READY. Confirmar por consulta Authentication limitada ao e-mail C que ele não existe, usando CLI autenticada apenas para gerenciamento de leitura. Não usar credenciais de gerenciamento para documentos financeiros. Se a conta existir, abortar sem reutilizar ou escolher outro identificador automaticamente. Preservar os documentos e contas A/B anteriores.

## Casos e evidências

1. Inicializar Firebase Android e conferir App ID/projeto; criar C e autenticar normalmente; guest deve permanecer sem sessão.
2. Instanciar FirebaseSession, FirestoreUserRepository, FirestoreTransactionRepository e FirestoreBudgetRepository reais de lib/data/. Nenhuma reimplementação de CRUD no teste.
3. UserRepository.fetch retorna null; ensureProfile cria; fetch confirma UID, e-mail, nome e createdAt. Repetir ensureProfile e conferir idempotência e auditoria preservada.
4. TransactionRepository.create cria três receitas. fetchPage(limit: 2), cursor para página de um item e página vazia: confirmar ordem occurredAt DESC, createdAt DESC e ID ASC, sem duplicação. Se empatar createdAt, calcular ordem esperada pelo ID, sem pressupor sequência de criação.
5. Comparar modelos retornados com valores, categoria, datas e centavos esperados; validar timestamps de auditoria resolvidos. Atualizar usando modelo real e consultar novamente; conferir createdAt preservado e updatedAt não anterior. Leituras dos repositórios usam Source.server e não apenas cache.
6. BudgetRepository.save/fetchMonth confirma criação, limite e competência; salvar novamente confirma atualização sem duplicar identidade.
7. Guest tenta leitura e alteração dos documentos recém-criados de C, diretamente pelo SDK cliente: exigir exatamente permission-denied. Não considerar rede/timeout uma aprovação. Validar também barreira local sem sessão nos repositórios (unauthenticated), distinguindo-a de negativa remota. Mapeamento DataFailure.permissionDenied deve ser verificado explicitamente via guardData na chamada negada. SDK direto apenas para operações adversariais que os contratos por sessão não permitem expressar; CRUD funcional obrigatoriamente pelos repositórios.
8. Após tentativas negadas, confirmar que os modelos não mudaram. Qualquer acesso indevido permitido interrompe imediatamente os testes e deve ser informado; não avançar para demais cenários.
9. Remover orçamento e receitas pelos repositórios reais. Confirmar listas vazias pelos repositórios e ausência individual com get(Source.server) apenas nos caminhos rastreados. Leitura direta complementar verifica exclusão; não substitui o CRUD dos repositórios.

Persistência só aprovada após gravação confirmada e releitura do servidor. Não declarar teste de sobrevivência a reinício do processo: isso exige estratégia separada de sessão e retomada. Registrar cada etapa aprovada/falha, sem erros brutos que possam conter credenciais.

## Limpeza e interrupções

Em finally, limpar exclusivamente os documentos financeiros criados nesta execução, pelos repositórios, e confirmar ausência no servidor. Registrar caminhos exatos se a limpeza falhar. Não excluir coleções ou dados preexistentes. Não excluir contas Authentication.

As regras proíbem excluir users/{uid}. Solicitar aprovação explícita para reter temporariamente a nova conta C e seu perfil. A/B e o perfil A permanecem intocados. Ao concluir, registrar UID C e caminho do perfil para limpeza manual posterior autorizada. Logout e descarte das instâncias locais após execução normal. Não contornar regras com Admin SDK.

## Comandos previstos — não executar antes da aprovação

O runner deverá estar implementado e revisado antes do comando de integração. Pré-verificação da ausência de C deverá ser incluída no helper somente de leitura, sem executar o helper JavaScript que exige ausência de A/B.

```powershell
node firebase/dart_android_preflight.cjs
flutter devices
flutter test integration_test/m3_dart_repositories_test.dart -d 127.0.0.1:5556 --no-pub --concurrency=1 --dart-define=M3_DART_REMOTE_APPROVED=true --dart-define=M3_ALLOW_PROFILE_REMAINDER=true --dart-define=M3_INDEX_READY=true
```

Confirmar ID conectado antes de usar 127.0.0.1:5556. Capturar saída sanitizada em build/m3dart20261117c01-android.log, preservando exit code. Não repetir execução automaticamente se falhar. Rodar dart format ., flutter analyze e flutter test --concurrency=1 sequencialmente após alterações do runner; teste unitário normal não executa integration_test.

## Limitações e aprovação solicitada

RAM de aproximadamente 8 GB pode continuar limitando compilação mesmo com espaço livre. Não há aprovação de execução Android nesta preparação. O roteiro cobre integrações FlutterFire e mapeadores reais; não adiciona M4 ou UI. O isolamento entre dois usuários autenticados já foi validado em JavaScript e não será repetido com novas duas contas aqui; o novo teste cobre guest e barreiras de sessão no Android.

Aprovação necessária: uma nova conta C com o e-mail acima; perfil e quatro documentos financeiros descritos; testes adversariais guest; limpeza financeira pelos repositórios; retenção temporária de C e seu perfil; compilação e execução única no MSI, interrompendo em caso de OOM.

## Resultado

Uma compila??o Android aprovada, 16/16 verifica??es, limpeza financeira confirmada por Source.server. UID C: nluCnbgRa8NJvuv6SI3TMlTqTe83; perfil retido users/nluCnbgRa8NJvuv6SI3TMlTqTe83. Relat?rio local build/m3dart20261117c01-report.json. Reposit?rios Dart reais exercitados, sem repetir JS. Detalhes e caminhos removidos em docs/PROGRESSO.md.
