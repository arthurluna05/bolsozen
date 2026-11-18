# M6 — Planejamento de edição, exclusão e consulta do histórico

## Encerramento aprovado com ressalvas

Usuário aprovou funcionamento após testes manuais e **dispensou M6.6**. Marco encerrado com ressalvas, sem declarar essa homologação executada. Entregues CRUD/confirmar exclusão, busca e filtros combinados, agrupamento local, ocultação do saldo e recentes; preservados UID, precisão, trava de mutações e reconciliação. Evidência anterior: 656 testes aprovados e 52 informes de depreciação, zero erros/warnings; sem repetir bateria nesta tarefa. Relatório [M6_HOMOLOGACAO.md](M6_HOMOLOGACAO.md).

Ressalvas acumuladas M4/M5/M6 encaminhadas ao M9: integrações locais adicionais, CRUD Android/Web nativo, teclado/TalkBack, persistência após reinício ainda não comprovada, falhas de conexão e depreciações. Commit local autorizado somente para M6; M7 apenas planejamento posterior. Registros abaixo são históricos e não reabrem etapas dispensadas nem autorizam implementação seguinte.

## Situação vigente — M6.5 entregue para revisão

M6.4 aprovado tecnicamente pelo usuário (638 testes/50 informes). Autorizado exclusivamente M6.5: ocultação do Saldo total e revisão dos recentes. Não iniciar M6.6 sem nova autorização. Registros seguintes são históricos.

Implementada a proposta original de visibilidade local no Dashboard: começa visível, máscara `••••••` ao ocultar, olho aberto/fechado e labels Ocultar saldo/Mostrar saldo. BalanceCard recebe estado/callback; o texto oculto contém somente máscara e a semântica anuncia Saldo oculto, sem carregar o valor em outra label/tooltip. Preferência sobrevive abas/refresh pelo IndexedStack existente; reset ao invalidar sessão/substituir controller ou UID, além do descarte da árvore privada no SessionGate. Não persiste nem consulta nada ao alternar.

Ocultação limitada ao saldo principal; receitas, despesas, categorias, recentes, Histórico e formulário continuam com os dados usuais. Gradiente/carteira/tipografia/raios/posição do olho TEL-04 e controles TEL-06 preservados. Sem alteração em MainShell, SessionGate, FinancialController, FinancialProjection, domínio, repositórios ou Firebase nesta etapa.

Recentes continuam com **um item** de FinancialProjection.recent sobre o histórico confirmado/ordenado. Testes cobrem criação, edição de tipo/categoria/valor/descrição, reordenação por data e remoção após exclusão/recarga, sem consultas próprias ou duplicação. Na falha de recarga, mantém snapshot anterior com aviso stale e retry somente de leitura. Alternar saldo não remove erros ou pendências. Resultados/evidências/limites em PROGRESSO.md e M6_5_VALIDACAO_VISUAL.md. Aguardar revisão antes do M6.6; sem escrita remota, staging, commit, push ou deploy.

## Situação vigente — M6.4 entregue para revisão

M6.3 aprovado pelo usuário (607 testes/47 informes). Implementado exclusivamente M6.4: busca local por descrição ou categoria, combinação AND de tipo/categoria/texto, modal Material e controles ampliados. Não iniciar M6.5 sem nova autorização. Registros de autorização abaixo são históricos.

Estado transitório em TransactionsScreen, preservado pelo IndexedStack e destruído pela árvore privada da sessão. FinancialProjection.filterHistory retorna lista imutável, mantendo ordem e modelos confirmados. Nenhuma consulta ao digitar ou selecionar; FinancialSummary e cálculos não usam a lista filtrada. Timer de meia-noite e retomada atualizam os rótulos locais sem rede.

A autorização específica M6.4 inclui busca sem acentos quando viável: normalização portuguesa e marcas combinantes, sem dependências, foi adotada. Substitui a decisão inicial mais restrita sobre acentos. Chip Todas remove somente tipo; mudar tipo remove somente categoria incompatível. Campo X limpa somente pesquisa. No modal, opção Todas do campo Categoria + Aplicar remove somente categoria; Cancelar descarta rascunho; Limpar filtros confirma explicitamente a remoção de texto, tipo e categoria, conforme explicação visível.

