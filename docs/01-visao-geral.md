# BolsoZen — 01. Visão geral do produto

**Versão:** 1.0  
**Status:** especificação-base para desenvolvimento do MVP acadêmico  
**Plataforma prioritária:** Android (Flutter)  
**Idioma / localidade:** português do Brasil (`pt_BR`), valores em BRL (`R$`)  
**Documentos relacionados:** `02-requisitos.md`, `03-jornadas.md`, `04-design-system.md`, `05-criterios-aceite.md`.

## 1. Resumo executivo

**BolsoZen** é um aplicativo móvel de controle financeiro pessoal que permite registrar receitas e despesas, organizar transações em categorias, acompanhar um saldo calculado, configurar limites mensais de despesas e consultar relatórios simples. Seu diferencial, no MVP, é a experiência objetiva e acolhedora: informação clara, poucos passos para lançar uma transação e visualização rápida do orçamento.

A implementação deve ser **real e demonstrável**, não um protótipo navegável alimentado por dados falsos. O app utilizará **Flutter/Dart**, **Firebase Authentication** (e-mail e senha) e **Cloud Firestore** para persistência dos registros associados a cada usuário.

## 2. Problema

Pessoas que desejam controlar gastos do dia a dia frequentemente dependem de anotações dispersas, planilhas difíceis de atualizar ou aplicativos com funcionalidades excessivas. Isso dificulta saber quanto entrou, quanto saiu e se os gastos de determinada categoria estão próximos do limite estabelecido.

## 3. Público-alvo

Pessoas que precisam de uma maneira simples de monitorar finanças individuais, especialmente estudantes e jovens adultos que estão começando a organizar o próprio orçamento. O MVP contempla **uso individual**, não contas compartilhadas.

## 4. Objetivo principal

Permitir que o usuário responda com facilidade:

1. Quanto tenho de saldo registrado?
2. Quanto recebi e gastei no mês selecionado?
3. Em quais categorias concentrei minhas despesas?
4. Quanto já utilizei dos limites definidos para cada categoria?
5. Quais transações compõem esses valores?

## 5. Objetivos específicos

- Criar conta, entrar e sair com autenticação segura.
- Registrar, consultar, editar e excluir receitas e despesas com armazenamento persistente.
- Associar cada despesa a uma categoria padrão.
- Definir e editar limites mensais por categoria.
- Mostrar indicadores e relatórios produzidos a partir de transações reais do usuário.
- Exibir estados de carregamento, ausência de dados e erros de forma compreensível.
- Seguir o protótipo visual aprovado, com adaptação responsiva ao dispositivo.

## 6. Escopo do MVP

| Incluído | Observação |
|---|---|
| Boas-vindas | Acesso a login e cadastro |
| Cadastro e login por e-mail/senha | Firebase Authentication |
| Recuperação de senha por e-mail | Envio por Firebase Authentication |
| Sessão persistente e logout | Redirecionamento conforme autenticação |
| Dashboard | Saldo total, receitas/despesas do mês, categorias, transações recentes |
| Transações | Criar, listar, filtrar, editar, excluir |
| Categorias predefinidas | Alimentação, Transporte, Compras, Lazer, Saúde, Educação, Moradia, Outros; receitas usam uma classificação simples |
| Orçamentos mensais | Limite por categoria de despesa e acompanhamento do consumo |
| Relatórios básicos | Evolução mensal e distribuição por categoria, somente dados do usuário |
| Perfil mínimo | Nome, e-mail, ação de sair; tela simples para completar navegação do protótipo |
| Dados na nuvem | Firestore, segregados por UID |
| Segurança | Regras de acesso, validações e testes dos fluxos relevantes |

### Fora do MVP

- Integração bancária / Open Finance, leitura de notificações ou importação automática de extrato.
- Cartões de crédito, parcelamento, faturas, múltiplas contas bancárias reais ou conciliação bancária.
- Transferências entre contas, investimentos, metas de patrimônio ou rendimento automático.
- IA, chatbot, recomendações financeiras, assinaturas ou notificações push.
- Compartilhamento de orçamento familiar, painel administrativo, pagamentos ou PIX.
- Versões para web e iOS como critérios obrigatórios de entrega.

