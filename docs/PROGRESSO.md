# BolsoZen — Progresso

## M6 encerrado com ressalvas — aceite manual do usuário

Usuário aprovou funcionamento e testes manuais necessários. **M6.6 dispensado, não executado.** M6 encerrado com ressalvas; detalhes em [M6_HOMOLOGACAO.md](M6_HOMOLOGACAO.md). Cadastro existente, edição/exclusão com confirmação, busca por descrição/categoria, filtros combinados, agrupamento, ocultação somente do saldo e recentes sincronizados entregues. Preservadas segurança por UID/expectedUserId, precisão monetária, serialização e reconciliação sem replay automático de mutações.

Evidência anterior preservada: **656 testes Flutter aprovados**, analyzer com **52 informes de depreciação**, zero erros/warnings. Nenhuma bateria repetida neste encerramento. Capturas e limites dos testes com fakes permanecem nos relatórios M6.2–M6.5; aceite manual não substitui evidência técnica ainda ausente. Registros abaixo são históricos.

### Ressalvas acumuladas transferidas ao M9

Preservados os backlogs M4/M5 e respectivas homologações: persistência autenticada após reinício real do Android quando não comprovada; bateria Chrome interrompida por OOM; validação de teclado nativo e TalkBack; integração adicional Firebase Auth/Firestore locais; validação Android/Web dos fluxos CRUD, condições de falha/reconciliação de conexão e revisão dos 52 informes do analyzer. Não declarar testes nativos/remotos não executados ou reabrir obrigatoriamente homologações dispensadas nesta tarefa. Novas operações remotas continuam dependendo de autorização específica.

Autorizado commit local exclusivamente dos arquivos M6/documentação, sem o JSON redundante. Planejamento M7 será elaborado após esse commit; nenhuma implementação M7 autorizada. Sem push/deploy, contas/dados remotos, regras/índices, Gradle ou dependências.

## M6.5 — Ocultação de saldo e revisão dos recentes, aguardando revisão

M6.4 aprovado tecnicamente (638 testes/50 informes), autorizado exclusivamente M6.5. **Não iniciar M6.6** sem nova autorização. Mantidos todos os fluxos aprovados e controles ampliados do Histórico. Registros abaixo são históricos.

### Arquivos desta etapa

- `lib/presentation/widgets/balance_card.dart`: estado controlado por visible/onToggleVisibility; máscara ou valor, semântica explícita e olho aberto/fechado com tooltip acessível. Mantido estilo TEL-04.
- `lib/presentation/screens/dashboard/dashboard_screen.dart`: bool em memória, inicialmente visível; preservado entre abas/refresh; reset por invalidação ou substituição de controller/UID e descarte normal da árvore privada.
- Novo `test/presentation/balance_privacy_test.dart`: testes de apresentação real com SessionGate/MainShell e repositório fake local; privacidade, ciclo de vida, recentes após CRUD, falhas/recarga e responsividade.
- `test/presentation/financial_screens_test.dart`: asserção antiga do olho indisponível alterada para ação real; demais verificações/fixtures preservadas.
- Novo `test/visual/m6_balance_capture.dart`, evidências em `docs/evidencias/m6-5/` e relatório `docs/M6_5_VALIDACAO_VISUAL.md`; atualizados este progresso e PLANO_M6.md.

### Privacidade e ciclo de vida

Ocultação somente do Saldo total: máscara •••••• e label Saldo oculto substituem o valor renderizado e sua semântica; o botão anuncia Mostrar saldo/Ocultar saldo. Não há segunda label com o valor oculto. Demais valores continuam visíveis conforme escopo aprovado. Nenhuma alteração financeira, consulta, persistência de preferência ou estado global. A preferência vive no Dashboard mantido pelo IndexedStack; não é compartilhada com outra sessão ou UID. Logout/alteração de conta remove a árvore privada e seus dados como antes.

### Revisão dos recentes e sincronização

FinancialProjection.recent permanece com um item, sem mudança na implementação. Usa o histórico completo confirmado e ordenado pelo domínio, não faz nova consulta. Testes verificam criação, edição de descrição/categoria/tipo/valor, alteração de data reordenando a lista e exclusão revelando o próximo registro, sem duplicação. FinancialController/cálculos/repositórios não precisaram de alteração.

Na confirmação de mutação com recarga falha, o recente anterior continua explicitamente desatualizado; alternar olho não limpa erro/stale/pendências. Retry permanece somente leitura, sem repetir create/update/delete. Logout durante leitura descarta resposta atrasada e não recupera valor/recentes. Erro inicial não apresenta saldo zero definitivo nem registros fictícios.

### Validação final M6.5

| Verificação | Resultado real |
|---|---|
| dart format . | Exit 0; 116 arquivos, um formatado na última execução (runner visual) |
| flutter analyze | Exit 1 pelos **52 informes de depreciação**, zero erros/warnings |
| flutter test --concurrency=1 | Exit 0; **656 aprovados**, preservados os 638 anteriores + 18 novos |
| git diff --check | Exit 0; somente avisos locais LF/CRLF, sem erros de whitespace |
| Captura opt-in | Um teste separado aprovado; oito PNGs, sem Firebase remoto ou OOM |

Dois informes líquidos novos: imports Material oficiais no teste e runner novos. Nenhuma supressão ou dependência adicionada; diagnóstico de estilo do teste corrigido. A execução inicial dos testes novos exigiu corrigir imports e o descarte do handle semântico do próprio teste, além de verificar label mesclada/tooltip nativo corretamente. A suíte final passou sem falhas.

Cobertura: visibilidade inicial, máscara/reexibição/alternância sem leituras e sem alterar summary; texto/semântica sem valor oculto; demais indicadores e Histórico visíveis; abas/refresh; reset no logout/UID; vazio/erro; recentes após CRUD e mudança de data; três casos de mutação confirmada com refresh falho e retry só leitura; logout durante leitura/resposta atrasada; 360/390/412 dp, texto 1×/2×. Capturas reais do renderer com Roboto/fixtures identificadas, inspecionadas contra TEL-04. No texto ampliado, o valor visível pode quebrar linha e o card acompanha o conteúdo; a máscara é mais curta. A fixture repõe a rolagem no topo para comparar enquadramentos; não muda o aplicativo. Detalhes em M6_5_VALIDACAO_VISUAL.md.

### Limitações e próximo passo

Testes usam contratos fake, sem Firebase remoto ou SDK nativo. Capturas usam renderer de testes; homologação manual de TalkBack, teclado/plataformas e ressalvas anteriores permanece no M9. Revisão visual do usuário pendente. Sem novas dependências, alterações de Gradle, regras/índices, dados/contas remotos, staging, commit, push ou deploy. JSON redundante continua preservado fora do Git. Próxima etapa possível: M6.6, somente após revisão e autorização.

## M6.4 — Busca e filtros do Histórico, aguardando revisão

M6.3 aprovado pelo usuário (607 testes, 47 informes). Implementado exclusivamente M6.4, incluindo ajuste solicitado de controles maiores. **Não iniciar M6.5**. Registros anteriores abaixo são históricos; nenhuma aprovação visual automática.

### Arquivos desta etapa

- `lib/presentation/screens/transactions/transactions_screen.dart`: estado local de pesquisa/tipo/categoria; integração do modal, limpeza e distinção de vazios, listener de invalidação, timer local de dia e retomada do aplicativo. IndexedStack existente conserva filtros entre abas; descarte da árvore privada/UID elimina estado e respostas de modal antigo.
- `lib/presentation/services/financial_projection.dart`: filterHistory puro sobre todo o histórico confirmado, coleção imutável e ordem original preservada. Pesquisa parcial por descrição OU categoria, ignorando caixa, espaços nas extremidades e acentos portugueses/marcas combinantes.
- Novos `lib/presentation/widgets/history_filters.dart` e `history_category_dialog.dart`: pesquisa real/limpeza, três chips com seleção semântica, categorias oficiais compatíveis, rascunho Aplicar/Cancelar e ação explícita Limpar filtros. Removido `unavailable_history_filters.dart`, agora sem uso.
- Novos `test/presentation/history_filter_projection_test.dart` e `history_filters_test.dart`; testes antigos `financial_screens_test.dart`, `main_shell_test.dart` e helper `transaction_edit_screens_test.dart` adaptados para distinguir rolagem vertical da lista da rolagem horizontal do novo campo. Asserção de ausência de campo passa a verificar a busca real; proibição de ellipsis continua nos textos financeiros, não no hint nativo do campo.
- Novo runner opt-in `test/visual/m6_history_capture.dart`, PNGs em `docs/evidencias/m6-4/`, relatório `docs/M6_4_VALIDACAO_VISUAL.md`, este progresso e `docs/PLANO_M6.md`.

### Comportamento e segurança

Combinação tipo E categoria E busca, com descrição OU categoria dentro da busca. Chip Todas remove somente tipo; mudança de tipo limpa categoria incompatível; X remove somente texto; opção Todas do campo Categoria + Aplicar remove somente categoria; Limpar filtros remove os três critérios explicitamente. Cancelar não altera filtros ativos. Modal mantém navegação/foco Material e devolve foco ao ajuste.

Sem novas leituras por tecla, chip, categoria, mudança de data ou alternância de aba. Filtros cobrem páginas completas (teste com 201 registros), não modificam transações nem FinancialSummary/saldo. Edição e exclusão confirmadas refletem automaticamente na projeção filtrada. Hoje/Ontem usam dias locais e atualizam à meia-noite/retomada; grupos são gerados depois dos filtros, sem cabeçalhos vazios. Erro e stale continuam explícitos, sem virar saldo zero ou mensagem enganosa de ausência. Histórico realmente vazio mantém orientação e acesso real a adicionar.

Controles proporcionais com mínimo 48 dp e fonte do tema 14/w600; tune 26 dp/alvo 48×48; pesquisa com altura mínima visual 48 dp. Em texto ampliado, chips quebram em linhas, preservando toque e leitura. Cards, ícones pastéis, títulos/datas e barra inferior existentes preservados. Comparação visual e capturas no relatório específico.

### Limitações

Normalização cobre português/latim básico e marcas combinantes, sem transliteração universal. Filtragem linear local adequada ao MVP, sem busca remota. Testes/fotos utilizam fakes e renderer Flutter; não comprovam teclado nativo/TalkBack, navegador real ou persistência remota. Homologação manual dessas plataformas e ressalvas anteriores permanecem no M9. Revisão visual do usuário pendente. Não houve alteração adicional em FinancialController, domínio monetário, repositórios, MainShell/SessionGate, regras/índices, Gradle ou dependências. Nenhuma operação Firebase remota, staging, commit, push ou deploy. JSON redundante preservado fora do Git.

### Validação final M6.4

| Verificação | Resultado real |
|---|---|
| dart format . | Exit 0; 114 arquivos, um formatado na última execução |
| flutter analyze | Exit 1 por **50 informes de depreciação**, zero erros/warnings |
| flutter test --concurrency=1 | Exit 0; **638 aprovados**, preservando os 607 anteriores e acrescentando 31 |
| Captura opt-in final | Exit 0; um teste separado aprovado, oito PNGs pelo renderer Flutter, sem Firebase/OOM |
| git diff --check | Exit 0; avisos locais LF/CRLF não são erros de whitespace |

Os três informes líquidos adicionais vêm de imports Material nos novos widgets/testes/runner (quatro imports novos, um arquivo antigo removido). Corrigidos diagnósticos novos de estilo, import desnecessário e hasFlag depreciado, sem suprimir regras ou instalar material_ui. Na execução inicial, um teste antigo de rolagem falhou por encontrar também o Scrollable horizontal da busca; corrigido o seletor para eixo vertical e repetida a suíte completa. A simulação inicial de lifecycle do teste foi ajustada para transições Flutter válidas. Não houve OOM.

Cobertura nova: busca parcial/acentos/Unicode/caixa/trim; combinação e limpeza independente; modal cancelar/aplicar e foco; 201 registros/páginas completas sem consultas extras; ordenação e cabeçalhos de virada de ano/dia; dados stale/erro/vazio; edição/exclusão; alternância de abas, logout e troca de UID; 360/390/412 dp com texto 1× e 2×, sem overflow, contraste/rótulos/alvos de toque automatizados.

Próxima etapa possível: M6.5, somente após aprovação desta entrega e nova autorização.

## M6.3 — Exclusão com confirmação, aguardando revisão

M6.2 aprovado pelo usuário, baseline 561 testes/44 informes. Implementado exclusivamente M6.3; **não iniciar M6.4** sem nova autorização. Preservados edição, criação, navegação privada e identidade visual aprovadas. Sem busca/filtros, ocultação ou recursos dos marcos posteriores.

### Arquivos desta etapa

- `lib/presentation/controllers/financial_controller.dart`: deleteTransaction sobre original do snapshot, trava/versionamento compartilhados com create/update, expectedUserId e verificação de ausência do ID antes de publicar recarga; pendingDeletedIds e confirmsDeletion para leitura sem replay.
- `lib/presentation/widgets/transaction_actions_sheet.dart`: enum de ação tipado para Editar/Excluir e lixeira error; menu existente reutilizado, sem exclusão automática.
- Novo `lib/presentation/widgets/delete_transaction_dialog.dart`: AlertDialog com descrição/valor, aviso irreversível, Cancelar/Excluir, progresso e bloqueio de confirmação repetida; fechamento durante envio não cancela requisição e retorno tardio não altera widget descartado. Retry somente de leitura para refresh pendente/incerteza/notFound.
- `lib/app/main_shell.dart`: seleção tipada e diálogo no Navigator privado com useRootNavigator=false, identidade revalidada antes da abertura; preserva uma instância financeira e descarte pelo SessionGate.
- `transaction_form_screen.dart`: apenas mensagem genérica de alteração confirmada pendente para não chamar uma exclusão de movimentação salva; nenhuma mudança de campos/layout. A trava impede novo lançamento até leitura de reconciliação.
- `test/presentation/financial_test_fakes.dart`: delete fake instrumentado, com UID e notFound. Novos `transaction_delete_test.dart` e `transaction_delete_screens_test.dart`.
- `transaction_edit_screens_test.dart` e `test/visual/m6_edit_capture.dart`: asserção do menu atualizada para Excluir agora real; casos de edição anteriores preservados. PNGs históricos M6.2 não sobrescritos.
- Novo runner opt-in `test/visual/m6_delete_capture.dart`; documentação PLANO_M6.md, este progresso e relatório M6_3_VALIDACAO_VISUAL.md; capturas isoladas em docs/evidencias/m6-3.

Repositórios/contratos, FirebaseSession, domínio/Money/FinancialCalculator, TransactionTile/TransactionsScreen, SessionGate, regras/índices, Gradle e dependências não receberam novas alterações M6.3. Diffs M6.1/M6.2 ainda presentes contra o commit M5 são preexistentes e foram preservados.

### Estados e segurança

Só o botão Excluir do diálogo dispara a operação. Cancelar/Voltar antes disso não escreve. Controller exige UID/ID/modelo confirmado e revalida após await; não aceita ID arbitrário ou conteúdo alterado desde seleção. Todas as mutações compartilham a mesma trava. Dados financeiros antigos continuam até commit e recarga completa confirmada, sem atualização otimista.

Commit confirmado com leitura falha mostra Transação excluída e mantém o snapshot explicitamente stale; botão Atualizar dados não chama delete. Resultado incerto preserva ID original para conferência por leitura, não prova cancelamento e não repete automaticamente. notFound é tratado como erro, não como sucesso automático após consulta. Fechar durante operação apenas descarta o diálogo; controller conclui/registre pendência sem reabrir UI. Troca de conta/logout destrói pilha privada inclusive diálogo, e respostas antigas não publicam dados nem navegam.

Testes são locais, com fakes; não comprovam persistência/SDK/regras em servidor real. Não foram criados/excluídos usuários ou documentos remotos. Operação já enviada não é garantidamente cancelada ao sair; acesso/caminho nunca é redirecionado para B. Conflitos de múltiplos dispositivos e ressalvas nativas M9 continuam documentados. Sem build pesado, staging, commit, push ou deploy; JSON redundante preservado fora do Git.

### Validação final M6.3

| Verificação | Resultado real |
|---|---|
| dart format . | Exit 0; 110 arquivos, um teste formatado na execução final |
| flutter analyze | Exit 1 pelos **47 informes de depreciação**, zero erros/warnings |
| flutter test --concurrency=1 | Exit 0; **607 aprovados**, 561 anteriores preservados + 46 novos |
| Captura opt-in | Exit 0; um teste separado aprovado, oito PNGs e manifesto, sem OOM |
| git diff --check | Exit 0, sem erros; avisos LF/CRLF informativos |

