# BolsoZen — Plano técnico do MVP

## Diretrizes

Fontes: AGENTS.md, documentos 01 a 05 e design/telas/bolsozen_prototipo.png. Android, pt-BR e BRL. Não ampliar o escopo. Cada marco depende de autorização própria; não avançar automaticamente. Não fazer commit, push, deploy ou publicar configurações sem autorização.

## Arquitetura e dependências

Três camadas: apresentação (telas, widgets, controladores), domínio (modelos imutáveis, contratos, categorias e funções financeiras puras) e dados (repositórios Firebase e mapeadores). Domínio sem Firebase ou widgets; apresentação sem acesso direto ao Firestore. Evitar classes de caso de uso para operações triviais.

Estado: ChangeNotifier e ListenableBuilder; setState para formulários e filtros locais. Injeção por construtores, composição em app_dependencies.dart. Navigator para rotas secundárias e NavigationBar para as cinco áreas. SessionGate deriva o acesso da sessão real. Descartar assinaturas e dados ao trocar UID ou sair.

No M1, remover material_ui e substituir imports pelo Material oficial: o contador atual não justifica a dependência adicional. Manter inicialmente cupertino_icons. Usar flutter_localizations e intl. No M3, adicionar firebase_core, firebase_auth e cloud_firestore. integration_test pertence ao SDK. Gráficos simples com CustomPainter e alternativa textual, sem biblioteca adicional inicialmente. Selecionar versões compatíveis com Flutter 3.50.0/Dart 3.14.0 e registrar lockfile; não atualizar SDK sem necessidade.

Estrutura criada sob demanda, sem arquivos vazios:

```text
lib/
  main.dart
  app/                 # app, composição, session_gate e main_shell
  core/                # theme, formatting e errors
  domain/              # models, repositories e services
  data/                # firebase, repositories e mappers
  presentation/
    controllers/
    screens/           # welcome, auth, dashboard, transactions, budgets, reports, profile
    widgets/
test/                  # domain, data e presentation
integration_test/
firebase/tests/        # testes de regras
```

## Dados e integração Firebase

Contratos: AuthRepository (sessão, cadastro, login, recuperação e logout), UserRepository (obter/garantir perfil), TransactionRepository (páginas e CRUD), BudgetRepository (consulta mensal, salvar/remover). Serviço financeiro puro calcula indicadores. UID sempre vem da sessão.

| Caminho | Campos |
|---|---|
| users/{uid} | displayName, email, createdAt |
| users/{uid}/transactions/{id} | userId, type, amountCents, categoryId, description, occurredAt, createdAt, updatedAt |
| users/{uid}/budgets/{YYYY-MM_categoryId} | userId, monthKey, categoryId, limitCents, createdAt, updatedAt |

ID de transação gerado pelo Firestore. Categorias constantes conforme RF, sem coleção própria. Conta principal fixa. Auditoria com timestamps de servidor; preservar createdAt. occurredAt representa a data informada, com apresentação e agrupamento pelo calendário local; testar conversões UTC/local. Não persistir totais duplicados.

Regras: negar por padrão, exigir autenticação e UID igual ao caminho; validar campos permitidos/obrigatórios, tipos, dinheiro positivo, descrição de 1–120 caracteres após trim e categoria compatível. Impedir troca de proprietário e createdAt. Validar monthKey e sua correspondência ao ID/categoria do limite. Sem acesso genérico a subcoleções. Nunca persistir senhas ou credenciais administrativas. Versionar regras e índices; testar proprietário, outro UID, anônimo e registros inválidos com @firebase/rules-unit-testing e Emulator Suite.

Carregar transações em páginas de 100, ordenadas por occurredAt, createdAt e ID, com cursor. Completar leitura antes de apresentar saldo global como completo; nunca agregar só a primeira página. Compartilhar conjunto carregado, recalcular após CRUD confirmado e atualizar ao retomar app ou solicitar atualização. Falha mantém estado explícito; pendência offline não significa sucesso confirmado. Descartar dados no logout. Estratégia adequada ao pequeno volume acadêmico, com custo proporcional ao histórico; medir massa maior e registrar limitação.

Sequência futura: verificar ferramentas; usuário escolher/criar projeto; registrar Android com com.bolsozen.bolsozen; habilitar e-mail/senha; criar Firestore restritivo; autenticar CLIs localmente; executar FlutterFire para Android; revisar arquivos gerados; inicializar Firebase; configurar emuladores; testar; publicar regras/índices somente com autorização; validar no serviço real. Configurações e regras na raiz conforme ferramentas.

Participação humana: conta Google, projeto, região Firestore, habilitação dos serviços, autenticação local e validação do e-mail de recuperação. Não solicitar tokens/senhas no chat ou habilitar serviços pagos sem aprovação. Authentication e perfil não são atômicos: permitir repetir criação idempotente de perfil sem recadastrar usuário.

Referências oficiais: https://firebase.google.com/docs/flutter/setup e https://firebase.google.com/docs/rules/unit-tests.

## Interface e domínio financeiro

Tema claro Material 3, primary #0E7D68 e demais tokens do design system. Roboto inicial; Inter somente com asset autorizado. Componentes reutilizáveis: botões com carregamento, campos, cartões, transações, categorias, progresso, seletor mensal e estados vazio/erro. Comparar screenshots em 360, 390 e 412 dp, teclado aberto e texto ampliado. Solicitar assets separados da marca e registrar alternativas provisórias.

