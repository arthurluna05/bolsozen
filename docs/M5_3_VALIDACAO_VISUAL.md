# M5.3 — Revisão de fidelidade TEL-04 e TEL-06

**Visual revisado do M5.3 aprovado pelo usuário.** Os quatro ajustes finais solicitados foram incorporados durante o M5.4 autorizado, sem iniciar M5.5. A aprovação não representa fidelidade pixel-perfect nem homologação Android/Web inexistente. Resultados anteriores abaixo são históricos; o registro seguinte descreve a versão vigente.

## Ajustes finais aprovados — 18/11/2026

Dashboard sem seletor mensal: saldo de todo o histórico, receitas/despesas/categorias do mês corrente, recentes preservados. Competência acompanha virada do calendário e retomada do aplicativo por relógio/timer local, sem logout ou nova consulta; API selectMonth e FinancialMonth mantidos. Histórico preserva agrupamento, pastéis e alinhamentos: cabeçalhos agora textPrimary 14/w600, títulos 16/w600 e ícones 28 dp. Ícones do Dashboard continuam 24 dp. Descrições extensas quebram linhas; não há ellipsis monetário.

| Elemento ajustado | Protótipo/decisão aprovada | Versão atual | Fidelidade | Pendência |
|---|---|---|---|---|
| Competência TEL-04 | Sem seletor | Removido da interface, mês corrente automático | Fiel | Períodos manuais M7/M8 |
| Cabeçalhos TEL-06 | Pedido final de preto/semibold maior | textPrimary, 14/w600 | Fiel à alteração aprovada | Nenhuma funcionalidade nova |
| Ícones TEL-06 | Maiores, mesmos fundos/cores | 28 dp; símbolos Material anteriores | Aproximado | Traços Material ainda diferem da imagem raster |
| Títulos TEL-06 | Maior legibilidade/semibold | 16/w600, quebra responsiva | Fiel à alteração aprovada | Mais linhas com nomes extensos |

| Tela | Versão aprovada antes dos quatro ajustes | Versão atual |
|---|---|---|
| Dashboard 390 | [Aprovada](evidencias/m5-3/aprovado-dashboard-390.png) | [Atual](evidencias/m5-3/dashboard-390-texto-1.png) |
| Histórico 390 | [Aprovada](evidencias/m5-3/aprovado-transacoes-390.png) | [Atual](evidencias/m5-3/transacoes-390-texto-1.png) |

Doze capturas financeiras regeneradas; suíte normal agora com 454 aprovados e analyzer com 37 informes, zero erros/warnings. Dois testes de captura separados aprovados para as 18 imagens financeiras/formulário. Valores são fixtures identificadas, sem Firebase remoto. Capturas em 360/390/412 dp e texto 2 demonstram adaptação por rolagem/quebra de linha; não são execução nativa. Botões futuros e barra inferior continuam fixtures/indisponíveis conforme registro abaixo. Aproximações da carteira/gradiente e dependências M6–M8 já documentadas permanecem, sem reabrir o aceite do M5.3. TEL-05 e limitações em [M5_4_VALIDACAO_VISUAL.md](M5_4_VALIDACAO_VISUAL.md).

## Histórico da revisão anterior

Fontes relidas: AGENTS.md, PLANO_M5.md, PROGRESSO.md, Design System, critérios de aceite e prancha oficial design/telas/bolsozen_prototipo.png. Comparadas diretamente as capturas anteriores em 390 dp com TEL-04/TEL-06. Nenhuma referência externa, imagem gerada, biblioteca nova ou alteração de protótipo/requisitos.

## Diferenças encontradas e correções

A primeira versão tinha duas caixas mensais grandes, saldo chapado, ícones todos verdes, valores secundários 20/w700 e ausência das seções inferiores. O Histórico era uma lista com separadores, sem a estrutura visual de busca, chips ou cabeçalhos por dia. Havia um botão de refresh no lugar do sino. Isso produzia densidade e proporções diferentes da prancha.

A revisão mantém o app normal e a arquitetura, mas altera especificamente essas decisões visuais:

