# M6.4 — Histórico com busca e filtros reais

Referências: TEL-06 em `design/telas/bolsozen_prototipo.png`, `04-design-system.md`, revisão visual M5.3 e solicitação expressa de controles maiores. Aceite visual do usuário ainda pendente. As capturas usam renderer Flutter de testes com Roboto local e fixtures identificadas, não dados reais nem Firebase remoto. Não equivalem a homologação nativa Android/Chrome ou pixel-perfect.

## Composição e interação

Mantidos título, cabeçalhos 14/w600/textPrimary, cards, ícones 28 com pastéis, descrições 16/w600, valores/sinais, FAB, barra inferior real de três destinos e respiro lateral. Campo cinza e lupa preservados; pesquisa agora editável, com X acessível. Tune verde ampliado a 26 dp e alvo 48×48. Chips agora botões reais com labelLarge 14/w600, altura mínima 48 dp e larguras proporcionais. Seleção anunciada por semântica e indicada por borda. Cores verde escuro, menta e vermelho-claro mantidas. A legenda antiga de funcionalidade futura foi removida.

O protótipo apresenta controles mais baixos; o aumento é uma adaptação aprovada pelo usuário. Com fonte ampliada, os chips quebram em linhas quando necessário. O diálogo Material é complementar à prancha, com rascunho de categoria, Aplicar, Cancelar e Limpar filtros; esta última ação explica que remove os três critérios. Navegação por foco padrão Material e restauração no tune após fechamento. A comparação inicial detectou truncamento de Todas as categorias com texto 200%; o rótulo foi encurtado para Todas sob o campo Categoria, mantendo o significado e a ação de remoção.

## Evidências

Antes: [TEL-06 integrada M5.5](evidencias/m5-5/transacoes-390-texto-1.png), ainda com controles menores e legenda indisponível.

Capturas desta etapa em `evidencias/m6-4/`:

- `historico-360-texto-1.png`, `historico-390-texto-1.png`, `historico-412-texto-1.png`.
- `historico-360-texto-2.png`: texto ampliado.
- `combinados-390-texto-1.png`: pesquisa sem acento, Despesas e Alimentação simultâneos.
- `modal-390-texto-1.png` e `modal-360-texto-2.png`.
- `sem-resultados-390-texto-1.png`: mensagem e ação de limpeza.

Runner opt-in: `test/visual/m6_history_capture.dart`, define `M6_HISTORY_VISUAL_CAPTURE=true` e `BOLSOZEN_FONT_DIR` para as fontes material_fonts do SDK local. Cada captura exige uma única carga e nenhuma mutação nos fakes. Não há inicialização Firebase.

| Elemento | Referência/antes | Revisão | Avaliação |
|---|---|---|---|
| Busca | Cinza, lupa, sem interação | Mesmo estilo, entrada real e limpeza | Aproximado; alvo ampliado |
| Chips | Pequenos, arredondados e coloridos | 48 dp mínimos, 14/w600, seleção acessível | Adaptação expressamente solicitada |
| Ajustes | Tune verde pequeno | 26 dp, alvo 48×48, modal real | Aproximado; ampliado |
| Cards e ícones | TEL-06/pastéis aprovados | Componentes existentes preservados | Preservado |
| Datas | Hoje/Ontem/demais datas | Mesma composição, atualiza à meia-noite/retomada | Preservado |
| Modal | Não detalhado na prancha | AlertDialog Material/token oficial | Complementar |
| Navegação | Prancha final com cinco abas | Três destinos reais existentes | Orçamento/Relatórios reservados M7/M8 |

## Verificações e limites

Execução final: 638 testes Flutter aprovados (607 anteriores + 31), captura opt-in com um teste aprovado e oito PNGs, formatador e diff --check aprovados. Analyzer: 50 informes de depreciação, nenhum erro/warning. Capturas inspecionadas diretamente contra a prancha e versão anterior; sem overflow nas larguras registradas. O truncamento do rótulo inicial no modal a 200% foi corrigido e recapturado. Busca e tune estão mais altos que antes, chips maiores e caption de indisponibilidade removida; cards e navegação continuam com a composição anterior. Isso não constitui aceite visual do usuário.

Testes de layout em 360/390/412 dp com escalas 1 e 2, áreas de toque, rótulos e contraste automatizado; testes de aplicação/cancelamento, foco e estados sem resultados/erro. Não há transformação de erro ou dados stale em lista vazia. O renderer de testes não comprova teclado nativo, TalkBack ou comportamento de navegador real. Homologação manual desses ambientes permanece no M9; revisão visual destas capturas cabe ao usuário. Sem novas bibliotecas, imagens ou fontes de produção. M6.5 não iniciado.
