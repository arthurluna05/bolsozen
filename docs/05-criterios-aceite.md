# BolsoZen — 05. Critérios de aceite e plano de validação

**Versão:** 1.0  
**Finalidade:** estabelecer testes verificáveis para cada requisito, evitando concluir etapas apenas pela aparência.  
**Ambiente-alvo:** Flutter Android + Firebase Authentication + Cloud Firestore; Firebase Emulator Suite recomendado para testes de segurança e integrações.

## 1. Critério geral de conclusão de uma fase

Uma fase só é marcada como **Concluída** quando:

- O código previsto foi implementado e não depende de placeholders enganosos.
- Os critérios de aceite da fase passaram em execução real ou teste automatizado.
- `dart format .`, `flutter analyze` e `flutter test` foram executados; resultados documentados.
- Erros de rede, validação e estados vazios relevantes foram tratados.
- Regras Firestore e integração externa aplicáveis foram verificadas, quando a fase envolve persistência.
- A interface foi comparada visualmente com a referência, quando a fase envolve UI.
- `docs/PROGRESSO.md` informa evidências, testes, limitações e pendências.

**Proibido:** marcar “Concluída” uma etapa que não foi testada por falta de emulador, credenciais, projeto Firebase ou conectividade. Nesses casos, usar **Bloqueada** ou **Implementada / Não validada**.

## 2. Conjunto de dados de teste controlados

Utilizar usuário A de teste e usuário B independente no ambiente de desenvolvimento. Nunca incluir credenciais reais no repositório. Partir de banco limpo, ou dados criados explicitamente pelo teste.

### Conjunto financeiro T1

| Tipo | Data | Categoria | Valor |
|---|---|---|---:|
| Receita | 2026-11-03 | Salário | R$ 1.000,00 |
| Despesa | 2026-11-04 | Alimentação | R$ 250,00 |
| Despesa | 2026-11-05 | Transporte | R$ 100,00 |
| Despesa | 2026-10-12 | Lazer | R$ 50,00 |

**Resultados esperados:** saldo global R$ 600,00; novembro/2026: receitas R$ 1.000,00, despesas R$ 350,00; outubro/2026: despesas R$ 50,00. O saldo global permanece R$ 600,00 ao mudar o mês selecionado.

### Conjunto de orçamento T2 (novembro/2026)

| Categoria | Limite | Despesas no mês | Consumo esperado |
|---|---:|---:|---:|
| Alimentação | R$ 300,00 | R$ 250,00 | 83,33% |
| Transporte | R$ 200,00 | R$ 100,00 | 50,00% |

Somente as categorias com limite entram no cálculo do indicador de uso total do orçamento: (250 + 100) / (300 + 200) = **70%**. Alertar Alimentação por ultrapassar 80%; Transporte permanece normal. A apresentação pode arredondar 83,33% para 83% ou uma casa decimal, mantendo consistência.

## 3. Critérios de aceite por funcionalidade

### CA-01 — Abertura, sessão e roteamento (`RF-01` a `RF-04`)

**Dado** usuário sem sessão, **quando** abrir o app, **então** verá Boas-vindas/Login e não acessará rota privada.

**Dado** usuário autenticado, **quando** fechar e reabrir o app, **então** acessará área privada após verificação da sessão, sem novo login.

**Dado** usuário autenticado, **quando** tocar em **Sair**, **então** a sessão será encerrada e uma rota privada não poderá ser aberta sem autenticação.

**Evidência:** teste de widget/integração ou gravação da navegação, mais verificação real com Firebase.

### CA-02 — Cadastro (`RF-01`, `RF-06`)

- Nome vazio ou com menos de dois caracteres: bloquear envio e mostrar validação.
- E-mail inválido: bloquear e mostrar validação.
- Senha com menos de oito caracteres: bloquear e mostrar validação.
- Confirmação diferente: bloquear e explicar divergência.
- E-mail existente: mostrar erro claro sem travar o formulário.
- Cadastro válido: criar usuário no Firebase, registrar perfil mínimo e entrar no Dashboard.
- Senhas jamais aparecem em logs nem em documentos Firestore.

### CA-03 — Login e recuperação (`RF-02`, `RF-05`, `RF-06`)

- Credenciais válidas: login e acesso ao dashboard.
- Credenciais incorretas: mensagem genérica e formulário recuperável.
- Sem rede: feedback de falha e opção de tentar novamente.
- Recuperação: e-mail válido provoca solicitação de recuperação via Firebase; confirmação na UI deve evitar expor se uma conta existe.
- Durante envio, botão desabilitado para evitar duplicações.

### CA-04 — Dashboard e saldo (`RF-08` a `RF-13`, `RN-02`, `RN-03`)

**Dado** conjunto T1, **quando** abrir o Dashboard, **então** saldo total será R$ 600,00 e, em novembro/2026, receitas R$ 1.000,00 e despesas R$ 350,00.

**Quando** selecionar outubro/2026 nas visualizações mensais, **então** despesas correspondentes serão R$ 50,00; o saldo global não muda.