Ajuste visual autorizado: controles com altura mínima de 48 dp, fonte de tema labelLarge (14/w600), largura proporcional e quebra responsiva; ícone tune 26 dp em alvo 48×48 e pesquisa com altura mínima visual de 48 dp. Tela de texto ampliado pode distribuir chips em duas linhas para preservar legibilidade. Tokens e cards TEL-06 mantidos. Evidências e limitações em M6_4_VALIDACAO_VISUAL.md e PROGRESSO.md.

Nenhuma alteração adicional no FinancialController, domínio, repositórios, MainShell, SessionGate, Firebase, Gradle ou dependências nesta etapa. Não houve escrita remota, staging, commit, push ou deploy. Próxima etapa possível: M6.5, somente após revisão e autorização.

## Situação vigente — M6.3 implementado para revisão

M6.2 revisado e aprovado tecnicamente pelo usuário com 561 testes e 44 informes. Autorizado exclusivamente M6.3. **Não iniciar M6.4** ou qualquer etapa posterior. Registros seguintes retratam entregas anteriores e não substituem esta autorização vigente.

Menu TransactionActionsSheet mantém Editar e agora oferece Excluir, com lixeira na cor error. A seleção só abre DeleteTransactionDialog/AlertDialog no Navigator privado, com descrição, valor, aviso irreversível, Cancelar e Excluir. Não existe delete no toque da linha ou na seleção do menu. Confirmação repetida bloqueada por estado local e trava comum do controller. Fechar/Voltar durante envio não cancela a operação já submetida, não repete a escrita e não impede o controller de terminar sua confirmação/recarga.

deleteTransaction recebe o modelo original do snapshot confirmado, valida UID/ID/conteúdo e usa a mesma rotina/trava de create/update. Revalida após qualquer leitura anterior, chama delete(id, expectedUserId: UID fixo) uma vez e inicia carga completa posterior. Só publica o novo saldo/lista depois de verificar ausência do ID; se ele ainda vier, conserva snapshot anterior explicitamente desatualizado. Não há cálculos nem remoção otimista nos widgets.

Cancelamento antes de confirmar não chama o repositório. Erro definido mantém registro/saldo e mensagem. Commit confirmado com refresh falho informa exclusão e oferece apenas leitura. Resultado incerto não vira sucesso/falha definitiva, bloqueia outra mutação até leitura e não reenvia delete; ausência constatada em snapshot completo pode confirmar o estado resultante. notFound permanece erro específico mesmo após leitura e não vira sucesso automático. Menu/diálogo usam a árvore privada; logout/UID/dispose descartam UI e respostas antigas.

A aparência TEL-04/TEL-06 não foi redesenhada; diálogo é complemento Material com tokens oficiais e ações de contraste verificadas. Regras/índices, domínio/cálculos, repositórios e guardas M6.1, Gradle, dependências, busca/filtros e ocultação preservados. Nenhuma operação Firebase remota, commit, push ou deploy. Evidências/resultados finais em PROGRESSO.md e M6_3_VALIDACAO_VISUAL.md. Aguardar revisão antes do M6.4.

Validação final: **607 testes aprovados** (561 anteriores + 46 novos), analyzer com **47 informes de depreciação**, sem erros/warnings; format e diff-check aprovados. Um teste de captura separado aprovado com oito PNGs inspecionados. Não houve testes remotos/emuladores/SDK nativo nem homologação Android/Web nesta entrega.

## Situação vigente — M6.2 entregue para revisão

M6.1 revisado e aprovado pelo usuário com 515 testes e 41 informes. Autorizado exclusivamente M6.2; **não iniciar M6.3**. Registros de autorização M6.1 abaixo são históricos. Entregue edição real pelo Histórico → bottom sheet Material somente Editar → mesmo TransactionFormScreen TEL-05 em modo de edição, pelo Navigator privado e FinancialController compartilhado. Sem tela de detalhes, exclusão, busca/filtros ou ocultação.

