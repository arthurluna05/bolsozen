# BolsoZen — 02. Requisitos funcionais, dados e regras financeiras

**Versão:** 1.0  
**Convenções:** `RF` = requisito funcional; `RN` = regra de negócio; `RNF` = não funcional; `P0` = obrigatório para funcionamento; `P1` = obrigatório para o MVP completo; `P2` = melhoria pós-MVP.  
**Fonte funcional:** este documento prevalece sobre números e datas ilustrativos das imagens do protótipo.

## 1. Requisitos funcionais

### 1.1 Autenticação e perfil

| ID | Pri. | Requisito |
|---|---|---|
| RF-01 | P0 | Cadastrar usuário com nome, e-mail e senha e confirmação da senha |
| RF-02 | P0 | Entrar com e-mail e senha via Firebase Authentication |
| RF-03 | P0 | Manter sessão persistente entre aberturas do aplicativo |
| RF-04 | P0 | Encerrar sessão e retornar à área pública |
| RF-05 | P1 | Recuperar senha enviando e-mail pelo Firebase |
| RF-06 | P1 | Mostrar mensagens compreensíveis para senha incorreta, cadastro existente, e-mail inválido e indisponibilidade de rede |
| RF-07 | P1 | Exibir perfil mínimo com nome, e-mail e botão “Sair” |

Validação de cadastro: nome com 2 a 80 caracteres úteis; e-mail com formato válido e normalizado para comparação; senha com **mínimo de 8 caracteres no app**; confirmação deve coincidir; formulário bloqueado enquanto envia. A senha nunca é salva no Firestore ou em logs. Termos e Política de Privacidade **não devem apresentar links falsos**: para a entrega, fornecer textos/páginas reais ou retirar a caixa de aceite até disponibilizá-los.

### 1.2 Dashboard

| ID | Pri. | Requisito |
|---|---|---|
| RF-08 | P0 | Mostrar saldo global derivado de todas as transações |
| RF-09 | P0 | Mostrar total de receitas e despesas do mês de referência |
| RF-10 | P1 | Mostrar gastos por categoria, com valores e percentuais do total de despesas do mês |
| RF-11 | P1 | Mostrar as transações recentes ordenadas por data e critério secundário estável |
| RF-12 | P1 | Permitir ocultar/mostrar valores no cartão de saldo durante a sessão de uso |
| RF-13 | P1 | Atalho “+” para lançar uma transação |

O cartão “Meta do mês” da referência deve ser entendido como **percentual de uso do orçamento total configurado no mês**. Se não houver limites definidos, mostrar “Defina limites” ou estado neutro, **não 0% como se fosse meta existente**. Quando há limites, `percentual = despesas nas categorias com limite / soma dos limites dessas categorias × 100`, com indicação clara do que o indicador representa. Se o valor ultrapassar 100%, não truncar o número textual (somente a barra gráfica pode saturar).

### 1.3 Transações

| ID | Pri. | Requisito |
|---|---|---|
| RF-14 | P0 | Cadastrar receita ou despesa com valor, categoria, data e descrição |
| RF-15 | P0 | Listar transações do usuário, da mais recente para a mais antiga |
| RF-16 | P0 | Editar uma transação existente |
| RF-17 | P0 | Excluir uma transação com confirmação |
| RF-18 | P1 | Filtrar histórico entre Todas, Receitas e Despesas |
| RF-19 | P1 | Buscar transações pelo texto da descrição e nome de categoria, nos dados carregados |
| RF-20 | P1 | Indicar data, categoria, descrição e valor com sinal/estilo apropriado |
| RF-21 | P1 | Mostrar feedback de sucesso, erro, carregamento e lista vazia |

**Campos do registro:**

| Campo | Tipo lógico | Obrigatório | Regra |
|---|---|---|---|
| `id` | string (ID do documento) | sim | Gerado pelo Firestore |
| `userId` | string | sim | UID autenticado; validado nas regras |
| `type` | `income` ou `expense` | sim | Somente esses dois valores |
| `amountCents` | inteiro | sim | Positivo; mínimo 1 centavo |
| `categoryId` | string | sim | Categoria válida para o tipo |
| `description` | string | sim | Texto com 1–120 caracteres, após trim |
| `occurredAt` | timestamp/data | sim | Data de referência da transação |
| `createdAt` | timestamp | sim | Registro da criação |
| `updatedAt` | timestamp | sim | Registro da última atualização |

A interface pode exibir “Conta principal” como campo **informativo e não editável**. Não criar entidade de contas bancárias no MVP. A localização da data do movimento deve respeitar o fuso local na apresentação e agrupamento por calendário.

### 1.4 Orçamentos mensais