Novos testes: 21 de controller e 25 de widgets, cobrindo CA-07 saldo 750/novembro zero/outubro 250; receitas/despesas/último registro; categorias/recentes; original inválido/UID/ID; trava create/update/delete; nenhuma remoção otimista; confirmação da ausência do ID; falhas definidas/recarga/incerteza/notFound e retry só de leitura; fechamento/cancelamento/toques repetidos; troca de UID/logout/dispose; 360/390/412 com texto 1/2, descrição/valor extensos, rótulos/alvos/contraste. Novo lançamento durante pendência de exclusão não grava e informa alteração confirmada aguardando atualização.

Analyzer manteve 44 informes anteriores e acrescentou três imports Material oficiais (delete_transaction_dialog.dart, transaction_delete_screens_test.dart, m6_delete_capture.dart). Sete informes novos de estilo foram corrigidos antes da execução final; nenhum diagnóstico ocultado nem dependência adicionada. Suítes direcionadas controller/widget passaram, seguidas da suíte completa. Asserções antigas de menu somente Editar foram adaptadas à autorização explícita M6.3, sem remover testes.

Oito screenshots abertas/inspecionadas, dimensões PNG conferidas; menu e confirmação em 390, confirmação 360/412, texto 2 e casos de valor/descrição extensos. Nenhum overflow identificado nas capturas finais. Diálogo é complemento Material da jornada J-05, não desenhado na prancha; cores/Roboto/raios e TEL-04/TEL-06 preservados. Evidências em [M6_3_VALIDACAO_VISUAL.md](M6_3_VALIDACAO_VISUAL.md). Não declarar pixel-perfect, aprovação visual automática ou execução Android/Chrome com base no renderer de testes.

## M6.2 — Edição de transações, aguardando revisão

M6.1 aprovado pelo usuário, baseline 515 testes/41 informes. Implementado exclusivamente M6.2. **Não iniciar M6.3 sem autorização.** Sem exclusão na UI, busca/filtros, ocultação ou módulos posteriores.

### Arquivos M6.2

- `lib/presentation/controllers/financial_controller.dart`: updateTransaction com original confirmado, UID fixo, validações e preservação do modelo; submissão compartilhada com create, pendingUpdates para verificar a recarga e confirmação por leitura dos campos esperados. Resultado incerto passa a sinalizar erro/stale no estado compartilhado, inclusive ao retornar à aba, sem esconder a possibilidade de escrita já realizada.
- `lib/presentation/screens/transactions/transaction_form_screen.dart`: mesmo formulário em criação/edição, títulos/botões adequados, preenchimento por Money.formatCents, data exata conservada sem edição explícita, loading/erros/reconciliação/notFound sem reenvio de update ou fallback create.
- Novo `lib/presentation/widgets/transaction_actions_sheet.dart`: bottom sheet discreto com transação selecionada e única ação Editar. Cancelar pelo Voltar/fechar não grava; não existe Excluir.
- `lib/presentation/widgets/transaction_tile.dart`: callback/semântica de toque e InkWell com raio existente; composição, fontes, cores e ícones preservados. `transactions_screen.dart` recebe callback para ações somente sobre registros editáveis do snapshot.
- `lib/app/main_shell.dart`: menu/formulário no Navigator privado, identidade revalidada após fechar menu, mesma instância financeira e trava de abertura. Sem outra carga ao abrir/retornar.
- `test/presentation/financial_test_fakes.dart`: update fake com UID, registro existente e instrumentação para falhas; sem uso na produção. Novos `transaction_update_test.dart` e `transaction_edit_screens_test.dart`.
- Novo runner opt-in `test/visual/m6_edit_capture.dart`, evidências em docs/evidencias/m6-2 e relatório M6_2_VALIDACAO_VISUAL.md. Atualizados este progresso e PLANO_M6.md.

Repositórios/contratos/guardas implementados no M6.1 foram reutilizados sem nova alteração nesta etapa; diffs deles contra o commit M5 continuam sendo trabalho preexistente preservado. Não modificados domínio monetário, modelo, regras/índices, SessionGate, autenticação, Gradle ou dependências. JSON redundante continua não rastreado; nenhum staging/commit/push/deploy.

### Fluxo e limites

Histórico → item real → menu somente Editar → formulário TEL-05 preenchido → validação → update com expectedUserId → carga completa → verificar ID/campos → retorno à origem. Sem atualização otimista, novo ID ou create na edição. Todos os indicadores/recentes continuam derivados do FinancialCalculator e do snapshot comum.

Commit confirmado com refresh falho mantém aviso Edição salva e permite somente leitura; resultado incerto não declara falha definitiva/sucesso e bloqueia o rascunho até conferência. Leitura compatível pode confirmar os campos esperados e retornar; conteúdo diferente deixa o rascunho sem reenvio, orientando retornar/conferir. Documento ausente oferece atualização e não é recriado. UI não é liberada para outro UID; menu e formulário são descartados pela árvore do gate no logout/troca, e respostas atrasadas são ignoradas.

Limitações mantidas: teste com fake não comprova persistência/SDK nativo/regras no servidor; nenhum teste remoto ou emulador iniciado nesta etapa. Não existe controle transacional de conflito entre edições de dispositivos além das guardas e validação de snapshot já descritas no plano. Timeout não cancela escrita já submetida. Sessão/IME/TalkBack/execução nativa continuam sujeitos às ressalvas M9, sem reabrir M5.6 dispensado.

### Validações M6.2 e evidências

| Verificação | Resultado real |
|---|---|
| dart format . | Exit 0; 106 arquivos, zero alterados na execução final |
| flutter analyze | Exit 1 pelos **44 informes de depreciação**, zero erros/warnings |
| flutter test --concurrency=1 | Exit 0; **561 aprovados**, preservando 515 anteriores + 46 novos |
| Captura opt-in M6.2 | Exit 0; um teste separado aprovado e oito PNGs, sem OOM |
| git diff --check | Exit 0, sem erros; avisos LF/CRLF locais informativos |

Novos testes: 21 de controller e 25 de widgets, com CA-07, centavos/faixa segura, campos/preenchimento, data original e alteração explícita, snapshot/UID, trava create/update, menu apenas Editar/fechamento, cancelamento, sucesso/retorno/recente, falha definida/recarga/incerteza/notFound, leitura sem replay, troca de sessão/dispose e 360/390/412 dp com texto 1/2 e teclado simulado. Regressores M4/M5 e testes M6.1 preservados. Analyzer: três imports Material oficiais novos (transaction_actions_sheet, transaction_edit_screens_test e m6_edit_capture), somados ao baseline 41; dois informes de estilo corrigidos antes da validação final, sem supressão.

Oito screenshots inspecionadas, dimensões dos PNGs conferidas: menu e edição de receita/despesa em 390, despesa 360/412, menu/edição em texto 2 a 360 e caso com inset de teclado. Comparadas com TEL-05/TEL-06, sem redesenho ou overflow identificado. Evidências e limites em [M6_2_VALIDACAO_VISUAL.md](M6_2_VALIDACAO_VISUAL.md). Menu complementar usa padrões Material; não existe desenho específico dele na prancha. Não equivalem a execução Android/Chrome, teclado nativo ou aceite visual automático.

Primeiras execuções dos testes de tela falharam na rolagem/localização e toque central de cards extensos em ListView lazy. Corrigido somente o helper para encontrar a linha e tocar sua parte visível; não ocultadas falhas nem alterado layout aprovado para passar testes. Logs finais locais em build/m6-2-*.log; nenhum log/cache/build versionado.

## M6.1 — Barreira de identidade em edição/exclusão, entregue para revisão

Planejamento M6 aprovado pelo usuário, incluindo as seis decisões registradas em PLANO_M6.md. Autorização exclusiva do M6.1; **não iniciar M6.2** sem aprovação. M5 permanece encerrado no commit `5ce9c6e8fafa222133c204de62d8d27c1e555f8f`.

### Arquivos alterados e decisões

- `lib/domain/repositories/transaction_repository.dart`: expectedUserId opcional em update/delete, compatível com chamadas sem o argumento, documentado como verificação e não seleção de proprietário.
- `lib/data/repositories/firestore_transaction_repository.dart`: verifica identidade na entrada antes de qualquer referência/transação; preserva verificação no callback, acrescenta conferência após get e mantém guardas antes da escrita e após confirmação. Caminho sempre usa UID do FirebaseSession; sem persistência alternativa ou alteração de auditoria.
- `test/data/transaction_repository_session_test.dart`: transporte local estendido com documentos/snapshots, update/delete enfileirados, pausas de leitura/confirmação, retry transacional simulado e falhas tipadas. Não interpreta enfileiramento do fake como prova de commit remoto.
- `test/presentation/financial_test_fakes.dart`: apenas assinaturas de update/delete atualizadas para implementar o contrato; sem implementação antecipada de edição/exclusão na apresentação.
- `docs/PLANO_M6.md` e este progresso: aprovação do planejamento, escopo entregue e limitações registrados. Alterações documentais anteriores ao M6.1 preservadas.

FinancialController, FirebaseSession, FinancialTransaction, Money/BigInt, calculadora, UI/rotas, regras/índices, Gradle e dependências não foram alterados. Regras/índices existentes revisados somente por leitura: isolamento por UID, proprietário/criação imutáveis e índice da consulta paginada preservados.

### Testes e alcance

Testes unitários com Auth fake, referências reais do SDK Dart e transporte de mensagens interceptado no processo; sem plugin nativo/rede, emuladores ou Firebase remoto. Cobertura nova: UID correto e divergente, nenhuma operação antes de identidade compatível, sessão B já ativa com mesmo ID, logout/troca antes/durante callback/get/retry, troca após enfileirar, documento ausente e proprietário inválido, unavailable/permission-denied/deadline-exceeded, chamadas antigas em B, proprietário e createdAt imutáveis e valores no/acima do limite seguro. Mantidos todos os casos anteriores.

A primeira execução direcionada não compilou por assinatura estreita do fake Transaction.update (Map<String,dynamic> em vez de Map<Object,Object?> exigido pelo SDK). Corrigido somente o fake; execução seguinte aprovou 52 testes direcionados. Acrescentados depois dois cenários para documento ausente durante troca de sessão, incluídos na suíte final. Logs locais ignorados em build/m6-1-*.log; sem senhas/tokens ou dados reais.

| Validação final M6.1 | Resultado real |
|---|---|
| dart format . | Exit 0, 102 arquivos examinados; um teste formatado na última execução |
| flutter analyze | Exit 1 pelos **41 informes de depreciação** conhecidos; zero erros/warnings, nenhum diagnóstico novo |
| flutter test --concurrency=1 | Exit 0, **515 aprovados**, 475 anteriores + 40 novos; inclui os 54 casos do arquivo de sessão |
| git diff --check | Exit 0, sem erros; avisos LF/CRLF locais informativos |

Sem emuladores/servidor nesta execução. Os testes não substituem validação Firestore/FlutterFire real; verificam execução do repositório e erros por transporte interceptado. Não foram reexecutados testes remotos nem bateria de Security Rules.

### Limitações e próxima etapa

Chamadas antigas sem expectedUserId operam na sessão corrente; futuros consumidores M6.2/M6.3 devem sempre passar UID esperado. Uma operação já submetida ao usuário A não é garantidamente cancelada por logout; guardas impedem redirecionar para B e não retornam sucesso à sessão incompatível. Erro incerto conserva os dados/ID de entrada e DataFailure para reconciliação por leitura, sem replay automático do repositório. A simulação local não valida rede, persistência ou aplicação das Security Rules por servidor; regras não modificadas nem reexecutadas nesta etapa.

Próxima entrega possível: M6.2, edição pelo controller/formulário/menu, somente após revisão e nova autorização. Sem telas, menus, busca/filtros, ocultação, dados remotos, build pesado, deploy, staging, commit ou push nesta execução. JSON redundante permanece preservado e fora do Git.

## Pós-commit M5 — Planejamento M6 preparado, não implementado

Commit local M5 concluído: **`5ce9c6e8fafa222133c204de62d8d27c1e555f8f`**, mensagem `feat: implementar dashboard e transacoes essenciais`, **90 arquivos**, branch main. Staging conferido contra manifesto explícito e `git diff --cached --check` aprovado; `git diff --check` também aprovado. Sem push/deploy. Imediatamente após o commit, somente `assets/illustrations/google-services.json` permaneceu não rastreado, preservado sem exclusão.

Após o commit foram relidos AGENTS.md, plano/progresso, documentos 01–05, protótipo e código financeiro. Criado **[PLANO_M6.md](PLANO_M6.md)**, exclusivamente documental. Esta anotação e o plano M6 são posteriores e **não estão no commit M5**; aguardar revisão antes de registrar ou implementar o próximo marco.

M6 proposto: M6.1 barreira expectedUserId compatível para update/delete; M6.2 edição reutilizando formulário; M6.3 exclusão confirmada; M6.4 busca/filtros locais por tipo/categoria e organização; M6.5 olho do saldo e regressão de recentes; M6.6 verificação dirigida/evidências. Cada subetapa depende de autorização. update/delete já existem no repositório; proteção adicional é importante especialmente para delete por ID após troca de UID. Busca/chips/tune/olho ainda indisponíveis têm destino M6; sino, meta e Ver mais não se tornam novos recursos deste marco.

Planejamento preserva FinancialController único, precisão Money/BigInt, carga completa e recálculo do domínio, sessão/rotas e visual aprovados. Decisões para revisão: extensão de contrato, menu/diálogo e formulário, filtros combinados e privacidade somente do saldo em memória. Sem orçamento, relatórios, Google Login ou BolsoZen Bot. Ressalvas M4/M5 continuam transferidas ao M9; nenhuma nova homologação, operação remota ou código M6 nesta tarefa.

## M5 — Encerrado por aprovação manual do usuário, com ressalvas

Usuário testou o aplicativo financeiro integrado e aprovou seu funcionamento. **M5 encerrado; homologação extensa M5.6 dispensada por decisão expressa do usuário.** Dispensa não significa execução ou aprovação de testes inexistentes. Registros anteriores de revisão pendente são históricos.

Entregues: Dashboard com saldo global/mês corrente/categorias/recentes; Histórico completo; cadastro real de receitas/despesas; formulário TEL-05; três abas privadas integradas e Perfil reutilizado; FinancialController único compartilhado; proteção por UID/expectedUserId; parser/formatador e fronteiras monetárias Web corrigidos com BigInt e inteiros seguros. Fonte de dados continua nos repositórios existentes, sem números fictícios em produção.

Evidência automatizada anterior preservada: **475 testes Flutter aprovados**, format sem erros, analyzer com **41 informes de depreciação** e zero erros/warnings, captura integrada opt-in aprovada com oito screenshots. Esta tarefa não reexecutou Flutter, integração, testes remotos ou homologação extensa; revisão documental e comandos Git não substituem essas evidências. Registro conciso em [M5_HOMOLOGACAO.md](M5_HOMOLOGACAO.md), relatórios visuais e logs ignorados anteriores preservados.

### Ressalvas cumulativas transferidas ao M9

- Integração financeira adicional com SDKs reais apontando exclusivamente aos emuladores locais Auth/Firestore.
- Verificações Android/Web que não foram executadas no M5, sem converter testes de widgets/capturas em homologação nativa.
- Teclado virtual e acessibilidade nativa/TalkBack; texto ampliado e insets simulados são somente evidência local.
- Persistência após encerramento/reabertura real do processo quando ainda não comprovada, inclusive sessão autenticada Android herdada do M4.
- Bateria Chrome automatizada do M4 interrompida por OOM, origem fixa/reload/histórico e checkpoints restantes; persistência Safari relatada pelo usuário continua evidência manual, sem generalização ao Android.
- Revisão dos **41 informes atuais**, incluindo o histórico M4; não somar contagens históricas nem ocultar diagnósticos.

Preservados [M4_HOMOLOGACAO.md](M4_HOMOLOGACAO.md) e backlog M9 do PLANO.md. Ressalvas aceitas não bloqueiam encerramento ou commit; futura execução depende do marco/autorização apropriados. Sem Firebase remoto, regras/índices/Gradle/dependências alterados ou exclusão de dados nesta tarefa.

### Revisão e registro Git do M5