- Avatar verde e inicial branca decorativa; saudação com nome do perfil e 👋; sino outlined **sem ação e excluído da semântica**. Refresh real por puxar para baixo, testado nas duas telas.
- Saldo em gradiente verde, recorte arredondado, sombra suave, carteira decorativa e olho circular indisponível. Texto do saldo continua exclusivamente Money/FinancialController.
- Três indicadores compactos: receitas/despesas reais e Meta do mês com **Em breve**, sem percentual ou alegação de orçamento inexistente. Nenhum orçamento foi consultado; integração M7 continua pendente.
- Participação dos gastos: ícones pastel, nomes, barras e percentuais reais do FinancialSummary. Ver mais indisponível, sem rota falsa. **Participação nas despesas é diferente de consumo de orçamento.**
- Recente: primeiro registro do histórico confirmado, conforme a única linha visível em TEL-04; card com descrição/data/sinal/cor. Ver todas e FAB ficam indisponíveis, identificados para M5.5; não há formulário ou escrita.
- Histórico com busca e filtros apenas visuais, aviso explícito de disponibilidade no M6, sem TextField/FilterChip ou callbacks. Cabeçalhos Hoje/Ontem/outras datas e linhas em cards brancos com sombras leves e ícones distintos.
- Seletor mensal deslocado para **depois dos três indicadores**: saldo e indicadores ficam adjacentes, diferente da primeira alternativa acima dos indicadores. Funcionalidade preservada, sem leitura extra.

## Antes e depois — 390 dp

| Tela | Primeira entrega, sem aceite definitivo | Revisão atual |
|---|---|---|
| Dashboard | [Antes](evidencias/m5-3/antes-dashboard-390.png) | [Revisado](evidencias/m5-3/dashboard-390-texto-1.png) |
| Histórico | [Antes](evidencias/m5-3/antes-transacoes-390.png) | [Revisado](evidencias/m5-3/transacoes-390-texto-1.png) |

As duas imagens anteriores foram preservadas antes da atualização. Dados-base T1 continuam com saldo R$ 600,00, receitas R$ 1.000,00 e despesas de novembro R$ 350,00. Nome/descrições da fixture foram encurtados e continuam explicitamente de teste; isso não é mudança de dados de usuário.

Há uma **fixture adicional de composição**, apenas no runner, com três categorias no mês e dois dias: [Dashboard](evidencias/m5-3/dashboard-390-texto-1-composicao.png) e [Histórico](evidencias/m5-3/transacoes-390-texto-1-composicao.png). Ela mantém as quantias individuais, mas muda as datas somente em memória; seu mês tem R$ 400,00 em despesas, participações 62,5%/25%/12,5% e o mesmo saldo global de R$ 600,00. Não confundir essa fixture com T1, com percentuais ilustrativos da prancha ou com persistência real.

## Auditoria elemento por elemento