| ID | Pri. | Requisito |
|---|---|---|
| RF-22 | P1 | Exibir seletor de mês/ano, com mês corrente como padrão |
| RF-23 | P1 | Configurar limite mensal para categoria de despesa |
| RF-24 | P1 | Editar ou remover limite mensal existente |
| RF-25 | P1 | Mostrar consumido, limite e percentual de utilização por categoria |
| RF-26 | P1 | Destacar limites em atenção e ultrapassados |

Limite deve ser positivo, em centavos inteiros. Apenas categorias de **despesa** recebem limite. Sem limite cadastrado, a tela deve indicar claramente que o usuário ainda não configurou orçamento. Excluir um limite não exclui transações.

### 1.5 Relatórios

| ID | Pri. | Requisito |
|---|---|---|
| RF-27 | P1 | Mostrar despesas do mês selecionado e comparação com mês anterior |
| RF-28 | P1 | Mostrar distribuição percentual de despesas por categoria |
| RF-29 | P1 | Mostrar evolução mensal das despesas em gráfico simples (até 6 meses incluindo o selecionado) |
| RF-30 | P1 | Exibir estados sem dados nos gráficos, sem números inventados |

As abas “Visão geral”, “Categorias” e “Evolução” são vistas da **mesma fonte de dados**. Se houver implementação por etapas, entregar a primeira aba funcional antes das outras; não deixar abas clicáveis que apenas exibem conteúdo fictício.

## 2. Regras de negócio financeiras

### RN-01 — Precisão monetária

Persistir valores monetários como inteiro de centavos (`amountCents`, `limitCents`). **Nunca usar `double`/ponto flutuante como fonte de verdade monetária.** Converter entradas “120,50” para 12050 centavos com parsing controlado e exibir em formato `R$ 120,50` (pt-BR). Valor de transação não pode ser zero ou negativo; o sinal decorre do tipo.

### RN-02 — Saldo total

`saldoTotalCents = Σ(amountCents de income, todo o histórico) - Σ(amountCents de expense, todo o histórico)`.

Exemplo: receita R$ 1.000,00 e despesas de R$ 250,00 + R$ 100,00 → saldo R$ 650,00. Sem transações, saldo = R$ 0,00. Saldo negativo é permitido. **Não somar o saldo novamente sobre o resultado anterior:** sempre derivar dos registros válidos.

### RN-03 — Totais por mês

No mês `AAAA-MM`, `receitasMes = soma de income com occurredAt no mês` e `despesasMes = soma de expense com occurredAt no mês`. As datas são agrupadas conforme o calendário local definido pelo aplicativo. A seleção de mês não altera o saldo global; altera apenas indicadores mensais.

### RN-04 — Participação por categoria

`participacaoCategoria = despesasCategoriaNoMes / despesasTotaisNoMes × 100` se `despesasTotaisNoMes > 0`; caso contrário, exibir vazio ou 0% contextualizado. Valores de receita **não** entram no gráfico de gastos por categoria. Os percentuais podem apresentar pequenas diferenças de arredondamento no display.

### RN-05 — Consumo de orçamento

Para categoria `C` no mês `M`:

`consumidoCents = soma das despesas da categoria C com occurredAt em M`  
`percentualUtilizado = consumidoCents / limitCents × 100`, quando limite > 0.

Sinalizações sugeridas:
- **Abaixo de 80%:** normal.
- **De 80% até menos de 100%:** atenção.
- **100% ou mais:** limite atingido/ultrapassado.

Usar textos e ícones em conjunto com cores; não depender exclusivamente de vermelho ou verde.

### RN-06 — Orçamento por competência mensal

Os limites são cadastrados por chave de mês `YYYY-MM`, por usuário e categoria. **Não copiar automaticamente** os limites para meses futuros. A navegação entre meses mostra o que está cadastrado para cada mês.

### RN-07 — Edição e exclusão

Editar valor, tipo, categoria ou data deve recalcular todos os agregados impactados, inclusive se a transação mudar de mês. Excluir remove sua contribuição dos totais, gráficos e limites. Pedir confirmação antes da exclusão e mostrar erro se a operação falhar.

### RN-08 — Ordenação e desempate

Ordenar por `occurredAt` descendente; para datas iguais, usar `createdAt` descendente e ID como desempate estável quando necessário. Datas do protótipo (ex.: janeiro de 2025) são **exemplos visuais**, não valores fixos no código.

### RN-09 — Comparação com mês anterior

`variacao = (despesasMesAtual - despesasMesAnterior) / despesasMesAnterior × 100` quando mês anterior > 0. Se o mês anterior foi zero, exibir “Sem base de comparação”, e não uma porcentagem infinita ou incorreta. A cor da variação deve refletir o significado claramente; uma queda de despesas pode ser apresentada como redução, não como erro.