Formulário recebe o original confirmado, preenche valor com Money.formatCents e preserva ID/UID/createdAt e occurredAt exato quando a data não mudar (inclusive hora/UTC/microssegundos; confirmar o mesmo dia no calendário não o altera). Tipo limpa categoria incompatível; mesmas validações, Conta principal informativa e visual aprovados. Voltar não grava. Snapshot incompatível/ausente na abertura não expõe campos nem oferece criação alternativa.

FinancialController ganhou updateTransaction e consultas pequenas de seleção/confirmação, sem cálculos na UI. A implementação privada de submissão é compartilhada com create, usando uma trava/versionamento e expectedUserId fixo. Original precisa corresponder integralmente ao registro do snapshot do UID atual; nova validação após aguardar leitura anterior impede operar em ID removido/alterado durante esse intervalo. Não há novo create em modo edição.

Após update confirmado, exige nova carga completa e presença do ID com todos os campos editáveis esperados, mesmo proprietário/createdAt; updatedAt continua gerado pela camada de dados e não é comparado a um timestamp antecipado pela UI. Mantém snapshot anterior explicitamente stale se recarga falhar ou voltar com conteúdo antigo; retry faz somente leitura. Resultado incerto marca erro/stale e exige leitura antes de outra mutação. No formulário, só confirma por leitura se o snapshot completo corresponder ao esperado; se diferente, mantém envio bloqueado e orienta conferir o Histórico/reabrir, sem afirmar cancelamento. notFound informa e oferece leitura sem recriar nem reenviar. Erros definidos preservam entradas.

Arquivos M6.2 e evidências em PROGRESSO.md e M6_2_VALIDACAO_VISUAL.md. Guardas/contratos M6.1, repositório Firebase, Money/domínio, SessionGate, identidade, navegação de três abas e fluxo M4/M5 preservados. Testes novos são locais com fakes; não homologam persistência Firebase real. Nenhuma operação remota, alteração de regras/índices/Gradle/dependências, commit/push/deploy. Aguardar revisão antes de exclusão M6.3.

Validação M6.2: 561 testes aprovados (515 anteriores + 46 novos); analyzer com 44 informes de depreciação, sem erros/warnings; format/diff-check aprovados. Um teste separado de captura com oito PNGs. Sem testes remotos ou plugins nativos nesta etapa.

## Histórico M6.1 e detalhamento das subetapas

**Planejamento aprovado pelo usuário; somente M6.1 autorizado e implementado para revisão. M6.2 e seguintes não autorizados.** Base: M5 encerrado com ressalvas e commit local `5ce9c6e8fafa222133c204de62d8d27c1e555f8f` (90 arquivos). Baseline anterior: 475 testes Flutter aprovados e 41 informes de depreciação, zero erros/warnings. O restante deste plano descreve etapas futuras, sem autorizar sua execução.

## Registro M6.1 — segurança de update/delete

Usuário aprovou extensão expectedUserId, menu por transação nas etapas próprias, combinação de busca/filtros, ocultação somente do saldo principal durante a sessão e preservação visual. Orçamento, relatórios, notificações, Google Login e BolsoZen Bot permanecem excluídos deste marco. Essas decisões substituem o estado de revisão pendente da versão inicial do plano.

TransactionRepository e FirestoreTransactionRepository agora aceitam `update(transaction, {expectedUserId})` e `delete(id, {expectedUserId})`, opcionais e compatíveis com chamadas anteriores. UID/caminho continuam derivados exclusivamente do FirebaseSession. Divergência é recusada antes de resolver coleção/documento ou iniciar transação. Cada callback/tentativa transacional valida o UID capturado; após get verifica novamente antes de interpretar conteúdo e antes de enfileirar escrita; ao concluir await verifica antes de retornar sucesso.

