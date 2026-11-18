# M5.5 — MainShell integrado para revisão

Referências: prancha oficial TEL-04/TEL-05/TEL-06, Design System, PLANO_M5 e relatórios visuais M5.3/M5.4 aprovados. Alteração restrita à integração autorizada: três abas reais, FABs e Ver todas funcionais, sem redesenho das telas. Não é homologação definitiva M5.6.

## Capturas

Capturadas pelo renderer Flutter de testes com fontes locais Roboto/MaterialIcons, gate, MainShell e rotas reais. Apenas contratos externos usam fakes; nenhum Firebase inicializado ou documento criado. Manifesto registra uma leitura inicial e zero escritas por composição. Banner identifica dados de teste; valores/nomes/e-mails não pertencem a usuários remotos.

| Condição | Screenshot |
|---|---|
| Início 390 dp | [Dashboard integrado](evidencias/m5-5/dashboard-390-texto-1.png) |
| Transações 390 dp | [Histórico integrado](evidencias/m5-5/transacoes-390-texto-1.png) |
| Perfil 390 dp | [Perfil real com contrato fake](evidencias/m5-5/perfil-390-texto-1.png) |
| Formulário 390 dp | [Rota secundária TEL-05](evidencias/m5-5/formulario-390-texto-1.png) |
| Início 360 dp | [Imagem](evidencias/m5-5/dashboard-360-texto-1.png) |
| Início 412 dp | [Imagem](evidencias/m5-5/dashboard-412-texto-1.png) |
| Início 360 dp / texto 2 | [Imagem](evidencias/m5-5/dashboard-360-texto-2.png) |
| Transações 360 dp / texto 2 | [Imagem](evidencias/m5-5/transacoes-360-texto-2.png) |

[Manifesto](evidencias/m5-5/manifest.json). Oito imagens, um teste opt-in separado aprovado. Nenhuma barra inferior de fixture foi usada nesta captura; os cinco destinos dos runners antigos continuam isolados.

## Comparação com o protótipo

| Elemento | Resultado observado | Limitação/diferença |
|---|---|---|
| Barra inferior | NavigationBar oficial, branco, primary no ativo, indicador mintSurface, ícones 24 e Roboto 12; três destinos tocáveis | Três em vez dos cinco da prancha por decisão aprovada; indicador Material destaca o ícone, não todo o rótulo |
| Dashboard | Composição M5.3 preservada, FAB verde circular e Ver todas agora funcionais | Carteira/traços Material aproximados; meta/olho/detalhamento mantêm dependências documentadas M6–M8 |
| Histórico | Cabeçalhos/ícones/títulos aprovados preservados; FAB real e padding para último item | Busca/filtros continuam visuais e explicitamente indisponíveis até M6 |
| Formulário | Cabeçalho com retorno, sem NavigationBar visível e sem barra duplicada | Campos/conta informativa/data numérica conforme relatório M5.4; captura inicial não submete dados |
| Perfil | Componente M4 original, nome/e-mail correspondentes e botão Sair | Perfil não tem tela própria na prancha; composição complementar já aprovada |
| Responsividade | Dashboard em 360/390/412; fonte 2 exige rolagem/quebras; FAB e navegação permanecem acessíveis | Recorte de conteúdo fora da viewport é esperado na rolagem, não perda de dados |

As imagens foram abertas e comparadas diretamente com a prancha. Não identificado overflow nas capturas finais. Retorno, área segura e ausência de barras duplicadas também têm testes de widget. Não declarar pixel-perfect: ícones Material/gradiente são aproximados e quantias das fixtures diferem da prancha. Sem barra de status iPhone desenhada artificialmente.

## Comportamento verificado

21 testes novos do shell, suíte normal com **475 aprovados** (454 anteriores preservados). Incluem login para Início, barreira de perfil, abas/controller/carga únicos, preservação da rolagem, Ver todas, formulário pelas duas origens, retorno com saldo e histórico atualizados, bloqueio de abertura duplicada, falha de refresh após commit com retry somente de leitura e aviso stale ao voltar manualmente, logout/dispose/Voltar, troca de UID e respostas atrasadas. Responsividade 360/390/412 com fonte 1/2 e diretrizes locais de rótulos/alvos de toque verificadas. Fluxos M4 de cadastro/login/recuperação/perfil parcial continuam cobertos na mesma árvore integrada.

`dart format .`: 102 arquivos, zero alterados na execução final. Analyzer: 41 informes de depreciação (37 baseline + quatro imports Material), zero erros/warnings. `git diff --check`: sem erros, apenas avisos informativos de conversão LF/CRLF em arquivos locais. Logs ignorados em build/m5-5-*.log.

## Reproduzir a captura local

```powershell
$env:BOLSOZEN_FONT_DIR='C:\dev\flutter\bin\cache\artifacts\material_fonts'
flutter test test/visual/m5_shell_capture.dart --dart-define=M5_VISUAL_CAPTURE=true --concurrency=1
```

Desabilitado por padrão, fora da descoberta normal de testes. Ajustar caminho de fontes ao SDK instalado; não copiar fontes nem executar app normal com contas reais para gerar estas imagens.

## Pendências

Revisão visual do usuário e autorização do M5.6. Nenhum novo build/execução Android/Chrome, teclado nativo ou TalkBack homologado nesta etapa; sem teste de persistência por plugins reais. Integração com emuladores e dispositivo pertence ao próximo escopo autorizado. Leitura paginada continua não atômica perante alterações externas; incerteza de escrita segue o tratamento M5.4, sem replay automático. Não houve alteração Firebase/regras/índices/Gradle/dependências, operação remota, staging, commit, push ou deploy.