Branch main e base M4 `606af8b5cee6eeba349d9aab22af1f5d89be9551` confirmadas. Seleção explícita dos arquivos M5, incluindo testes, diagnósticos monetários reutilizáveis e evidências identificadas como fixtures. JSON redundante `assets/illustrations/google-services.json` preservado, excluído da seleção. Builds/logs/caches/perfis de navegador e credenciais administrativas não serão versionados. Revisão de conteúdo e diff-check antecedem staging/commit; hash e quantidade serão informados no relatório final a partir do resultado do Git. Nenhum push/deploy. Planejamento do M6 somente após esse commit, sem implementação.

Seleção pré-commit conferida: **90 arquivos**, sendo 60 textos/fontes/manifestos e 30 PNGs de evidências. Nenhum arquivo temporário/build/cache selecionado; revisão e varredura por padrões de chaves privadas, service account e tokens não encontraram ocorrências na seleção textual. Senhas ilustrativas de testes permanecem restritas a fakes/emuladores já identificados; não são credenciais de contas remotas. Dados monetários das screenshots são fixtures identificadas, sem dados financeiros pessoais. Revisão não constitui garantia absoluta de detecção automática de segredos.

## M5.5 — Navegação privada integrada, aguardando revisão

M5.4 revisado e aprovado tecnicamente pelo usuário. Implementado exclusivamente M5.5. **Não iniciar M5.6 sem autorização.** Os registros seguintes descrevem etapas históricas; aplicação normal agora abre Dashboard após identidade e perfil confirmados.

### Arquivos e comportamento

- Novo `lib/app/main_shell.dart`: dono de um FinancialController por identidade pronta; initState cria/carrega uma vez, dispose encerra seus recursos. IndexedStack preserva telas/rolagem e controller entre Início, Transações e Perfil. Formulário usa a mesma instância e Navigator privado, com trava contra abertura duplicada.
- `lib/app/auth_experience.dart` e `lib/main.dart`: readyBuilder passa a criar MainShell com chave navigationVersion/UID, recebendo o repositório financeiro já existente de AppDependencies. FirebaseStartup, AppDependencies, SessionController e SessionGate continuam reutilizados; nenhum segundo bootstrap ou repositório criado.
- `lib/core/theme/app_theme.dart`: tema centralizado de NavigationBar oficial, três destinos reais, Roboto 12, ícones 24, primary/mintSurface, altura 64. Sem abas falsas Orçamento/Relatórios.
- `dashboard_screen.dart`: FAB real e Ver todas funcional por callbacks da composição, preservando estilo aprovado, mês atual e cálculos do controller. `transactions_screen.dart`: FAB real e espaço inferior na lista para não encobrir o último item. Nenhum acesso Firestore no build.
- `integration_test/m4_ui_local_app.dart`: somente inclusão do repositório já inicializado na composição exigida; guardas demo-bolsozen/emuladores preservadas, sem execução do runner remoto.
- Testes novos `test/presentation/main_shell_harness.dart` e `main_shell_test.dart`; ajustados `auth_screens_test.dart`, `register_screens_test.dart` e `test/visual/m4_auth_preview.dart` para o novo destino padrão, mantendo os casos anteriores e visitando a aba Perfil nos testes específicos desse destino.
- Novo runner opt-in `test/visual/m5_shell_capture.dart`, evidências em docs/evidencias/m5-5 e relatório M5_5_VALIDACAO_VISUAL.md. Atualizados este progresso e PLANO_M5.md.

### Segurança, sincronização e limites

Não há nova leitura ao abrir formulário/trocar aba/retornar de gravação. O controller existente realiza a única recarga completa posterior ao commit; confirmação e atualização pendente permanecem distintas. Retry de leitura não repete create. Ao sair manualmente de formulário com atualização pendente, o snapshot anterior continua explicitamente desatualizado; sem snapshot, nenhum zero é apresentado como confirmado.

Gate só cria shell com sessão/perfil válidos; ausência/erro de perfil segue o M4. Logout e troca de UID removem inclusive rotas secundárias; controller antigo limpa dados e é descartado. Resultados atrasados não publicam nem navegam em sessão nova. Perfil mantém nome/e-mail reais e logout com tratamento de falhas. Domínio, precisão monetária, expectedUserId e repositórios financeiros preservados nesta etapa.

### Validação

| Verificação final M5.5 | Resultado |
|---|---|
| dart format . | Exit 0; 102 arquivos, zero alterados na execução final |
| flutter analyze | Exit 1 pelos 41 informes de depreciação; zero erros/warnings |
| flutter test --concurrency=1 | Exit 0; **475 aprovados**, 454 anteriores preservados + 21 novos |
| Captura opt-in integrada | Exit 0; um teste separado aprovado e oito PNGs, sem OOM |
| git diff --check | Exit 0; sem erros de whitespace, avisos LF/CRLF informativos |

Novos informes do analyzer: imports Material oficiais em main_shell.dart, main_shell_harness.dart, main_shell_test.dart e m5_shell_capture.dart, sem supressão/refatoração ampla. Os 21 testes cobrem login para Dashboard, barreiras de perfil, três abas, uma carga/controller, preservação de rolagem, Ver todas, abertura/retorno pelas duas origens, abertura duplicada, atualização saldo/lista, commit com falha de refresh/retry de leitura, aviso stale, logout/descarte/Voltar, UID e respostas atrasadas, 360/390/412 dp com texto 1/2 e alvos/rótulos acessíveis.

Oito screenshots inspecionadas: três abas e formulário em 390 dp, Dashboard em 360/412, Dashboard/Histórico com texto 2 em 360. Barra é a NavigationBar real de três destinos, não fixture de cinco abas. Formulário sem barra visível; nenhuma duplicação/overflow identificado. Ícones e indicador nativos mantêm aproximações descritas em [M5_5_VALIDACAO_VISUAL.md](M5_5_VALIDACAO_VISUAL.md). Captura verifica FAB tocável e registra seus limites no manifesto; sem submissão ou gravação. Não confundir com execução nativa Android/Chrome ou aprovação visual automática.

A primeira execução direcionada encontrou somente falhas na preparação/expectativas dos testes novos: tentativa de tocar Entrar fora da viewport, representação textual esperada do saldo negativo, e-mail normalizado e descarte do handle de semântica no fim do teste. Corrigidos os testes, sem esconder falhas; suíte direcionada com 21 aprovados. Analyzer detectou inicialmente um argumento novo ausente no runner local M4; corrigido com a instância já existente. Logs locais ignorados em build/m5-5-*.log, sem credenciais/dados remotos.

Sem build Android pesado, alteração Firebase/regras/índices, contas/transações remotas, dependências, Gradle, staging, commit, push ou deploy. JSON redundante preservado e não incluído no Git. Homologação com plugins reais/dispositivo pertence ao próximo marco autorizado; evidência do renderer de testes não substitui Android/Web/TalkBack.

## M5.4 — Formulário e criação, entregue para revisão (18/11/2026)

**M5.3 aprovado visualmente pelo usuário.** Os quatro ajustes finais autorizados foram incorporados nesta entrega. M5.4 implementado e aguardando revisão; M5.5 não iniciado. Os registros anteriores são históricos e não substituem esta situação atual.

### Entrega e arquivos

- Novo `lib/presentation/screens/transactions/transaction_form_screen.dart`: formulário TEL-05 com Receita/Despesa, valor em reais, categorias compatíveis, data inclusive futura, descrição obrigatória e Conta principal informativa. Reutiliza SubmitButton, CategoryIcon, Money, tokens e Material 3 existentes. Validação, loading, bloqueio de envio duplicado e erros em português; sem alteração da navegação normal.
- Novo `lib/domain/services/transaction_validation.dart`: validações puras de valor positivo/seguro, descrição de 1–120 caracteres Unicode, categoria/tipo e data. Sem segundo modelo monetário.
- `financial_controller.dart`: criação pelo TransactionRepository real com expectedUserId e uma única chamada de escrita, seguida de carga completa compartilhada. Não publica totais parciais. Aguarda leitura anterior e inicia leitura nova após confirmação da gravação; exige que o ID confirmado apareça no histórico antes de declarar dados atualizados. Falha de atualização não repete criação. Resultado incerto bloqueia reenvio do mesmo formulário e exige conferência do histórico; uma leitura não garante cancelamento de escrita anterior.
- `dashboard_screen.dart`: seletor removido da interface; competência sempre do mês local atual, incluindo virada do mês e retorno do segundo plano. Timer local com intervalo máximo diário, sem polling Firestore, cancelado em background/dispose. FinancialMonth e selectMonth preservados. Saldo global mantém todo o histórico; totais/categorias usam mês corrente.
- `transactions_screen.dart`, `transaction_tile.dart`, `category_icon.dart`: cabeçalhos textPrimary 14/semibold, títulos 16/semibold e ícones 28 dp somente no Histórico; cores, fundos, agrupamento e espaçamentos preservados.
- `financial_visual_tokens.dart`: cor de texto do controle Despesa do novo formulário ajustada para contraste; não redesenha componentes aprovados.
- Testes novos: `transaction_validation_test.dart`, `transaction_creation_test.dart`, `dashboard_current_month_test.dart` e `transaction_form_test.dart`; adaptados `financial_screens_test.dart` e `financial_test_fakes.dart`. Runners `m5_financial_capture.dart` e novo `m5_transaction_capture.dart` reutilizam `visual_fonts.dart`, somente com opt-in.
- Documentação: PLANO_M5.md, este progresso, M5_3_VALIDACAO_VISUAL.md e novo M5_4_VALIDACAO_VISUAL.md. Evidências atualizadas em docs/evidencias/m5-3 e m5-4; preservadas as capturas aprovadas de 390 dp com prefixo aprovado-.

### Qualidade e evidências

Suíte de **454 testes Flutter aprovados**: os 414 anteriores preservados e 40 novos. Cobertura de receita/despesa, validações, precisão, datas futuras, submissão duplicada, escrita confirmada seguida de falha de leitura, resultado incerto, UID/logout/dispose, virada de mês sem nova consulta, navegação isolada, responsividade 360/390/412 dp, texto ampliado, teclado simulado e acessibilidade. Nenhuma operação Firebase remota.

`dart format .`: exit 0, 98 arquivos, zero alterados na última execução. `flutter analyze`: 37 informes de depreciação, zero erros/warnings, exit 1 pelos informes (33 anteriores e quatro imports Material oficiais novos); sem supressão. `flutter test --concurrency=1`: 454 aprovados, exit 0. Dois testes separados de captura opt-in aprovados, gerando 18 imagens (12 Dashboard/Histórico e seis formulário). `git diff --check`: sem erros de whitespace na verificação final.

A execução inicial encontrou contraste insuficiente no controle Despesa e uma expectativa de teste pelo tooltip inglês Back; corrigidos o contraste do novo controle e o teste para Voltar. Inspeção visual detectou data por extenso cortada com fonte 2; campo passou a dd/MM/yyyy pt-BR. Não houve OOM. Logs locais ignorados em build/m5-4-*.log; não incluir logs no Git.

### Limitações e próxima etapa

Capturas são do renderer Flutter de testes com fixtures identificadas, não do Chrome/Android. Insets de teclado são simulados, sem homologação de IME/TalkBack. Data numérica, rótulos flutuantes e contador de descrição são adaptações documentadas de TEL-05. Formulário/controlador ainda isolados da aplicação normal; ligação das rotas/FAB e recarga entre abas pertence exclusivamente ao M5.5. Sem criação remota, alteração de repositórios financeiros, regras, índices, Gradle ou dependências nesta entrega. JSON redundante preservado e fora do staging; sem commit/push/deploy. Próximo passo: revisão visual do TEL-05 e dos quatro ajustes pelo usuário, aguardando autorização para M5.5.

## M5.3 — Revisão visual obrigatória, aguardando novo aceite

**O usuário revogou o aceite visual anterior para homologação definitiva.** Executada somente a correção visual TEL-04/TEL-06 solicitada; não iniciar M5.4. Este registro substitui as decisões visuais anteriores que omitiam sino, olho, terceiro indicador, categorias, recentes e estrutura de busca/chips. Essas estruturas agora foram expressamente autorizadas com indisponibilidade honesta dos recursos futuros, sem implementar os módulos completos.

### Correções entregues e limites

Dashboard: avatar verde, saudação com nome real/👋 e sino não interativo; saldo com gradiente amostrado, carteira decorativa, olho circular desabilitado; três indicadores compactos (receitas/despesas reais e Meta do mês Em breve); categorias/ícones pastel/barras/percentuais confirmados; um lançamento recente; Ver mais/Ver todas/FAB indisponíveis com identificação do marco futuro. Seletor mensal permanece funcional, agora abaixo dos indicadores. Refresh real por puxar para baixo, validado nas duas telas.

Histórico: busca/lupa/ajustes e pills somente visuais, sem handlers ou promessa de funcionalidade; caption explícita M6. Agrupamento de dias locais em Hoje/Ontem/outras datas, cards brancos com sombras suaves, ícones específicos coloridos e tipografia monetária compacta. ListView.builder permanece lazy por linha/cabeçalho. Busca e chips rolam junto com o histórico para manter espaço ao conteúdo ampliado e ao aviso stale fixo.

FinancialProjection é uma projeção pequena, determinística e somente de apresentação: usa categoryPercentages já calculado por FinancialCalculator, seleciona o primeiro histórico confirmado para recente e intercala cabeçalhos de datas. Nenhum saldo/totais foi duplicado, nenhuma transação retirada da lista completa e nenhuma consulta adicional. Participação nos gastos não é utilização de orçamento. Meta não afirma que não há configuração, pois orçamento não foi consultado; mostra somente Em breve.

FinancialController, FinancialCalculator, Money/precisão, repositórios/expectedUserId, modelos, SessionController/Gate, autenticação, onboarding, Perfil, regras/índices/Firebase e Gradle não foram alterados nesta revisão. Tema global preservado; tons financeiros derivados da prancha estão isolados. App normal continua sem conexão às telas financeiras; não há formulário, edição/exclusão, busca/filtragem ou navegação de produção nova. O rodapé de cinco destinos aparece **apenas no runner visual**, excluído da semântica e sem ações; não é NavigationBar funcional.

### Arquivos desta revisão

- Novos lib/core/theme/financial_visual_tokens.dart e lib/presentation/services/financial_projection.dart.
- Novos widgets category_spending_section.dart, unavailable_financial_action.dart e unavailable_history_filters.dart.
- Revisados dashboard_screen.dart, transactions_screen.dart, balance_card.dart, category_icon.dart, monthly_totals_cards.dart e transaction_tile.dart. financial_month_selector.dart/financial_load_state.dart e controller preservados.
- Teste novo test/presentation/financial_projection_test.dart; ajustados financial_screens_test.dart e test/visual/m5_financial_capture.dart, mantendo todos os casos anteriores.
- docs/M5_3_VALIDACAO_VISUAL.md refeito com comparação antes/depois, tabela de fidelidade e auditoria de ícones/cores; este progresso e nota de atualização em PLANO_M5.md.
- Evidências: doze PNGs revisados e manifesto em docs/evidencias/m5-3; preservadas duas imagens anteriores de 390 dp como antes-dashboard-390.png e antes-transacoes-390.png. Nenhuma fonte/imagem externa acrescentada ao app.

### Execuções e resultados reais

| Validação | Resultado |
|---|---|
| dart format . | Exit 0; 90 arquivos examinados, um ajustado na execução final |
| flutter analyze | Exit 1 pelos **33 informes de depreciação**, zero erros/warnings |
| flutter test --concurrency=1 | **414 aprovados**, exit 0; os 407 casos preservados + sete direcionados |
| Captura opt-in pelo renderer Flutter | Um teste separado aprovado, doze imagens finais, exit 0, sem OOM |
| git diff --check | Exit 0, sem erros de whitespace; avisos locais LF/CRLF continuam informativos |

Os sete testes novos cobrem participação versus orçamento, recente imutável, agrupamento/virada de ano, vazio sem invenção, composição/ações indisponíveis e atualização por gesto nas duas telas. Casos existentes de responsividade, texto ampliado, semântica/contraste, UID, estado stale/erro/loading e domínio foram preservados. Somente asserções visuais incompatíveis com o novo pedido (ausência de FAB, saudação sem emoji, data sempre no subtítulo e texto de acesso antigo) foram atualizadas; nenhum teste foi removido.

