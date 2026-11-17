# BolsoZen — 04. Design system e especificação visual

**Versão:** 1.0  
**Base visual:** prancha de prototipação BolsoZen com oito telas e painel lateral de identidade visual.  
**Implementação:** Flutter, Material Design 3, interface mobile-first e pt-BR.

> **Importante:** a imagem gerada é uma referência de aparência, não um arquivo Figma com medidas exatas. Este documento transforma as escolhas visuais em tokens implementáveis. Onde a prancha não oferece dimensões verificáveis, os valores abaixo são **especificações propostas**, que podem ser refinadas por comparação de screenshots.

## 1. Identidade

**Nome:** BolsoZen  
**Conceito:** finanças com tranquilidade, leveza e organização.  
**Personalidade visual:** confiável, amigável, limpa, serena, sem excesso de elementos decorativos.  
**Símbolo:** carteira verde com moeda dourada. O desenho exato da marca/ilustração precisa de um asset autorizado (SVG/PNG); não usar a captura inteira da prancha como ícone do app.

## 2. Tokens de cor

| Token | Hex | Uso |
|---|---|---|
| `primary` | `#0E7D68` | Marca, botões primários, destaques e estado ativo |
| `secondary` | `#10B981` | Progressos, detalhes e gráficos |
| `mint` | `#A7F3D0` | Suporte e fundos suaves |
| `mintSurface` | `#E9FDF6` | Cartões/chips secundários |
| `background` | `#FFFFFF` | Fundo das telas |
| `surface` | `#FFFFFF` | Cartões e formulários |
| `surfaceMuted` | `#F3F4F6` | Campo, divisores e áreas neutras |
| `textPrimary` | `#111827` | Títulos e texto principal |
| `textSecondary` | `#6B7280` | Textos explicativos e legendas |
| `success` | `#22C55E` | Feedback positivo (com rótulo) |
| `warning` | `#F59E0B` | Avisos de orçamento |
| `error` | `#EF4444` | Erros e despesas |
| `border` | `#E5E7EB` | Bordas suaves |

**Semântica:** valores de receitas podem usar verde escuro; valores de despesas, vermelho; valores de saldo positivo ou negativo devem ser acompanhados por sinal e rótulo, não só cor. Avisos críticos devem ter texto e ícone além da cor.

**Contraste:** verificar com WCAG (texto normal ao menos 4,5:1, quando aplicável). Caso `secondary` ou `mint` não ofereçam contraste suficiente para texto pequeno, usar `primary`/`textPrimary` para o texto, deixando as tonalidades claras no fundo.

## 3. Tipografia

Fonte de preferência: **Inter** se estiver configurada como asset/dependência; fallback **Roboto**/tipografia Material do sistema. Manter consistência de uma família no projeto.

| Estilo | Peso | Tamanho sugerido |
|---|---|---|
| Título grande / display curto | 700 | 28 sp |
| Título médio | 700 | 20 sp |
| Título pequeno | 600 | 16 sp |
| Corpo principal | 400 | 14 sp |
| Corpo de destaque | 600 | 14 sp |
| Legenda | 400 | 12 sp |
| Valor financeiro em destaque | 700 | 24–28 sp |

Respeitar escalonamento de fontes do dispositivo; não fixar containers apenas para caber o texto de uma captura.

## 4. Espaçamentos, raios e elevação

| Token | Valor sugerido |
|---|---|
| Espaçamento `xs` | 4 dp |
| Espaçamento `sm` | 8 dp |
| Espaçamento `md` | 12 dp |
| Espaçamento `base` | 16 dp |
| Espaçamento `lg` | 24 dp |
| Espaçamento `xl` | 32 dp |
| Padding horizontal de tela | 16 dp |
| Radius de campo/chip | 10–12 dp |
| Radius de card | 14–18 dp |
| Radius botão principal | 12 dp |
| Radius FAB | circular |
| Altura mínima alvo de toque | ~48 dp |
| Elevação de cartão | sutil (0–2) |