Preservados proprietário, ID, createdAt imutável, updatedAt de servidor, validação do mapper/modelo, dinheiro seguro e erros tipados. Nenhuma alteração em FinancialController, FirebaseSession, modelo, regras/índices, domínio de cálculos, navegação ou UI. Fake financeiro de apresentação recebeu somente assinatura compatível; testes de transporte existentes foram estendidos.

Os testes novos usam referências/snapshots reais do SDK Dart com Auth fake e transporte nativo interceptado localmente; não inicializam plugin nativo real ou rede. Cobrem chamadas antigas, proprietários e IDs coincidentes, UID/logout durante leitura, mudança antes do callback e em nova tentativa transacional, confirmação tardia/incerta, erro de rede/permissão, registro ausente/inválido, criação imutável e fronteira monetária. Resultados finais da suíte em PROGRESSO.md.

Validação final M6.1: **515 testes Flutter aprovados**, preservando 475 anteriores e acrescentando 40; 54 casos no arquivo de sessão do repositório incluídos nessa contagem. Analyzer: 41 informes de depreciação conhecidos, zero erros/warnings; format e diff-check sem erros. Nenhum teste de emulador/regra ou serviço remoto executado. Aguardar revisão antes do M6.2.

Limites: chamada antiga sem expectedUserId continua significando operar na sessão atual; consumidores futuros de edição/exclusão devem fornecer UID de origem explicitamente. Operação já enviada para A pode ter resultado incerto após troca de sessão; isso não cancela nem redireciona a escrita a B. Future<void>/DataFailure e ID/modelo de entrada são preservados para reconciliação por leitura pelo consumidor, sem novo protocolo de persistência ou replay automático. Retry interno normal do SDK em conflito continua possível e revalida UID em cada callback; não equivale a reenviar a mutação pela interface. Coordenação visual/reconciliação do controller será implementada somente nas etapas autorizadas M6.2/M6.3.

Fontes relidas após o commit: AGENTS.md, PLANO.md, PROGRESSO.md e documentos 01–05; inspeção direta de design/telas/bolsozen_prototipo.png e dos componentes atuais. Este plano não altera requisitos, protótipo ou regras de segurança. Android principal, Web complementar, pt-BR e Material 3/Roboto existentes.

## 1. Escopo original e limites

M6 do PLANO.md: edição/exclusão, filtros, busca, agrupamento, recentes e ocultação; reutilizar o formulário. Rastreabilidade: RF-12/RF-16–21, RN-01/02/03/07/08, jornadas J-03/J-05 e CA-04/06/07/10/11/12. Filtro explícito por categoria incluído no planejamento por solicitação atual do usuário; RF-19 já exige busca pelo nome da categoria.

- Editar tipo, valor, categoria, data e descrição de transação existente, sem mudar ID/proprietário/criação.
- Excluir somente após confirmação com descrição e valor; cancelamento não chama o repositório.
- Buscar em descrição ou nome de categoria; combinar com Todas/Receitas/Despesas e categoria específica.
- Preservar ordem do domínio e agrupamento por dias locais, com vazio real ou sem resultados distinguíveis.
- Tornar funcional o olho do cartão de saldo durante a sessão; manter recentes reais sincronizados.

Não incluir orçamento, relatórios, outras abas, notificações, contas bancárias, Google Login ou BolsoZen Bot. Navegação continua com Início/Transações/Perfil. Dashboard segue somente mês corrente; períodos manuais permanecem nos marcos próprios. Sem novas dependências, Gradle, regras, índices, serviços pagos ou operações remotas neste planejamento.

## 2. Diagnóstico do código existente

