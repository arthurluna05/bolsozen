# M4.4 — Evidências e revisão visual

Estado: telas implementadas, 269 testes locais aprovados e comparação básica Chrome realizada. **Aguardando revisão do usuário; homologação visual integral pendente**, incluindo Android/teclado nativo e capturas adicionais interrompidas por falta de memória do processo Dart. Não declarar pixel-perfect.

## Fontes e decisões preservadas

Relidos AGENTS.md, PLANO.md, PLANO_M4.md, PROGRESSO.md e documentos 01–05; prancha `design/telas/bolsozen_prototipo.png` inspecionada. Hierarquia aplicada: requisitos/segurança, tokens do Design System, composição da prancha e componentes aprovados. Nenhum documento de requisitos ou asset foi alterado.

| Tela | Referência visual e composição |
|---|---|
| Login | TEL-02 e coluna Login da prancha: retorno, título/instrução, E-mail/Senha com ícones de contorno, recuperação alinhada à direita, Entrar, divisor “ou”, Criar conta e informação de autenticação Firebase |
| Recuperação | TEL-10 complementar: cabeçalho/retorno, instrução, E-mail, envio, confirmação neutra e retorno ao login; usa os mesmos componentes de TEL-02 |
| Perfil | TEL-09 complementar: inicial do nome, nome/e-mail, cartão Minha conta e Sair. Sem desenho completo na prancha, sem dashboard ou barra com áreas inexistentes |
| Boas-vindas | TEL-01 e decisões M1 aprovadas: logo oficial grande com nome incorporado, três imagens/carrossel e layout preservados; apenas ação de Entrar conectada |

TEL-03/Cadastro foi consultada como referência da família visual, mas **não implementada**: pertence ao M4.5. Criar conta continua mostrando aviso acessível e não abre cadastro falso.

## Tokens reutilizados

Roboto existente; títulos médios 20/w700, corpo 14/w400, rótulos 14/w600 e legendas 12. primary #0E7D68, secondary #10B981, mintSurface #E9FDF6, surfaceMuted #F3F4F6, textPrimary #111827, textSecondary #6B7280 e border #E5E7EB. Espaçamentos 4/8/12/16/24/32, padding de tela 16, raios de campo/botão 12 e cartão 16. Cartão herda elevação 1 do tema. Ícones oficiais Material de contorno, sem bibliotecas/fontes novas.

Densidade standard e alvos de toque mínimos de 48 dp aplicados no AuthFormLayout; não alteram a densidade/layout da boas-vindas. primaryContainer/onPrimaryContainer usam mintSurface/primary para evitar cor de avatar gerada fora da paleta. Texto de erro de campo usa textPrimary legível, com borda de erro e mensagem explícita; confirmação usa primary. Não depender apenas de cor.

## Método de captura e identificação dos dados

Aplicativo Flutter executado no Chrome headless pelo entrypoint **exclusivo de testes** `test/visual/m4_auth_preview.dart`, usando AuthExperience, SessionGate e as telas de produção. Somente contratos de autenticação/perfil são substituídos por fakes locais. Banner visível **TESTE VISUAL**, nome “Teste visual BolsoZen” e endereço visual@example.test identificam a fixture. Não são conta ou perfil Firebase; nenhum FirebaseApp/repositório remoto é instanciado pelo runner e nenhuma conta real é criada/usada.

As capturas são renderizações reais do Flutter/Chrome, não imagens geradas nem mockups desenhados. Não comprovam SDK, login remoto ou entrega de e-mail. Script Node `test/visual/capture_m4_auth.cjs` usa somente CDP local e APIs nativas do Node; sem dependências adicionais. A seleção do arquivo final preserva apenas a versão corrigida das telas, com DPR 1, altura 900 e larguras CSS equivalentes às larguras lógicas testadas. Manifesto com dimensões e hashes em [evidencias/m4-4/manifest.json](evidencias/m4-4/manifest.json).

## Screenshots finais preservadas

| Tela | 360 dp | 390 dp | 412 dp |
|---|---|---|---|
| Login | [PNG](evidencias/m4-4/login-360.png) | [PNG](evidencias/m4-4/login-390.png) | [PNG](evidencias/m4-4/login-412.png) |
| Recuperação | [PNG](evidencias/m4-4/recuperacao-360.png) | [PNG](evidencias/m4-4/recuperacao-390.png) | [PNG](evidencias/m4-4/recuperacao-412.png) |
| Perfil de teste | [PNG](evidencias/m4-4/perfil-teste-360.png) | [PNG](evidencias/m4-4/perfil-teste-390.png) | [PNG](evidencias/m4-4/perfil-teste-412.png) |

Adicional: [confirmação neutra da recuperação, 390 dp](evidencias/m4-4/recuperacao-confirmacao-teste-390.png). Todas as dez imagens foram inspecionadas; cerca de 232 KB no total. Banner e dados de teste não aparecem na aplicação de produção.

## Divergências identificadas e corrigidas