Analyzer: 30 informes da primeira entrega M5.3 e três imports Material oficiais novos; um informe de estilo identificado na revisão foi corrigido. Sem ocultar diagnósticos ou instalar material_ui. A primeira suíte completa da revisão aprovou 413 e falhou em um teste antigo: overflow real de 6 px ao combinar texto ampliado, filtros visuais e estado stale/erro. Corrigido tornando busca/chips parte rolável da lista e mantendo aviso fora dela; teste mantido. Suíte final com 414 aprovados executada após a correção. Log da falha preservado localmente em build/m5-3-revisao-test-primeira.log; logs finais de análise/teste/captura em build/m5-3-revisao-*.log, ignorados.

### Evidência visual, diferenças e decisões pendentes

Doze capturas finais abertas/inspecionadas e comparadas com a prancha: duas telas em 360/390/412 dp, texto 2 em 360, valor extenso e fixture adicional de composição em 390. Capturas do renderer Flutter de testes com Roboto/MaterialIcons locais e emoji de fonte de sistema existente somente no runner; não Android/Chrome. Sem overflow nas capturas finais. O conteúdo ampliado rola e valores extremos podem ocupar mais linhas, sem perda de centavos ou ellipsis.

Fixture T1 mantém saldo 60000, receitas 100000 e despesas novembro 35000 centavos. Na fixture adicional, datas foram alteradas **somente em memória de teste** para três categorias no mês e dois grupos de dias; despesas mensais 40000, saldo global 60000. Não confundir com os valores da prancha ou com dados reais de usuário. Não houve criação remota, conta de teste, envio de e-mail ou acesso Firebase nesta revisão.

Relatório completo: [M5_3_VALIDACAO_VISUAL.md](M5_3_VALIDACAO_VISUAL.md). Classificações incluem Fiel, Aproximado, Diferente e Adiado por dependência funcional, sem declarar 100% ou pixel-perfect. Carteira/alguns traços Material e cores raster são aproximados; seletor mensal/caption M6 são adaptações explícitas. O vermelho compacto foi escurecido para contraste em texto 14, mantendo o vermelho global do tema intacto. Usuário deve revisar essa opção versus vermelho original em texto maior, a posição do seletor, as indisponibilidades e eventual necessidade de asset próprio da carteira. Nenhum asset/dependência foi incluído sem aprovação.

Permanecem adiados: ação do olho, busca/filtros/edição/exclusão completos M6; percentuais de orçamento M7; detalhamento/relatórios M8; formulário M5.4 e ligação/navegação M5.5. TalkBack, renderização/rolagem Android/Web e aceite visual definitivo continuam pendentes. Não houve build pesado, instalação, deploy, staging, commit ou push. JSON redundante assets/illustrations/google-services.json preservado e não rastreado. **Aguardar revisão visual do usuário; M5.4 não autorizado.**

## M5.3 — Dashboard e lista implementados para revisão

M5.2 revisado/aprovado pelo usuário. Implementado exclusivamente M5.3, sem formulário, escrita ou ligação à navegação normal; M5.4 e posteriores não autorizados. Os registros de autorização anteriores abaixo são históricos.

### Arquivos desta etapa

- lib/presentation/screens/dashboard/dashboard_screen.dart.
- lib/presentation/screens/transactions/transactions_screen.dart.
- lib/presentation/widgets/balance_card.dart, monthly_totals_cards.dart, financial_month_selector.dart, transaction_tile.dart, category_icon.dart e financial_load_state.dart.
- test/presentation/financial_screens_test.dart e financial_test_fakes.dart.
- test/visual/m5_financial_capture.dart, runner opt-in fora da descoberta padrão *_test.dart.
- docs/evidencias/m5-3/: dez PNGs e manifest.json, somente fixtures identificadas.
- docs/M5_3_VALIDACAO_VISUAL.md, docs/PLANO_M5.md e este progresso.

Alterações M5.1/M5.2 já existentes foram preservadas; o status Git também contém esses arquivos ainda sem commit. Nenhuma modificação adicional no controller, domínio, repositórios, sessão, tema global, onboarding, autenticação, Perfil, Firebase, regras, índices, Gradle ou dependências. JSON redundante assets/illustrations/google-services.json continua não rastreado, intacto e fora de staging.

### Funcionalidades entregues

Dashboard com nome/inicial do perfil correspondente ao UID, saldo global, receitas/despesas confirmadas, seletor de competência e atualização manual. Apenas formata resultados do FinancialController/Money; não calcula totais em widgets. Indicação textual da área Transações, sem ação falsa ou rota incompleta. Lista completa com ListView.builder, ordem do domínio, descrição/categoria/data de ocorrência, sinais +/− e ícones Material. Não há onTap de edição, filtros, busca, gráfico, orçamento, FAB ou barra inferior antecipados.

ListenableBuilder reage a idle/loading/refreshing/ready/empty/error/sessionInvalidated. Carga incompleta/erro inicial não mostram saldo zero fictício; vazio confirmado mostra zeros legítimos. Refresh preserva snapshot completo anterior apenas com aviso de possível desatualização. Aviso e recuperação ficam fora da área de rolagem em ambas as telas, inclusive quando o usuário já rolou. UID incompatível/sessão invalidada oculta os dados, sem nome ou valores anteriores.

### Validações executadas

| Comando/verificação | Resultado real |
|---|---|
| dart format . | Exit 0; 84 arquivos examinados, dois formatados na execução final |
| flutter analyze | Exit 1 apenas pelos **30 informes de depreciação**; zero erros/warnings |
| flutter test --concurrency=1 | **407 aprovados**, exit 0: 374 anteriores + **33 novos** |
| Runner visual opt-in | **Um teste adicional aprovado**, exit 0; dez capturas do renderer Flutter com fontes Roboto/MaterialIcons do SDK; sem OOM |
| git diff --check | Exit 0; avisos locais LF/CRLF não são erros de whitespace |

Analyzer: 20 informes preexistentes e dez novos de import package:flutter/material.dart (oito arquivos de telas/widgets, teste de widgets e captura). Mantido Material oficial conforme decisões aprovadas; sem ignorar diagnósticos, adicionar material_ui ou alterar SDK/dependências. Três informes novos de estilo da análise inicial foram corrigidos.

Cobertura nova: saldos positivo/zero/negativo, nome/tema, T1 mensal e troca de competência sem leitura extra, ordem lazy/lista/datas/sinais, idle/vazio/carga incompleta, rede/retry, refresh/stale/erro, aviso persistente após rolagem, UID incompatível/logout, semântica de tipo/categoria/data/valor, alvos de toque Android/labels/contraste e 12 combinações de tela/largura 360–390–412/texto 1–2 com valor máximo seguro e descrição longa.

Primeira execução focal encontrou duas falhas no próprio teste: exigir todos os itens já construídos por uma lista lazy e encerrar tarde o handle de semântica. Corrigidas para verificar a ordem visível e rolar até o último item e liberar o handle antes de encerrar o teste. Nenhum teste removido. Uma revisão posterior fixou o aviso stale fora da rolagem; dois testes novos verificam esse comportamento. A suíte final acima passou após esse ajuste.

### Comparação visual e limitações

Prancha oficial inspecionada visualmente; capturas reais do **renderer Flutter de testes**, com fontes locais Roboto/MaterialIcons e sombras reais do tema, comparadas a TEL-04/TEL-06. Não são screenshots Android/Chrome nem prova de persistência Firebase. Seis capturas normais (duas telas × três larguras), duas com texto 2 em 360 e duas com texto 2/valor extremo/descrição extensa. Captura inicial foi corrigida para não usar sombras artificiais desabilitadas pelo test runner e para não ampliar o rótulo técnico da fixture. Dez arquivos finais correspondem ao código final.

Referências, links e diferenças detalhados em [M5_3_VALIDACAO_VISUAL.md](M5_3_VALIDACAO_VISUAL.md). Omissões M6–M8/M5.4–M5.5 são intencionais e autorizadas; ícones usam apenas os tokens oficiais, sem inventar azuis/roxos para categorias. Valores secundários usam titleLarge 20/w700 para manter contraste do vermelho do token como texto grande; quantias extremas e texto ampliado ocupam mais linhas sem ellipsis, redução silenciosa de fonte ou perda de centavos. Não declarar pixel-perfect.

Testes de acessibilidade básicos passaram, mas TalkBack, toque/rolagem nativos e renderização Android/Web aguardam homologação em plataforma. App normal continua no fluxo aprovado do M4, sem novos dados fictícios de produção ou rotas conectadas. Logs locais ignorados: build/m5-3-analyze.log, build/m5-3-test.log, build/m5-3-capture.log; nenhuma credencial ou dado pessoal real nas evidências.

Próximo passo: usuário revisar telas/capturas e autorizar separadamente M5.4. Criação de transações continua fora desta entrega; composição normal somente M5.5. Nenhum teste remoto, conta/documento remoto, build Android/Web, staging, commit, push ou deploy nesta etapa.

## M5.2 — Carregamento financeiro implementado para revisão

M5.1 aprovado pelo usuário, incluindo expectedUserId, política de precisão BigInt/faixa técnica e 337 testes anteriores. Implementado exclusivamente M5.2; M5.3 e seguintes aguardam autorização. Os estados antigos de autorização abaixo são históricos.

### Arquivos desta etapa

- Novo lib/presentation/controllers/financial_controller.dart.
- Novo test/presentation/financial_controller_test.dart.
- Atualizados docs/PLANO_M5.md e docs/PROGRESSO.md.

Alterações M5.1 já presentes no início foram preservadas; status Git contém também esses arquivos ainda não registrados. Não foram novamente alterados domínio financeiro, repositórios, sessão, configuração, dependências, Gradle, regras, índices, assets ou funcionalidades de autenticação nesta etapa. assets/illustrations/google-services.json continua não rastreado e sem staging.

### Entrega e estados públicos

FinancialController com ChangeNotifier, injetando TransactionRepository, SessionController e UID esperado fixo; mês inicial opcional. Não inicia consultas no construtor. API load/refresh/retry/selectMonth; estado observável pronto para ListenableBuilder futuro, sem widgets/telas de produção nesta etapa. FinancialPhase: idle, loading, refreshing, ready, empty, error, sessionInvalidated. Expõe mês, lista imutável confirmada, FinancialSummary?, DataFailure?, isLoading, hasConfirmedSnapshot e isStale.

Carga sequencial de páginas de 100 até página curta/vazia. Cursor é o último registro bruto; valida avanço/tupla/ciclos e tamanho da página. Buffer local por ID, duplicatas idênticas deduplicadas, conteúdo conflitante recusado. Registro de outro UID invalida a instância e apaga snapshot. Valores individuais passam pela faixa monetária aprovada. Cálculos e ordenação finais somente por FinancialCalculator; nenhum resumo parcial publicado. Troca de mês recalcula apenas em memória, inclusive quando alterado durante carga.

Uma Future compartilhada evita refresh simultâneo/reentrante e load repetido após sucesso. Geração/UID/versão da sessão validados antes de cada fetch e após awaits; expectedUserId sempre fornecido. O controller observa a sessão pronta existente e invalida imediatamente ao sair/trocar identidade, inclusive A -> B -> A. Não armazena objetos Firebase ou credenciais. Dispose remove listener e impede publicação/notificação tardia. O shell futuro será dono da instância; nenhuma composição foi ligada agora.

Refresh pode preservar o snapshot completo anterior do mesmo UID com isStale=true, inclusive após erro de rede. Erro na primeira carga mantém summary=null, nunca saldo zero definitivo. Permission-denied apaga os dados; falhas de sessão tornam a instância terminal. Falhas inesperadas não expõem mensagens técnicas. Nenhuma criação de transação implementada.

### Testes e resultados reais

- dart format .: exit 0; 73 arquivos examinados, zero alterado na execução final.
- flutter analyze: exit 1 pelos **20 informes de depreciação preexistentes**, zero erros e zero warnings. Cinco informes novos de estilo identificados na primeira análise foram corrigidos sem supressão.
- flutter test --concurrency=1: **374 testes aprovados**, exit 0, incluindo os 337 anteriores e **37 novos** do controller.
- git diff --check: exit 0, sem erros de whitespace; avisos LF/CRLF locais não representam falha.

Cobertura nova: vazio/0/100/101/200/201; saldo positivo/zero/negativo; T1/outros meses e ano/futuro; ordenação e imutabilidade; duplicatas e cursor bruto; conflito, cursor parado/cíclico/retrocesso e página fora do contrato; falha intermediária/retry sem totais parciais; mês alterado durante carga; refresh/load/retry concorrentes e listener reentrante; snapshot stale/recuperação; permission-denied e sessão perdida; logout, A -> B, A -> B -> A, dispose e respostas tardias; controller B independente; barreira SDK antes do evento; UID alheio; valor incompatível; falha desconhecida e construtor com identidade divergente.

Testes usam repositório determinístico e o SessionController real com Auth/User fakes locais já existentes. Nenhum SDK/emulador remoto ou dado real usado. Logs sanitizados locais em build/m5-2-analyze.log e build/m5-2-test.log, ignorados. Não reexecutados runners M3/M4, Chrome/DDC ou build Android; nenhum OOM nesta etapa.

### Limitações, validação pendente e próxima etapa

Controller ainda isolado do app normal: não há Dashboard, formulário, navegação, escrita ou interface visual para homologar agora. Não houve integração Firestore real nesta etapa. Paginação não é snapshot atômico global; mudanças externas podem exigir refresh; custo e memória crescem com o histórico. O snapshot anterior só poderá aparecer na UI futura com indicação explícita de desatualização. A competência extrema fora da janela anterior suportada pela calculadora gera erro explícito, sem alteração do domínio.

M5.3 deverá implementar Dashboard/lista/componentes e consumo com ListenableBuilder sob nova autorização, com comparação visual/responsividade. M5.4 continua responsável por criação/recarga após gravação e M5.5 pela ligação à aplicação. Não houve commit, staging, push, deploy, acesso remoto ou alteração fora desse escopo. Aguardar revisão do usuário antes de prosseguir.

## M5.1 — Correção da precisão monetária entregue para revisão

Barreira expectedUserId aprovada. Correção monetária especificamente autorizada pelo usuário, com limite técnico de **9007199254740991 centavos** nas fronteiras de entrada e persistência, comum a Android/Web. M5.2 não autorizado. Este registro atualiza os estados históricos de correção pendente abaixo.

### Implementação e arquivos desta correção

- lib/domain/services/money.dart: parse original por BigInt antes de int, limite centralizado e erro de precisão pt-BR; formatação Web defensiva. Assinaturas parseCents/formatCents preservadas.
- lib/domain/services/financial_calculator.dart: mantém soma BigInt; na Web rejeita entradas incompatíveis e agregados acima da faixa antes de converter. Na VM preserva cálculos nativos maiores exatos e detecção de overflow.
- lib/data/mappers/firestore_mappers.dart: valida amountCents/limitCents nas duas direções, sem coerção de double/string ou recuperação fictícia de valor já arredondado pelo SDK.
- lib/data/repositories/firestore_transaction_repository.dart e firestore_budget_repository.dart: rejeição antecipada na criação/save. A barreira de sessão anterior foi preservada; update de transação usa o mapper validado, sem mudar o contrato. Sem funcionalidade nova de orçamento.
- test/domain/money_test.dart e test/data/firestore_mappers_test.dart: asserções de entrada/persistência antes acima da faixa ajustadas à política aprovada; testes mantidos.
- test/domain/money_precision_test.dart e test/data/repository_session_test.dart: novos casos de fronteira, erro, formatação, agregados, rejeição antes do SDK; cobertura anterior preservada.
- test/diagnostics/money_precision_probe.dart: atualizado para verificar aceitação exata/rejeição e agregado por plataforma; runner Chrome anterior reutilizado sem mudança.
- docs/PLANO_M5.md e este progresso: política final, evidências, diferenças por plataforma e limitações.

### Resultados reais desta execução

| Verificação | Resultado |
|---|---|
| dart format . | Exit 0; 71 arquivos examinados, um ajustado na última execução |
| flutter analyze | Exit 1 somente pelos 20 informes de depreciação conhecidos; zero erros/warnings após correção dos novos testes |
| flutter test --concurrency=1 | **337 aprovados**, exit 0; 322 casos mantidos + 15 novos |
| Probe VM | Exit 0; quatro entradas exatas, quatro rejeitadas; agregado 9007199254740993 exato |
| dart compile js -O1 | Exit 0; compilação do probe em 0,69 s, sem build Android |
| Probe Chrome real/dart2js | Exit 0; quatro entradas exatas, quatro rejeitadas; quatro números previamente convertidos recusados; agregado fora da faixa rejeitado, nenhuma perda nos valores aceitos |
| git diff --check | Exit 0; apenas avisos de conversão local LF/CRLF |