**Quando** tocar no olho do saldo, **então** o valor se oculta; ao tocar novamente, reaparece.

**Quando** usuário ainda não tiver transações ou limites, **então** mostrar dados zerados e estados vazios úteis, sem os números do protótipo.

### CA-05 — Criar transação (`RF-14`, `RN-01`)

- Exibir seletor Receita/Despesa, Valor, Categoria, Data, Descrição e Conta principal informativa.
- Aceitar entradas como `120`, `120,50` ou entrada monetária formatada via máscara coerente.
- Converter `R$ 120,50` para `12050` centavos, sem erros de arredondamento.
- Rejeitar zero, valor negativo e texto monetário inválido.
- Exigir categoria compatível e descrição não vazia.
- Salvar no Firestore na coleção do UID autenticado.
- Após salvar, atualizar histórico e indicadores sem reiniciar o aplicativo.
- Em erro remoto, manter campos preenchidos e permitir tentar novamente.

### CA-06 — Histórico e filtros (`RF-15`, `RF-18` a `RF-21`)

- Conjunto T1 aparece da data mais recente para a mais antiga.
- Chip **Receitas** mostra somente entradas; **Despesas**, somente saídas; **Todas**, ambas.
- Pesquisa por “Alimentação” ou texto de descrição retorna itens correspondentes entre os carregados.
- Pesquisa sem correspondência apresenta “Nenhuma transação encontrada”.
- Ícones, datas e valores refletem tipo e categoria corretos.
- Se lista estiver vazia, exibir ação para criar primeira transação.

### CA-07 — Editar e excluir (`RF-16`, `RF-17`, `RN-07`)

1. Com T1, editar despesa Alimentação de R$ 250,00 para R$ 200,00.
2. **Esperado:** saldo global aumenta de R$ 600,00 para **R$ 650,00**, despesas novembro caem de R$ 350,00 para **R$ 300,00** e consumo de Alimentação cai de 83,33% para **66,67%**.
3. Transferir a data dessa transação de novembro para outubro: novembro perde R$ 200,00 e outubro ganha R$ 200,00; saldo global não muda.
4. Excluir transação Transporte de R$ 100,00 após confirmar: saldo sobe R$ 100,00 e dashboards/gráficos recalculam.
5. Cancelar exclusão: nenhum dado alterado.
6. Simular falha de exclusão: item permanece até a confirmação real da operação.

### CA-08 — Limites mensais (`RF-22` a `RF-26`, `RN-05`, `RN-06`)

- Criar limites do conjunto T2.
- Alimentação exibe R$ 250,00 / R$ 300,00 e cerca de 83,33%, com aviso de atenção.
- Transporte exibe R$ 100,00 / R$ 200,00 e 50%, sem aviso.
- Indicador global de uso do orçamento mostra 70% conforme RNF/RN definidos.
- Editar limite de Alimentação para R$ 200,00: percentual 125% e estado de limite ultrapassado.
- Remover limite: não exclui transações e categoria passa a não ter orçamento definido.
- Mudar para dezembro/2026: não herdar automaticamente os limites de novembro.
- Nunca dividir por zero nem exibir `NaN`/`Infinity`.

### CA-09 — Relatórios (`RF-27` a `RF-30`, `RN-04`, `RN-09`)

- T1 em novembro: despesas R$ 350,00; no mês anterior, R$ 50,00.
- Variação mês contra mês: **+600%** em despesas (350 versus 50).
- Distribuição em novembro: Alimentação ≈ 71,43%; Transporte ≈ 28,57%.
- Gráfico mensal reflete outubro e novembro, com datas coerentes.
- Se mês anterior tem zero despesas, exibir “Sem base de comparação”.
- Mês sem despesas: gráfico vazio/zero com explicação, sem categorias fictícias.
- Gráficos e legendas oferecem valores em texto ou semântica acessível.

### CA-10 — Segurança por usuário (`RNF-03`)

- Sem autenticação: negar leitura e escrita nas coleções privadas.
- Usuário A: pode ler/escrever seus próprios registros válidos.
- Usuário B: não consegue ler/editar/excluir transações e orçamentos de A, mesmo acessando diretamente o caminho Firestore de A.
- UID de documento não pode ser trocado, injetado ou falsificado pelo cliente.
- Regras validam tipos básicos e campos relevantes; dados inválidos são recusados.
- Testar regras com Firebase Emulator Suite e versioná-las.

### CA-11 — UI e navegação (`RNF-02`, `RNF-05`, `RNF-06`)

- Identidade cromática e tipográfica alinhada a `04-design-system.md`.
- Barra inferior nas cinco telas privadas principais com aba ativa correta.
- Botões Entrar, Criar conta, Salvar, Editar limites, Voltar e Sair funcionam.
- Nenhum overflow em larguras de aproximadamente 360, 390 e 412 dp, com teclado aberto.
- Campos exibem feedback adequado; texto ampliado permanece utilizável.
- Ícones possuem label semântico; dados não dependem apenas de cor.
- Screenshots comparados com protótipo, com diferenças relevantes registradas.