### RN-10 — Sem demonstração enganosa

Conta recém-criada inicia vazia. Mock data somente em testes, fixtures de desenvolvimento isoladas ou modo demonstração **explicitamente identificado**, não como conteúdo persistente real.

## 3. Categorias iniciais

| `categoryId` | Rótulo | Tipo | Sugestão de ícone |
|---|---|---|---|
| `food` | Alimentação | despesa | talheres |
| `transport` | Transporte | despesa | carro/ônibus |
| `shopping` | Compras | despesa | sacola |
| `leisure` | Lazer | despesa | controle |
| `health` | Saúde | despesa | coração/cruz |
| `education` | Educação | despesa | livro |
| `housing` | Moradia | despesa | casa |
| `other_expense` | Outros | despesa | mais opções |
| `salary` | Salário | receita | seta para cima |
| `other_income` | Outras receitas | receita | carteira/seta |

IDs internos estáveis, rótulos traduzíveis para interface PT-BR. Categorias não exigem documentos próprios no Firestore no MVP.

## 4. Modelo de dados sugerido — Firestore

```text
users/{uid}
  displayName: string
  email: string
  createdAt: timestamp

users/{uid}/transactions/{transactionId}
  userId: string
  type: "income" | "expense"
  amountCents: integer
  categoryId: string
  description: string
  occurredAt: timestamp
  createdAt: timestamp
  updatedAt: timestamp

users/{uid}/budgets/{YYYY-MM_categoryId}
  userId: string
  monthKey: "YYYY-MM"
  categoryId: string
  limitCents: integer
  createdAt: timestamp
  updatedAt: timestamp
```

**Segurança obrigatória:** leitura/escrita de `users/{uid}` e subcoleções apenas se `request.auth != null && request.auth.uid == uid`, com validação de campos, tipos, valores permitidos e limites razoáveis. O cliente jamais deve conseguir inserir uma transação com `userId` de outra pessoa, nem alterar `userId` de um registro. Regras Firestore devem ser versionadas e testadas por emulador de segurança antes de considerar prontas. **Não abrir regras globais de leitura/escrita em produção.**

As queries que exigirem índices compostos devem ter seu índice documentado/versionado. Os agregados podem ser calculados no cliente para volumes pequenos do MVP, desde que carregamento e escopo do usuário sejam controlados; evitar carregar indefinidamente todos os registros sem estratégia de paginação caso o conjunto cresça. Não guardar totais duplicados como fonte de verdade na primeira versão.

## 5. Requisitos não funcionais

| ID | Pri. | Requisito |
|---|---|---|
| RNF-01 | P0 | Aplicativo Flutter Android, com versão SDK compatível ao ambiente instalado |
| RNF-02 | P0 | UI pt-BR, formatação monetária e datas legíveis |
| RNF-03 | P0 | Segregação por UID e regras Firestore que neguem acesso entre usuários |
| RNF-04 | P0 | Validação de formulários e tratamento de erros de rede |
| RNF-05 | P1 | Responsividade em largura de celular comum e com teclado aberto |
| RNF-06 | P1 | Acessibilidade: contraste, alvos de toque, labels e escalonamento de texto |
| RNF-07 | P1 | Componentes reutilizáveis e separação razoável de UI, dados e domínio |
| RNF-08 | P1 | `flutter analyze` sem erros; testes de lógica financeira e fluxos críticos |
| RNF-09 | P1 | Dados atualizados na UI após alterações sem reiniciar o aplicativo |
| RNF-10 | P1 | Tela de carregamento, estado vazio e feedback de falha para chamadas remotas |

## 6. Regras de priorização

1. P0 (autenticação, base de dados, CRUD e saldo) antes de P1.
2. P1 (orçamento, relatórios, refinamento) depois da consistência financeira.
3. P2 somente se o MVP estiver concluído e houver autorização explícita.
4. As telas devem refletir funcionalidades reais; não criar navegação ou botões decorativos sem ação.

## 7. Dependências de terceiros

- `firebase_core`, `firebase_auth`, `cloud_firestore` para serviços Firebase.
- `intl` para localização/formatação.
- Biblioteca de gráficos **somente se necessária** e após avaliar manutenção e compatibilidade.
- Estado: escolher solução simples adequada ao tamanho do projeto; documentar a decisão no plano técnico e manter consistência.

**Observação:** a configuração manual do Firebase Console, Android App ID e geração de arquivos pelo FlutterFire depende do ambiente real. Registrar os passos quando não forem automatizáveis; nunca substituir o Firebase real por uma implementação fake e declarar a etapa como pronta.