Logs locais build/m5-1-safe-analyze.log, build/m5-1-safe-test.log e build/m5-1-safe-money-vm.log; evidência Chrome atual em build/m5-1-money-chrome.json, com javaScript=true e aggregateRejected=true. Artefatos ignorados, sem credenciais. O probe anterior de diagnóstico foi atualizado para a regressão; seus achados originais permanecem documentados no histórico abaixo. As 15 novas unidades abrangem 11 casos monetários/agregados, três de mapeadores e um de rejeição antecipada dos repositórios.

Na primeira análise desta correção houve duas referências a fixtures locais antes da declaração e três informes de estilo no probe; corrigidos sem supressão. A validação final contém apenas os 20 informes preexistentes.

### Comportamento e limitações

Entradas acima da faixa agora falham explicitamente em ambas as plataformas; inclusive 2^53 isoladamente representável é recusado para manter política uniforme. Centavos comuns, agrupamento pt-BR, um centavo, sinais na formatação e regras financeiras normais continuam exatos. Testes T1/T2 e financeiros anteriores passaram.

Dados Firestore fora da faixa são inválidos, mesmo que o SDK já os tenha arredondado; não são exibidos como exatos, convertidos em zero ou ignorados. As regras remotas continuam intactas: a proteção implementada é no cliente e não impede gravação por outro cliente. Não houve operação remota ou teste SDK real desses extremos. Domínio/formatação nativos maiores continuam exatos e permitidos, porém não voltam a ser entrada/persistência válida; na Web agregados maiores são erros explícitos, sem resumo aproximado.

Não repetido o runner Flutter Web/DDC bloqueado anteriormente; probe Chrome/dart2js não equivale à homologação da aplicação completa. Não houve OOM, nova compilação Android, dependência, mudança de autenticação, regra/índice/Gradle ou criação de dado remoto. Nenhum commit/push/deploy/staging. JSON redundante assets/illustrations/google-services.json preservado e não rastreado.

Próxima tarefa: revisão do usuário desta correção M5.1; implementação de M5.2 exige nova autorização. Não há telas novas para homologar visualmente nesta etapa.

## Histórico M5.1 — Barreira de sessão entregue; precisão Web investigada

Planejamento M5 aprovado, incluindo as nove decisões expressamente confirmadas pelo usuário. Autorização restrita ao M5.1; M5.2 e seguintes não autorizados. Registros de planejamento abaixo são históricos e não substituem esta atualização.

### Arquivos criados/alterados

- lib/domain/repositories/transaction_repository.dart: expectedUserId opcional em fetchPage/create.
- lib/data/repositories/firestore_transaction_repository.dart: verificação da identidade esperada antes de acesso; UID real continua exclusivamente em FirebaseSession.
- test/data/transaction_repository_session_test.dart: 14 testes de sessão/concorrência/compatibilidade.
- test/domain/money_precision_test.dart: 7 testes de valores representáveis, formatação, sinal e round-trip.
- test/diagnostics/money_precision_probe.dart: probe puro nativo/JS com oito valores, referências textuais/BigInt.
- test/diagnostics/run_money_precision_browser.cjs: diagnóstico Chrome loopback, sem pacote adicional ou Firebase.
- docs/PLANO_M5.md e este arquivo: decisões aprovadas, execução e proposta de correção pendente. PLANO_M5.md já estava novo/não rastreado no início desta etapa.

### Segurança e testes

Barreira aplicada somente a leitura/criação; update/delete preservados. Verificações antes/durante/depois de operações permanecem, inclusive rejeição após mudança de sessão mesmo se o commit já puder ter ocorrido para o proprietário original. Sem promessa de cancelar gravação enviada. Cobertos UID correto/divergente, SDK em B quando chamada espera A, sessão ausente, chamadas sem argumento, troca/logout durante fetch/transaction get, troca antes do callback e depois de set antes da confirmação.

Testes de dados usam SDK com transporte local simulado e Auth controlado, sem backend ou operações remotas. Fixtures Pigeon dependem da versão instalada. Tentativa inicial dos novos testes identificou ausência do app padrão no mock; corrigida inicialização simulada. Avisos de classes SDK sealed no primeiro fake foram eliminados usando referências reais do SDK e transporte simulado, sem supressão de diagnósticos.

Validações executadas sequencialmente, sem build Android:

- dart format .: exit 0; 71 arquivos, nenhum alterado na execução final.
- flutter analyze: exit 1 por **20 informes de depreciação preexistentes**, 0 erros e 0 warnings; nenhum diagnóstico novo remanescente.
- flutter test --concurrency=1: **322 testes aprovados**, exit 0 (301 anteriores preservados + 14 de sessão + 7 monetários).
- Probe Dart nativo: oito casos exatos; compilação dart2js exit 0; Node e Chrome executados com sucesso e **dois casos inexatos reproduzidos**, sem OOM. Resultado local em build/m5-1-money-chrome.json; demais logs build/m5-1-* ignorados.
- flutter test --platform chrome test/domain/money_precision_test.dart --concurrency=1: **bloqueado antes de executar os sete testes**, com exceções no carregamento DDC e diagnóstico do Flutter `Iframe JS Execution Stalled`. Host Chrome respondia; execução interrompida, exit 1, sem repetição. Não atribuir a OOM sem evidência nem declarar esses sete testes aprovados no Flutter Web. O Flutter informa que concurrency é ignorado em testes Web. Log local build/m5-1-money-flutter-chrome.log preservado; a evidência browser disponível é o probe dart2js, não esta suíte.
- git diff --check: exit 0, sem erros de whitespace; avisos locais LF/CRLF não são falhas do check.

### Problema monetário encontrado e decisão necessária

No Chrome, Money.parseCents('90071992547409,93') e int.parse('9007199254740993') retornam 9007199254740992 e a formatação mostra R$ 90.071.992.547.409,92. Entrada terminada em ,95 vira ,96. Ambos são exatos na VM. Valores até 9007199254740991 e os inteiros representáveis isolados 9007199254740992/9007199254740994 passaram no probe. Precisão não é uniforme para todo inteiro acima de 2^53−1.

**Money.parseCents/formatCents não foram alterados.** Proposta mínima no PLANO_M5.md: comparar conversão de BigInt original para int e rejeitar entrada inexata, preservando assinaturas, gramática e valores nativos exatos. Requer aprovação específica por mudar aceitação Web. Rejeição do input não resolve sozinha dados nativos maiores já arredondados pelo SDK Web; eventual política comum de faixa exige decisão adicional. Não marcar precisão Web integralmente aprovada porque a suíte VM passou.

### Limitações e próxima tarefa

Nenhuma UI/controller/navegação M5.2 implementada, teste remoto executado ou configuração/regra/índice/Gradle/dependência alterada. assets/illustrations/google-services.json preservado não rastreado, sem staging/commit/push/deploy. Testes unitários de transporte não substituem integração real futura. Sem nova homologação visual nesta etapa sem telas.

Próximo passo: usuário revisar M5.1 e a correção monetária proposta, decidir a política de precisão entre plataformas e autorizar separadamente a continuação. Não iniciar FinancialController ou M5.2 automaticamente.

## M5 — Histórico do planejamento inicial

M4 oficialmente encerrado no commit `606af8b5cee6eeba349d9aab22af1f5d89be9551`. Autorizada exclusivamente a elaboração de [PLANO_M5.md](PLANO_M5.md); nenhum código M5 implementado. Ressalvas M4 permanecem aceitas e transferidas para M9, sem reabrir o marco.

Revisados documentos obrigatórios, protótipo e domínio financeiro, TransactionRepository/FirestoreTransactionRepository, SessionController/SessionGate e AppDependencies. Money existe em domain/services/money.dart; create retorna ID, não documento completo. Plano reutiliza esses componentes, ChangeNotifier/ListenableBuilder e três telas reais: Dashboard, Transações e Nova transação; Perfil M4 preservado.

Propostas: carregar todas as páginas de 100 em buffer, só então publicar resumo/lista, deduplicar por ID e bloquear cursor sem avanço; calcular exclusivamente com FinancialCalculator/FinancialSummary, Money e FinancialMonth. Competência altera apenas totais mensais em memória. Após create confirmado, uma recarga completa compartilhada atualiza Dashboard/lista; falha dessa recarga não repete a criação. Controller privado por sessão descarta resultados de gerações/UIDs antigos e não publica dados parciais como definitivos.

Decisões para revisão: barra temporária Início/Transações/Perfil sem orçamento/relatórios; omissão dos elementos M6–M8 da prancha e seletor de competência junto aos cards; barreira expectedUserId em fetchPage/create para corrida entre SDK e evento de autenticação; tratamento explícito de precisão monetária Web após testes de fronteira. Não há alteração de contrato, regra, índice ou Money executada agora.

Subetapas propostas, todas pendentes de autorização:

- [ ] M5.1 — Barreira de sessão, contratos e validações/precisão.
- [ ] M5.2 — FinancialController, carga completa e competência com fakes.
- [ ] M5.3 — Dashboard/lista/componentes e comparação visual isolada.
- [ ] M5.4 — Formulário de receita/despesa, envio único e recarga.
- [ ] M5.5 — MainShell e ligação protegida à aplicação normal.
- [ ] M5.6 — Integração local, evidências e relatório de revisão.

Fora do M5: edição/exclusão, busca/filtros avançados, orçamento e relatórios. Google Login e BolsoZen Bot registrados apenas como possíveis melhorias futuras fora do MVP, sem alterar M5–M9.

Arquivos desta tarefa: novo docs/PLANO_M5.md e atualização deste progresso. Revisão exclusivamente documental e git diff --check; não reexecutados format/analyze/test ou homologação pesada, pois código não mudou. Baseline histórico preservado: 301 testes Flutter e 20 informes do analyzer; não apresentados como nova execução. Nenhum acesso Firebase remoto, conta/transação criada, dependência instalada, Gradle/configuração/asset alterado, staging, commit, push ou deploy. JSON redundante assets/illustrations/google-services.json intacto e não rastreado.

Próxima tarefa: usuário revisar decisões e autorizar separadamente M5.1. Não iniciar implementação automaticamente.

## M4 — Encerrado e aprovado pelo usuário com ressalvas

O usuário revisou e aprovou o funcionamento e o visual da autenticação e autorizou expressamente encerrar o M4 com as limitações abaixo, sem repetir a homologação completa. Este aceite substitui o estado de revisão pendente dos registros históricos M4.1–M4.6, sem transformar testes não executados em aprovações.

Entregues login, cadastro real, recuperação de senha, perfil mínimo, conclusão de perfil ausente, sessão e navegação protegida. Aparência e funcionamento aprovados manualmente no Safari/iPhone. O usuário confirmou recebimento do e-mail/redefinição efetiva e persistência após reabertura ou reload. Android normal compilado, instalado e executado; telas públicas e reabertura sem sessão observadas.

Evidências preservadas: **301 testes Flutter aprovados**; **19 verificações locais Dart/FlutterFire aprovadas no M4.5** (12 anteriores e 7 novas), além de 6 testes Node da asserção UI. A bateria Chrome UI M4.6 permanece parcial: 3 verificações confirmadas, uma aprovação bruta invalidada e execução interrompida por OOM; não foi reexecutada. Analyzer: 0 erros/warnings, **20 informes de depreciação**, exit 1 pelos informes. Não houve nova execução de testes neste encerramento documental.

### Ressalvas aceitas e transferidas para M9

- Persistência autenticada após encerramento/reabertura real do processo Android ainda não homologada, incluindo perfil/logout/Voltar nesse roteiro nativo.
- Completar a bateria Chrome automatizada em origem fixa após avaliação de recursos e autorização de nova execução; preservados OOM e a revisão da asserção sem aprovar resultados inexistentes.
- Teclado virtual nativo e TalkBack sem homologação manual completa; manter validações de responsividade/texto ampliado na homologação final.
- Revisar os 20 informes do analyzer sem supressão ou migração de dependências não aprovada.

Essas limitações **não impedem o encerramento do M4**, por decisão explícita do usuário. Foram incluídas no planejamento oficial do M9 em [PLANO.md](PLANO.md). Relatório técnico e escopos exatos em [M4_HOMOLOGACAO.md](M4_HOMOLOGACAO.md). Não repetir automaticamente testes remotos ou criar contas para saná-las.

### Revisão pré-commit do M4

Branch main confirmada; revisão restrita às alterações de autenticação M4.1–M4.6, testes/runners locais, evidências sanitizadas e documentação de encerramento/transferência das ressalvas para M9. Os diffs de UserRepository/FirestoreUserRepository são as barreiras de sessão expectedUserId aprovadas no M4.3, não novas funcionalidades financeiras. Fixtures dos testes e imagens são sintéticas/identificadas, sem dados pessoais reais; senhas de integração são aleatórias somente em memória. Logs, dumps, perfis de navegador e builds permanecem locais/ignorados.

Executados git status e git diff --check. Seleção preparada por lista explícita de **83 arquivos do M4**: 58 fontes/documentos/JSON de evidências e 25 screenshots. Revisão de padrões de chaves privadas, credenciais administrativas, tokens OAuth/JWT/GitHub e import de Admin sem achados; endereços encontrados são fixtures de exemplo, sem dados pessoais reais identificados. Isso complementa a inspeção dos diffs e imagens, sem tratar scanner como prova absoluta. Lista/artefatos auxiliares da revisão ficam em build/, ignorados. Exigidos git diff --cached --check e conferência final antes do commit autorizado `feat: implementar autenticacao completa BolsoZen`. Excluído da seleção assets/illustrations/google-services.json, mantido intacto e não rastreado. Nenhum push, deploy, alteração Firebase ou instalação de dependências autorizado nesta tarefa. Hash e estado pós-commit serão apresentados no relatório da entrega, sem outro commit para gravar o próprio hash.

Próxima etapa: apresentar o escopo original do M5 (Dashboard e transações essenciais) para revisão. **M5 não implementado e ainda exige autorização específica.** Google Login e BolsoZen Bot continuam ideias futuras fora do MVP.

## M4.6 — Homologação parcial, relatório entregue para revisão

**M4.1–M4.5 aprovados pelo usuário; M4.6 autorizado exclusivamente. M4 ainda não concluído e M5 não autorizado.** Registros abaixo são históricos; suas restrições de autorização antigas não substituem a autorização atual.

Relatório completo, matriz de cobertura, screenshots e roteiro de pendências: [M4_HOMOLOGACAO.md](M4_HOMOLOGACAO.md).

### Aceite manual informado pelo usuário

Safari/iPhone: onboarding/identidade, login, cadastro, recuperação e fluxos Firebase aprovados. O usuário confirmou adicionalmente recebimento do e-mail e redefinição efetiva da senha pelo link, além de persistência após fechar/reabrir ou recarregar o navegador. Evidência manual do usuário, sem atribuí-la a execução automatizada do agente ou inferir validação Android/Chrome equivalente. Nenhuma credencial foi solicitada e nenhum novo e-mail real foi enviado pelo agente.

### Android normal — evidências obtidas

MSI 127.0.0.1:5556, Android 9/API 28/x64. Executado lib/main.dart, sem runner M3: uma compilação assembleDebug em 33,0 s, APK gerado. Instalação streaming ficou sem progresso em 20,65%; interrompida e substituída por `adb install --no-streaming -r -t` usando o mesmo APK, sem nova compilação ou limpeza dos dados; resultado Success.

Inicialização Firebase/composição/gate e boas-vindas sem sessão confirmados. Abertas telas reais de login, recuperação e cadastro; retorno da recuperação ao login e navegação ao cadastro confirmados. Campo recebeu foco/texto ilustrativo publico@example.test, sem senha ou submit. Capturas públicas em `docs/evidencias/m4-6/android/`.

Android reconheceu InputConnection e mInputShown=true; porém configuração show_ime_with_hard_keyboard=0 e capturas sem teclado virtual visível. Não declarar IME visual/TalkBack homologados. Viewport observado aproximadamente 720×1280 dp (1080×1920 pixels, densidade 240), distinto das larguras dos testes de widgets.

Processo realmente encerrado via force-stop e reaberto preservando dados: PID 7378 -> 7876, boas-vindas confirmada após aguardar inicialização. Isso valida **reabertura sem sessão**, não persistência autenticada. Captura transitória do launcher durante inicialização foi substituída pela evidência correta, e o helper passou a recusar telas fora do pacote. Na consulta final, o MSI já não estava disponível por ADB; não houve reconexão automática.