| Componente | Já entregue | Trabalho planejado M6 |
|---|---|---|
| MainShell / SessionGate / SessionController | Uma instância financeira por sessão pronta, árvore privada descartável e rotas secundárias | Reutilizar composição e incluir rotas/ações de edição sem outro controller |
| FinancialController | Carga completa paginada, snapshot confirmado, recarga, create e resultados de falha/incerteza | Acrescentar update/delete coordenados, mantendo serialização de mutações e confirmação posterior |
| TransactionRepository / FirestoreTransactionRepository | CRUD; update/delete já usam transações Firestore, UID SDK e verificações assíncronas | Estender barreira expectedUserId a update/delete antes da exposição pública |
| FinancialTransaction / Money / TransactionValidation | Modelo imutável, centavos/BigInt/limite seguro e validações | Reutilizar sem segundo parser/modelo monetário |
| TransactionFormScreen | Formulário de criação TEL-05 e atualização pendente | Modo de edição preenchido, título Editar transação e ação Salvar alterações |
| FinancialCalculator | Saldo/totais/ordenação a partir do conjunto completo | Recalcular por summarize após carga confirmada; nenhuma soma nos widgets |
| FinancialProjection | Um recente real e cabeçalhos Hoje/Ontem/outras datas | Filtragem visual pura antes de gerar cabeçalhos, preservando ordem e recentes existentes |
| TransactionsScreen / TransactionTile | ListView.builder, agrupamento e cards responsivos | Campo/chips funcionais, filtro de categoria e ações acessíveis por item |
| BalanceCard | Gradiente/carteira/olho indisponível | Visibilidade controlada em memória, sem mudar dados nem consultar Firebase |

`update` valida userId, lê documento existente, preserva createdAt e usa updatedAt de servidor. `delete` captura o UID corrente no início: uma ação atrasada de A não deve operar no caminho de B, mesmo se o ID existir nos dois usuários. A barreira expectedUserId foi acrescentada no M6.1 conforme registro acima; verifica identidade e nunca seleciona proprietário pela interface. Consumidores visuais de edição/exclusão continuam futuros.

## 3. Arquitetura e comportamento das mutações

Manter apresentação/domínio/dados e ChangeNotifier/ListenableBuilder. Nenhuma consulta Firebase em tela/widget. MainShell continua dono do controller; autenticação e Perfil M4 não mudam.

Contrato compatível implementado no M6.1: named parameter opcional `expectedUserId` em update e delete, mantendo chamadas anteriores válidas. FirebaseSession continua fornecendo o UID real. Identidade é verificada na entrada, antes de leituras/escritas, dentro das tentativas da transação SDK e após awaits. update mantém a validação do proprietário do modelo. Nas etapas futuras, controller capturará UID/navigationVersion, exigirá registro do snapshot confirmado do mesmo usuário e não aceitará ID arbitrário da interface como autorização.

Controller coordenará create/update/delete sob uma única trava de mutação, evitando refresh redundante e envios simultâneos. Esperar leitura anterior antes de iniciar escrita; depois de commit confirmado iniciar uma nova carga completa, nunca reaproveitar leitura anterior ao commit. Reaproveitar estados/resultados M5.4 onde forem adequados; adaptar o registro de verificação pendente de modo pequeno para representar inclusão, edição esperada ou remoção, sem framework genérico de comandos.

- **Edição confirmada:** carga completa deve conter o mesmo ID com os campos editáveis confirmados e createdAt original; auditoria atualizada vem do servidor. Não declarar atualização se ainda chegou o conteúdo antigo.
- **Exclusão confirmada:** carga completa deve comprovar ausência do ID. Não remover item/totais otimisticamente antes da confirmação como se a operação tivesse concluído.
- **Commit confirmado, refresh falhou:** sinalizar atualização pendente, oferecer somente retry de leitura; preservar snapshot anterior explicitamente desatualizado, quando seguro. Sem snapshot, não fabricar saldo zero.
- **Resultado de escrita desconhecido:** não tratar timeout como cancelamento. Bloquear repetição automática e exigir conferência por leitura antes de outra ação; não transformar falha em sucesso. Manter o rascunho da edição quando seguro e esclarecer o estado.
- **notFound:** informar que registro não está disponível e permitir atualização; não recriar via create nem considerar uma falha genérica prova de exclusão bem-sucedida.
- **Logout/troca de UID/dispose:** descartar respostas, rascunhos/rotas da identidade antiga e snapshots, preservando guardas já existentes.