- Link Esqueci minha senha recebeu sublinhado conforme prancha; retorno da recuperação segue a mesma linguagem de link.
- A compactação desktop reduzia a pintura dos botões nas primeiras capturas; AuthFormLayout passou a fixar densidade standard e preservar mínimo 48 dp, mantendo estilos/radius do tema. A boas-vindas não foi redesenhada.
- Legenda Login com Firebase passou a usar textSecondary, mantendo informação secundária abaixo do destaque verde.
- A ativação inicial do gate apagaria o formulário durante login sem UID. Ajustado para manter a árvore pública nesse estágio: botão mostra loading, falha preserva campos e senha permanece apenas em memória. UID confirmado destrói o formulário e exige perfil antes do acesso privado. Testes cobrem esse comportamento.

## Diferenças intencionais ou inevitáveis restantes

- Campos usam surfaceMuted do Design System; a imagem raster aparenta campos mais claros. Botões usam preenchimento sólido e radius 12 do tema, sem reproduzir sombras/gradientes imprecisos da prancha. Tokens têm prioridade.
- E-mail/senha começam vazios; os valores ilustrativos da prancha não foram copiados. Não há política/termos, cadastro ou navegação financeira falsa.
- Roboto foi mantida como aprovado; a fonte e as métricas raster da prancha não permitem comprovar correspondência exata. Nenhuma Inter ou biblioteca de ícones foi instalada.
- Perfil e recuperação não possuem tela desenhada integralmente na prancha; são extensões funcionais TEL-09/TEL-10 com os mesmos tokens. Perfil é destino temporário aprovado para M4; Dashboard permanece M5.
- Capturas Chrome não incluem barra iOS, moldura de telefone ou status bar desenhada. No Android será usada a área segura nativa. O banner TESTE VISUAL é exclusivo da evidência local.
- Responsividade utiliza largura disponível e rolagem, sem fixar posições absolutas a partir da imagem gerada. Quebras de linha variam por largura e escala de texto.

## Responsividade e acessibilidade verificadas

18 testes de widget: Login/Recuperação/Perfil × 360/390/412 dp × escalas 1/2, altura 640. Nos formulários, teclado de teste aberto e viewInsets de 300 dp; ações acessíveis por rolagem e sem exceções de layout. Perfil foi verificado com texto ampliado, sem campo/teclado desnecessário. Campos têm foco/teclado apropriados, senha com mostrar/ocultar e tooltip, mensagens liveRegion e botões desabilitados/loading. As capturas normais nas três larguras não apresentaram cortes ou overflow na inspeção.

Isso **não equivale a validar teclado Android real, TalkBack/VoiceOver, tabulação completa ou todas as alturas/orientações**. Escala 2 e teclado simulado passaram nos testes automatizados; suas capturas adicionais no Chrome não foram concluídas.

## Interrupção e limites da execução visual

A primeira coleta, antes das correções, encontrou asserção do engine Web `_viewInsets.isNonNegative` ao alternar a emulação móvel do CDP. Suas imagens iniciais ficaram em build/m4-4-visual-before, fora do conjunto final. A coleta seguinte usou viewports CSS sem emulação móvel, após repetir format/analyze/test com sucesso.

Na coleta final foram salvas as dez imagens acima. Durante recargas adicionais para estados/escala/teclado, o processo Dart das ferramentas encerrou com **runtime/vm/zone.cc:95 — Out of memory**, e o cliente de captura recebeu timeout CDP. Não foi tratado como aprovação da sessão completa; [manifesto](evidencias/m4-4/manifest.json) registra interrupção. O Chrome temporário foi encerrado, logs preservados e **nenhuma nova compilação foi iniciada após o OOM**. Não houve limpeza de cache ou alteração de memória Gradle. A observação de memória livre após a falha não é medição de pico nem diagnóstico preciso de sua causa.

Após a interrupção, apenas o supervisor JS foi melhorado: grava manifesto incremental, possui timeout e limita o modo padrão às dez capturas básicas; extras exigem --extended. Essa revisão passou node --check, mas não foi reexecutada no navegador após o OOM. Não modifica a UI ou os resultados anteriores de testes.

Evidências locais adicionais ignoradas: build/m4-4-tests.log, build/m4-4-analyze.log, build/m4-4-visual-run.log e build/m4-4-visual-final-run.log. Não copiar logs brutos ou dumps para o Git.

## Pendências de homologação

1. Revisão do usuário das imagens e das diferenças acima; M4.4 ainda não declarado aprovado.
2. Validar visualmente no Android e com teclado nativo/tecnologia assistiva em etapa autorizada, preservando ajustes de memória e sem build simultâneo.
3. Se necessário, autorizar nova coleta após diagnóstico/ajuste de recursos para imagens de texto 2× e teclado simulado; não repetir automaticamente a compilação após OOM.
4. Homologar autenticação/persistência/entrega de e-mail com roteiro autorizado em etapa posterior. Nenhum teste remoto realizado agora.
5. Cadastro/Completar perfil somente após aprovação específica do M4.5.