Não executados cadastro/login remotos, perfil autenticado, logout/Voltar pós-logout ou reinício com sessão válida no Android. Nenhuma nova conta remota foi autorizada; A/B/C não utilizadas. APK foi compilado antes das duas trocas equivalentes de imports abaixo; código final verificado por analyzer/testes, sem recompilar Android.

### Chrome local — interrupção e revisão das evidências

Entry point de teste monta UI/composição/repositórios FlutterFire reais, sem fakes, com guardas para demo-bolsozen/Auth 127.0.0.1:9099/Firestore 127.0.0.1:8080 antes de usar os clientes. Runner desabilitado por padrão; origem fixa http://localhost:7366. Não altera o app normal para apontar a emuladores nem importa suas opções de produção.

**Três verificações confirmadas:** área pública sem Perfil, bootstrap até UI pública e validação de cadastro vazio. O runner submeteu cadastro com dados exclusivamente locais, mas o resultado definitivo de conta/perfil não foi comprovado antes da interrupção. O Firestore Emulator encerrou por **memória nativa insuficiente do Java**, malloc de 858256 bytes; automação terminou em UI_EXPECTATION_TIMEOUT, exit 1. Emuladores/Chrome/Flutter próprios encerrados e nenhuma operação pesada repetida após OOM. Dados efêmeros não exportados; nenhuma mutação remota.

O log bruto relatou 4 aprovações. A inspeção das imagens invalidou a quarta: o nome digitado no formulário foi aceito como perfil por uma asserção fraca; a captura ainda mostrava cadastro em loading. Correção exige Perfil, Sair, nome/e-mail correspondentes e ausência de formulários públicos. **6 testes Node puros aprovados** para impedir o falso positivo; a bateria UI corrigida não foi reexecutada. Não contar nome no formulário ou timeout de rede como sucesso de persistência/segurança.

[Revisão autoritativa](evidencias/m4-6/web/validation-review.json) preserva o resultado bruto e a reclassificação. A imagem originalmente chamada web-perfil-local.png foi arquivada como cadastro-em-envio-inconclusivo.png, sem apresentá-la como perfil. Frame Web inicial ainda sem imagens decodificadas não é homologação visual ou prova de regressão de assets. Evidências anteriores aprovadas/Safari permanecem preservadas.

Reload mantendo sessão, logout/histórico Chrome, login correto/incorreto, recuperação, troca de UID, cadastro parcial e rede não foram concluídos nesta bateria UI. Os 19 checks SDK M4.5 e 77 testes de regras M3 permanecem **históricos, não repetidos nesta etapa**; após OOM não foi iniciado outro emulador.

### Qualidade e depreciações

| Comando | Resultado M4.6 |
|---|---|
| dart format . | 68 arquivos, execução final 0 alterações; exit 0 |
| flutter analyze | 0 erros/warnings; **20 informes deprecated_member_use**, exit 1 |
| flutter test --concurrency=1 | **301 aprovados, 0 falhas**, exit 0 |
| git diff --check | Aprovado, somente avisos locais LF/CRLF |
| node --test firebase/tests/m4_ui_assertions.test.cjs | **6 aprovados**, 0 falhas; testes puros da automação |

Na entrada havia 22 informes: 10 preexistentes no M3 e 12 líquidos do M4. Corrigidos dois imports seguros: main.dart usa widgets.dart; app_colors.dart usa dart:ui. Sem mudança de símbolo, tema ou dependência. Restam **8 preexistentes + 12 do M4**; lista detalhada no relatório. Os demais exigem migração Material/Cupertino/dependências fora do escopo; não foram ocultados.

301 testes preservados, sem novos testes Flutter M4.6. Incluem perfil parcial, concorrência, UID, neutralidade, erros, logout/navegação e responsividade 360/390/412 dp com texto 1/2 e teclado simulado. Não equivalem a execução Android privada, reinício autenticado, teclado nativo ou TalkBack.

### Arquivos, segurança e próxima tarefa

- Produção: somente imports de `lib/main.dart` e `lib/core/theme/app_colors.dart` alterados neste M4.6. Telas e identidade visual aprovadas preservadas.
- Criados `integration_test/m4_ui_local_app.dart`, `firebase/tests/run_m4_ui_local.cjs`, `m4_ui_assertions.cjs`, `m4_ui_assertions.test.cjs` e `test/visual/m4_android_public.py`, exclusivos de homologação.
- Documentação: `docs/M4_HOMOLOGACAO.md`, `docs/PLANO_M4.md`, este progresso e evidências sanitizadas em `docs/evidencias/m4-6/`.
- Memória Gradle/paralelismo, opções Firebase, projeto, regras/índices e dependências intactos. JAVA_TOOL_OPTIONS=-Xmx384m limitado ao processo local do emulador. Nenhum cache apagado, deploy, commit, staging ou push; JSON redundante continua intacto e não rastreado.
- Logs/dumps permanecem locais/ignorados: build/m4-6-*, firestore-debug.log, hs_err_pid19820.log, replay_pid19820.log. Não incluir dumps Java, senhas, tokens ou perfil Chrome no Git. A interrupção posterior do servidor não repetiu operações já executadas.

Próxima tarefa: usuário revisar relatório e escolher como completar as pendências. Retomada Chrome exige avaliação de memória e aprovação de tentativa com runner corrigido; sem repetição automática após OOM. Android autenticado pode ser validado manualmente pelo usuário, sem credenciais no chat, ou por roteiro remoto específico previamente aprovado (proposta no relatório, ainda não executada). Teclado virtual/acessibilidade nativos pendentes. M4 não encerrado automaticamente; não iniciar M5.

## M4.5 — Cadastro e conclusão de perfil implementados e validados localmente

M4.4 foi **revisado visualmente e aprovado pelo usuário**: onboarding, login e recuperação satisfatórios e fiéis ao protótipo. Esse aceite substitui a pendência de revisão visual do registro histórico M4.4, sem inventar validações Android que não foram executadas. M4.5 expressamente autorizado e entregue para revisão; **M4.6 não autorizado**. Perfil mínimo real permanece o destino privado aprovado até M5.

### Arquivos desta etapa

Criados:

- `lib/presentation/screens/auth/register_screen.dart`: TEL-03, nome/e-mail/senha/confirmação, validação do domínio, foco no primeiro inválido, senhas com visibilidade independente, loading e mensagens pt-BR.
- `lib/presentation/screens/auth/complete_profile_screen.dart`: somente para ausência confirmada, nome e e-mail real somente leitura, salvar perfil e sair, sem senha ou novo cadastro.
- `test/presentation/register_screens_test.dart`: 32 novos testes; 20 funcionais e 12 responsivos.
- `docs/M4_5_VALIDACAO_VISUAL.md` e `docs/evidencias/m4-5/`: seis screenshots reais e manifesto de captura local.

Alterados:

- `lib/app/auth_experience.dart`: callbacks reais de Entrar/Criar conta e uma única rota pública que alterna Login/Cadastro sem empilhá-los; ausência confirmada usa Completar perfil.
- `lib/presentation/screens/welcome/welcome_screen.dart`: somente callback de Criar conta; layout, logo, ilustrações/carrossel preservados.
- `lib/presentation/screens/auth/login_screen.dart`: callback do botão Criar conta, sem redesenhar a tela.
- `lib/presentation/widgets/password_field.dart`: rótulo, autofill de senha nova e ação de teclado configuráveis; padrões do login preservados.
- `lib/presentation/controllers/session_controller.dart`: expõe canSignOut e hasPendingProfileCreation para os estados reais da UI; reutiliza coordenação de cadastro/perfil já testada, sem duplicar o adaptador Firebase.
- `lib/presentation/screens/auth/session_status_screen.dart`: saída durante carregamento quando permitida, mensagem de cadastro parcial e ação Tentar salvar perfil novamente, sem segundo cadastro.
- `test/presentation/auth_screens_test.dart` e `test/widget_test.dart`: expectativas provisórias de indisponibilidade substituídas por navegação/formulário agora autorizados; cobertura anterior preservada.
- `integration_test/m4_auth_emulator.dart`: sete verificações adicionais usando SessionController e repositórios reais, com as mesmas barreiras de projeto demo/endpoints locais.
- `test/visual/m4_auth_preview.dart` e `test/visual/capture_m4_auth.cjs`: cenário local de cadastro/ausência de perfil e modo --m4-5 de seis capturas em uma página, sem recargas sucessivas.
- `docs/PLANO_M4.md` e este progresso: aprovação M4.4, entrega, resultados e limites M4.5.

Removido o componente provisório `lib/presentation/widgets/registration_availability.dart`, sem uso após as duas entradas reais de cadastro. Alterações preexistentes M4.1–M4.4 foram preservadas. Nesta etapa não foram alterados domínio, adaptadores/repositórios de dados, SessionGate, tema global, main/bootstrap, FirebaseOptions, regras, índices, Gradle ou dependências.

### Fluxo e segurança

Todos os campos são validados antes de signUp. Senha/confirmação chegam intactas, sem trim, corte, normalização ou log; somente nome e e-mail seguem as regras existentes. Cadastro bloqueia toque/submit duplicados e mantém campos em falhas do provedor, incluindo e-mail já utilizado e rede.

SessionController continua sendo a fonte da transição, sem push privado no retorno isolado do SDK. Aguarda identidade autenticada correspondente, ensureProfile idempotente e leitura confirmada antes do Perfil mínimo. Nome é vinculado ao UID esperado; perfil existente não é substituído. createdAt permanece preservado. Conta criada com falha no perfil deixa sessão explícita e permite retry somente da gravação/leitura do perfil, sem recadastrar nem rollback da conta.

Perfil ausente após entrada/restauração solicita somente nome; não deriva nome do e-mail. E-mail vem da sessão, somente leitura. Perfil inválido ou permission-denied mantém tela de erro recuperável, sem converter falha em ausência. Logout pode ser solicitado durante conclusão/gravação de perfil; respostas antigas são descartadas após saída/troca de UID/dispose. Isso não promete cancelar uma gravação já enviada ao SDK; eventual confirmação tardia não reabre a árvore privada.

Login/Cadastro compartilham uma rota sobre as boas-vindas: alternar substitui e descarta o formulário anterior, sem acumular pilhas ou senhas. Voltar retorna às boas-vindas. SessionGate destrói a árvore pública no sucesso confirmado e a privada no logout/troca de UID. Recuperação e Perfil mínimo aprovados permanecem disponíveis; Dashboard e M4.6 não implementados.

### Qualidade — sequência final

| Comando | Resultado |
|---|---|
| `dart format .` | 67 arquivos; execução final 0 alterações; exit 0 |
| `flutter analyze` | **0 erros, 0 warnings, 22 informes deprecated_member_use**; exit 1 pelos informes |
| `flutter test --concurrency=1` | **301 aprovados, 0 falhas**: 269 anteriores + 32 novos; exit 0 |
| `git diff --check` | Aprovado; avisos locais LF/CRLF sem erros de whitespace |

Os informes Material/Cupertino do SDK não foram ocultados nem substituídos por pacotes novos. Eram 20 no M4.4; três imports novos (duas telas e teste) e remoção do componente antigo resultam em 22. Lint novo de bloco if e uso incorreto de getter somente no teste foram corrigidos antes da sequência final.

A primeira suíte teve 295 aprovações e seis falhas em testes antigos de layout que esperavam AlertDialog de Criar conta. O comportamento foi substituído pelo cadastro real autorizado; testes passaram a verificar callback e preservaram as seis combinações de largura/texto. Após ajuste e alterações finais no runner local, a sequência foi repetida e terminou com 301 aprovados. A tentativa inicial de analyzer no sandbox não produziu saída e foi interrompida; as validações finais utilizaram acesso ao SDK fora do sandbox, sem build simultâneo.

Cobertura nova: nome vazio/inválido, e-mail inválido, senha curta, confirmação diferente, e-mail utilizado, rede, valores preservados, autofill/visibilidade independente, duplicidade por teclado/toque, auth antes/depois do retorno SDK, espera do perfil, cadastro parcial com retry sem conta duplicada, idempotência e leitura após gravação, sessão sem perfil em montagem nova, erro/permissão sem sobrescrita, saída durante escrita, UID/respostas antigas e alternância de navegação. Os 12 novos casos responsivos cobrem Cadastro/Completar perfil em 360/390/412 dp, texto 1/2, altura 640 e teclado simulado 300 dp.

### Integração FlutterFire exclusivamente local

Executado o runner Dart real no Chrome, com **19 verificações aprovadas**, 12 anteriores e 7 novas M4.5. Projeto **demo-bolsozen**; Auth **127.0.0.1:9099** e Firestore **127.0.0.1:8080**, ambos conectados antes de AppDependencies ou qualquer operação. O runner não importa main.dart/firebase_options.dart e exige as flags de habilitação/projeto/endpoints; supervisor permanece desabilitado por padrão. Não utiliza Firebase Admin ou bypass de regras para operações do aplicativo.

```powershell
$env:JAVA_TOOL_OPTIONS='-Xmx384m'
firebase emulators:exec --project demo-bolsozen --only auth,firestore "node firebase/tests/run_m4_auth_emulator.cjs --execute-local"
```

JAVA_TOOL_OPTIONS foi definido apenas no processo dessa execução, para limitar o emulador Java; Gradle e ambiente persistente não foram alterados. Somente uma compilação por vez; Chrome visual anterior já encerrado.

SDKs reais confirmaram cadastro/e-mail normalizado/stream, perfil lido do servidor, idempotência, e-mail duplicado tipado, login com espaços na senha preservados, credencial inválida neutra, reset de e-mail inexistente no emulador e logout. Os sete novos checks confirmaram cadastro pelo controller com UID/perfil correspondente, preservação de nome e createdAt ao garantir perfil existente com outro nome, limpeza no logout, conta autenticada sem perfil detectada como ausente, validação de nome na conclusão, perfil salvo e relido sem segunda conta e logout final.

Resultado success=true, checksPassed=19, runnerExited code=0, emulators:exec exit=0. Instâncias descartadas/sessão encerrada e Auth/Firestore locais desligados normalmente; dados efêmeros não foram exportados. Nenhuma conta ou documento de bolsozen-f2f35 foi criado, consultado ou modificado pelo runner. A/B/C e perfis retidos permanecem intocados. Não foi repetida a bateria de 77 regras, pois regras/índices não mudaram.

### Evidências visuais, limites e próxima tarefa

[Validação visual M4.5](M4_5_VALIDACAO_VISUAL.md): seis screenshots reais Flutter/Chrome, cadastro TEL-03 e Completar perfil em 360/390/412 dp, inspecionadas e arquivadas com manifesto em `docs/evidencias/m4-5/`. Preview exclusivo de teste, fakes e banner TESTE VISUAL; essas imagens não comprovam backend. Captura concluída sem runtimeErrors ou OOM, uma compilação/página, Chrome temporário encerrado. Termos/Privacidade omitidos conforme requisitos por ausência de textos reais; campos vazios, cinza e botão sólido seguem os tokens/componentes M4.4. Não declarar pixel-perfect ou aprovação do M4.5 pelo usuário.

Logs locais ignorados: `build/m4-5-analyze.log`, `build/m4-5-tests.log`, `build/m4-5-emulator.log`, `build/m4-5-visual-run.log`. Nenhum cache foi apagado. Não houve build Android, operação Firebase remota, e-mail real, alteração de contas existentes, deploy, staging, commit ou push. JSON redundante permanece intacto e não rastreado.

Pendências: revisão funcional/visual do M4.5 pelo usuário; Android/teclado nativo/TalkBack, reinício real do processo e persistência do navegador, confirmação manual de recuperação e eventual roteiro remoto pertencem à homologação M4.6, que **exige nova autorização**. Perfil ausente foi simulado em nova montagem e exercitado com SDK real no emulador, sem comprovar reinício Android. Falhas parciais/rede/corridas são determinísticas nos fakes; não se afirma que houve interrupção real de rede durante commit. M4 não está encerrado e M4.6 não foi iniciado.

## M4.4 — Login, recuperação e perfil mínimo implementados; revisão visual pendente

M4.3 revisado e aprovado pelo usuário. M4.4 autorizado exclusivamente e entregue para revisão. M4.5 e posteriores não autorizados. Os registros abaixo das etapas anteriores são históricos; a ativação do gate que estava adiada no M4.3 foi realizada nesta etapa.

### Entrega e arquivos