Não persistir agregados nem subtrair/somar valores sobre saldo anterior. Atualizar Dashboard, lista, recentes e percentuais já existentes da mesma carga. Nenhuma tela de orçamento/relatórios será criada para demonstrar recálculo; o domínio e seus testes permanecem reutilizáveis pelos marcos futuros.

Limitação conhecida: paginação não é um snapshot transacional da coleção, e o repositório atual não faz resolução de conflito entre edições concorrentes de dispositivos. Não prometer merge/controle de versão inexistente. Qualquer mudança contratual adicional para concorrência remota deve ser justificada e aprovada separadamente; não é requisito novo implícito deste plano.

## 4. Fluxos e composição visual

**Edição:** toque acessível em item do Histórico → bottom sheet Material com ação Editar → TransactionFormScreen preenchido → validar → update → confirmar recarga → retornar ao Histórico sem refetch extra. Não criar tela de detalhe vazia. Durante implementação incremental mostrar apenas ações realmente entregues.

**Exclusão:** mesmo menu → Excluir → AlertDialog com descrição/valor, Cancelar e Excluir → delete confirmado → recarga completa → permanecer na origem com feedback. Bloquear confirmação repetida. Guardar identidade/ID da seleção e revalidar antes do envio; mudança de sessão remove também diálogo/menu pelo Navigator privado.

Formulário mantém TEL-05, mesmos tokens e campos: categoria muda com o tipo, valor preenchido por Money.formatCents dentro da faixa suportada, Conta principal informativa, descrição validada. Não truncar quantia nem criar novo ID. Preservar occurredAt original quando a data não for editada; somente seleção explícita produz nova data local. Preservar createdAt e deixar updatedAt ao repositório/servidor. Em falha definida conservar entradas. Voltar sem salvar não grava.

Histórico mantém TEL-06 aprovado: cabeçalhos textPrimary/semibold, títulos 16, ícones 28/pastéis e valores com sinais; não redesenhar. Campo real ocupa a estrutura atual de busca. Chips reais mantêm cores/raios e estado selecionado acessível. Ícone tune abre filtro Material simples por categoria, com Aplicar/Cancelar/Limpar. Seleções do modal só passam a valer em Aplicar; Cancelar conserva filtro anterior.

## 5. Busca, filtros e organização

Proposta: estado de busca/tipo/categoria em TransactionsScreen (StatefulWidget com setState), mantido pelo IndexedStack e descartado com a sessão. Projeção pura em FinancialProjection ou pequeno helper de apresentação somente se necessário; sem segundo controller financeiro.

- Filtro por tipo **E** filtro de categoria **E** busca; busca casa descrição **OU** rótulo da categoria.
- Todas é ausência de filtro de tipo, não a limpeza silenciosa de busca/categoria. Ação Limpar filtros restaura todos explicitamente.
- Tipo selecionado restringe categorias disponíveis; trocar tipo limpa categoria incompatível. Todas permite categorias dos dois tipos com rótulos corretos.
- Busca parcial, trim e comparação sem diferença de maiúsculas/minúsculas. A autorização M6.4 acrescentou tolerância aos acentos portugueses e marcas combinantes, sem modificar os textos originais.
- Aplicar sobre todo o histórico confirmado, não somente itens montados pelo ListView ou a primeira página. Retornar coleção imutável, sem alterar a ordem occurredAt DESC, createdAt DESC e ID ASC do domínio.
- Aplicar filtros **antes** do agrupamento, sem cabeçalhos vazios. Vazio real: ação Adicionar; filtro sem resultados: Nenhuma transação encontrada e Limpar filtros. Rede/permission-denied continuam estados de erro, nunca vazio.
- Filtros não alteram saldo global, totais mensais ou gastos por categoria do Dashboard; não chamar summarize com subconjunto filtrado.
- Datas locais Hoje/Ontem precisam ser reavaliadas ao retomar a tela/app e na virada do dia quando aberta, apenas por relógio local; sem polling Firestore. Testar meia-noite, mês/ano e conversões locais.

