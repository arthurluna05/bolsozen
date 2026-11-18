# M6.3 — Menu e confirmação de exclusão

Implementado para revisão, sem avançar ao M6.4. Referências: protótipo TEL-04/TEL-06, Design System, jornadas J-05 e CA-07. O diálogo não é desenhado integralmente na prancha: é um complemento Material funcional, não uma reprodução pixel-perfect.

## Capturas do renderer Flutter

| Condição | Evidência |
|---|---|
| Menu 390 dp | [Editar e Excluir](evidencias/m6-3/acoes-390-texto-1.png) |
| Confirmação despesa 390 dp | [Diálogo principal](evidencias/m6-3/confirmar-despesa-390-texto-1.png) |
| Confirmação despesa 360 dp | [Imagem](evidencias/m6-3/confirmar-despesa-360-texto-1.png) |
| Confirmação despesa 412 dp | [Imagem](evidencias/m6-3/confirmar-despesa-412-texto-1.png) |
| Despesa 360 dp, texto 2 | [Fonte ampliada](evidencias/m6-3/confirmar-despesa-360-texto-2.png) |
| Receita 390 dp | [Receita](evidencias/m6-3/confirmar-receita-390-texto-1.png) |
| Receita 390 dp, valor/descrição extensos | [Quantia extensa](evidencias/m6-3/confirmar-receita-390-texto-1-valor-extenso.png) |
| Receita 360 dp, texto 2, valor/descrição extensos | [Combinação extrema](evidencias/m6-3/confirmar-receita-360-texto-2-valor-extenso.png) |

Oito PNGs abertos/inspecionados e dimensões conferidas (360/390/412 × 844). Um teste opt-in de captura aprovado. [Manifesto](evidencias/m6-3/manifest.json): somente fixtures identificadas, zero creates/updates/deletes nas capturas, nenhum Firebase inicializado. O runner abre o menu/diálogo, mas nunca confirma exclusão. Renderer real Flutter de testes/RepaintBoundary, fontes locais do SDK; não Android/Chrome.

## Auditoria visual

| Elemento | Implementação observada | Fidelidade/limite |
|---|---|---|
| Histórico | Cards, ícones, pastéis, títulos, datas e barra inferior aprovados mantidos sob modal | Preservado; nenhuma busca/filtro habilitado |
| Menu | Mesmo bottom sheet M6.2, Editar mantido e Excluir acrescentado | Ícone delete_outline na cor error oficial; texto textPrimary para legibilidade |
| Confirmação | AlertDialog branco, raio de card 16, Roboto, título Excluir transação?, descrição, BRL e aviso irreversível | Complemento coerente com tokens, sem modelo específico na prancha |
| Ações | Cancelar primary; Excluir error com texto textPrimary/onError | Cor oficial preservada; texto escuro no vermelho evita contraste insuficiente de branco pequeno |
| Fonte/quantia extensas | Texto quebra linha, conteúdo rolável e ações visíveis | Sem overflow identificado; não cortar centavos ou fixar altura para caber captura |
| Navegação | Sheet fecha antes do diálogo; nenhuma barra duplicada | Ambos pertencem ao Navigator privado; cancelar/Voltar não envia mutação |

Testes locais de rótulos, alvos Android e contraste aprovados nas três larguras com texto 1/2. Não equivale a TalkBack/IME/homologação manual nativa. Estados de progresso e erro foram testados com widgets/fakes; as capturas mostram somente seleção/confirmação sem escrita.

## Qualidade e segurança

**607 testes Flutter aprovados**, preservando 561 anteriores e acrescentando 46 (21 controller e 25 widgets). CA-07: editar Alimentação para 200, mover para outubro e excluir Transporte resulta em saldo 750, despesas novembro zero e outubro 250. Exclusão de receita/despesa, último item, categorias/recentes, cancelamento, múltiplos envios, create/update/delete concorrentes, ausência confirmada, falhas/recarga/reconciliação/notFound, fechamento durante operação e troca de identidade/dispose cobertos.

Analyzer: **47 informes de depreciação**, zero erros/warnings (44 baseline + três imports Material oficiais em diálogo, teste de telas e runner). Sete informes locais de estilo corrigidos sem supressão antes da validação final. Format e diff-check aprovados. Logs locais ignorados em build/m6-3-*.log. Nenhuma nova execução de segurança por servidor ou SDK nativo; regras/índices não alterados.

PendingDeletedIds exige ausência do ID no histórico completo antes de publicar saldo/lista novos; snapshot anterior permanece stale se a recarga falha ou ainda contém o registro. Resultado incerto só permite leitura até reconciliação; notFound específico não vira sucesso automático. Trava comum impede outra mutação enquanto aguarda confirmação/reconciliação. Diálogo pode fechar durante envio com aviso de que isso não cancela a operação. O controller continua vivo no shell e não repete delete nem reabre diálogo quando a resposta chega.

## Reprodução opt-in

```powershell
$env:BOLSOZEN_FONT_DIR='C:\dev\flutter\bin\cache\artifacts\material_fonts'
flutter test test/visual/m6_delete_capture.dart --dart-define=M6_DELETE_VISUAL_CAPTURE=true --concurrency=1
```

Desabilitado por padrão e fora da descoberta normal de testes. PNGs históricos M6.2 foram preservados, sem recaptura/sobrescrita; seu runner foi apenas compatibilizado com o menu atual. Não executar esse runner antigo para substituir evidência histórica inadvertidamente.

## Pendências

Revisão técnica/visual do usuário e autorização do M6.4. Persistência real, Android/Web, teclado/TalkBack e limitações de conflitos entre dispositivos permanecem documentadas no backlog M9 e no plano. Timeout/logout não garante cancelamento de escrita enviada. Nenhum dado/usuário remoto alterado, build pesado, dependência/Gradle, regra/índice, commit, push ou deploy nesta etapa. Busca/filtros e ocultação continuam reservados aos marcos próprios.