- Criados `lib/app/auth_experience.dart`, `lib/presentation/screens/auth/login_screen.dart`, `password_reset_screen.dart`, `session_status_screen.dart` e `lib/presentation/screens/profile/profile_screen.dart`.
- Criados componentes em `lib/presentation/widgets/`: `auth_form_layout.dart`, `password_field.dart`, `submit_button.dart` e `registration_availability.dart`.
- Alterados `lib/main.dart`, `lib/app/app_dependencies.dart`, `lib/app/session_gate.dart`, `lib/presentation/controllers/session_controller.dart`, `lib/core/theme/app_theme.dart` e `lib/presentation/screens/welcome/welcome_screen.dart`.
- Criados `test/presentation/auth_screens_test.dart`, `test/visual/m4_auth_preview.dart` e `test/visual/capture_m4_auth.cjs`; atualizados `test/presentation/session_controller_test.dart`, `session_fakes.dart` e `test/widget_test.dart`.
- Documentação: `docs/PLANO_M4.md`, este progresso, `docs/M4_4_VALIDACAO_VISUAL.md` e dez capturas com manifesto em `docs/evidencias/m4-4/`.

Login real com validação, visibilidade de senha, loading, bloqueio de envios duplicados e mensagens neutras. Recuperação usa o contrato existente, sem consultar existência de conta; confirmação neutra, falha de rede explícita e proteção contra reentrada. Perfil mostra nome real do Firestore e e-mail da sessão, inicial do nome e logout com tratamento de falhas. Nenhuma senha é persistida pelo aplicativo ou registrada em logs.

`FirebaseStartup` continua responsável pela inicialização única; sua composição monta `AppDependencies` e o `SessionGate` com destinos reais. A área pública mantém o formulário durante autenticação e erros; após identidade confirmada, o gate aguarda perfil válido antes de abrir a área privada. Logout/troca de UID destrói a árvore anterior. Falha de perfil tem retry seguro; perfil ausente informa a situação e permite sair, sem criação automática ou antecipação de Completar perfil. Criar conta permanece uma mensagem de indisponibilidade, sem rota falsa. Logo, imagens, carrossel e composição das boas-vindas preservados.

O controller coordena também a recuperação de senha, descarta respostas antigas após mudança de identidade/dispose e bloqueia operações concorrentes. O tema reaproveita os tokens existentes; formulários usam densidade padrão e botões de 48 dp também no desktop, sem alterar a densidade das boas-vindas. Não foram adicionadas dependências ou alterados Firebase, regras, índices, Gradle ou repositórios financeiros.

### Validações executadas sequencialmente

| Comando | Resultado final |
|---|---|
| `dart format .` | 65 arquivos; última execução formatou 3; exit 0 |
| `flutter analyze` | 0 erros, 0 warnings, **20 informes deprecated_member_use**; exit 1 pelos informes |
| `flutter test --concurrency=1` | **269 aprovados**, 0 falhas; exit 0 |
| `git diff --check` | Aprovado; avisos locais LF/CRLF, sem erros de whitespace |

São 228 testes anteriores e 41 novos: 36 de widgets (18 funcionais e 18 responsivos) e 5 do controller. A expectativa antiga de indisponibilidade de Entrar foi atualizada para validar seu callback real. Cobertura inclui formulários vazios/inválidos, senha visível, mensagens neutras, rede, duplicidade por toque/teclado, recuperação, perfil correspondente, erro/ausência de perfil, retry, logout falho/confirmado, mudança de UID e proteção de navegação. Responsividade automatizada: 360/390/412 dp, altura 640, escalas de texto 1 e 2; login/recuperação incluem foco e inset de teclado de 300 dp.

Os 20 informes são de imports oficiais Material marcados como deprecated pelo SDK instalado: 10 preexistentes e 10 nos novos arquivos. Não foram ocultados, nem adicionada a dependência material_ui. Logs locais ignorados: `build/m4-4-analyze.log` e `build/m4-4-tests.log`.

### Evidências visuais e limitação de memória

Comparação documentada em [Validação visual M4.4](M4_4_VALIDACAO_VISUAL.md). Dez screenshots reais do renderer Flutter/Chrome foram capturadas e inspecionadas: login, recuperação e perfil nas três larguras, mais confirmação neutra em 390 dp. Estão em `docs/evidencias/m4-4/`, com dimensões e hashes no manifesto. O preview é exclusivo de teste, usa fakes locais identificados por TESTE VISUAL e não inicializa Firebase; nome/e-mail nas imagens são fixtures, não dados reais.

Corrigidos sublinhado dos links, altura dos botões no Chrome, tratamento tipográfico do rodapé e preservação do formulário durante login. Campos seguem o fundo cinza do Design System; recuperação/perfil seguem as telas complementares documentadas. Não se declara fidelidade pixel-perfect ou aprovação visual pelo usuário.

A primeira captura teve erro de métricas ao simular viewport mobile no CDP; a ferramenta foi corrigida para viewport CSS. Na execução final, **após as dez capturas**, o processo Dart das ferramentas Flutter encerrou com `Out of memory` durante capturas adicionais. Log preservado em `build/m4-4-visual-final-run.log`; a automação terminou com timeout CDP. Chrome temporário encerrado; nenhuma compilação foi repetida após o OOM. O script foi depois limitado a dez capturas por padrão, com manifesto incremental e modo `--extended` opcional; somente sua sintaxe Node foi verificada após essa alteração, sem nova execução visual.

As capturas adicionais com texto ampliado/teclado e estados de perfil ausente/erro não foram concluídas no Chrome. Esses comportamentos têm cobertura automatizada, mas isso não substitui homologação visual. Android, teclado nativo, TalkBack, persistência real de sessão entre reinícios e envio efetivo de e-mail não foram validados nesta etapa. Não houve build Android, teste remoto, conta criada, uso das contas A/B/C, alteração de dados, deploy, staging, commit ou push.

### Próxima tarefa e pendências

- Usuário revisar implementação e capturas; homologação visual integral permanece pendente.
- Validar visualmente Android e teclado/acessibilidade nativos em execução futura autorizada; avaliar recursos antes de repetir compilação após OOM.
- Se necessário, completar capturas ampliadas/teclado em sessão visual com menor consumo, sem repetir automaticamente a compilação.
- M4.5 (cadastro e Completar perfil) depende de nova autorização. Não iniciar automaticamente.

## M4.3 — SessionController e SessionGate implementados e testados

M4.2 revisado e aprovado pelo usuário. Implementação exclusiva do M4.3 autorizada e entregue para revisão. M4.4 e posteriores NÃO autorizados; destino privado futuro continua sendo Perfil mínimo real durante M4, Dashboard somente no M5.

Arquivos criados nesta etapa:

- `lib/presentation/controllers/session_controller.dart`: ChangeNotifier com sessão derivada do stream AuthRepository, carregamento/validação do perfil e coordenação de autenticação, criação idempotente e logout. Sem credenciais armazenadas em campos, objetos Firebase ou logs.
- `lib/app/session_gate.dart`: ListenableBuilder e Navigator interno com identidade da árvore por versão da sessão e área. Destinos injetados obrigatórios, sem telas técnicas/provisórias embutidas em produção. Gate cria/inicia uma vez e descarta o controller de sua propriedade.
- `test/presentation/session_controller_test.dart`: 30 testes com fakes controlados.
- `test/presentation/session_gate_test.dart`: 11 testes de widgets e navegação, incluindo bootstrap.
- `test/presentation/session_fakes.dart`: fakes exclusivamente de teste, com Futures/streams controlados e destinos técnicos somente nos testes.

Arquivos modificados nesta etapa:

- `lib/app/app_dependencies.dart`: factory createSessionController retorna controller ainda não iniciado, com os contratos já compostos.
- `lib/app/firebase_startup.dart`: childBuilder opcional, mutuamente exclusivo com child; permite construir gate/composição somente após inicialização confirmada, preservando a API anterior.
- `lib/domain/repositories/user_repository.dart` e `lib/data/repositories/firestore_user_repository.dart`: argumento opcional expectedUserId em fetch/ensureProfile, usado apenas para conferir sessão antes do acesso. O UID do caminho continua sendo obtido de FirebaseSession, nunca do argumento. Mantidas transação, idempotência, timestamps e verificações M3 após operações assíncronas. A barreira evita aplicar o nome do cadastro A ao usuário B se o SDK trocar a sessão antes de seu evento chegar ao controller.
- `test/data/repository_session_test.dart`: novo teste comprova rejeição de UID esperado divergente antes de qualquer leitura/escrita Firestore.
- `test/data/app_dependencies_test.dart`: cobertura da factory sem assinatura/consulta antecipada.
- `docs/PROGRESSO.md` e `docs/PLANO_M4.md`: decisões, resultados e limites desta etapa.

Não alterados: main.dart, welcome_screen.dart, logo/carrossel, telas finais, regras/índices, configuração Firebase, Gradle, dependências e repositórios financeiros. Alterações não registradas das etapas anteriores foram preservadas. Nenhum staging ou commit; JSON redundante permanece intacto e não rastreado.

### Estados e concorrência

SessionPhase: checking (primeiro evento pendente), public, authenticating, loadingProfile, missingProfile, profileError, ready e sessionError (falha do stream). Logout é operação ocupada sobre o estado confirmado, sem apagar perfil antecipadamente ou fingir saída quando o provedor falha. isReady requer UID correspondente e perfil confirmado. Perfil com UID/e-mail incompatível é invalidData; ausência real é missingProfile, não erro ou perfil fabricado.

Versões de identidade e de requisição invalidam resultados após logout, troca de UID, ciclo A -> B -> A e dispose. Mudança de identidade limpa imediatamente o perfil anterior. Assinaturas são canceladas ao descartar o controller; start e retry de sessão não multiplicam listeners. Erros são AuthFailure/DataFailure seguros; não há FirebaseException exposta à apresentação.

Bloqueio de operações evita login/cadastro/logout/retry duplicados. Password e confirmação são apenas parâmetros locais, nunca campos. Não há Future.timeout ou inferência de cancelamento de cadastro. Retorno de login/cadastro não libera acesso sem evento de autenticação e perfil correspondente. Se o evento chegar antes do retorno do cadastro, o nome ainda não é usado; após confirmação de UID, ensureProfile e fetch são coordenados. Se outra conta entrar, o nome antigo não é utilizado nessa nova conta.

retryProfile não repete login/cadastro. Quando uma criação explicitamente solicitada falha parcialmente, o controller mantém somente nome/UID para retry idempotente; login normal não cria ou sobrescreve perfil. completeProfile só é aceito em estado de perfil realmente ausente, com nome válido e expectedUserId vinculado. Perfil malformado/permission-denied permanece erro recuperável, sem sobrescrita automática.

### Navegação e integração mínima

O gate só chama readyBuilder com perfil válido. checking/authenticating/loadingProfile usam loadingBuilder; público, ausência e erro têm builders separados. Cada identidade/área recebe Navigator próprio; logout confirmado, troca de UID ou erro de sessão remove toda a árvore privada, inclusive rotas empilhadas. O contexto fornecido aos builders pertence ao Navigator interno. NavigatorPopHandler encaminha Voltar à pilha vigente; não mantém rotas da conta anterior.

Integração preparada e comprovada com fakes: FirebaseStartup.childBuilder só monta o gate após o Future de inicialização completar, e AppDependencies.createSessionController não inicia consultas antes de o gate assumir seu ciclo de vida. Não ocorre segunda inicialização Firebase.

**Ativação em produção deliberadamente adiada:** main.dart continua mostrando a boas-vindas existente. Montar SessionGate ali agora exigiria telas privadas, de perfil ausente e de erro ainda não fornecidas no escopo visual autorizado. Nenhum builder técnico de teste foi instalado no app real. Na etapa posterior autorizada, conectar o gate com destinos reais e manter rotas privadas dentro de seu Navigator; não empilhá-las no Navigator externo/rootNavigator. A proteção foi validada nos testes, não declarada como fluxo de login já acessível em produção.

### Validação local e resultados

| Comando, na sequência exigida | Resultado final |
|---|---|
| `dart format .` | 54 arquivos; primeira execução formatou 10, final 0 alterações; exit 0 |
| `flutter analyze` | Sem erros/warnings; 10 informes preexistentes deprecated_member_use; exit 1 pelos informes |
| `flutter test --concurrency=1` | **228 aprovados**, 0 falhas: 186 anteriores + 42 novos; exit 0 |
| `git diff --check` | Aprovado; avisos locais LF/CRLF, sem erro de whitespace |

Cobertura nova: primeiro evento atrasado, sessão pública, perfil válido/ausente/UID ou e-mail incompatível/malformado, rede/permission-denied/sessionChanged, retry sem autenticar de novo, logout confirmado/pendente/falho, troca de conta e respostas antigas, dispose e cancelamento, evento repetido, evento auth antes/depois de retorno SDK, criação parcial com retry, nome vinculado ao UID esperado e não sobrescrita de perfil inválido. Widgets comprovam espera do perfil, erro sem conteúdo privado, destruição efetiva da árvore/pilha, Voltar após logout, troca A/B, preservação da pilha válida em falha de logout, bootstrap e ownership/dispose.

A primeira suíte ficou parada no teste de navegação que cancela e refaz a assinatura. Diagnóstico isolado confirmou necessidade de tester.runAsync para essa operação fora do relógio simulado do widget; checkpoints temporários foram removidos. Somente processos identificados dessas execuções locais interrompidas foram encerrados; logs preservados. Após correção exclusivamente no teste, o teste isolado passou e a sequência completa foi repetida, encerrando com 228 aprovados. Lints novos de construtor/braces e import não usado foram corrigidos antes do resultado final; não há novos informes.

Evidências locais ignoradas: `build/m4-3-analyze.log`, `build/m4-3-tests.log`, `build/m4-3-tests-interrupted.log` e logs m4-3-gate-* de diagnóstico. Nenhuma operação ou teste remoto, emulador Firebase, build Android/Web, instalação, exclusão, deploy, commit ou push nesta etapa. A/B/C e perfis A/C permanecem preservados.

Limitações: fakes validam coordenação/navegação, não conectividade, reinício do processo, expiração real de token ou histórico real do navegador. As garantias de acesso ao servidor continuam nas regras M3; o gate não substitui Security Rules. A assinatura de expectedUserId foi testada localmente antes de acessar Firestore; sua integração com SDK real deverá entrar na homologação local futura, sem nova operação remota automática. Não houve alteração visual em produção para comparar por screenshot.

Próxima tarefa: usuário revisar M4.3 e autorizar separadamente M4.4. Somente então implementar telas reais de login/recuperação/perfil e ligar os destinos prontos; cadastro/completar perfil visual seguem M4.5. Não avançar automaticamente nem conectar a UI a fluxos incompletos.

## M4.2 — Adaptador Firebase Authentication implementado e validado localmente

M4.1 revisado e aprovado pelo usuário. M4.2 expressamente autorizado e entregue; aguarda revisão. M4.3 e posteriores NÃO autorizados. Perfil mínimo real continua aprovado como destino futuro durante M4, sem qualquer ligação às telas nesta etapa.

Arquivos criados nesta etapa:

- `lib/data/repositories/firebase_auth_repository.dart`: implementação integral de AuthRepository, FirebaseAuth injetado, conversão para AuthUser e configuração da persistência Web.
- `lib/data/firebase/auth_error_mapper.dart`: tradução sanitizada por AuthOperation para AuthFailure, sem expor FirebaseException, UserCredential ou mensagens brutas à apresentação.
- `lib/app/app_dependencies.dart`: composição assíncrona dos contratos de autenticação, perfil, transações e orçamento, com FirebaseSession compartilhado entre os repositórios Firestore. Reutiliza as instâncias recebidas, rejeita apps/projetos incompatíveis, não chama initializeApp e não acessa documentos durante a composição.
- `test/data/auth_error_mapper_test.dart`, `test/data/firebase_auth_repository_test.dart`, `test/data/app_dependencies_test.dart`: 59 novos testes, usando fakes.
- `test/data/auth_test_fakes.dart`: fakes mínimos do SDK, restritos aos testes.
- `integration_test/m4_auth_emulator.dart`: entrypoint Dart de integração no Chrome, desabilitado por padrão, somente demo-bolsozen e hosts locais explícitos; não importa main.dart nem firebase_options.dart.
- `firebase/tests/run_m4_auth_emulator.cjs`: supervisor Node sem dependências adicionais, bloqueado por padrão, exige variáveis de ambiente dos dois emuladores e projeto demo antes de iniciar Flutter. Captura somente eventos sanitizados, encerra o Chrome temporário após resultado e deixa emulators:exec desligar os serviços.