| Elemento | Protótipo | Implementação revisada | Fidelidade | Pendência |
|---|---|---|---|---|
| Cabeçalho TEL-04 | Avatar verde, inicial branca, saudação/emoji e subtítulo alinhados | Avatar 40 dp, nome injetado, 👋, textos 16/12 e sino à direita | Aproximado | Métricas da prancha são raster; emoji depende do sistema |
| Sino | Contorno escuro no canto direito | notifications_none_outlined 24, sem gesto/sem botão semântico | Aproximado | Não há notificações; não foi criada tela |
| Hierarquia do saldo | Rótulo branco menor e valor branco dominante | Rótulo 14 e valor 28/w700, padding 16 | Fiel | Quantias longas/texto ampliado exigem mais linhas |
| Fundo/profundidade do saldo | Verde em gradiente, sombra discreta e raios | Gradiente amostrado, raio 16, elevação 1/sombra suavizada | Aproximado | Sem especificação vetorial/medidas exatas do gradiente |
| Carteira decorativa | Carteira de traço com aba inclinada | account_balance_wallet_outlined 88, branco 12% | Aproximado | Ícone Material difere do desenho; asset próprio aprovado seria necessário para desenho idêntico |
| Olho visual | Ícone em círculo escuro à direita | visibility_outlined 20 em alvo circular 48, desabilitado | Aproximado | Não oculta saldo nesta revisão |
| Ação de ocultar | Disponível no projeto final | Sem callback; tooltip/semântica indicam M6 | Adiado por dependência funcional | M6 |
| Três indicadores | Cards compactos lado a lado | Três cards com setas/alvo, labels 12 e valores 16; empilham se necessário | Aproximado | Terceiro valor não pode copiar 72% ilustrativo |
| Meta | Percentual de orçamento configurado | Em breve, neutro, sem consulta ou percentual | Adiado por dependência funcional | M7; não afirmar que não há orçamento sem lê-lo |
| Seletor mensal | Ausente em TEL-04 original | Linha de competência abaixo dos indicadores | Diferente | Adaptação M5 aprovada; usuário revisar posição |
| Gastos por categoria | Título, ícones, barras verdes e percentuais à direita | Mesma distribuição, com percentuais derivados do domínio | Aproximado | Duas categorias em T1, três na fixture adicional; sem inventar categoria para preencher |
| Ver mais | Link alinhado à direita | Mesma posição, disabled e identificação de M8 | Adiado por dependência funcional | Detalhamento M8; sem navegação nesta etapa |
| Transações recentes | Cabeçalho/Ver todas e uma linha visível | Primeiro lançamento real já ordenado, card e sinais | Aproximado | Data/quantia dependem do histórico real; não há nova consulta |
| Ver todas e adicionar | Link e FAB verde com sombra | Controles disabled, referência explícita ao M5.5 | Adiado por dependência funcional | Formulário M5.4 e ligação M5.5 |
| Busca/filtros TEL-06 | Campo cinza, lupa e ajustes | Estrutura visual sem edição, caption M6 e sem ação | Aproximado | Caption extra para não sugerir busca funcional |
| Chips TEL-06 | Todas verde, Receitas menta, Despesas rosa | Pills com cores distintas; sem handlers; texto ampliado usa Wrap | Aproximado | Filtragem continua M6 |
| Cabeçalhos por dia | Hoje/Ontem/data em verde | Projeção determinística em dias locais; histórico não muda | Fiel | Sem filtros ou agrupamentos financeiros novos |
| Linhas TEL-06 | Fundo branco, sombra leve, ícone pastel e valor à direita | Raio 12, elevação 1 suavizada, corpo 14/12, valor 14/w600 | Aproximado | Valores/descrições extensos migram para mais linhas |
| Cor dos valores | Receita verde e despesa vermelha compacta | Verde oficial e vermelho escurecido #D91032 | Aproximado | Tom ajustado para contraste de texto pequeno; revisar escolha visual |
| Navegação inferior | Cinco destinos e ativo em menta | Desenho de fixture em capturas, cinco ícones sem ações | Adiado por dependência funcional | Não existe NavigationBar nova no app; ligação M5.5, orçamento M7, relatórios M8 |

Classificação visual não é aprovação automática de comportamento futuro. Presença dos mesmos componentes não foi usada como prova de fidelidade total; cores, densidade, tamanhos, espaçamentos e diferenças continuam explicitados acima.

## Auditoria de ícones e cores