Usar **SafeArea** e rolagem vertical nos formulários. Em celulares menores, priorizar conteúdo acessível em vez de tentar manter todas as informações acima da dobra.

## 5. Componentes

### 5.1 Botões

- **Primário:** fundo `primary`, texto branco, altura ~48 dp, borda arredondada. Exemplos: **Entrar**, **Criar conta**, **Salvar transação**.
- **Secundário:** fundo `mintSurface`, borda suave `secondary`, texto `primary`. Exemplos: **Criar conta** na tela inicial e **Editar limites**.
- **Texto:** para voltar ou ações auxiliares, como **Já tenho conta**.
- **Carregamento:** botão desabilitado durante operação, com indicador legível.

### 5.2 Campos de formulário

Borda suave, ícone à esquerda opcional, rótulo claro, placeholder, indicação de obrigatório e erro abaixo do campo. Teclados adequados (`emailAddress`, numérico decimal para valores), foco correto, botão para mostrar senha e ação de avançar entre campos.

### 5.3 Chips e seletores

Chips pill para filtros (Todas, Receitas, Despesas); toggle segmentado para tipo de transação. Estado selecionado claramente destacado por fundo, borda, texto e/ou ícone.

### 5.4 Cartões financeiros

- Card principal de saldo com preenchimento `primary` e alto contraste.
- Pequenos cards para receitas, despesas e percentual de orçamento.
- Cards de categorias com ícone colorido, nome, valor e progresso.
- Evitar sombras pesadas, gradientes excessivos ou cartões aninhados demais.

### 5.5 Lista de transações

Ícone da categoria em fundo pastel; título com descrição, subtítulo com categoria/data, valor alinhado à direita. Receita com sinal `+`, despesa com sinal `−`. Área tocável com affordance de edição/detalhes. Separadores discretos.

### 5.6 Navegação inferior

Cinco entradas: Início, Transações, Orçamento, Relatórios, Perfil. Ícones estilo Material/Lucide equivalente; rótulos curtos. Aba selecionada em `primary` com fundo `mintSurface` ou destaque equivalente. Manter consistência em todas as telas principais.

### 5.7 Gráficos

- Gráfico de linhas para evolução mensal, com eixo de meses e valores formatados.
- Gráfico de rosca para proporção de despesas por categoria.
- Barras/progressos para categorias e limites.
- Todo gráfico deve oferecer rótulos ou legenda textual acessível; estados vazios não exibem valores fictícios.

## 6. Especificação por tela

### TEL-01 — Boas-vindas

Fundo branco, identidade BolsoZen centralizada, subtítulo acolhedor, ilustração financeira suave, botões **Entrar** (primário) e **Criar conta** (secundário) próximos à parte inferior. O carrossel/pontos da prancha são **apenas decorativos no MVP** e podem ser omitidos para não sugerir telas inexistentes.

### TEL-02 — Login

Seta de retorno, título “Entrar no BolsoZen”, descrição curta, campos E-mail e Senha, link **Esqueci minha senha**, botão **Entrar**, divisor/área com **Criar conta**, selo informativo de autenticação segura. Sem e-mail ou senha de exemplo preenchidos por padrão.

### TEL-03 — Cadastro

Título “Criar sua conta”, campos Nome, E-mail, Senha, Confirmar senha, botão **Criar conta** e link **Já tenho conta**. Se a caixa de Termos/Privacidade for mantida, os links devem abrir políticas reais fornecidas pelo projeto.

### TEL-04 — Dashboard

Saudação com avatar simples (inicial do nome), eventual ícone de sino **somente se houver funcionalidade real**; caso contrário, omitir sino. Card grande Saldo total com botão de ocultar. Três indicadores: receitas, despesas e uso total de limites quando existentes. Barras por categoria, transações recentes, FAB `+` e barra inferior. A área pode rolar verticalmente.

### TEL-05 — Nova transação

Cabeçalho e seta de retorno; seletor Receita/Despesa, valor, categoria, data, descrição e “Conta principal” informativa; botão **Salvar transação**. Tela deve caber com teclado aberto por rolagem. Edição reutiliza o formulário com título e dados preexistentes, usando ação **Salvar alterações**.