Sem consulta remota para cada tecla/filtro, índices novos, busca avançada, intervalo de datas ou contagens agregadas persistidas. Custo em memória/CPU proporcional ao histórico, adequado à massa acadêmica e explicitamente limitado.

## 6. Ocultação e elementos ainda indisponíveis

RF-12/CA-04 preveem ocultação somente do cartão Saldo total durante a sessão. Proposta: bool local no Dashboard preservado entre abas pelo IndexedStack; estado inicial visível, reset com nova árvore de sessão, sem SharedPreferences/Firestore. BalanceCard recebe valor de visibilidade/callback; oculto renderiza máscara `••••••` e semântica Saldo oculto, sem valor financeiro subjacente exposto ao leitor de tela. Olho alterna labels Mostrar saldo/Ocultar saldo. Receitas/despesas e linhas não serão ocultadas por esse botão, pois não há requisito de modo de privacidade global.

| Elemento atual | Situação | Destino |
|---|---|---|
| Olho no saldo | Indisponível, tooltip M6 | Tornar funcional no M6 |
| Busca/lupa, chips e tune | Composição não interativa, caption M6 | Tornar busca/tipo/categoria reais; remover caption ao concluir |
| Linha de transação | Sem ações Editar/Excluir | Menu acessível e confirmação reais no M6 |
| Agrupamento e recente | Já reais no M5; recente mostra um item | Preservar composição; verificar atualização após edição/exclusão, sem ampliar quantidade arbitrariamente |
| Sino | Decorativo, sem ação/semântica enganosa, autorizado na revisão M5.3 | Continua sem notificações; fora deste marco/MVP |
| Carteira no saldo | Gráfico decorativo Material | Preservar, não transformar em botão |
| Meta do mês Em breve | Neutro, sem cálculo fictício | Continua adiado ao M7, fora do M6 |
| Ver mais em categorias | Indisponível, dependência M8 | Não criar destino falso no M6 |
| Orçamento/Relatórios | Somente fixture visual antiga; ausentes na navegação real | Permanecem fora do M6 |
| Conta principal | Informação fixa, sem seletor falso | Preservar; não é módulo incompleto |

O sino diverge da recomendação inicial de omiti-lo, mas sua presença não interativa foi expressamente aprovada na revisão M5.3. Preservar essa decisão, sem inferir autorização para notificações. FABs, Ver todas e abas reais já funcionam; não reimplementar.

## 7. Subetapas propostas — cada uma exige autorização

| Etapa | Objetivo/arquivos previstos | Dependência | Testes e critério de conclusão |
|---|---|---|---|
| M6.1 | Barreira expectedUserId compatível em TransactionRepository/FirestoreTransactionRepository para update/delete; fakes e testes data correspondentes | Plano M6 aprovado | UID correto/divergente antes e durante awaits/retry SDK, ID coincidente A/B, chamadas antigas compatíveis, createdAt/proprietário preservados; nenhuma ação UI nova |
| M6.2 | update no FinancialController; modo edição no TransactionFormScreen; callbacks em MainShell/TransactionsScreen/TransactionTile; menu pequeno transaction_actions_sheet.dart se necessário | M6.1 | Campos preenchidos/validações, receita↔despesa, alteração de mês, cancelamento, uma escrita, falha/retry só de leitura, resultado incerto e UID/dispose; T1 saldo 600→650 e despesas novembro 350→300 ao editar 250→200 |
| M6.3 | delete no controller e menu; confirmation_dialog específico só se reutilizável/necessário; integração do shell | M6.2 | Cancelar não grava; confirmar uma vez; erro mantém item; commit+refresh falho não repete delete; ausência confirmada; excluir Transporte após cenário CA-07 eleva saldo 650→750; identidade revalidada após diálogo |
| M6.4 | Busca, chips e categoria reais; substituir UnavailableHistoryFilters por widget usado history_filters.dart; projeção e agrupamento local mantidos | M6.3 | Combinações tipo/categoria/texto, categoria incompatível, Unicode/case, múltiplas páginas, ordem/desempates, nenhum resultado, relógio local e filtros sem consultas/totais alterados |
| M6.5 | BalanceCard/Dashboard com olho funcional; validar recentes reais após CRUD | M6.4 | Máscara visual e semântica sem valor, alternância/abas/refresh, reset UID/logout; recente desaparece/reordena por dados confirmados, sem fake; nenhum cálculo novo |
| M6.6 | Verificação dirigida dos fluxos entregues, screenshots TEL-04/TEL-05/TEL-06 e integração local viável; relatório M6 | M6.5 | Preservar 475 testes e casos novos; 360/390/412, texto ampliado/teclado, emuladores demo-bolsozen com endpoints guardados; evidências reais/limitações e revisão humana antes do encerramento |