Telas: boas-vindas, login, cadastro, recuperação, perfil mínimo, dashboard, histórico, nova/editar transação, orçamento/editor de limites e relatórios com Visão geral/Categorias/Evolução da mesma fonte. Não mostrar abas inacabadas, sino sem função, links falsos ou conta editável. Omitir aceite de termos sem textos reais. Contas novas vazias; fixtures somente em testes identificados.

Dinheiro em int de centavos, parsing pt-BR sem double intermediário. Saldo = receitas menos despesas de todo histórico, podendo ser negativo; registros futuros contam segundo documentação. Totais mensais por occurredAt; seleção mensal não altera saldo global. Histórico descendente por data/criação/ID; busca por descrição e categoria nos dados carregados. Troca de tipo limpa categoria incompatível.

Limites positivos por categoria de despesa/mês, sem cópia automática. Consumo = despesas/limite; normal abaixo de 80%, atenção de 80% a menos de 100%, atingido a partir de 100%. Comparar limiares com inteiros. Indicador global usa apenas categorias com limite; sem limites, orientar configuração. Percentuais textuais não truncados acima de 100%; apenas barras saturam. Relatórios: despesas por categoria, seis meses incluindo selecionado, comparação anterior zero como “Sem base de comparação”. Decimais apenas para percentuais/apresentação. CRUD recalcula todos os agregados, inclusive mudanças de mês. Nenhum total acumulado sobre resultado anterior.

## Marcos e critérios

Dependências cumulativas. Em todo marco relevante: dart format ., flutter analyze e flutter test, testes específicos, evidências e atualização de PROGRESSO.md. Sem execução comprovada, marcar Implementado / Não validado.

| Marco | Objetivo, módulos e funcionalidades | Dependências | Testes e conclusão | Intervenção humana |
|---|---|---|---|---|
| M0 | Criar PLANO.md e PROGRESSO.md apenas | Nenhuma | Revisão documental e diff restrito aos dois arquivos | Revisar planejamento |
| M1 | Base Flutter, tema, localização, componentes e boas-vindas; app/core/presentation | Remover material_ui; adicionar localização e intl | Renderização, navegação pública funcional, português, responsividade; executar Android | Autorizar marco; assets ou registrar limitação |
| M2 | Modelos, contratos, categorias e regras; domain e testes | M1; nenhuma nova | Parsing, saldo negativo, datas futuras, meses/anos, ordenação e limites; T1/T2 aprovados | Autorizar marco |
| M3 | Inicialização, mapeadores, repositórios, regras, índices e emuladores; data/configuração/firebase/tests | M2; pacotes Firebase, CLIs e ferramentas de regras | Serialização, acesso A/B/anônimo, inválidos e proprietário imutável; persistência e configuração real validadas | Console, região, login local; publicação separadamente autorizada |
| M4 | Cadastro/login/sessão/recuperação/perfil/logout; auth, session_gate e profile | M3 | CA-01 a CA-03; validações, envio duplicado, rede, perfil parcial, troca de conta e sessão real | Validar recuperação por e-mail |
| M5 | Criar/listar transações, paginação, dashboard/saldo/totais e estados reais; controlador financeiro e telas | M4 | Gravar/reabrir, centavos, falhas preservam formulário, múltiplas páginas; totais completos corretos | Validar Android |
| M6 | Edição/exclusão, filtros, busca, agrupamento, recentes e ocultação; reutilizar formulário | M5 | CA-04 a CA-07 e persistência; cancelamento/falha, troca de mês/tipo e desempates | Validar fluxos e screenshots |
| M7 | Seletor mensal, editor, remoção, alertas e consumo; budgets/widgets | M6 | CA-08; 0/80/99,99/100/125%, sem herança e sem excluir transações; T2 global 70% | Validar orçamento |
| M8 | Três vistas, gráficos acessíveis e comparação; reports/widgets | M7; nenhuma nova | CA-09; seis meses/virada de ano, vazio/base zero e atualização após CRUD | Revisar gráficos e screenshots |
| M9 | Homologação, README, evidências e APK; testes de integração/documentação | M8 e ambiente Android | CA-01 a CA-12, MAN-01 a MAN-12; APK instalado/executado e P0/P1 aprovados | Homologar e decidir assinatura; chave privada fora do Git |

## Testes, riscos e entrega

Testes unitários cobrem RN-01 a RN-10; widgets cobrem validações, estados e navegação; integração cobre sessão, persistência, CRUD e troca de conta; regras exercitam acesso direto adversarial. T1: saldo R$ 600,00, novembro receitas R$ 1.000,00/despesas R$ 350,00, outubro despesas R$ 50,00. T2: alimentação 83,33%, transporte 50%, global 70%. Variação novembro/outubro +600%. Reproduzir edições/exclusões do CA-07.

Riscos: acesso Firebase/emuladores ainda não validado, assets ausentes, custo de carregar histórico, gravações pendentes offline, perfil parcial, datas em mudanças de fuso e assinatura release atualmente debug. Medir volume e registrar comportamento local de datas. Qualquer divergência de escopo exige decisão antes da alteração.

MVP concluído somente com P0/P1 e aceites aprovados, regras testadas, persistência real, UI comparada, documentação atualizada e APK release executado. Build não substitui teste em dispositivo. Não declarar etapa concluída sem evidências; autorizar cada fase separadamente.