### TEL-06 — Histórico

Título **Transações**, busca com filtro, chips de tipo, agrupamento por data, linha com ícone/descrição/categoria/valor e barra inferior. Os itens devem oferecer ações reais de editar/excluir via toque ou menu contextual.

### TEL-07 — Orçamento

Título **Orçamento mensal**, seletor de mês, aviso de consumo elevado **somente quando aplicável**, lista de categorias com valor consumido/limite e indicador circular ou linear, botão **Editar limites**, barra inferior. Sem limite cadastrado, mostrar estado inicial e CTA.

### TEL-08 — Relatórios

Título **Relatórios**, abas Visão geral/Categorias/Evolução, cartão de total mensal e comparação, gráfico de linha e donut/legenda, barra inferior. Separar visualmente percentuais de distribuição dos percentuais de orçamento para evitar ambiguidade.

### TEL-09 — Perfil mínimo (complementar)

A prancha traz o item **Perfil** na navegação, mas não desenha sua tela. Criar uma tela consistente com o design: avatar com inicial, nome, e-mail, card simples “Minha conta” e botão **Sair**. Sem opções extras que não tenham funcionamento real.

### TEL-10 — Recuperar senha (complementar)

A prancha traz o link **Esqueci minha senha**, mas não a tela. Criar formulário simples com E-mail, instrução e botão **Enviar link de recuperação**, além de retorno ao login.

## 7. Estados visuais obrigatórios

Para cada tela principal, contemplar pelo menos:

- **Inicial/carregando:** skeleton discreto ou `CircularProgressIndicator`.
- **Vazio:** ícone/ilustração neutra e chamada para ação.
- **Erro:** texto amigável e ação de tentar novamente.
- **Sucesso:** snackbar ou mensagem de confirmação após salvar.
- **Campos inválidos:** borda/mensagem de erro sem quebrar layout.
- **Valores protegidos:** saldo oculto (por exemplo, `••••••`) quando usuário tocar no ícone de olho.

## 8. Acessibilidade e responsividade

1. Usar `SafeArea`, `SingleChildScrollView` e layouts flexíveis onde fizer sentido.
2. Testar ao menos em largura compacta (~360 dp) e padrão (~390–412 dp), com texto aumentado.
3. Não cortar quantias longas; considerar `FittedBox` ou adaptação controlada de tipografia.
4. Labels semânticos para ícones, campos e gráficos.
5. Alvos de toque adequados e feedback de interação.
6. Verificar contraste, tema claro e orientação retrato. Tema escuro não é obrigatório no MVP.
7. Não reproduzir a barra de status do iPhone desenhada na imagem; usar status bar nativa do dispositivo Android.

## 9. Organização sugerida de tokens Flutter

```text
lib/
  core/
    theme/
      app_colors.dart
      app_spacing.dart
      app_theme.dart
  shared/
    widgets/
      primary_button.dart
      empty_state.dart
      transaction_tile.dart
      category_icon.dart
      budget_progress.dart
```

Esta estrutura é uma sugestão inicial, não uma obrigação de criar arquivos vazios. Codex deve adequá-la à arquitetura escolhida no planejamento.

## 10. Critério de fidelidade visual

Para cada tela:

1. Abrir imagem da referência correspondente.
2. Implementar o layout com dados reais ou estados de teste claramente identificados.
3. Capturar screenshot do app no emulador no mesmo tamanho de referência, quando possível.
4. Comparar espaçamentos, alinhamento, hierarquia, fontes, raios, cores e comportamento de rolagem.
5. Corrigir divergências perceptíveis sem comprometer acessibilidade.

**Não declarar fidelidade “pixel-perfect”** se o protótipo não fornecer medidas editáveis e não houver comparação visual real. As capturas da prancha podem ter pequenas inconsistências visuais/textuais próprias de imagens geradas; prevalece a funcionalidade descrita em `02-requisitos.md`.
