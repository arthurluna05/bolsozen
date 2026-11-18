# M6.2 — Edição TEL-05 e menu do Histórico

Entregue para revisão, sem avançar para exclusão M6.3. Referências: protótipo oficial TEL-05/TEL-06, Design System e aparência aprovada no M5. A mesma TransactionFormScreen atende criação/edição; não há segundo formulário nem tela de detalhes.

## Capturas reais do renderer Flutter

| Condição | Screenshot |
|---|---|
| Menu 390 dp | [Somente Editar](evidencias/m6-2/acoes-390-texto-1-teclado-0.png) |
| Despesa 390 dp | [Editar transação](evidencias/m6-2/editar-despesa-390-texto-1-teclado-0.png) |
| Receita 390 dp | [Campos de receita](evidencias/m6-2/editar-receita-390-texto-1-teclado-0.png) |
| Despesa 360 dp | [Imagem](evidencias/m6-2/editar-despesa-360-texto-1-teclado-0.png) |
| Despesa 412 dp | [Imagem](evidencias/m6-2/editar-despesa-412-texto-1-teclado-0.png) |
| Menu 360 dp, texto 2 | [Texto ampliado](evidencias/m6-2/acoes-360-texto-2-teclado-0.png) |
| Despesa 360 dp, texto 2 | [Texto ampliado](evidencias/m6-2/editar-despesa-360-texto-2-teclado-0.png) |
| Despesa 360 dp, inset teclado 300 | [Rolagem e foco](evidencias/m6-2/editar-despesa-360-texto-1-teclado-300.png) |

Oito PNGs abertos/inspecionados e comparados com a prancha, dimensões 360/390/412 × 844 conferidas nos arquivos. [Manifesto](evidencias/m6-2/manifest.json) registra uma carga por sessão e zero creates/updates na captura. Nomes, quantias e descrições são fixtures com identificação de teste; nenhum Firebase inicializado ou dado remoto utilizado. Captura por RepaintBoundary.toImage, fontes locais Roboto/MaterialIcons e mesmo gate/shell/rotas de produção; contratos externos fake.

## Comparação visual

| Elemento | Resultado | Classificação/limite |
|---|---|---|
| Campos/tipo/conta/botão TEL-05 | Reutilizados tamanhos, cores, raios, margens, ícones e tipografia do formulário aprovado | Composição preservada; título e ação mudam para Editar transação/Salvar alterações |
| Valores/data | Campos preenchidos do snapshot; Money.formatCents; data numérica pt-BR | Quantias são fixtures, não as ilustrativas da prancha; preserva adaptação já aprovada M5.4 |
| Histórico TEL-06 | Cards/ícones/pastéis/cabeçalhos mantidos; toque e semântica novos | Nenhum redesenho; busca/filtros continuam indisponíveis até M6.4 |
| Bottom sheet | Branco, texto do tema, ícone Material edit_outlined primary, margens 16 e safe area | Complemento funcional da jornada J-05, não desenhado integralmente na prancha; não alegar reprodução exata |
| Navegação | Menu fecha ao selecionar Editar; rota secundária com Voltar, sem barra inferior visível | Reutiliza Navigator privado; sem barras duplicadas ou destino falso |
| Fonte ampliada | Campos/menu crescem, descrição quebra linha e conteúdo rola | Preserva acessibilidade em vez de dimensões fixas; não identificado overflow nas capturas |
| Teclado | Inset simulado reduz área; foco e botão acessíveis por rolagem | Não é screenshot de IME nativo nem homologação Android/iPhone |

Roboto, AppColors/AppSpacing/AppRadii e tokens financeiros existentes reutilizados. Sem fonte, imagem, pacote de UI ou ícone externo novo. Menu oferece somente Editar; não contém Excluir. Não declarar pixel-perfect nem aprovação visual do usuário antes da revisão.

## Testes e limites

**561 testes Flutter aprovados**: 515 anteriores + 46 novos (21 controller e 25 widgets). CA-07 validado: Alimentação 250→200 leva saldo 600→650 e despesas novembro 350→300; mover para outubro mantém saldo, novembro 100 e outubro 250. Exclusão não implementada/testada como fluxo UI nesta etapa.

Testes abrangem preservação de ID/UID/createdAt/data original inclusive hora/UTC/microssegundos; confirmação do mesmo dia; novos tipo/categoria/descrição/data; centavos e faixa segura; snapshot ausente/adulterado; trava compartilhada create/update; leitura anterior e recarga completa posterior; dados antigos ou ID ausente não confirmam atualização; erros, resultado incerto, notFound, retry somente de leitura, sessão/dispose, recentes e responsividade/semântica.

Analyzer: **44 informes de depreciação**, zero erros/warnings (41 baseline + imports Material no menu, teste de telas e runner de captura). Dois informes novos de estilo foram corrigidos sem supressão. Format e diff-check aprovados. Um teste separado de captura aprovado, oito imagens, sem OOM. Logs ignorados em build/m6-2-*.log.

Primeiros testes de widgets localizaram limitações do helper para ListView lazy/cards maiores que a viewport: corrigido para rolar até o registro e tocar o topo visível, em vez do centro geométrico fora da tela. Nenhuma alteração do layout para acomodar o teste; suíte final passou. Teste de original adulterado usa rota dentro do shell real para manter o controller vivo e exercer a validação do formulário.

## Reprodução local opt-in

```powershell
$env:BOLSOZEN_FONT_DIR='C:\dev\flutter\bin\cache\artifacts\material_fonts'
flutter test test/visual/m6_edit_capture.dart --dart-define=M6_VISUAL_CAPTURE=true --concurrency=1
```

Runner desabilitado por padrão e fora da descoberta normal de testes. Nenhuma submissão nas capturas. SDK Firebase/regras/índices não foram executados ou alterados; testes de integração real, Android/Web/IME/TalkBack não foram homologados nesta etapa. Falha/timeout não garante cancelamento de escrita já enviada. Conflitos de edições entre dispositivos continuam limitação documentada, sem novo protocolo de versionamento. Nenhum build pesado, dado remoto, dependência, Gradle, commit/push/deploy. Aguardar revisão antes do M6.3.