| Referência | Antes | Agora / dimensão / cor / fundo | Diferença de traço e necessidade |
|---|---|---|---|
| Sino outlined | refresh 24 verde | notifications_none_outlined 24, textPrimary, sem fundo | Contorno Material aproximado; decorativo |
| Carteira no saldo | Ausente | account_balance_wallet_outlined 88, branco 12%, sobre gradiente | Material é mais geométrico; não é reprodução vetorial exata |
| Olho circular | Ausente | visibility_outlined 20, branco, círculo verde escuro | Contorno Material aproximado; ação M6 |
| Receita / Despesa | Setas 20 e textos grandes | arrow_upward/downward 20, verde/vermelho, cards brancos | Contorno/haste nativos, proporções compactadas |
| Meta do mês | Ausente | track_changes_outlined 20, warning, card branco | Alvo com geometria Material próxima à prancha |
| Alimentação no Histórico | Utensílios verdes / menta | restaurant_outlined 24, #EF4055 / #FEE1E3 | Fork/knife, traço nativo ligeiramente mais espesso |
| Alimentação no Dashboard | Ausente | restaurant_outlined 24, #F58B16 / #FEEEDC | A prancha usa variante âmbar na distribuição |
| Transporte | Carro verde / menta | directions_car_outlined 24, #2876ED / #DAE5FD | Azul e carro frontal; curvas Material aproximadas |
| Lazer | Controle verde / menta | sports_esports_outlined 24, #7337D2 / #EEE2FC | Roxo e controle; botões internos não idênticos |
| Compras | Sacola verde / menta | shopping_bag_outlined 24, #F58B16 / #FEEEDC | Alça/contorno Material; sem asset externo |
| Receitas | Seta verde / menta | arrow_upward 24, primary / #CEFDDE | Referência tem decoração suave atrás da seta; aproximado |
| Busca | Ausente | search 20, textSecondary / surfaceMuted | Lupa nativa; não é campo editável |
| Ajustes | Ausente | tune 24, primary | Barras/controles Material equivalentes, sem ação |
| Competência | Calendário e chevrons | calendar_today_outlined 20 e chevron_left/right 24 | Preservados; únicos controles funcionais de seleção |
| Adicionar | Ausente | add 24, branco / primary, circular com elevação | Disabled; sem abertura de formulário falso |
| Rodapé (fixture) | Ausente | home/receipt_long ativos, pie_chart_outline, bar_chart, person_outline 24 | Ícones Material e fundo menta; apenas teste, sem interação |

Novos tons ficam em **financial_visual_tokens.dart**, sem alterar AppColors/AppTheme aprovados de autenticação. Prancha amostrada diretamente: (1204,150) = #01855C, (1420,170) = #00694C e avatar (1207,95) = #7AE09D. Esses pontos orientam gradiente/avatar. Demais acentos/pastéis aproximam as regiões observadas; compressão, gradientes e antialias produzem vários tons na imagem, portanto não são declarados “cores exatas Figma”. Não foram usados apps genéricos como referência.

O vermelho compacto #D91032 é uma adaptação deliberada de contraste em vez do texto 20 sp anterior. Opções para revisão: **A**, manter 14/w600 com vermelho escurecido (atual), preservando densidade e contraste; **B**, voltar ao token #EF4444 com texto grande para contraste, sacrificando a densidade. Não foi alterada a cor global de erro.

## Arquitetura e limites funcionais

FinancialController, FinancialCalculator, Money/BigInt/faixa segura, repositórios, expectedUserId, SessionController/Gate, regras e índices permaneceram intactos nesta revisão. Não houve ligação à aplicação normal, navegação, escrita ou conta remota.

FinancialProjection é uma derivação pequena e pura da apresentação: formata/normaliza os percentuais já calculados em FinancialSummary, seleciona o primeiro item de history e intercala cabeçalhos de datas. Não recalcula saldo/percentuais financeiros e não consulta Firestore. ListView.builder continua lazy por linha/cabeçalho, sem montar um grupo inteiro antecipadamente. Nenhuma transação é filtrada ou perdida.

Estados idle/loading/refreshing/ready/empty/error/sessionInvalidated continuam do controller; barras/recentes só aparecem com snapshot confirmado. Aviso stale fica fixo fora da rolagem. Perfil divergente ou sessão invalidada continuam ocultando nome/dados. Sem despesas, não há barras/percentuais fabricados; meta não diz “sem orçamento configurado”, pois nenhum orçamento foi consultado.

## Capturas e execução

Renderer **Flutter test engine / RepaintBoundary.toImage**, DPR 1, viewport 844 dp; não é Chrome/Android. Roboto/MaterialIcons do SDK local; emoji usa fonte de sistema existente somente no runner. Sem fonte/asset novo no app ou imagem externa. Sombras reais habilitadas. Cada captura usa árvore isolada e fixtures explicitamente identificadas no manifesto.

O rodapé de cinco destinos é **exclusivamente desenho de teste**, excluído da semântica e sem handlers. Não é NavigationBar nem prova de navegação funcional. Cabeçalho técnico e rodapé ilustrativo não escalam com o texto das telas; o conteúdo real escala normalmente.