Arquivos adicionais somente quando usados: testes `test/data/` e `test/presentation/` para mutações, filtros e privacidade, extensão de fixtures/runners visuais locais, documentação de progresso. Não criar arquivos vazios, novo modelo financeiro ou dependências. Manter testes históricos M5 e autenticação M4, adaptando somente expectativas do comportamento explicitamente alterado.

CA-07 mudança de data para outubro: após editar Alimentação para 200, saldo continua 650, novembro cai para 100 e outubro sobe para 250; após excluir Transporte, saldo 750 e novembro zero. Testar ida/volta tipo/categoria, datas futuras e desempates. Assertivas de consumo de limites permanecem testes puros existentes, sem construir telas/integração M7 agora.

## 8. Estratégia de qualidade e riscos

Em cada implementação autorizada: dart format ., flutter analyze, flutter test --concurrency=1 e git diff --check, sequenciais; registrar contagens/diagnósticos reais, sem meta artificial de quantidade. Fakes controlados para falhas, páginas e eventos de sessão; testes SDK/regras somente em emuladores demo-bolsozen com guardas antes de criar dados locais. Operações remotas exigem roteiro/autorização próprios e não são condição implícita deste plano.

Capturas Flutter reais com fixtures identificadas, comparadas à prancha; renderer de testes não equivale a homologação Android/Web. MSI/Chrome apenas quando disponíveis e autorizados, uma compilação por vez; parar em OOM sem repetição automática. Nenhuma obrigação de retomar a extensa homologação M5.6 dispensada. Backlog cumulativo M4/M5 continua no M9.

Riscos: conteúdo externo alterado durante formulário/paginação; fuso/data sem edição acidental; SDK confirmar commit e rede falhar antes da recarga; reexecução indevida de escrita; mistura de UID; custo de carga completa; depreciações do SDK. Mitigações: identidade imutável, revalidação/carga compartilhada, resultados explícitos e testes determinísticos. Não usar lista filtrada para cálculos financeiros nem remover item antes do servidor.

## 9. Decisões aprovadas e próximos passos

1. Plano/subetapas e M6.1–M6.4 aprovados; M6.5 autorizado e entregue para revisão. Não iniciar M6.6 automaticamente.
2. Extensão opcional expectedUserId a update/delete aprovada e implementada, mantendo UID real do FirebaseSession e chamadas antigas.
3. Menu Material por item, confirmação e reutilização TEL-05 aprovados no plano; implementação apenas nas autorizações M6.2/M6.3.
4. Combinação local dos filtros/busca e controles ampliados implementados no M6.4 autorizado; aguardar revisão.
5. Ocultação somente do Saldo total durante a sessão implementada no M6.5 autorizado. Preservadas telas/identidade e exclusões de escopo expressas do usuário.

Não avançar automaticamente para M6.6. Plano e anotações pós-commit continuam fora do commit M5. Entregas M6.1–M6.5 descritas acima permanecem sem commit; nenhuma escrita Firebase remota, alteração de regras/índices, dependências, Gradle, push ou deploy.
