# M6.5 — Saldo visível/oculto

Referências: TEL-04 da prancha oficial `design/telas/bolsozen_prototipo.png`, Design System e Dashboard aprovado nos marcos M5/M6. Capturas opt-in por `test/visual/m6_balance_capture.dart`, com renderer Flutter, Roboto local e contratos fake; não inicializam Firebase. Fixtures identificadas em banner, sem persistência. Aceite visual do usuário pendente.

## Evidências realizadas e comparação

Pasta `docs/evidencias/m6-5/`: `saldo-visivel` e `saldo-oculto` em 360/390/412 dp com texto 1× e 360 dp com texto 2×, oito PNGs capturados e um teste opt-in aprovado. Para reproduzir, informar BOLSOZEN_FONT_DIR para material_fonts do SDK local e executar o runner com `--dart-define=M6_BALANCE_VISUAL_CAPTURE=true`. Sem esse define o teste de captura fica desabilitado e não integra a bateria padrão.

- [Visível 390 dp](evidencias/m6-5/saldo-visivel-390-texto-1.png) e [oculto 390 dp](evidencias/m6-5/saldo-oculto-390-texto-1.png).
- [Visível 360 dp, texto 2×](evidencias/m6-5/saldo-visivel-360-texto-2.png) e [oculto 360 dp, texto 2×](evidencias/m6-5/saldo-oculto-360-texto-2.png).

Capturas inspecionadas contra TEL-04: card/gradiente/carteira e composição preservados, máscara e olho fechado nos estados ocultos; demais valores visíveis. Na escala 2×, valor monetário visível quebra linha, card/indicadores crescem e a tela rola, sem overflow. Máscara exige menos altura; o runner retorna ao topo antes de cada captura para comparar o mesmo enquadramento. Não foram fixadas alturas nem reduzida fonte para caber na imagem. Sem OOM ou build Android/Chrome.

Validação: 656 testes Flutter aprovados (638 anteriores + 18), formatador e diff-check aprovados; analyzer com 52 informes de depreciação, zero erros/warnings. Teste semântico percorre labels, valores e tooltips e confirma ausência do saldo oculto; novos casos preservam valores mensais, categorias e Histórico. Integração real/serviço remoto não foi testada nesta etapa.

| Elemento | Implementação M6.5 | Comparação com referência |
|---|---|---|
| Card | Gradiente, carteira decorativa, padding, tipografia e sombras existentes | Preservados |
| Olho | Mesma posição/círculo/ícone Material 20 dp; agora acionável | Preservado; estado fechado acrescentado |
| Valor oculto | Máscara •••••• com estilo do valor | Estado funcional complementar |
| Semântica | Saldo oculto + botão Mostrar saldo | Sem anúncio do valor oculto |
| Indicadores/categorias/recentes | Permanecem visíveis e derivados do snapshot | Preservados |
| Histórico | Busca, chips e ajustes ampliados M6.4 inalterados | Preservados |

Não se promete fidelidade pixel-perfect: a prancha não especifica todos os detalhes do estado oculto. A ocultação não é um modo global de privacidade, não altera valores e não persiste preferência. O renderer não equivale a homologação de TalkBack/teclado nativo ou Android/Chrome; verificações manuais acumuladas seguem para M9. M6.6 ainda não autorizado.