| Cenário | Dashboard | Histórico |
|---|---|---|
| 360 dp / texto 1 | [Imagem](evidencias/m5-3/dashboard-360-texto-1.png) | [Imagem](evidencias/m5-3/transacoes-360-texto-1.png) |
| 390 dp / texto 1 | [Imagem](evidencias/m5-3/dashboard-390-texto-1.png) | [Imagem](evidencias/m5-3/transacoes-390-texto-1.png) |
| 412 dp / texto 1 | [Imagem](evidencias/m5-3/dashboard-412-texto-1.png) | [Imagem](evidencias/m5-3/transacoes-412-texto-1.png) |
| 360 dp / texto 2 | [Imagem](evidencias/m5-3/dashboard-360-texto-2.png) | [Imagem](evidencias/m5-3/transacoes-360-texto-2.png) |
| 360 dp / texto 2 / valor extenso | [Imagem](evidencias/m5-3/dashboard-360-texto-2-valor-longo.png) | [Imagem](evidencias/m5-3/transacoes-360-texto-2-valor-longo.png) |
| 390 dp / composição com três categorias e dois dias | [Imagem](evidencias/m5-3/dashboard-390-texto-1-composicao.png) | [Imagem](evidencias/m5-3/transacoes-390-texto-1-composicao.png) |

Metadados e natureza das fixtures em [manifest.json](evidencias/m5-3/manifest.json). Captura opt-in, fora da descoberta padrão de testes:

```powershell
$env:BOLSOZEN_FONT_DIR='C:\dev\flutter\bin\cache\artifacts\material_fonts'
flutter test test/visual/m5_financial_capture.dart --dart-define=M5_VISUAL_CAPTURE=true --concurrency=1
```

Não copiar fontes para o projeto; ajustar o caminho ao SDK local. O runner não inicializa Firebase, não executa a aplicação normal nem runners M3/M4. Quantias extensas preservam todos os centavos, podendo quebrar linha; texto ampliado exige rolagem. Pills usam Wrap em escala alta para não separar letras das palavras.

## Qualidade, decisões e pendências

Primeira entrega: 407 testes aprovados e 30 informes do analyzer, evidência funcional histórica; **não representam aceite visual desta revisão**. Os 407 casos foram preservados, adaptando apenas asserções que exigiam os elementos visuais agora revogados (ausência do FAB/sino, texto informativo antigo e ausência de agrupamento). Sete casos direcionados novos cobrem participação versus orçamento, recente imutável, datas/virada de ano, vazio sem invenção, composição/ações indisponíveis e refresh por gesto.

Resultados finais: dart format . exit 0 (90 arquivos); flutter analyze exit 1 por 33 informes de depreciação, zero erros/warnings; **414 testes aprovados** na suíte normal (407 preservados + sete novos); um teste de captura separado aprovado com doze imagens; git diff --check exit 0. As doze capturas finais foram abertas/inspecionadas e comparadas com a referência. Sem OOM. Não contar a captura como teste normal adicional.

A primeira suíte completa detectou overflow de 6 px em texto ampliado durante stale/erro no Histórico. Corrigido movendo busca/chips para a rolagem da lista, mantendo o aviso fixo e o teste que identificou a falha. Na escala ampliada, pills usam Wrap para não quebrar “Receitas/Despesas” em letras. O teste visual também passou após essas correções. Evidências/logs e contagens históricas em PROGRESSO.md. Sem testes remotos ou aprovação Android/Web/TalkBack nesta tarefa.

Revisão necessária do usuário: composição em 390 dp, tons aproximados/contraste compacto, posição do seletor, presença dos controles indisponíveis e desenho de carteira aproximado. Meta neutra não exige mudança de arquitetura nem consulta de orçamento; não foi preciso inventar metas ou implementar M7. Reprodução idêntica da carteira exigiria asset aprovado; não incluído. Navegação/cadastro e ações completas M6–M8 continuam adiados. **Não declarar fidelidade 100%, pixel-perfect ou M5.3 homologado definitivamente. Aguardar revisão antes de M5.4.**
