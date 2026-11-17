# BolsoZen — Progresso

## Encerramento definitivo do M3 — aprovado em 17/11/2026

M3 concluído e aprovado tecnicamente pelo usuário. Esta decisão substitui as pendências históricas de aprovação, execução Dart, suporte Web e limpeza registradas nas seções anteriores. Os relatos e limitações das execuções foram preservados abaixo. M4 não autorizado.

### Retenção aprovada dos dados de teste

O usuário decidiu manter as contas descartáveis A, B e C no Authentication e os perfis A e C no Firestore. A retenção é uma decisão aprovada, não um bloqueio ou pendência para concluir o M3. Não excluir ou alterar esses registros sem nova autorização específica.

| Conta | UID | E-mail |
|---|---|---|
| A | CdQnPRoT1PM2CfrZewhsrfb1hzX2 | bolsozen-m3r20261117a01-a@example.com |
| B | RWBAcI9r0nZ5x6eJ7JVwFcKTjBF3 | bolsozen-m3r20261117a01-b@example.com |
| C | nluCnbgRa8NJvuv6SI3TMlTqTe83 | bolsozen-m3dart20261117c01-c@example.com |

Perfis mantidos: `users/CdQnPRoT1PM2CfrZewhsrfb1hzX2` e `users/nluCnbgRa8NJvuv6SI3TMlTqTe83`. Identidades e perfis conferidos no inventário anterior, somente de leitura. As seis transações e os dois orçamentos temporários foram removidos e sua ausência foi confirmada; os dois caminhos de probes também estavam ausentes. Nenhuma nova consulta ou mutação remota foi realizada no encerramento documental.

### Validações aprovadas e limites

| Bateria executada anteriormente | Resultado |
|---|---|
| Flutter local | 89 testes aprovados |
| Segurança Firestore no emulador demo-bolsozen | 77 testes aprovados |
| Firebase remoto pelo SDK cliente JavaScript | 28 verificações aprovadas |
| Android/MSI com repositórios Dart reais | 1 teste de integração, 16 verificações aprovadas |

Android, Firebase, regras de segurança e repositórios Dart validados dentro dos escopos descritos nos roteiros e evidências. Android permanece a plataforma principal; build e execução no MSI concluídos sem alterar os ajustes de memória Gradle. A integração Dart confirmou autenticação real, perfil idempotente, CRUD financeiro, conversões, auditoria, leitura do servidor, paginação 2+1+0 e negativas sem autenticação. O isolamento entre dois usuários autenticados foi validado nas baterias JavaScript e de regras locais, sem atribuí-lo ao roteiro Android de uma única conta.

Web configurado pela FlutterFire CLI oficial com os apps existentes; inicialização real no Chrome e tela pública validadas, incluindo confirmação dos IDs da instância Firebase. Autenticação e CRUD Web não foram validados. Não foi testada a persistência após reinício de processo no roteiro Android. A revisão visual Web não substitui homologação completa de todos os tamanhos e gestos. Os 10 informes de depreciação preexistentes do Flutter analyzer permanecem; última execução sem erros ou warnings, mas exit code 1 pelos informes. Não repetir testes remotos para esta revisão documental.

### Revisão pré-commit

`git status` mostrou 13 arquivos rastreados modificados e 30 novos, totalizando 43 candidatos. Nenhum arquivo estava no staging; não foi executado git add ou commit. Revisão do diff e varredura dos candidatos para chaves privadas, contas de serviço, tokens OAuth/refresh/JWT/GitHub/AWS, segredos JSON, senhas literais e URLs autenticadas: nenhum segredo privado identificado. A única ocorrência de possível senha foi inspecionada: interpolação de Random.secure no runner Android, não uma senha persistida. A varredura por padrões é uma verificação limitada, não garantia absoluta de ausência de segredos.

`lib/firebase_options.dart` e `android/app/google-services.json` são configurações de cliente, sem chave privada de service account. Podem ser versionados; API keys Firebase identificam o projeto e não substituem autorização por Security Rules. As restrições das API keys no Console não foram auditadas nesta etapa. Referência: https://firebase.google.com/docs/projects/api-keys.

Recomendação de seleção: 42 dos 43 candidatos podem compor o commit do M3. Deixar fora `assets/illustrations/google-services.json`, cópia byte a byte idêntica à configuração Android, redundante e fora do diretório correto; o pubspec já lista individualmente os PNGs e não empacota esse JSON. O arquivo foi preservado, sem exclusão ou alteração do .gitignore nesta tarefa. Evitar git add .; selecionar explicitamente os caminhos abaixo.

Arquivos candidatos aprováveis por grupo:

- Base/Android: `.gitignore`, `android/app/build.gradle.kts`, `android/app/google-services.json`, `android/app/src/main/AndroidManifest.xml`, `android/gradle.properties`, `android/settings.gradle.kts`, `pubspec.yaml`, `pubspec.lock`.
- Aplicação: `lib/main.dart`, `lib/app/app.dart`, `lib/app/firebase_startup.dart`, `lib/firebase_options.dart`.
- Dados: `lib/data/firebase/data_failure.dart`, `lib/data/firebase/firebase_session.dart`, `lib/data/mappers/firestore_mappers.dart`, `lib/data/repositories/firestore_budget_repository.dart`, `lib/data/repositories/firestore_transaction_repository.dart`, `lib/data/repositories/firestore_user_repository.dart`.
- Perfil de domínio: `lib/domain/models/user_profile.dart`, `lib/domain/repositories/user_repository.dart`.
- Testes Flutter: `test/data/firestore_mappers_test.dart`, `test/data/repository_session_test.dart`, `test/firebase_startup_test.dart`, `integration_test/m3_dart_repositories_test.dart`, `integration_test/m3_remote_test.dart`.
- Firebase: `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `firebase/README.md`, `firebase/REMOTE_TEST_PLAN.md`, `firebase/DART_ANDROID_TEST_PLAN.md`, `firebase/remote_preflight.cjs`, `firebase/remote_client_preflight.cjs`, `firebase/dart_android_preflight.cjs`, `firebase/tests/package.json`, `firebase/tests/package-lock.json`, `firebase/tests/rules.test.mjs`, `firebase/tests/m3_remote_client.mjs`.
- Registradores gerados que já são rastreados: `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`. Mantêm coerência com os plugins; não significam Firebase macOS/Windows configurado ou validado.
- Progresso: `docs/PROGRESSO.md`.

Artefatos locais confirmados fora da seleção/rastreamento: build/, .dart_tool/, firebase/tests/node_modules/, android/local.properties e logs de crash Android. Nunca incluir relatórios/logs, tokens da CLI, .env, keystores ou credenciais administrativas. Runners remotos ficam desabilitados por padrão; comandos históricos com flags de aprovação não devem ser repetidos, pois as contas já existem. Helpers de pré-verificação dependem da instalação local da CLI Windows e do login local, sem credenciais embutidas. Alguns trechos históricos dos roteiros/progresso têm caracteres de acentuação degradados; preservados, com esta seção como estado final vigente.

Validação desta tarefa: revisão local de arquivos, recuperação das evidências anteriores e `git diff --check`; nenhuma implementação ou teste novo. Não executados dart format, flutter analyze ou flutter test novamente, pois a única alteração desta tarefa é este documento. Nenhuma exclusão, deploy, mudança de regras/índices, commit, push ou avanço para M4. Próxima ação: usuário revisar a seleção e autorizar separadamente o commit, se desejar.

## M3 — Firebase Web finalizado em 17/11/2026

Esta seção atualiza as pendências Web dos registros históricos abaixo. Resultados anteriores de integração Android/Dart e JavaScript aprovados pelo usuário; não repetidos nesta execução.

- FlutterFire CLI oficial executada com `configure --project=bolsozen-f2f35 --platforms=android,web --android-package-name=com.bolsozen.bolsozen --web-app-id=1:691532851056:web:4590b99cc5ded05cc0d1b5 --out=lib/firebase_options.dart --yes`.
- Apps existentes conferidos pela Firebase CLI: Android `1:691532851056:android:de5076a8ee9cd05dc0d1b5` e “BolsoZen Web” `1:691532851056:web:4590b99cc5ded05cc0d1b5`. Nenhum registro duplicado ou projeto novo.
- Causa corrigida: `DefaultFirebaseOptions.currentPlatform` lançava UnsupportedError em Web; arquivo regenerado retorna opções Web, mantendo opções Android. Gerados authDomain, storageBucket e measurementId existentes do app Web; nenhum serviço de Analytics foi instalado ou habilitado nesta etapa.
- Arquivos alterados nesta etapa: `lib/firebase_options.dart`, `firebase.json` (metadados FlutterFire com plataforma Web) e `docs/PROGRESSO.md`. Nenhuma dependência adicionada/removida. Scripts e evidências temporários somente em build/, ignorado pelo Git.
- Hashes antes/depois confirmaram preservação de android/gradle.properties, google-services.json, Gradle Android, main.dart, welcome_screen.dart, firestore.rules e firestore.indexes.json. A seção Android de FirebaseOptions manteve os mesmos valores e package com.bolsozen.bolsozen. Não houve novo build ou execução Android nesta etapa; permanece válida a evidência anterior aprovada pelo usuário.

Validações desta etapa:

- `dart format .`: 35 arquivos, nenhuma alteração de formatação necessária.
- `flutter analyze`: 10 informes de depreciação preexistentes, nenhum erro ou warning; exit code 1 pelos informes (não foi um comando com saída zero).
- `flutter test --concurrency=1`: 89 testes aprovados.
- `flutter run -d chrome --no-pub --web-port=7357 --web-browser-flag=--headless --web-browser-flag=--disable-gpu`: aplicação normal compilada e executada no Chrome, bootstrap concluído e tela de boas-vindas exibida. Não houve exceção de inicialização no log nem tela de erro. Consulta somente de leitura ao depurador Dart confirmou `Firebase.app().options.projectId == bolsozen-f2f35` e App ID Web correto na instância inicializada.
- Screenshot real inspecionada em viewport 390 × 900: logo oficial, subtítulo, primeira ilustração, três indicadores e botões Entrar/Criar conta visíveis. Árvore de acessibilidade confirmou os rótulos da tela. Não foi repetida homologação de swipe ou de todas as larguras nesta etapa; fonte da UI preservada.
- `git diff --check`: aprovado, com avisos de conversão LF/CRLF em arquivos preexistentes. Chrome temporário e flutter run encerrados ao final.

Evidências locais: `build/m3-web-final-run.log`, `build/m3-web-final-analyze.log`, `build/m3-web-final-tests.log`, `build/m3-web-final.png`, `build/m3-web-browser-evidence.json`, `build/m3-web-firebase-instance.jsonl` e `build/m3-web-before-hashes.json`.

Nenhuma conta ou documento criado/alterado/excluído, nenhuma bateria de testes remotos reexecutada, nenhuma alteração de regras/índices ou memória Gradle; sem deploy, commit, M4 ou ativação de serviços pagos. Esta validação Web cobre inicialização e tela pública; não declara CRUD Web ou autenticação Web validados.

Estado histórico desta entrega Web: aguardava revisão. Revisão aprovada no encerramento acima; retenção de contas/perfis aprovada e sem bloqueio. M4 permanece não autorizado. Validação manual opcional: `flutter run -d chrome` e conferir a tela no navegador visível.

## Estado atual — 17/11/2026

- Flutter 3.50.0 stable e Dart 3.14.0 identificados nos metadados locais.
- Cinco documentos e protótipo analisados; AGENTS.md lido.
- M1 implementado e M2 validado. M3 tem configuração Firebase Android/Web e camada de dados; persistência remota aprovada em JavaScript e nos repositórios Dart Android. Sem telas de autenticação ou financeiras.
- Na verificação inicial desta etapa: main limpa, um commit à frente da referência local origin/main; sem fetch.
- M0 criou somente os documentos. M1 altera a base Flutter e dependências conforme detalhado abaixo; sem commit.

## Marcos

- [x] Análise do repositório, documentos e protótipo.
- [x] M0 — Registrar planejamento técnico e progresso.
- [ ] M1 — Implementado / Não validado integralmente: testes automatizados aprovados; Android e revisão visual pendentes; avisos do SDK registrados abaixo.
- [x] M2 — Domínio financeiro e testes: concluído no escopo puro, 53 testes unitários aprovados.
- [x] M3 — Concluído e aprovado: Android, Web e Firebase validados nos escopos registrados; 89 testes Flutter, 77 de segurança, 28 verificações JS e 16 Android/Dart aprovados. Contas A/B/C e perfis A/C mantidos por decisão aprovada, sem bloqueio.
- [ ] M4 — Autenticação completa.
- [ ] M5 — Transações e dashboard essencial.
- [ ] M6 — Gestão e histórico completos.
- [ ] M7 — Orçamento mensal.
- [ ] M8 — Relatórios.
- [ ] M9 — Homologação e APK.

M1 e M2 autorizados e implementados, com pendências próprias registradas. M3 autorizado, entrega local detalhada abaixo. M4 a M9 aguardam autorização individual. Detalhes em PLANO.md.

## Evidências do M0

- Verificação de existência dos dois documentos antes da criação e inspeção do estado Git.
- Planejamento reconciliado com requisitos, jornadas, design e critérios de aceite já lidos.
- Validação desta entrega: revisão textual e diff limitado aos dois Markdown.
- Não executados dart format ., flutter analyze, flutter test ou build: alteração exclusivamente documental; nenhum comportamento implementado ou validado.

## Bloqueios e pendências

- Sem bloqueio para concluir o planejamento.
- M3 encerrado: projeto/apps conferidos, regras publicadas correspondentes às locais, índice READY e integrações Android/Dart e Web aprovadas nos escopos registrados. Retenção das contas/perfis de teste aprovada; sem pendência de exclusão.
- Logo fornecida em assets/branding/bolsozen_logo.png; nome diferente do inicialmente informado, confirmado pelo usuário para uso sem alteração.
- Testar escala do carregamento paginado completo e conversões de datas/fuso.
- Tratar perfil parcialmente criado e gravação offline sem sucesso falso.
- Decidir assinatura de release antes da entrega; atual configuração utiliza debug.
- Sem autorização para publicar regras/índices, habilitar serviços pagos, fazer push ou deploy.

## Próxima tarefa recomendada

Revisar a seleção pré-commit do M3 descrita no encerramento acima. Commit e início de M4 exigem autorização própria. Não repetir cadastros/testes remotos ou excluir contas e perfis retidos.

## Entrega M1

### Arquivos e funcionalidades

- lib/main.dart: inicializa BolsoZenApp; contador removido.
- lib/app/app.dart: MaterialApp, tema claro, pt_BR, delegados oficiais Material/Widgets/Cupertino e título BolsoZen.
- lib/core/theme/app_colors.dart: paleta centralizada do design system.
- lib/core/theme/app_spacing.dart: espaçamentos e raios.
- lib/core/theme/app_theme.dart: Material 3, Roboto, tipografia, botões, campos e cartões.
- lib/presentation/screens/welcome/welcome_screen.dart: logo oficial com BoxFit.contain, sem edição do PNG, proposta do app, SafeArea, largura limitada e rolagem. Botões Entrar/Criar conta abrem diálogo acessível sobre disponibilidade futura, sem autenticação ou páginas falsas.
- pubspec.yaml/pubspec.lock: material_ui removido, flutter_localizations e intl adicionados como dependências diretas; dependências transitivas desnecessárias removidas pelo resolvedor. Preservada alteração prévia do usuário cupertino_icons ^2.0.0. Corrigida declaração de assets para dentro de flutter.
- test/widget_test.dart: substitui teste do contador por 10 testes de marca/localização, ações, layout e disponibilidade de formatação BRL via intl; nenhuma regra financeira antecipada.
- assets/branding/bolsozen_logo.png: arquivo preexistente do usuário, apenas referenciado, sem edição ou renomeação.

### Verificações executadas

- flutter pub get: sucesso.
- dart format .: sucesso; última execução, 7 arquivos verificados, 0 alterações.
- flutter analyze: executado, saída 1 com 8 informações de deprecated_member_use, sem erros de compilação ou warnings. SDK local deprecia flutter/material.dart, flutter/cupertino.dart e GlobalMaterialLocalizations em favor dos pacotes separados. Não suprimidos diagnósticos nem reintroduzida dependência sem autorização. Esta divergência não era conhecida no planejamento.
- flutter test: última execução aprovada, 10/10. Corrigidos dois testes de toque para rolar até os botões quando a viewport é baixa.
- Responsividade automatizada: 360, 390 e 412 dp, altura 640, escala de texto 1 e 2; botões acessíveis por rolagem, sem exceções de layout. Isso não constitui comparação visual por screenshots.
- flutter devices: nenhum Android conectado inicialmente. flutter emulators encontrou Pixel_8 e Medium_Phone_API_37.0.
- flutter emulators --launch Pixel_8: comando aceito; dispositivo emulator-5554 permaneceu offline nas verificações seguintes.
- flutter run -d emulator-5554 --no-pub: falhou, nenhum dispositivo suportado correspondente. Sem evidência de renderização Android ou screenshot real; não declarar aprovação visual.

### Diferenças e validação manual pendente na entrega inicial

- Usada a logo oficial fornecida, diferente da carteira da prancha; nome já integrado ao PNG, sem duplicá-lo como texto visual. Sem recorte, distorção ou substituição.
- Ilustração secundária de gráfico/moedas ausente por não haver asset fornecido; não foi inventada. Pontos decorativos de carrossel omitidos conforme design system.
- Título explicativo e conteúdo centralizado, botões após o conteúdo e rolagem em telas compactas; hierarquia adaptada à logo fornecida, sem alegação pixel-perfect.
- Roboto declarada no tema, sem download de fontes ou dependência adicional; confirmar aparência no Android.
- Abrir emulador funcional ou conectar Android com depuração USB; executar flutter devices e flutter run -d <id>. Conferir proporções/transparência da logo, cores, espaçamentos, rolagem, diálogos, TalkBack, texto ampliado e comparar screenshot com prancha.
- Decidir se manter imports depreciados conforme autorização original ou revisar a remoção de material_ui para alinhar ao SDK atual. Não alterar SDK, reintroduzir pacotes ou ocultar diagnósticos sem decisão.
- M1 permanece Implementado / Não validado integralmente até revisão visual/Android e resolução da pendência do analisador. Nenhum M2+, Firebase, commit, push ou deploy realizado.

### Ajuste visual M1 — carrossel e hierarquia

- Ajuste autorizado explicitamente pelo usuário: carrossel funcional simples, apesar de o design system permitir pontos meramente decorativos. Documentos de requisitos e protótipo preservados.
- Arquivos alterados nesta revisão: lib/presentation/screens/welcome/welcome_screen.dart, pubspec.yaml, test/widget_test.dart e docs/PROGRESSO.md. Mantidas as demais alterações preexistentes do M1.
- Confirmados e inspecionados visualmente onboarding01.png, onboarding02.png e onboarding03.png. Corrigida declaração para assets/illustrations/ dentro de flutter/assets; sem editar imagens, adicionar pacotes ou alterar lockfile nesta revisão.
- Removido título “Suas finanças com mais tranquilidade”. Ordem atual: logo oficial em 128 × 128 com proporção preservada, nome BolsoZen, único subtítulo solicitado, carrossel e botões. O PNG original já contém o nome da marca; foi preservado integralmente, com nome textual separado conforme solicitado.
- Carrossel com PageView nativo, três páginas, swipe horizontal, sem autoplay e sem textos específicos por slide. Área responsiva com AspectRatio e BoxFit.contain; três pontos atualizados por onPageChanged e anúncio semântico “Ilustração N de 3”. Estado limitado ao widget privado do carrossel.
- Botões mantêm estilos existentes e diálogos de disponibilidade futura; sem autenticação, rotas falsas ou lógica financeira.
- dart format .: aprovado, 7 arquivos processados na última execução.
- flutter analyze: executado; saída 1, mesmos 8 diagnósticos informativos deprecated_member_use do SDK, sem novos diagnósticos. Não suprimidos nem alteradas dependências fora do pedido.
- flutter test: aprovado, 11/11. Teste novo verifica swipe até as três imagens, retorno à segunda, três pontos presentes e anúncio da página; mantidos testes de botões/localização e layout em 360/390/412 dp com texto 1× e 2×. Corrigido descarte do handle semântico do teste antes do encerramento.
- Diferenças restantes: logo e ilustrações são os arquivos oficiais fornecidos, com composição própria diferente da prancha; dimensões adaptadas ao layout Flutter, rolagem para alturas compactas/texto ampliado. Não houve captura ou comparação de screenshots reais nesta revisão, portanto não se afirma fidelidade pixel-perfect.
- Validações manuais pendentes: renderização Android, aparência/transparência das imagens em fundo branco, proporções/espaçamentos, swipe real, indicador e TalkBack, comparação com o protótipo. Permanece a decisão sobre depreciações do SDK antes de encerrar integralmente M1. Não iniciar M2 sem autorização; sem commit.

## Registro das próximas fases

## M3 — validação remota JavaScript autorizada e concluída

- Projeto exclusivo: bolsozen-f2f35, database (default), app Web existente. Execução m3r20261117a01 em 17/11/2026, aproximadamente 12:43:16–12:43:26 (UTC-3). Pré-verificação confirmou contas ausentes, regras iguais às locais e índice transactions CICAgOjXh4EK em READY imediatamente antes das mutações autorizadas.
- Runner novo firebase/tests/m3_remote_client.mjs: desabilitado por padrão, sem rede nesse modo; execução exige --execute-approved e --allow-profile-remainder. Bloqueia journal existente, evitando recadastro/reexecução automática. Senhas geradas criptograficamente em memória, sessões A/B/guest separadas com persistência somente em memória e cache Firestore em memória; sem contas pessoais, Admin SDK, service accounts ou tokens de gerenciamento nas operações financeiras.
- Helper novo firebase/remote_client_preflight.cjs: consultas de gerenciamento somente de leitura para regras/índice, lookup restrito aos dois emails e configuração do app Web já registrado. Não acessa documentos financeiros. Na primeira tentativa, houve falha no helper antes de iniciar a execução; corrigido reaproveitamento indevido do objeto de opções que a biblioteca da CLI modifica entre GET e POST. Pré-verificação repetida e aprovada antes de qualquer criação.
- firebase/tests/package.json: adicionado comando separado test:remote:client, sem novas dependências. Reutilizado firebase 12.19.0 já instalado. firebase/REMOTE_TEST_PLAN.md atualizado com variante JS, evidências e limitação dos repositórios Dart.
- Nenhum arquivo Flutter de produto, configuração Gradle, regra ou índice foi alterado nesta etapa. Ajustes de memória do usuário preservados. Armazenamento não é mais bloqueio conforme informado pelo usuário (>60 GB livres); máquina continua com aproximadamente 8 GB de RAM. Não houve compilação Android nem limpeza de caches.

### Resultados remotos — 28 verificações aprovadas, 0 falhas

- Dois casos de Authentication: criação das contas A/B, logout/login normal e confirmação do mesmo UID.
- Um caso de sessões independentes: A e B mantêm os respectivos UIDs, guest permanece sem autenticação.
- Um caso de perfil: criação transacional com createdAt de servidor e leitura confirmada.
- Três casos de receitas: criar/ler os documentos com 101, 202 e 303 centavos, tipo income/salary, marcação TESTE_M3 e data 2099-12-10.
- Um caso de edição: primeira receita passa para 111 centavos e descrição de teste atualizada; nova leitura confirma conteúdo e createdAt preservado.
- Um caso de paginação: occurredAt DESC, createdAt DESC e ID ASC, três páginas de 2, 1 e 0 itens, IDs completos sem repetição e ordem conferida.
- Dois casos de orçamento: criar/consultar mês 2099-12_food com 1000 centavos, alterar para 1200 e confirmar criação preservada.
- Doze casos de segurança: B e guest, cada um tentando ler/criar/alterar/excluir receita de A e ler perfil/orçamento de A. Todas as doze falhas retornaram explicitamente permission-denied; nenhuma falha genérica de rede foi aceita como prova. Nenhum acesso indevido permitido.
- Um caso de integridade: receita permanece com 111 centavos e probes inexistentes após tentativas indevidas.
- Quatro casos de exclusão: remover orçamento e três receitas, verificando ausência no servidor; orçamento também ausente na consulta mensal.
- Esses 28 casos são verificações agrupadas do runner JS, não testes dos repositórios Dart. Usa SDK firebase/app + firebase/auth + firebase/firestore, sem emulador durante a validação remota. Operações financeiras não usam credenciais da CLI. Não houve nenhuma alteração de dados preexistentes, regras/índices, faturamento, deploy, commit ou push.

### Limpeza confirmada e remanescentes

Sob users/CdQnPRoT1PM2CfrZewhsrfb1hzX2/, removidos e verificados por getDocFromServer:

- transactions/BDZlwKMnJLFGy3fYQjQB
- transactions/Y77XhxcMwjM1l8biwALr
- transactions/YXs8Ppmwx9jUiSBUi4mC
- budgets/2099-12_food

Probes transactions/m3r20261117a01-probe-b e transactions/m3r20261117a01-probe-guest não foram criados (permission-denied) e tiveram ausência conferida. remainingFinancialDocuments=[] no relatório. Nenhuma exclusão de coleção ou de dados de outros usuários.

Remanescentes autorizados para limpeza posterior:

- Perfil: users/CdQnPRoT1PM2CfrZewhsrfb1hzX2. A regra nega delete; não houve tentativa de contorno ou de exclusão administrativa.
- Conta A: UID CdQnPRoT1PM2CfrZewhsrfb1hzX2; email bolsozen-m3r20261117a01-a@example.com.
- Conta B: UID RWBAcI9r0nZ5x6eJ7JVwFcKTjBF3; email bolsozen-m3r20261117a01-b@example.com.
- Contas deslogadas, instâncias locais do SDK encerradas; nenhuma conta Authentication excluída. Não há senhas salvas para reutilização. Limpeza posterior deve ser específica por UID, após autorização.

### Evidências e limites

- build/m3r20261117a01-js-events.jsonl: eventos sanitizados gravados antes/depois de operações, com UIDs/caminhos, sem senhas/tokens/configuração cliente.
- build/m3r20261117a01-js-report.json: passed=28, failed=0, overallPassed=true, securityFailure=false, dartRepositoriesTested=false. Processo terminou com código 0; memória residente final aproximadamente 121 MiB (não medição de pico).
- node --check dos dois arquivos novos aprovado; modo padrão desabilitado exercitado sem rede e sem mutações. dart format . aprovado (35 arquivos, somente arquivo temporário build/test/listener_0.dart foi reformatado); flutter analyze executado, 10 informações de depreciação conhecidas, sem erros/warnings; flutter test --concurrency=1 aprovado, 89/89. Evidências locais em build/m3-js-final-analyze.log e build/m3-js-final-flutter.log. git diff --check aprovado. Nenhum build Android iniciado; duas consultas/verificações locais antigas e travadas do próprio agente foram encerradas para evitar duplicação, preservando processos do VS Code e MSI.
- Integração remota dos repositórios Dart/Flutter permanece pendente: JS não prova comportamento dos plugins/mapeadores Dart, inicialização Web Flutter ou renderização Android. O roteiro Dart original não deve ser repetido com cadastros existentes; requer estratégia posterior e aprovação. M4 permanece não iniciado.

## M3 — preparação de testes remotos, sem mutações executadas

- Autorizada somente preparação e diagnóstico até aprovação explícita dos identificadores/operações/limpeza. Nenhuma conta ou documento remoto foi criado, alterado ou removido nesta etapa. Nenhum novo deploy.
- Projeto bolsozen-f2f35, database (default), região southamerica-east1; configuração Android segue com.bolsozen.bolsozen e App ID existente. A árvore Git já continha mudanças do M3, ajustes Gradle do usuário e os dois JSONs fornecidos. Não estava limpa; nenhum arquivo alheio foi descartado e não houve mudanças de UI nesta preparação.
- Diagnóstico somente de leitura: firebase/remote_preflight.cjs usa o login da CLI apenas para GETs de metadados (release/ruleset e estado do índice), não para acesso a documentos. Não usa Admin SDK, service account nem imprime tokens. Regras remotas publicadas em 2026-11-17T15:01:28.070215Z, fonte correspondente ao arquivo local após normalização de BOM/finais de linha, SHA-256 d5bd92b0ac7be98377a62c72b88c8eedcb3ef0b091823219366b113a1b7e8573.
- Índice transactions CICAgOjXh4EK: READY; collection scope, occurredAt DESC, createdAt DESC e __name__ ASC. A listagem resumida da CLI omite estado; confirmado pela API de gerenciamento, sem consultar documentos ou criar índice duplicado. Revalidar antes da execução; se não READY, bloquear fetchPage/paginação e testar somente referências de documento e consultas independentes.
- Rotina preparada em integration_test/m3_remote_test.dart, separada do ponto de entrada do app e desabilitada por padrão. Exige M3_REMOTE_APPROVED=true e aceitação explícita M3_ALLOW_PROFILE_REMAINDER=true antes de inicializar SDK/criar contas. Alvo fixo Android e projeto esperado; M3_INDEX_READY controla consultas dependentes do índice.
- Dependência de desenvolvimento adicionada: integration_test oficial do SDK Flutter, com transitivas de ferramentas registradas no lockfile; nenhuma dependência runtime nova. Resolução completada com permissão de symlink do Windows, sem alterar configuração do sistema.
- Plano completo em firebase/REMOTE_TEST_PLAN.md. Execução m3r20261117a01; duas contas de exemplo bolsozen-m3r20261117a01-a@example.com e bolsozen-m3r20261117a01-b@example.com. Senhas aleatórias somente em memória. UIDs e IDs de transação gerados pelo Firebase serão relatados após criação autorizada, sem credenciais.
- Planejado: um perfil A, três receitas temporárias para CRUD/paginação, um orçamento 2099-12_food, duas tentativas de criação indevida que devem ser negadas. Operações próprias pelos repositórios Dart; acessos ao UID A por B/guest via SDK cliente direto exigem permission-denied, nunca falha genérica de rede.
- Limitação de limpeza identificada antes de criar dados: rules/users/{uid} nega delete. Perfil A não pode ser removido por esse cliente; deverá constar como remanescente para limpeza manual específica no Console pelo proprietário. Não alterar regras nem usar conta administrativa para contornar isso. Se esse remanescente não for aprovado, não executar o roteiro completo.
- Receitas, orçamento e probes serão removidos/verificados somente em caminhos rastreados desta execução. Nenhuma exclusão de coleção. As duas contas Authentication ficarão até autorização específica posterior; a rotina não contém User.delete. Senhas não serão retidas; limpeza posterior de contas pelo proprietário no Console com UIDs relatados.
- Testes remotos executados: nenhum. Segurança remota via SDK cliente: ainda não testada. Repositórios Dart remotos: ainda não testados. Limpeza remota realizada: nenhuma, pois não houve criações. Roteiro aguardando aprovação.
- Verificações locais finais: dart format . aprovado (34 arquivos); flutter analyze executado, 10 informações de depreciação conhecidas, sem erros/warnings; flutter test --concurrency=1 aprovado (89/89); Emulator Suite local demo-bolsozen aprovado (77/77); git diff --check aprovado. Evidências em build/m3-remote-prep-analyze.log, build/m3-remote-prep-flutter.log e build/m3-remote-prep-security.log. Ocorreram falhas transitórias do runtime Windows/Dart na primeira tentativa local; conflito de import Category na rotina foi corrigido e as verificações repetidas. O teste de integração remoto não foi executado. Nenhum resultado remoto inferido dos testes locais.
- Arquivos desta preparação: novos firebase/remote_preflight.cjs, firebase/REMOTE_TEST_PLAN.md e integration_test/m3_remote_test.dart; atualizados pubspec.yaml/pubspec.lock para ferramenta oficial de testes e docs/PROGRESSO.md. Código de produto/UI e regras/índices preservados.
## Revisão final da infraestrutura M3

- Destino novamente confirmado em consulta somente de leitura: bolsozen-f2f35. JSON Android, opções Dart, metadados FlutterFire, namespace/applicationId e app listado pela CLI concordam com com.bolsozen.bolsozen e o mesmo App ID registrado. Nenhuma chave copiada para esta documentação.
- main.dart mantém WidgetsFlutterBinding.ensureInitialized e Firebase.initializeApp com DefaultFirebaseOptions.currentPlatform; FirebaseStartup só libera boas-vindas após sucesso, mostra erro recuperável e registra diagnóstico em debug. Nenhuma leitura/gravação financeira automática na abertura.
- Usuário informou compilação e execução Android pelo MSI App Player após ajuste de memória. Revisão confirmou dispositivo 127.0.0.1:5556 conectado (Android 9/API 28, android-x64), APK debug local de 74.013.148 bytes e pacote instalado. Ao abrir o pacote já instalado, processo com.bolsozen.bolsozen PID 5102 e log do mesmo PID: FirebaseInitProvider: FirebaseApp initialization successful. Não houve reinstalação, limpeza de dados ou nova compilação nesta revisão.
- Limite da evidência Android: inicialização nativa verificada e execução visual relatada pelo usuário. Captura inicial desta revisão ficou branca e attach ao VM Service não concluiu; foi encerrado. Portanto, não considerar screenshot de boas-vindas ou CRUD remoto independentemente homologados nesta revisão. Nenhuma falha Firebase foi encontrada no log filtrado do processo; há aviso de depreciação do opt-out Impeller, sem alteração da renderização nesta tarefa.
- Preservados integralmente os ajustes preexistentes em android/gradle.properties: heap 1536 MB, metaspace 512 MB, code cache 256 MB, HeapDumpOnOutOfMemoryError, parallel=false, workers.max=2 e daemon=true. Não restaurar heap 8 GB. A ausência de newline final também não foi alterada.
- Regras revisadas: owner exige autenticação e UID igual ao caminho; userId validado nas escritas, createdAt imutável, updatedAt de servidor, campos/tipos/categorias e identidade de orçamento restritos; negação padrão continua ativa para caminhos não previstos. Regras locais não foram publicadas.
- Testes de acesso cruzado refinados para usar payload válido de cada coleção: a recusa não depende de campos extras ou auditoria ausente. Arquivo alterado: firebase/tests/rules.test.mjs; mantidos os mesmos 77 casos.
- Consultas/índices conferidos: transactions usa occurredAt DESC, createdAt DESC e FieldPath.documentId ASC, em coleção do UID, com cursor desses três valores. firestore.indexes.json coincide com essa ordem, inclusive __name__ ASC explícito. Budgets usa igualdade simples em monthKey; perfil leitura por ID. Não há necessidade de índice composto adicional para essas duas consultas.
- firebase firestore:indexes --project bolsozen-f2f35 --json retornou indexes=[] e fieldOverrides=[] nesta revisão, sem alteração remota. Isso não confirma que o índice local está disponível no servidor; ele ainda deverá ser criado e atingir estado pronto após autorização.
- Qualidade: dart format . aprovado (33 arquivos, apenas formatação do diagnóstico de bootstrap da tarefa anterior); flutter analyze executado, 10 informações de depreciação, nenhum erro/warning; flutter test --concurrency=1 aprovado, 89/89; git diff --check aprovado.
- Segurança: novamente executado Firebase Emulator Suite exclusivamente com demo-bolsozen e host 127.0.0.1:8080, 77/77 aprovados; acesso de outro UID e anônimo negado para leitura/edição/exclusão. Nenhum dado de produção usado nos testes. Evidências em build/m3-final-security.log, build/m3-final-analyze.log e build/m3-final-flutter.log.
- Pendência Web da tarefa interrompida: falha original confirmada por execução Chrome e log UnsupportedError em DefaultFirebaseOptions.currentPlatform, sem opções Web. Após autorização explícita, app BolsoZen Web foi registrado no mesmo projeto, mas a regeneração FlutterFire foi interrompida e o arquivo local permanece Android-only. Esta revisão não registra outro app nem declara suporte Web concluído.
- Arquivos alterados nesta revisão: docs/PROGRESSO.md, firebase/README.md, firebase/tests/rules.test.mjs e formatação de lib/app/firebase_startup.dart. Demais mudanças preexistentes preservadas, incluindo gradle.properties.

### Publicação preparada — não executada

Na raiz, conferir novamente o destino e os índices existentes imediatamente antes de publicar:

```powershell
firebase apps:list ANDROID --project bolsozen-f2f35
firebase firestore:indexes --project bolsozen-f2f35 --json
```

Somente após autorização explícita, publicar separadamente os alvos exatos:

```powershell
firebase deploy --project bolsozen-f2f35 --config firebase.json --only firestore:indexes
firebase deploy --project bolsozen-f2f35 --config firebase.json --only firestore:rules
```

Arquivos de origem: firestore.indexes.json e firestore.rules; firebase.json seleciona os caminhos. Não publica Hosting, Functions, Authentication, arquivos do app ou dados financeiros. Não usar --force ou confirmar remoções de índices existentes. Publicar regras substitui o conjunto remoto vigente pelo arquivo local; revisar antes da autorização. Aguardar índice pronto no Console e validar consultas após publicação. Referências: https://firebase.google.com/docs/cli e https://firebase.google.com/docs/firestore/query-data/index-overview.

Nenhum comando firebase deploy foi executado (somente deploy --help para conferir a CLI). M4 não iniciado; sem commit, faturamento ou alteração de dados remotos. Para concluir M3 permanecem publicação autorizada, verificação remota controlada, CRUD dos repositórios Dart ponta a ponta e conclusão Web já solicitada.

## Entrega M3 — configuração Firebase, dados e segurança local

Estado: Implementado / Não validado integralmente. Nenhum projeto/app adicional criado, faturamento habilitado, regra/índice publicado, dado remoto excluído, login implementado ou commit realizado.

### Diagnóstico e configuração

- Antes das alterações: main quatro commits à frente da referência local origin/main; somente android/app/google-services.json e assets/illustrations/google-services.json não rastreados. Ambos preexistentes, com conteúdo idêntico e preservados.
- Projeto identificado por firebase projects:list e apps:list: bolsozen-f2f35, app Android existente com package com.bolsozen.bolsozen. Conferidos project ID, App ID e package do JSON contra a CLI e applicationId/namespace do Gradle. Não registrar chaves na documentação.
- Flutter 3.50.0, Dart 3.14.0, Firebase CLI 15.36.0, FlutterFire CLI 1.5.0, Node 24.11.1. Java do PATH/Gradle direto: 24.0.2; Flutter usa JBR 25.0.4 do Android Studio. Gradle wrapper 9.5.0, AGP 9.3.1 e plugin Kotlin declarado 2.4.20. flutter doctor não apontou incompatibilidades; Android emulator-5554 offline.
- A listagem inicial de projetos retornou sucesso JSON, mas o processo Node encerrou com assert de libuv. Consulta subsequente dos apps e FlutterFire em PTY funcionaram. FlutterFire foi localizado no Pub Cache, pois não estava no PATH da sessão.
- Executado flutterfire configure com project bolsozen-f2f35, platforms android e package com.bolsozen.bolsozen. Revisada saída lib/firebase_options.dart: apenas Android, mesmo App ID existente. Arquivos google-services/Gradle revisados; plugin com.google.gms.google-services 4.4.4 configurado. Sem outra plataforma registrada.
- Pacotes instalados/resolvidos: firebase_core 5.2.0, firebase_auth 7.1.0 e cloud_firestore 7.2.0, com lockfile atualizado. Resolução inicial apontou falta de suporte a symlinks; flutter pub get com permissão ampliada concluiu sem mudar configuração do Windows.
- Declarados individualmente os três PNGs de ilustração no pubspec para não empacotar a cópia JSON localizada nessa pasta. Nenhum asset foi excluído ou editado. Permissão INTERNET adicionada ao manifesto principal Android.

### Implementação e arquivos

- lib/firebase_options.dart: gerado pelo FlutterFire; configuração cliente Android, sem credenciais administrativas.
- lib/main.dart, lib/app/app.dart e novo lib/app/firebase_startup.dart: Firebase.initializeApp com opções geradas antes de liberar boas-vindas; carregamento, erro explícito sem detalhes técnicos e retry. A inicialização do SDK não afirma disponibilidade do banco remoto. Tela/carrossel preservados.
- lib/data/firebase/data_failure.dart: falhas tipadas com mensagens pt-BR; lib/data/firebase/firebase_session.dart: UID proveniente de FirebaseAuth e verificação de troca de sessão após operações assíncronas.
- lib/data/mappers/firestore_mappers.dart: campos permitidos/obrigatórios, tipos exatos, int monetário, categorias, timestamp, proprietário e identidade mensal; conversões transação/orçamento/perfil. Campos de auditoria escritos pela camada de repositório, nunca escolhidos pela UI.
- lib/data/repositories/firestore_transaction_repository.dart: criação com ID gerado, edição e exclusão transacionais; consulta por UID ordenada por occurredAt DESC, createdAt DESC e ID ASC, cursor de valores e limite de 1–100; leitura Source.server e resultado imutável. Preserva createdAt e rejeita proprietário/cursor divergente.
- lib/data/repositories/firestore_budget_repository.dart: consulta mensal indexada, salvar/criar/editar/remover limite por competência e categoria; preserva createdAt e não altera transações.
- lib/data/repositories/firestore_user_repository.dart: obter e garantir perfil idempotente; UID/e-mail vêm da sessão, perfil existente não é sobrescrito. Novos lib/domain/models/user_profile.dart e lib/domain/repositories/user_repository.dart definem o mínimo necessário à infraestrutura, sem autenticação real.
- Escritas usam transações com leitura e timestamps de servidor: sucesso depende de confirmação; não há anúncio falso de gravação offline. Nenhum cálculo financeiro duplicado e nenhum controlador financeiro criado. Repositórios ainda não conectados à UI.
- firestore.rules: negação por padrão; proprietário autenticado; campos/tipos; dinheiro positivo; categoria compatível; descrição; competência e ID do limite; timestamps de auditoria; imutabilidade de UID/criação e de competência/categoria dos limites. Perfil exige e-mail da sessão; exclusão de perfil não liberada, pois exclusão de conta não pertence ao MVP.
- firestore.indexes.json: índice composto da ordenação de transações. Orçamentos usam índice simples de monthKey e perfis leitura por ID. Nenhum índice publicado.
- firebase.json: configuração FlutterFire preservada e seções locais de regras/índices/emuladores (Firestore 127.0.0.1:8080, Auth 127.0.0.1:9099; UI desabilitada). Não foi criado alias remoto padrão para os testes.
- firebase/tests/package.json, package-lock.json e rules.test.mjs: testes Node; firebase/README.md contém comando reproduzível e isolamento do projeto demo.
- test/data/firestore_mappers_test.dart, test/data/repository_session_test.dart e test/firebase_startup_test.dart: conversões, recusa de inválidos, barreiras de sessão e inicialização/falha/retry.
- .gitignore: node_modules, artefatos locais Firebase e cache android/.kotlin. Flutter atualizou automaticamente registradores de plugins em macos/Flutter/GeneratedPluginRegistrant.swift e windows/flutter/generated_plugin_registrant.cc/generated_plugins.cmake; isso não registra apps Firebase nessas plataformas.
- android/settings.gradle.kts, android/app/build.gradle.kts, android/app/src/main/AndroidManifest.xml, pubspec.yaml, pubspec.lock e este documento também alterados.

### Testes e evidências locais

- dart format .: aprovado; última execução, 33 arquivos, 0 alterações.
- flutter analyze: executado, sem erros/warnings; saída 1 por 10 diagnósticos informativos deprecated_member_use. Oito já existentes e dois imports Material nos novos bootstrap/teste. Não suprimidos; não reintroduzida dependência rejeitada no M1.
- flutter test --concurrency=1: 89/89 aprovados (64 preexistentes, 20 de mapeadores, 4 de sessão/repositórios e 1 de startup). Corrigido retry que inicialmente retornava Future no callback de setState. Bem-vindas/carrossel continuam passando nos testes de widgets.
- Emulator Suite: firebase emulators:exec --project demo-bolsozen --only firestore "npm --prefix firebase/tests test" aprovado: 77/77, zero falhas. Testes recusam iniciar sem host local explícito, usam project ID demo fixo e limpam somente emulador. Nenhum teste leu/escreveu dados de produção.
- Cobertura de regras: proprietário, outro UID, anônimo; leitura/edição/exclusão; UID divergente; negativos/zero/decimais/tipos inválidos; categorias incompatíveis; campos inesperados/ausentes; descrição vazia/longa; datas; createdAt imutável; competência/ID de orçamento; perfil/e-mail; negação padrão; consultas e paginação. Duas fixtures iniciais foram corrigidas para realmente modificar auditoria e testar criação, não atualização de registro existente.
- Dependências Node: @firebase/rules-unit-testing 5.0.2 e firebase 12.19.0 como devDependencies. Override compatível @grpc/grpc-js ^1.13.6 corrige vulnerabilidade transitiva identificada na instalação; npm audit após ajuste: zero vulnerabilidades. Essas ferramentas não entram no APK.
- Evidências brutas locais em build/m3-analyze.log, build/m3-flutter-tests.log, build/m3-security.log e build/m3-android-build.log; diretório build ignorado pelo Git.
- git diff --check executado sem erros de whitespace; avisos de conversão LF/CRLF não representam falha.

### Bloqueios e limites de validação

- Primeira compilação Android falhou: daemon Gradle com heap 8 GB encerrou por memória nativa insuficiente. Houve também falta de espaço (C: chegou a ~5 MB), causando falha do compilador Dart. Usuário liberou espaço; testes Flutter foram repetidos e aprovados, sem excluir arquivos existentes.
- Segunda tentativa Android usou opções temporárias de processo para heap 1536 MB, metaspace 512 MB e dois workers, sem alterar gradle.properties. Falhou em :app:mergeDebugNativeLibs/ExtractJniTransform por espaço insuficiente ao extrair bibliotecas arm64/x86_64. O ~1 GB liberado foi consumido durante o build; C: voltou a menos de 1 MB livre. Nenhum APK produzido. Não repetir build antes de liberar vários GB (sugestão operacional: ao menos 5–10 GB para ferramentas/caches, sem garantia de consumo máximo).
- Emulador Android permanece offline; inicialização nativa e screenshot real não foram validados. Suíte de regras é execução real no emulador Firestore; testes Dart de repositórios cobrem barreiras de sessão/entrada, não CRUD positivo nativo ponta a ponta. Consultas equivalentes e CRUD positivo foram exercitados no SDK JS contra regras locais.
- Configuração cliente corresponde ao projeto remoto, mas não houve teste de autenticação/persistência remoto, publicação de regras/índices ou confirmação de que as regras preparadas estão ativas no serviço. O Firestore remoto continua com a configuração preexistente do usuário.
- Antes de concluir M3: liberar espaço sem apagar dados do usuário automaticamente, repetir build Android, validar inicialização e CRUD dos repositórios Dart em Android com emuladores locais; revisar regras/índices e autorizar separadamente qualquer publicação e validação remota controlada. M4 permanece não iniciado.

## Entrega M2 — domínio financeiro

Estado: Concluído no escopo autorizado de domínio puro. Nenhuma alteração na UI, configuração Firebase, implementação de persistência, autenticação, dependência nova ou commit.

### Arquivos criados

- lib/domain/models/category.dart: TransactionType e catálogo fechado de dez categorias, IDs estáveis, rótulos pt-BR e compatibilidade por tipo.
- lib/domain/models/financial_month.dart: competência com chave YYYY-MM, igualdade por valor, deslocamento mensal e agrupamento pelo calendário local.
- lib/domain/models/financial_transaction.dart: modelo imutável validado, centavos positivos, descrição trim de 1–120 caracteres, categoria compatível e copyWith preservando identidade/criação.
- lib/domain/models/monthly_budget.dart: limite imutável por usuário/mês/categoria de despesa, valor positivo e ID determinístico.
- lib/domain/models/financial_summary.dart: resultados imutáveis de totais mensais, utilização, distribuição, evolução e histórico. Percentuais são double derivados; dinheiro continua int. Coleções de saída não modificáveis.
- lib/domain/repositories/transaction_repository.dart: contrato financeiro por UID, consulta paginada com cursor de domínio e operações criar/editar/excluir; sem tipos Firebase. Criação retorna ID gerado pela implementação futura.
- lib/domain/repositories/budget_repository.dart: contrato financeiro por UID, consulta, salvar/substituir e remover limite mensal. Sem implementações, mocks ou contratos de autenticação antecipados.
- lib/domain/services/money.dart: parsing estrito de valores positivos pt-BR com agrupamento opcional, R$ e 1–2 casas decimais; formatação exata em BRL, inclusive saldo zero/negativo. Sem conversão monetária para double.
- lib/domain/services/financial_calculator.dart: funções puras, sem Flutter/Firebase/relógio. Recebem UID, competência, transações completas e limites; ignoram dados de outros UIDs. Saldo global, totais mensais, ordenação, categorias, orçamento, comparação e evolução de seis meses. Agregações protegem contra overflow do inteiro nativo com BigInt intermediário, retornando int ou erro explícito.
- test/domain/fixtures.dart: conjuntos controlados apenas para testes.
- test/domain/money_test.dart, models_test.dart e financial_calculator_test.dart: 53 testes unitários do domínio.
- docs/PROGRESSO.md atualizado; demais arquivos preexistentes preservados.

### Regras e evidências

- T1: saldo 60000 centavos, receita novembro 100000, despesa novembro 35000 e outubro 5000; seleção mensal não muda saldo global.
- T2: alimentação 83,33%, transporte 50%, indicador global 70%; despesas sem limite não entram no indicador. Percentuais acima de 100% não truncados; atenção em 80% e atingido em 100%, com comparação inteira dos limiares.
- Relatórios: participação alimentação ≈71,43% e transporte ≈28,57%, variação +600%, evolução de seis meses com virada de ano; redução pode ser negativa e base anterior zero retorna null.
- CA-07 reproduzido: edição para R$ 200 gera saldo R$ 650,00, novembro R$ 300,00 e alimentação 66,67%; mudança para outubro redistribui totais sem alterar saldo; exclusão de transporte eleva saldo a R$ 750,00.
- Cobertos: saldos positivo/zero/negativo, centavos além da precisão de double no runtime nativo, inválidos, categorias incompatíveis, valores zero/negativos, futura ocorrência, auditoria distinta da ocorrência, conversão UTC/local, ordenação por ocorrência/criação/ID ascendente, imutabilidade, remoção de limite e ausência de herança mensal.
- Sem limites: percentual/status null; sem despesas: distribuição vazia, nunca dados fictícios. Nenhuma divisão por zero. Duplicação de limites na mesma competência/categoria é recusada em vez de sobrescrever silenciosamente o cálculo.
- dart format .: aprovado, 20 arquivos processados na última execução, 0 alterações.
- dart analyze lib/domain: aprovado, No issues found.
- flutter analyze: executado; permanecem somente os 8 diagnósticos informativos preexistentes de deprecated_member_use do M1, saída 1; nenhum diagnóstico no M2. Seis apontamentos iniciais de estilo dos novos arquivos foram corrigidos e as verificações repetidas.
- flutter test: aprovado, 64/64 (53 domínio + 11 widgets preexistentes).
- git diff --check: aprovado. Nenhuma instalação, publicação ou alteração de dependências.

### Limitações e pendências antes de M3

- Contratos não têm implementação: geração de IDs/auditoria, paginação real, Firestore, índices e segurança de acesso devem ser implementados/testados apenas no M3 autorizado. Filtragem por UID no cálculo não substitui regras de segurança.
- Chamador deve fornecer histórico completo sem duplicatas; o domínio não infere se faltam páginas. Meses são agrupados pelo fuso local do runtime, sem fuso fixo adicional. Testes validam UTC/local no ambiente atual; variações entre dispositivos permanecem para integração.
- Valores monetários usam faixa de int do runtime Android/nativo; excesso é rejeitado, sem arredondamento silencioso. Web não é critério do MVP. Categorias/descrição são validadas por construtores, e dados inválidos vindos de serviços devem ser tratados na camada de dados futura.
- Autorização do usuário, acesso ao Console, região e ferramentas Firebase ainda pendentes para M3. Pendências visuais/Android e depreciações do M1 permanecem independentes desta entrega.
- Validação manual sugerida: revisar os contratos e os resultados T1/T2 antes de autorizar M3. Não há tela financeira a validar neste marco.

### Revisão M1 — logo ampliada e tipografia

- A pedido do usuário, removido nome BolsoZen em texto separado: o título visual agora é exclusivamente o nome incorporado à logo oficial.
- Logo ampliada de 128 para 280 dp, limitada pela largura disponível e com BoxFit.contain, sem modificar o PNG. Mantidos subtítulo único, carrossel e botões; rolagem preserva acesso em telas menores.
- Todos os estilos do TextTheme explicitam Roboto e seguem os tamanhos/pesos documentados: títulos 28/20/16, corpo 14 e legendas 12 sp. Ajustadas entrelinhas e espaçamento de letras para composição mais compacta e consistente com a referência. Diálogos também herdam a tipografia global.
- Arquivos alterados nesta revisão: lib/presentation/screens/welcome/welcome_screen.dart, lib/core/theme/app_theme.dart, test/widget_test.dart e docs/PROGRESSO.md. Sem novas dependências ou edição de assets.
- dart format .: aprovado, 7 arquivos processados. flutter test: 11/11 aprovados, incluindo carrossel e layouts em 360/390/412 dp com texto 1×/2×. flutter analyze: mesmos 8 diagnósticos informativos de depreciação preexistentes, sem novos diagnósticos.
- Continua pendente revisão visual no Android e comparação por screenshot; não se afirma correspondência exata da fonte rasterizada do protótipo. Roboto é a opção inicial aprovada, sem fonte Inter fornecida. M1 permanece não validado integralmente pelas pendências já registradas; sem M2 ou commit.

Para cada marco registrar: estado, checklist, arquivos alterados, comandos/resultados, evidências, limitações, problemas restantes e validação manual. Estados: Planejado, Em andamento, Implementado / Não validado, Bloqueado ou Concluído. Nunca marcar validação pendente como aprovada. Não avançar automaticamente entre marcos.

## M3 — Preparação da validação dos repositórios Dart no Android

Em 17/11/2026, revisados AGENTS.md, PLANO.md, este progresso, REMOTE_TEST_PLAN.md, runner Dart anterior, repositórios reais e gradle.properties. Estratégia registrada em firebase/DART_ANDROID_TEST_PLAN.md. O runner antigo não pode ser reexecutado: usa A/B já existentes e suas senhas não foram retidas.

Proposta ainda sem autorização remota: um novo runner integration_test/m3_dart_repositories_test.dart (a implementar), desabilitado por padrão, uma única conta C bolsozen-m3dart20261117c01-c@example.com, perfil, três receitas e orçamento 2099-12_food. Exercitar os três repositórios reais, mapeadores via round-trip, paginação 2+1+0, persistência por Source.server e permission-denied guest. SDK direto somente para tentativas adversariais e verificação complementar de ausência. Não repetir os 28 testes JS.

Preservadas as configurações de memória Gradle e todas as alterações locais preexistentes. Nenhuma compilação, criação de conta/documento, exclusão ou teste remoto iniciado nesta preparação. Arquivos desta etapa: novo plano específico e esta atualização documental; código Flutter e UI intactos. Não foram executados format/analyze/test: mudança exclusivamente documental. M3 continua aberto.

Pendente aprovação dos identificadores, operações, limpeza financeira e retenção de C/perfil (exclusão de perfil é proibida pelas regras). Antes da execução, repetir pré-verificação de projeto/regras/índice READY e consulta restrita da ausência de C. Após aprovação, implementar e revisar runner, validar localmente e executar uma única integração no MSI; se houver OOM, interromper antes de repetir. Não reutilizar APK normal como APK do runner.


## M3 ? Integra??o Dart Android executada em 17/11/2026

Execu??o expressamente autorizada do roteiro firebase/DART_ANDROID_TEST_PLAN.md. Uma ?nica compila??o, nenhum retry, sem alterar gradle.properties. MSI 127.0.0.1:5556 conectado; projeto bolsozen-f2f35 e package com.bolsozen.bolsozen conferidos. Helper somente de leitura confirmou aus?ncia de C, regras remotas correspondentes ?s locais (SHA d5bd92b0ac7be98377a62c72b88c8eedcb3ef0b091823219366b113a1b7e8573) e ?ndice CICAgOjXh4EK READY. O helper consulta configura??o cliente Web existente, sem executar testes Web; a identidade Android ? conferida pelo runner e google-services.json.

Arquivos desta etapa: integration_test/m3_dart_repositories_test.dart, firebase/dart_android_preflight.cjs, firebase/DART_ANDROID_TEST_PLAN.md, firebase/REMOTE_TEST_PLAN.md e docs/PROGRESSO.md. Sem depend?ncias novas; c?digo principal/UI, regras, ?ndices e ajustes Gradle preservados. Runner desabilitado por padr?o, com tr?s flags expl?citas para execu??o remota. N?o executar novamente com flags: a conta C agora existe.

Resultados:

- dart format .: 36 arquivos, runner formatado.
- flutter analyze: sem erros ou warnings; 10 informes preexistentes deprecated_member_use; exit code 1 por pol?tica padr?o do analyzer. Colis?o inicial de imports do runner corrigida antes do build.
- flutter test --concurrency=1: 89 testes locais aprovados.
- Integra??o Android: 1 testWidgets aprovado, contendo 16 verifica??es agrupadas aprovadas, 0 falhas; execu??o do teste aproximadamente 9 segundos ap?s instala??o. Gradle assembleDebug 75,3 segundos; instala??o 13,6 segundos. Exit code 0, sem OOM. Mem?ria livre observada durante build aproximadamente 530 MiB, sem medi??o de pico.
- Firebase Android e login/logout/login de C confirmados com mesmo UID, sess?es nomeadas isoladas.
- FirestoreUserRepository: fetch ausente, ensureProfile, fetch confirmado e idempot?ncia com createdAt preservado.
- FirestoreTransactionRepository: cria??o de tr?s receitas, leitura real Source.server, modelos/centavos/categoria/data/auditoria corretos, pagina??o ordenada 2+1+0 sem duplica??o, edi??o de uma receita e releitura, exclus?o das tr?s e lista final vazia.
- FirestoreBudgetRepository: cria??o, fetchMonth, atualiza??o com createdAt preservado, remo??o e lista final vazia.
- SDK cliente guest: leitura e altera??o negadas exatamente com permission-denied; guardData converteu para DataFailure.permissionDenied. Barreira do reposit?rio sem sess?o retornou DataFailure.unauthenticated. Integridade da receita conferida ap?s tentativas negadas. Estas chamadas adversariais diretas n?o s?o contabilizadas como CRUD de reposit?rio.
- Exclus?o financeira feita pelos reposit?rios, seguida de get(Source.server) para confirmar aus?ncia individual. Nenhum documento financeiro restante.
- git diff --check aprovado. N?o repetida bateria JS nem testes locais de regras, pois regras e ?ndices n?o mudaram. Nenhum deploy/commit/push, servi?o pago ou acesso a dados A/B.

Conta C retida: bolsozen-m3dart20261117c01-c@example.com, UID nluCnbgRa8NJvuv6SI3TMlTqTe83. Perfil retido: users/nluCnbgRa8NJvuv6SI3TMlTqTe83. Conta deslogada ao final; senha descartada, n?o registrada. N?o tentou excluir perfil ou conta.

Documentos removidos e aus?ncia confirmada no servidor, sob users/nluCnbgRa8NJvuv6SI3TMlTqTe83/:

- transactions/eqIJXsR8Q8AwQNgpDDDG
- transactions/evIKwmJjyj3m293FuFfG
- transactions/mbB5z7YA5wR4rGHjwWzO
- budgets/2099-12_food

Evid?ncias locais ignoradas pelo Git: build/m3dart20261117c01-android.log, build/m3dart20261117c01-unit.log e build/m3dart20261117c01-report.json. Logs do runner cont?m somente eventos sanitizados, UID e caminhos; sem senhas/tokens. O APK app-debug.apk desta execu??o cont?m o entrypoint de integra??o: para voltar ? experi?ncia normal, executar flutter run -d 127.0.0.1:5556 (n?o executar novamente o runner). Fonte da tela de boas-vindas n?o foi alterada; n?o foi feita nova homologa??o visual nesta etapa.

Pend?ncias: revis?o do usu?rio para encerrar M3; limpeza posterior espec?fica de contas A/B/C e perfis A/C por UID com autoriza??o; configura??o Flutter Web permanece pendente conforme registro anterior. Persist?ncia entre rein?cios de processo e recupera??o de interrup??o n?o foram testadas neste roteiro. M3 n?o marcado como conclu?do automaticamente; M4 permanece n?o autorizado.
