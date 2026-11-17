# M4 — Relatório de homologação M4.6

**Estado: M4 encerrado e aprovado pelo usuário com ressalvas documentadas. Homologação técnica parcial preservada; verificações restantes transferidas para M9. M5 não autorizado para implementação.**

## Decisão de aceite posterior à homologação

O usuário aprovou funcionamento/visual da autenticação e autorizou expressamente encerrar o M4 sem repetir a homologação completa. Login, cadastro, recuperação e perfil mínimo implementados; Safari aprovado manualmente, incluindo recebimento/redefinição da senha e persistência observada após reabertura/reload. Android compilado e executado; 301 testes Flutter e 19 verificações locais Dart/FlutterFire M4.5 aprovados. Esses resultados são os já executados, não uma nova bateria neste encerramento.

Permanecem conhecidas e aceitas: persistência autenticada após reinício Android não homologada; bateria Chrome automatizada interrompida por OOM, com a quarta asserção invalidada; teclado virtual nativo e TalkBack sem homologação manual completa; 20 informes no analyzer. Transferidas ao planejamento final M9 em [PLANO.md](PLANO.md). Não considerar teste bloqueado como aprovado nem inferir garantia Android a partir do Safari. O relatório abaixo mantém as evidências e a análise originais; itens que antes impediam aceite passam a ser backlog M9 por decisão do usuário.

## 1. Escopo e fontes

M4.1–M4.5 aprovados pelo usuário. Relidos AGENTS.md, PLANO.md, PLANO_M4.md, PROGRESSO.md, documentos 01–05, relatórios visuais M4.4/M4.5 e prancha oficial. Preservados tema, Roboto, componentes, logo, carrossel, telas e destino temporário Perfil mínimo. Nenhuma funcionalidade financeira ou nova funcionalidade de autenticação implementada.

Evidências distinguem testes executados nesta etapa, histórico anterior e validação manual informada pelo usuário. Fakes, SDK local, aplicativo Android normal e Safari remoto não são equivalentes.

## 2. Aprovação manual Safari/iPhone — informada pelo usuário

O usuário aprovou onboarding/identidade, login, cadastro, recuperação, fluxos de autenticação e integração Firebase observada no uso. Confirmou adicionalmente nesta homologação:

- Recebimento do e-mail e redefinição efetiva da senha pelo link.
- Persistência após fechar/reabrir ou recarregar o navegador.

Registrar como **validação manual do usuário no Safari**, sem atribuí-la a execução automatizada do agente. Não foram fornecidos versão do iOS/Safari, capturas novas, UIDs ou condições mais específicas de encerramento. Essa confirmação não comprova reinício Android nem substitui o ensaio Chrome em origem fixa. O agente não enviou novos e-mails reais ou utilizou contas pessoais.

## 3. Android — aplicativo normal

MSI App Player identificado por Flutter/ADB como 127.0.0.1:5556, modelo 2107113SI, Android 9/API 28, android-x64. Executado **lib/main.dart**, sem runners M3 ou fakes. Projeto configurado bolsozen-f2f35, package com.bolsozen.bolsozen, sem alterações nas opções Firebase.

```powershell
flutter run -d 127.0.0.1:5556 --no-pub --target=lib/main.dart
```

Uma compilação: assembleDebug concluído em **33,0 s**, APK gerado. A instalação ADB por streaming ficou sem progresso em 20,647684% da transferência, com 114 GB disponíveis em /data do emulador. A execução e seu cliente ADB foram interrompidos, sem apagar dados; reutilizado o mesmo APK, sem compilar novamente:

```powershell
adb -s 127.0.0.1:5556 install --no-streaming -r -t build/app/outputs/flutter-apk/app-debug.apk
adb -s 127.0.0.1:5556 shell am start -n com.bolsozen.bolsozen/.MainActivity
```

Instalação retornou **Success**, lastUpdateTime 2026-11-17 16:43:50. SHA-256 do APK: `B404ED6FBECE1744427A104A611C96ACEF502631630F186BCA3D7AB0E424E920`. APK compilado antes das duas trocas equivalentes de imports descritas na seção 6; nenhuma mudança visual ou funcional entre esses estados. O código final passou analyzer e testes, sem uma segunda compilação Android.

Confirmados:

- Bootstrap Firebase/composição/gate liberaram boas-vindas sem mensagem de falha e sem sessão autenticada. Isso comprova inicialização, não CRUD remoto nesta etapa.
- Navegação para Login, Recuperar senha e Cadastro; Voltar da recuperação permitiu acessar novamente o login/cadastro.
- Campo de e-mail recebeu foco e o endereço ilustrativo publico@example.test, **sem senha, submit, conta ou envio remoto**.
- InputConnectionAdaptor Flutter ativo; Android informou mInputShown=true e mShowRequested=true. Contudo show_ime_with_hard_keyboard=0 e o teclado virtual não foi desenhado nas capturas. Foco/entrada de texto confirmados; teclado virtual visível e TalkBack permanecem pendentes.
- Encerramento real via am force-stop e reabertura da MainActivity, sem limpar dados; PID anterior 7378 e novo PID 7876. Após aguardar inicialização, boas-vindas confirmada por hierarquia e screenshot. **Reabertura sem sessão**, não persistência autenticada.