**Regra de escopo:** nomes ou elementos visuais presentes no protótipo não autorizam automaticamente funcionalidades fora do MVP. Por exemplo, o campo **Conta** na tela de transação deve ser simplificado para uma conta lógica fixa, **Conta principal**, sem CRUD de contas; o objetivo é preservar o layout sem criar um módulo bancário adicional.

## 7. Premissas e decisões de produto

1. **Moeda única:** BRL; não há conversão de moedas.
2. **Conta lógica única:** todo registro pertence à “Conta principal” do usuário.
3. **Saldo total:** soma de todas as receitas menos soma de todas as despesas registradas pelo usuário em todo o histórico, sem saldo inicial separado. Pode ser negativo.
4. **Indicadores mensais:** receitas e despesas consideram o mês selecionado; na abertura, mês corrente do dispositivo.
5. **Transação lançada conta imediatamente:** não haverá status “pago/pendente” no MVP. Uma despesa registrada com data futura entra nos cálculos do período de sua data, não do mês atual.
6. **Data do movimento:** cada transação usa a data informada pelo usuário, não a data de criação do registro para os cálculos financeiros.
7. **Limites mensais:** por categoria de despesa, por mês/ano; não são transportados automaticamente para o mês seguinte.
8. **Categorias:** conjunto inicial predefinido; categorias personalizadas não são obrigatórias.
9. **Privacidade:** cada usuário visualiza e altera apenas seus próprios dados; não existe agregação entre contas.
10. **Dados de demonstração:** valores presentes no protótipo são ilustrativos. Não exibir R$ 5.320, R$ 7.500 ou transações fictícias como se fossem dados reais de uma conta recém-criada.

## 8. Telas do produto

| Tela | Propósito | Acesso |
|---|---|---|
| Boas-vindas | Apresentar a proposta e conduzir à autenticação | Público |
| Login | Autenticar usuário existente | Público |
| Cadastro | Criar uma conta | Público |
| Dashboard / Início | Mostrar panorama mensal e saldo global | Autenticado |
| Nova/Editar transação | Salvar informações financeiras | Autenticado |
| Histórico / Transações | Buscar, filtrar e gerenciar transações | Autenticado |
| Orçamento | Ver e editar limites por categoria | Autenticado |
| Relatórios | Consultar evolução e composição das despesas | Autenticado |
| Perfil mínimo | Ver identidade da conta e sair | Autenticado; **tela adicional necessária**, não detalhada na prancha |

## 9. Indicadores de sucesso (entrega acadêmica)

- Usuário cria conta, entra, encerra e retoma sessão com sucesso.
- Dados criados continuam disponíveis após fechar e reabrir o aplicativo e após autenticar novamente.
- Inclusão, edição e remoção de uma transação refletem no dashboard, histórico, orçamento e relatórios.
- Usuário A não consegue acessar dados do usuário B, inclusive em testes das regras de segurança.
- Fluxo básico de lançar despesa funciona em poucos passos e possui feedback de sucesso/erro.
- Interface não apresenta cortes de conteúdo em telas Android comuns e responde a teclado/rolagem.
- `flutter analyze` sem erros e testes relevantes aprovados.
- APK Android de release gerado e instalado em dispositivo/emulador compatível.

## 10. Restrições e riscos

| Risco | Estratégia de mitigação |
|---|---|
| Ampliação excessiva do escopo | Tratar todo recurso adicional como pós-MVP |
| Protótipo sem dados/estados completos | Documentar telas vazias, carregamento, erros e validações |
| Configuração externa do Firebase | Registrar tarefas manuais e não simular integração |
| Regras de segurança incorretas | Testar acesso autenticado, sem autenticação e com UID diferente |
| Divergência visual | Implementar tela a tela e comparar screenshots |
| Erros em operações financeiras | Representar valores como **centavos inteiros**; testar agregações e atualização após CRUD |

## 11. Definição de pronto do MVP

MVP pronto = funcionalidades P0 e P1 de `02-requisitos.md` implementadas conforme `05-criterios-aceite.md`, teste manual dos fluxos, dados reais persistidos, regras Firestore verificadas, interface alinhada ao design, README de execução e APK Android gerado. Qualquer pendência deve ser registrada explicitamente; o Codex não deve declarar como implementado algo que apenas foi esboçado.