Documentos atualizados: `docs/PROGRESSO.md` e `docs/PLANO_M4.md`. Nenhuma alteração em main.dart, FirebaseStartup, BolsoZenApp, welcome_screen.dart, navegação, modelos/validadores do M4.1, repositórios financeiros, dependências, firebase_options.dart, Firebase remoto, regras, índices, Gradle ou JSON redundante. AppDependencies ainda não foi conectado à aplicação: essa ligação e SessionController/SessionGate pertencem ao M4.3.

### Contrato e comportamento

- authStateChanges emite o estado inicial do SDK, inclusive null; usuário válido vira somente AuthUser. E-mail ausente/inválido, UID vazio ou credencial sem usuário produzem AuthFailure.unknown; não simulam sessão pública/sucesso. Erros de stream são tipados e eventos posteriores continuam sendo recebidos; cancelamento é propagado à origem.
- signIn normaliza somente o e-mail e reaplica validação de login; signUp reaplica a regra de cadastro. Senhas chegam intactas ao SDK, inclusive espaços, acentos e Unicode, sem armazenamento próprio ou logs. Sem retentativas automáticas de chamadas de autenticação.
- Login neutraliza invalid-credential, invalid-login-credentials, wrong-password e user-not-found. Cadastro existente, senha fraca, formato inválido, limitação de requisições, rede, serviço/configuração, conta desabilitada e token inválido têm tradução apropriada. Erro desconhecido permanece falha segura.
- sendPasswordReset configura pt-BR antes do envio, sem consultar existência de e-mail. user-not-found e user-disabled durante o envio têm a mesma conclusão pública neutra do sucesso; esta é uma proteção contra enumeração por condição de conta. Falha ao configurar idioma, falhas operacionais/rede/limite e códigos desconhecidos continuam sendo erros; não são tratados como sucesso. O contrato void usa a confirmação neutra já definida em AuthFailure para a futura UI.
- signOut aguarda o provedor e propaga falha tipada; não anuncia logout por conta própria.

### Persistência verificada nas APIs instaladas

firebase_auth 7.1.0 expõe setPersistence(Persistence.LOCAL), e firebase_auth_web 6.4.0 o delega ao SDK Web. FirebaseAuthRepository.initialize configura LOCAL somente em Web, uma vez por instância, e aguarda configuração antes das operações/stream. Chamadas concorrentes compartilham o Future. Falha bloqueia o uso, sem fallback silencioso ou retry automático; uma tentativa explícita futura de recomposição pode criar outra instância do repositório. Android não chama setPersistence e utiliza persistência nativa. Nenhuma flag isLoggedIn, preferências ou storage próprio de tokens.

### Testes e resultados reais

Comandos obrigatórios executados sequencialmente antes da integração:

| Verificação | Resultado |
|---|---|
| `dart format .` | 49 arquivos; primeira execução formatou 8 novos, última 0 alterações; exit 0 |
| `flutter analyze` | 0 erros, 0 warnings, 10 informes preexistentes deprecated_member_use; exit 1 pelos informes |
| `flutter test --concurrency=1` | 186 testes aprovados, 0 falhas: 127 anteriores + 59 novos; exit 0 |
| `git diff --check` | Aprovado; aviso local LF/CRLF em pubspec.lock sem diff de conteúdo/dependências |

A análise inicial identificou await em useFirestoreEmulator (API síncrona na versão instalada) e um lint de construtor; ambos corrigidos antes dos testes. O teste existente de FirebaseStartup imprime StateError intencional de falha/retry; não representa acesso ou falha remota.

Cobertura dos testes novos: normalização de e-mail, preservação de senha curta no login e espaços/Unicode no cadastro, validação antes da chamada SDK, credencial/usuário/e-mail nulos ou inválidos, mensagens por operação sem detalhes sensíveis, stream inicial/erros/eventos posteriores/cancelamento, confirmação neutra de recuperação, idioma pt-BR, falha de idioma, rede em cada operação sem retry, logout com espera/sucesso/falha, persistência LOCAL Web única/aguardada/erro sem fallback, Android sem chamada exclusiva Web e composição sem leituras/autenticação ou inicialização duplicada.

### Integração exclusivamente nos emuladores locais

Portas 9099/8080 estavam livres antes da execução; os emuladores foram iniciados pelo comando abaixo, sem reutilizar um ambiente existente. Firebase CLI confirmou demo-bolsozen e bloqueio de serviços não emulados desse projeto.

```powershell
firebase emulators:exec --project demo-bolsozen --only auth,firestore "node firebase/tests/run_m4_auth_emulator.cjs --execute-local"
```

Resultado: **12 verificações aprovadas**, runner Dart/Flutter real no Chrome, exit 0. Não é uma repetição da bateria JavaScript M3: Node apenas supervisiona o processo Flutter. Antes de criar conta local, runner configurou FirebaseAuth.useAuthEmulator(127.0.0.1,9099) e Firestore.useFirestoreEmulator(127.0.0.1,8080), confirmou demo-bolsozen e registrou os endpoints. Usa FirebaseOptions fictícias do projeto demo, sem opções de bolsozen-f2f35 e sem fallback para o remoto.

Verificados: configuração local, sessão inicial nula, cadastro com normalização, evento autenticado, perfil real pelo FirestoreUserRepository e releitura do servidor, idempotência/auditoria, cadastro duplicado com erro tipado, logout com evento nulo, login preservando espaços e mesmo UID, senha modificada negada com mensagem neutra, recuperação de endereço inexistente com conclusão neutra e logout final. Recuperação existente/entrega de e-mail não foi exercitada: endereço ausente evita gerar códigos/links de redefinição nos logs. Recebimento de e-mail e persistência entre reinícios continuam na homologação futura.

Conta e perfil pertenciam somente ao emulador efêmero; sessão encerrada e instâncias locais descartadas. Emulators:exec encerrou Auth/Firestore e Chrome temporário foi encerrado com saída 0. Não houve exclusão ou alteração de contas/perfis existentes remotos nem contato de dados com bolsozen-f2f35. Não foram repetidos os testes remotos M3 ou a bateria de 77 regras locais; regras permaneceram inalteradas, sendo utilizadas no teste de perfil local.

Evidências locais ignoradas: `build/m4-2-analyze.log`, `build/m4-2-tests.log`, `build/m4-2-emulator.log`; supervisor Node passou node --check e, sem flag, informou desabilitado sem iniciar Flutter/rede.

### Limitações e pendências para M4.3

Nenhum build Android pesado foi realizado. Persistência nativa foi respeitada por configuração/testes com fake; não há nova evidência de reinício de sessão Android nesta etapa. A integração Chrome comprova SDK real no emulador, não autenticação no projeto remoto, entrega de e-mail ou persistência após fechar/reabrir navegador. Fakes não comprovam backend; emulador não reproduz todas as políticas/limites de produção. Não há UI de confirmação ou navegação implementada.

Próxima tarefa, somente após aprovação: M4.3 — SessionController, SessionGate, tratamento de perfil ausente/parcial e ligação pós-bootstrap da composição já preparada. Revisar estratégia de retry explícito de configuração e descarte de respostas por UID no controller. Sem novas dependências, serviços, deploy, staging, commit ou push. Contas A/B/C e perfis A/C preservados; JSON redundante não incluído no Git.

## M4.1 — Contratos, modelos e validações implementados

O usuário aprovou o plano de M4 e explicitamente o Perfil mínimo real como destino privado temporário após login, substituído pelo Dashboard no M5. Autorização de implementação limitada a M4.1; M4.2 e posteriores NÃO autorizados. Decisões registradas também em PLANO_M4.md, sem alteração de navegação ou tela.

Arquivos criados:

- `lib/domain/models/auth_user.dart`: identidade imutável com UID obrigatório e e-mail válido/normalizado; sem dados de perfil ou credenciais.
- `lib/domain/models/auth_failure.dart`: AuthFailure/15 tipos de falha, códigos estáveis de domínio, mensagens pt-BR e confirmação neutra de recuperação. Não aceita mensagens arbitrárias do provedor ou valores digitados.
- `lib/domain/repositories/auth_repository.dart`: contrato abstrato com stream inicial/de mudanças, signIn, signUp, sendPasswordReset e signOut. Sem SDK, implementações Firebase ou persistência de credenciais.
- `lib/domain/services/auth_validation.dart`: funções puras para nome, e-mail, senha de cadastro/login e confirmação; retorno AuthFailure ou null.
- `test/domain/auth_validation_test.dart` e `test/domain/auth_models_test.dart`: 38 novos testes locais.

Documentos alterados: `docs/PLANO_M4.md` e `docs/PROGRESSO.md`. O plano já estava não rastreado antes desta implementação; foi preservado e atualizado. Nenhuma alteração em dependências, UI, repositórios financeiros, configuração Firebase, regras, índices ou memória Gradle. JSON redundante em assets/illustrations preservado e fora do staging.

Decisões técnicas:

- AuthUser usa campos final, rejeita UID vazio e guarda e-mail com trim/lowercase. O UID não é escolhido/transformado pela validação; virá do provedor no M4.2.
- Nome usa trim, máximo de 80 runes incluindo espaços internos e pelo menos dois caracteres não brancos, sem exigir sobrenome; acentuação e Unicode aceitos. Compatível com os limites existentes do perfil, sem modificá-lo.
- E-mail usa validação básica compatível com o perfil atual e normalização idempotente. Mantém aliases e acentos; não é um validador completo de RFC nem comprova endereço existente/aceitação pelo provedor.
- Login exige somente senha não vazia. Cadastro exige pelo menos 8 runes Unicode; confirmação compara o texto exatamente. Espaços, caixa e sequências Unicode não são normalizados, truncados ou registrados; até senha apenas com espaços é aceita pela regra local se tiver 8 caracteres, sem inventar requisito de complexidade. O provedor pode aplicar política mais restritiva no M4.2.
- Códigos de falha não são códigos Firebase; a tradução contextual pertence ao adaptador futuro. Credenciais inválidas usam mensagem genérica e recuperação tem texto neutro. Falhas de rede/serviço têm tipos próprios e não devem virar falso sucesso. Cadastro existente orienta entrar/recuperar. Nenhuma autenticação simulada foi ligada ao app; a prova mínima do contrato existe somente no teste.

Verificações executadas sequencialmente:

| Comando | Resultado real |
|---|---|
| `dart format .` | 41 arquivos verificados, 3 formatados; exit 0 |
| `flutter analyze` | 0 erros, 0 warnings, 10 informes deprecated_member_use preexistentes; exit 1 pelos informes |
| `flutter test --concurrency=1` | 127 testes aprovados, 0 falhas: 89 anteriores + 38 novos; exit 0 |
| `git diff --check` | Aprovado; avisos locais LF/CRLF não representam erro do diff |

Cobertura nova: nomes válidos/inválidos/limites/acentos/Unicode; e-mails válidos/inválidos e normalização; cadastro 7/8 caracteres, Unicode e texto longo sem truncar; login curto e vazio; espaços em senhas; confirmação obrigatória, diferenças de caixa e composição Unicode; validação/imutabilidade de AuthUser/AuthFailure; códigos/mensagens e assinaturas abstratas do contrato. Contagem de Unicode usa runes, não grafemas visuais. O teste de bootstrap existente imprime StateError intencional para testar erro/retry; a suíte terminou aprovada, sem falha Firebase real.

Logs locais ignorados: `build/m4-1-analyze.log` e `build/m4-1-tests.log`. Nenhum teste remoto, criação/alteração/exclusão de conta ou documento, build Android/Web, deploy, commit ou push nesta etapa.

Limitações e próxima etapa: M4.1 valida domínio puro; não comprova login, envio de e-mail, persistência de sessão ou tradução dos códigos reais do SDK. Nenhuma revisão visual necessária porque UI não mudou. Usuário deve revisar esta entrega; somente após nova autorização iniciar M4.2 (FirebaseAuthRepository, mapper, composição e integração local conforme plano). Contas A/B/C e perfis A/C continuam retidos por decisão aprovada. Não avançar automaticamente.

## M4 — Histórico do planejamento (plano posteriormente aprovado)

Plano registrado em `docs/PLANO_M4.md`, após consulta a AGENTS.md, PLANO.md, este progresso, documentos 01–05, protótipo oficial e componentes/infraestrutura existentes. M3 permanece concluído e registrado no commit `e34c884ed79cf041e5371c997dde7cd93cd9abad`; a retenção de A/B/C e perfis A/C continua aprovada e sem pendência de exclusão.

Proposta: AuthRepository/FirebaseAuthRepository e modelos próprios sem SDK no domínio; SessionController com ChangeNotifier/ListenableBuilder; SessionGate e Navigator nativo; reutilizar FirebaseStartup, FirebaseSession, FirestoreUserRepository idempotente, UserProfile e tema atual. AuthRepository ainda não existe no código e será criado somente na implementação autorizada. Nenhuma dependência adicional prevista.

Fluxos planejados: login, cadastro, recuperação com confirmação neutra, persistência Android/Web, recomposição de perfil ausente, tratamento de cadastro parcial, logout e limpeza de pilhas/estado ao mudar UID. Nome/e-mail reais, nenhuma senha no Firestore/logs, envio duplicado bloqueado. Boas-vindas/logo/carrossel serão preservados; seus botões só serão ligados quando os destinos estiverem prontos.

Decisão pendente de revisão: os documentos levam ao Dashboard após login, mas ele pertence ao M5. Propõe-se usar o Perfil mínimo real como destino privado do M4, sem dashboard provisório, dados financeiros ou abas inexistentes. Aprovar essa adaptação antes de implementar; requisitos-base e critérios financeiros permanecem intactos. Perfil ausente solicita nome real, sem recadastrar usuário.

Etapas futuras, ainda não iniciadas:

- [x] M4.0 — Revisar fontes, infraestrutura e protótipo; criar planejamento técnico.
- [x] Revisão/aprovação do plano e da adaptação do destino privado.
- [x] M4.1 — Contrato/modelos de autenticação, validações e testes puros: 38 testes novos aprovados, aguardando revisão da entrega.
- [x] M4.2 — Adaptador Firebase, mensagens por contexto e composição: 59 novos testes locais e 12 verificações em emuladores aprovados; aguardando revisão.
- [x] M4.3 — Sessão, gate injetável e recuperação idempotente de perfil: 42 novos testes aprovados; aguardando revisão, sem ativação de telas incompletas em produção.
- [ ] M4.4 — Login, recuperação e perfil mínimo; conectar Entrar.
- [ ] M4.5 — Cadastro e completar perfil; conectar Criar conta.
- [ ] M4.6 — Homologação Android/Web, reinício/reload, e-mail de recuperação e comparação visual.

Testes previstos: unitários de validação/erros, widgets de formulários/rotas/semântica, concorrência e troca de UID com fakes pequenos, integração Auth/Firestore no projeto local demo-bolsozen e posterior homologação autorizada com SDK real. Novas contas/e-mails remotos exigem plano e autorização específicos; não reutilizar credenciais descartadas do M3. Homologar recebimento de recuperação requer e-mail de teste acessível e participação humana. Não afirmar persistência após reinício com base em hot reload, nem entrega de e-mail somente pela solicitação ao SDK.

Arquivos alterados nesta etapa: somente `docs/PLANO_M4.md` (novo) e `docs/PROGRESSO.md`. Validação documental e `git diff --check`; sem código, testes Flutter, build, instalação, Firebase remoto, deploy, staging ou commit. `assets/illustrations/google-services.json` preservado, não incluído. Próxima tarefa: usuário revisar o plano e autorizar a implementação; M5 não autorizado.

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
- [ ] M4 — M4.1/M4.2 aprovados; M4.3 implementado e testado, aguardando revisão. M4.4 e posteriores não autorizados.
- [ ] M5 — Transações e dashboard essencial.
- [ ] M6 — Gestão e histórico completos.
- [ ] M7 — Orçamento mensal.
- [ ] M8 — Relatórios.
- [ ] M9 — Homologação e APK.

M1 e M2 autorizados e implementados, com pendências próprias registradas. M3 concluído e registrado em e34c884. M4 com plano aprovado, M4.1/M4.2 revisados/aprovados e M4.3 entregue; demais subetapas aguardam autorização. M5 a M9 aguardam autorização individual. Detalhes em PLANO.md e PLANO_M4.md.

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

Revisar a entrega M4.3 e autorizar separadamente M4.4, se desejar. Perfil mínimo temporário já aprovado para o M4. Não repetir cadastros/testes remotos ou excluir contas e perfis retidos. Nenhum commit novo autorizado.

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