### CA-12 — Persistência e falhas (`RNF-04`, `RNF-09`, `RNF-10`)

- Criar transação, fechar app e reabrir: registro continua disponível após carregar dados.
- Logout/login na mesma conta: dados permanecem.
- Login em outra conta: dados da anterior não aparecem.
- Falha de conexão ou permissão: UI informa erro, sem indicar sucesso falso.
- Estados de carregamento e vazio aparecem em contexto adequado.

## 4. Matriz resumida de rastreabilidade

| Entrega | Requisitos | Aceites |
|---|---|---|
| Autenticação e perfil | RF-01 a RF-07 | CA-01, CA-02, CA-03, CA-10 |
| Dashboard | RF-08 a RF-13 | CA-04, CA-11 |
| CRUD de transações | RF-14 a RF-21 | CA-05, CA-06, CA-07, CA-12 |
| Orçamento | RF-22 a RF-26 | CA-08 |
| Relatórios | RF-27 a RF-30 | CA-09 |
| Segurança e qualidade | RNF-01 a RNF-10 | CA-10, CA-11, CA-12 |

## 5. Testes automatizados mínimos

### Unitários (domínio financeiro)

- Parsing pt-BR e conversão para centavos (incluindo `0`, entradas inválidas e precisão).
- Soma do saldo, totais mensais e agrupamento por categoria.
- Recalcular totais após alteração/exclusão.
- Consumo de limite (0%, 80%, 99,99%, 100%, >100%).
- Relatório e comparação com mês anterior zero.
- Ordenação por data com desempate.

### Widget tests

- Campos e validações de cadastro/login.
- Alternância Receita/Despesa e categorias compatíveis.
- Estado vazio de Dashboard/Histórico.
- Navegação da barra inferior.
- Formulário com erro de gravação simulado sem perder dados.

### Integração / Firebase Emulator Suite

- Registro, login, logout e sessão.
- Criar/editar/excluir transação em dados de teste.
- Regras Firestore com UID correto, UID incorreto e usuário desautenticado.
- Persistência, carregamento e isolamento entre contas.

## 6. Testes manuais em dispositivo/emulador

| ID | Ação | Esperado | Resultado |
|---|---|---|---|
| MAN-01 | Instalar e abrir APK limpo | Boas-vindas funciona | Pendente |
| MAN-02 | Criar conta nova | Autentica e abre dashboard vazio | Pendente |
| MAN-03 | Criar receita e despesa | Totais corretos e persistência | Pendente |
| MAN-04 | Editar e excluir | Valores recalculados | Pendente |
| MAN-05 | Definir orçamento | Consumo e alertas corretos | Pendente |
| MAN-06 | Abrir relatórios | Gráficos refletem transações | Pendente |
| MAN-07 | Deslogar e entrar novamente | Dados preservados, sessão correta | Pendente |
| MAN-08 | Entrar com segunda conta | Nenhum dado da primeira visível | Pendente |
| MAN-09 | Desativar internet | Erros tratados e sem falso sucesso | Pendente |
| MAN-10 | Usar teclado e texto grande | Sem sobreposição/overflow impeditivo | Pendente |
| MAN-11 | Comparar telas com referência | Diferenças importantes corrigidas | Pendente |
| MAN-12 | Gerar e instalar APK release | Compila e inicia corretamente | Pendente |

Codex deve atualizar resultados na documentação de progresso; não substituir “Pendente” por “Passou” sem realização efetiva.

## 7. Comandos de qualidade

Na raiz do repositório:

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --release
```

O comando de build final não substitui teste em execução. Se houver dependência do Firebase, a verificação de configuração e execução no dispositivo é obrigatória. Registrar versão do Flutter/ambiente no README.

## 8. Evidências para entrega acadêmica

- Repositório organizado com instruções de instalação.
- Documentos de visão geral, requisitos, jornadas, design system e aceite.
- Código-fonte Flutter e configurações Firebase apropriadas sem credenciais administrativas.
- Arquivo de regras Firestore e testes de segurança.
- Evidências de `flutter analyze`/`flutter test`.
- Screenshots das telas principais preenchidas com dados de teste identificados.
- Vídeo ou demonstração do fluxo: cadastro → lançamento → dashboard → orçamento → relatórios → logout.
- APK release compilado e testado.

## 9. Checklist de homologação

- [ ] Requisitos P0 concluídos e validados.
- [ ] Requisitos P1 concluídos e validados.
- [ ] Cálculos financeiros aprovados com valores conhecidos.
- [ ] Firestore protegido por UID e regras testadas.
- [ ] Login, logout e sessão persistente funcionando.
- [ ] CRUD atualiza dashboard, orçamento e gráficos.
- [ ] Telas vazias/erro implementadas.
- [ ] Interface alinhada à prancha com revisão visual.
- [ ] Sem botões não funcionais ou dados falsos não identificados.
- [ ] Testes automatizados e manuais documentados.
- [ ] APK release executado com sucesso.
- [ ] README e documentação de entrega atualizados.