Capturas 1080×1920, densidade 240 (1,5 px/dp), viewport aproximado 720×1280 dp, formulário limitado pela largura máxima do componente. Não declarar teste Android nativo de 360/390/412 dp: essas dimensões são cobertas pelos testes de widgets e evidências anteriores Chrome.

| Evidência Android | Arquivo |
|---|---|
| Boas-vindas | [PNG](evidencias/m4-6/android/android-boas-vindas.png) |
| Login | [PNG](evidencias/m4-6/android/android-login.png) |
| Cadastro | [PNG](evidencias/m4-6/android/android-cadastro.png) |
| Recuperação | [PNG](evidencias/m4-6/android/android-recuperacao.png) |
| Campo com foco/texto, teclado virtual não visível | [PNG](evidencias/m4-6/android/android-cadastro-teclado.png) |
| Reabertura pública após force-stop | [PNG](evidencias/m4-6/android/android-reabertura-publica.png) |

Automação ADB inicial consultou a hierarquia cedo demais na reabertura; uma captura transitória do launcher foi substituída pela captura correta após confirmar MainActivity/boas-vindas. Helper passou a recusar captura fora do pacote e interromper se houver Perfil/Sair de sessão existente. Nenhuma captura do launcher é usada como aprovação. O buffer de crashes continha evento OpenGL das 11:53 anterior à execução; não foi atribuído a esta homologação. Na consulta final, o dispositivo já não estava disponível por ADB; não houve reconexão automática.

**Não executados no Android:** cadastro remoto, login correto/incorreto com conta, perfil autenticado, logout, Voltar após logout e reinício com sessão válida. Não há conta remota de homologação autorizada nesta etapa; A/B/C não foram utilizadas. Não considerar essas lacunas aprovadas por analogia com testes de widgets ou Safari.

## 4. Chrome — SDK real local, origem fixa, resultado parcial

Novo entrypoint **exclusivo de integração**, integration_test/m4_ui_local_app.dart, monta os mesmos BolsoZenApp, FirebaseStartup, AppDependencies, AuthExperience, controller/gate e telas de produção. Não usa fakes, não altera main.dart para emuladores e não importa firebase_options.dart. Exige flag explícita, kIsWeb, demo-bolsozen e endpoints locais antes de inicializar os SDKs. Repositórios recebem Auth 127.0.0.1:9099 e Firestore 127.0.0.1:8080 antes da composição. Sessão utiliza a persistência LOCAL do adaptador real.

Runner firebase/tests/run_m4_ui_local.cjs desabilitado por padrão, exige ambiente emulators:exec, usa SDK cliente e automação CDP na origem fixa **http://localhost:7366**, mesma instância/perfil Chrome entre reloads. Não usa Admin SDK ou credenciais de produção. A fixture sem perfil, planejada em SDK cliente Node no emulador, **não chegou a ser criada** nesta execução. Não há dependências novas.

```powershell
$env:JAVA_TOOL_OPTIONS='-Xmx384m'
firebase emulators:exec --project demo-bolsozen --only auth,firestore "node firebase/tests/run_m4_ui_local.cjs --execute-local"
```

Java limitado apenas no processo dessa execução; configuração persistente e Gradle intactos. Compilação Chrome posterior à compilação/instalação Android, sem builds simultâneos.

**Resultado revisado: três verificações confirmadas**, proteção pública sem Perfil, bootstrap até a UI pública e validação do cadastro vazio. A rotina então preencheu dados locais e submeteu cadastro de m46-ui-a@example.test. O resultado definitivo da conta/perfil **não foi comprovado** antes da interrupção; nunca foi conta remota. Emuladores efêmeros foram desligados, sem exportar seus dados.

O registro bruto relatou quatro aprovações. A inspeção das imagens invalidou a quarta: a asserção baseada somente no nome encontrou o texto digitado no cadastro; a imagem ainda mostrava o botão em loading. **Não é evidência de perfil pronto ou leitura Firestore confirmada.** O runner foi corrigido para exigir simultaneamente Perfil, Sair, nome/e-mail esperados e ausência de títulos dos formulários. Seis testes Node puros passaram contra esse falso positivo. A versão corrigida não foi reexecutada após OOM.

O Firestore Emulator encerrou por **memória nativa insuficiente do Java**, malloc de 858256 bytes (hs_err_pid19820.log). Não foi erro de regra/permissão nem validação do isolamento. A automação recebeu UI_EXPECTATION_TIMEOUT depois da perda do backend; emulators:exec retornou exit 1. Emuladores e processos próprios de Chrome/Flutter foram encerrados; nenhuma operação pesada foi repetida após o OOM. Não alterar heap/Gradle, caches ou configuração de serviços para esconder a falha.

| Artefato Web | Interpretação |
|---|---|
| [Revisão das evidências](evidencias/m4-6/web/validation-review.json) | Resultado autoritativo: 3 confirmadas, 1 asserção invalidada, demais bloqueadas |
| [Registro bruto](evidencias/m4-6/web/results-raw.json) | Preservado, mas suas 4 aprovações não equivalem a 4 resultados válidos |
| [Cadastro com validação](evidencias/m4-6/web/cadastro-validacao-local.png) | Mensagens da tentativa vazia anterior e dados locais digitados; senha oculta |
| [Cadastro em envio](evidencias/m4-6/web/cadastro-em-envio-inconclusivo.png) | Arquivo original chamava-se web-perfil-local.png; **não é tela de perfil** |
| [Frame inicial](evidencias/m4-6/web/inicial-assets-pendentes.png) | Imagens ainda não decodificadas; não comprova regressão visual nem aprovação do onboarding |

Reload mantendo sessão, logout/Voltar/Avançar, login correto/incorreto, recuperação, troca de conta, cadastro parcial e erro de rede **não foram concluídos nesta bateria Chrome UI**. Não substituir esses resultados pelos 19 checks do SDK executados no M4.5 ou pelo aceite Safari, embora ambos permaneçam evidências válidas em seus escopos.

## 5. Testes e matriz de evidências

Sequência executada após os ajustes Dart:

| Verificação | Resultado real M4.6 |
|---|---|
| dart format . | 68 arquivos, 0 alterações na execução final; exit 0 |
| flutter analyze | 0 erros, 0 warnings, 20 informes deprecated_member_use; exit 1 pelos informes |
| flutter test --concurrency=1 | **301 aprovados, 0 falhas**, exit 0 |
| git diff --check | Aprovado, somente avisos locais de conversão LF/CRLF |
| node --test firebase/tests/m4_ui_assertions.test.cjs | **6 aprovados, 0 falhas**; não são testes Flutter nem integração SDK |
| Integração UI Chrome/emuladores M4.6 | **3 confirmadas**, 1 asserção invalidada e bateria interrompida por OOM; exit 1 |
| Compilação Android | Uma compilação aprovada; instalação streaming bloqueada, sem streaming aprovada |

Os 301 incluem validações de domínio/adapter, neutralidade, senhas intactas, estados de sessão, perfil parcial/idempotência, concorrência, UID incompatível, logout/Voltar, erros, foco e responsividade. Não foram acrescentados testes Flutter no M4.6. Responsividade existente: larguras 360/390/412, texto 1/2, formulários com inset de teclado simulado 300 dp. Essas verificações não equivalem a TalkBack ou teclado virtual Android homologado.

| Comportamento | Evidências e limite |
|---|---|
| Cadastro/perfil real | SDK local M4.5: 19 checks aprovados no conjunto; Safari aprovado pelo usuário. Nova UI Chrome inconclusiva; Android privado pendente |
| Login correto/incorreto | Unitários/widgets + SDK local anterior; Safari fluxos aprovados. Sem repetir login remoto no Android |
| Recuperação | Confirmação neutra/rede nos testes; usuário confirmou recebimento e redefinição no Safari. Nenhum novo e-mail real pelo agente |
| Sessão persistente | Safari após reabertura/reload confirmado pelo usuário. Android autenticado e Chrome origem fixa pendentes |
| Logout/proteção | Controller/gate/widgets aprovados e integração SDK anterior; área pública Android observada. Logout nativo e histórico Chrome não concluídos |
| Perfil parcial | Widgets/controller e SDK local M4.5 aprovados; ensaio UI com reload não alcançado |
| Rede/permissão/UID | Cobertura local determinística; regras M3 e resultados remotos históricos preservados. Falha de rede não contada como permission-denied |
| UI/acessibilidade | Safari aprovado; screenshots anteriores em 360/390/412 e novas Android públicas. TalkBack e teclado virtual continuam pendentes |

Os 77 testes de regras M3 e 19 verificações Dart/SDK M4.5 são **históricos, não reexecutados no M4.6**. Após OOM não foi iniciada outra bateria de emuladores. Regras e índices permanecem intactos.

## 6. Depreciações — origem e correções

Na entrada, 22 informes: 10 já presentes no commit M3 e 12 líquidos do M4. Comparação com git show e34c884 e log do analyzer:

| Origem | Arquivos/ocorrências na entrada |
|---|---|
| Preexistentes M3: 10 | app/app.dart (import e GlobalMaterialLocalizations: 2); app/firebase_startup.dart; core/theme/app_colors.dart; core/theme/app_theme.dart; main.dart; welcome_screen.dart; test/firebase_startup_test.dart; test/widget_test.dart (Material e Cupertino: 2) |
| Introduzidos M4: 12 | app/auth_experience.dart; telas complete_profile, login, password_reset, register, session_status e profile (6); widgets auth_form_layout, password_field e submit_button (3); testes auth_screens e register_screens (2) |

Correções simples: main.dart passou de material.dart para widgets.dart (só usa binding/runApp); app_colors.dart passou para dart:ui (só usa Color). Não alteram símbolos usados, cores, renderização, dependências ou contrato. Resultado final: **20 informes = 8 preexistentes + 12 do M4**.

Os restantes pertencem à indicação de migração Material/Cupertino do SDK instalado. Trocar imports por material_ui/cupertino_ui exigiria dependências/migração fora do escopo aprovado. Não houve supressão de lint, refatoração ampla ou redesenho.

## 7. Arquivos e segurança

Alterados neste M4.6: somente imports de lib/main.dart e lib/core/theme/app_colors.dart no código de produção. Criados integration_test/m4_ui_local_app.dart, firebase/tests/run_m4_ui_local.cjs, m4_ui_assertions.cjs, m4_ui_assertions.test.cjs e test/visual/m4_android_public.py para homologação local, desabilitados por padrão. Atualizados PLANO_M4.md e PROGRESSO.md; este relatório e evidências adicionados.

Helper Android só permite ações públicas e texto ilustrativo, proíbe submit de autenticação/cadastro e para diante de Perfil/Sair. Arquivo temporário de hierarquia no dispositivo: /sdcard/bolsozen-m46-public.xml, criado por esta execução; não é perfil ou dado financeiro. Não foi feita limpeza de contas/dados existentes.

Preservados alterações anteriores M4.1–M4.5, memória/paralelismo Gradle, opções Firebase, regras/índices e dependências. Nenhum commit/staging/push/deploy, nenhuma conta remota nova, nenhum uso de A/B/C ou exclusão de perfil. assets/illustrations/google-services.json segue não rastreado e não incluído no Git.

Logs/dumps brutos permanecem locais e ignorados: build/m4-6-*, firestore-debug.log, hs_err_pid19820.log e replay_pid19820.log. Não versionar dumps Java, perfis de navegador, senhas ou tokens. Evidências versionáveis contêm somente screenshots públicas/fixtures locais, resultados sanitizados e documentação.

## 8. Verificações transferidas para M9 e roteiro proposto — não executado

1. **Revisão e encerramento autorizados pelo usuário com ressalvas.** Itens seguintes transferidos para M9; não executar automaticamente nem reabrir M4 por essa retenção.
2. **Retomada Chrome local após OOM:** avaliar RAM e memória comprometida do Windows; usuário pode fechar o MSI/outros aplicativos antes de nova execução. Não alterar pagefile/heap/Gradle automaticamente. Aprovar nova tentativa única com o runner corrigido, mesma origem 7366, somente demo-bolsozen. Completar os checkpoints ainda não aprovados, registrar falhas e parar novamente em OOM. Não reutilizar banco remoto como atalho.
3. **Android autenticado:** preferencialmente o usuário executar login, confirmar perfil, encerrar/reabrir processo, logout e Voltar com sua conta de teste, sem fornecer senha ao agente, e registrar o resultado. Alternativa exige autorização específica antes da primeira gravação remota pelo agente: criar somente bolsozen-m4h20261117d01-d@example.com e users/{uidD}, nome HOMOLOGAÇÃO M4 D; senha aleatória só em memória. Testar cadastro/perfil, login correto/incorreto, reinício com dados preservados, logout/Voltar. Nenhuma transação/orçamento, alteração de regra ou uso A/B/C. Não enviar recuperação para esse endereço ilustrativo. Ao final sair da sessão e manter conta/perfil para decisão posterior; não usar Admin para excluir perfil. **Nenhuma dessas operações remotas está autorizada ou foi executada.**
4. **Teclado/acessibilidade Android:** validar teclado virtual visível, texto ampliado e TalkBack em ambiente disponível. Não considerar o estado mInputShown isolado prova visual de IME. Ajustes de dispositivo, se necessários, devem ser combinados antes, preservando preferências existentes.
5. Consolidar os resultados restantes na homologação M9 e solicitar aceite final do MVP. O commit local do M4 foi autorizado separadamente nesta decisão de encerramento. M5, novas operações remotas, push e deploy não são autorizados por esse backlog.
