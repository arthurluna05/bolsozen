# M4.5 — Cadastro e conclusão de perfil: evidências visuais

M4.4 foi aprovado visualmente pelo usuário antes desta etapa: onboarding, login e recuperação satisfatórios e fiéis ao protótipo. Esse aceite posterior prevalece sobre a pendência histórica registrada no relatório M4.4. M4.5 aguarda revisão própria; não declarar pixel-perfect.

## Referências e componentes

Relidos AGENTS.md, PLANO.md, PLANO_M4.md, PROGRESSO.md, documentos 01–05 e M4_4_VALIDACAO_VISUAL.md. Prancha oficial `design/telas/bolsozen_prototipo.png` inspecionada, especialmente TEL-03: retorno, título “Criar sua conta”, instrução, Nome/E-mail/Senha/Confirmar senha com ícones, botão Criar conta e link Já tenho conta. Completar perfil é tela complementar documentada, sem desenho próprio na prancha.

Reutilizados AuthFormLayout, PasswordField e SubmitButton do M4.4; Material 3 e Roboto, título 20/w700, corpo 14, legenda 12, primary #0E7D68, textPrimary #111827, textSecondary #6B7280, surfaceMuted #F3F4F6 e border #E5E7EB. Padding 16, espaçamentos 8/16/24, raios 12 e alvos de toque 48 dp do tema. Ícones oficiais person_outline, mail_outline, lock_outline e visibility_outlined. Não houve troca de fontes, bibliotecas, tema global ou assets; onboarding/login/recuperação não foram redesenhados.

## Captura real no Chrome

Preview Flutter executado em Chrome headless, uma compilação e uma página, sem recargas sucessivas. Entry point `test/visual/m4_auth_preview.dart`, somente fakes locais com banner TESTE VISUAL. O roteiro clicou Criar conta, capturou cadastro em três larguras, alternou para login e usou uma sessão fake sem perfil para capturar Completar perfil. Nenhum FirebaseApp, conta remota, documento remoto ou e-mail real foi utilizado. As imagens são screenshots do renderer real, não mockups nem prova de persistência Firebase.

| Tela | 360 dp | 390 dp | 412 dp |
|---|---|---|---|
| Cadastro TEL-03 | [PNG](evidencias/m4-5/cadastro-360.png) | [PNG](evidencias/m4-5/cadastro-390.png) | [PNG](evidencias/m4-5/cadastro-412.png) |
| Completar perfil, fixture local | [PNG](evidencias/m4-5/completar-perfil-teste-360.png) | [PNG](evidencias/m4-5/completar-perfil-teste-390.png) | [PNG](evidencias/m4-5/completar-perfil-teste-412.png) |

[Manifesto de captura](evidencias/m4-5/manifest.json): status m4_5_complete, runtimeErrors vazio, DPR 1, altura 900, escala 1 e larguras CSS 360/390/412. As seis imagens foram abertas e comparadas com a referência. Sem cortes ou overflows visíveis; ícones, campos, botão e link mantêm a hierarquia TEL-03. O Chrome temporário foi encerrado depois das capturas; não houve OOM nesta execução. Logs locais de ferramenta ficam em build/m4-5-visual-run.log, fora do Git.

## Diferenças documentadas

- Checkbox/links de Termos e Privacidade omitidos conforme requisito e planejamento aprovados: não existem textos reais publicados. Por isso, botão e link ficam mais próximos do último campo que na prancha.
- Campos começam vazios; não copiar nome/e-mail/senha ilustrativos. Em Completar perfil, visual@example.test é fixture explicitamente identificada, nunca identidade fabricada em produção.
- Fundo cinza dos campos, preenchimento sólido do botão e medidas vêm dos tokens e componentes aprovados M4.4. A prancha raster não permite comprovar métricas exatas ou reproduzir gradientes/sombras por medida.
- Não desenhar status bar de iPhone, moldura ou elementos decorativos. Banner TESTE VISUAL é exclusivo do runner e não aparece no aplicativo normal.
- Completar perfil usa e-mail somente leitura e nome, sem senha, cadastro duplicado, dashboard ou opções de edição. Compartilha os componentes da família de autenticação.

## Responsividade e limites

12 novos testes de widgets cobrem Cadastro/Completar perfil × 360/390/412 × texto 1/2, altura 640 e teclado simulado com inset 300. Ações permanecem alcançáveis por rolagem e sem exceções de layout. Campos recebem foco no primeiro erro, avançam pelo teclado e possuem rótulos; senhas têm visibilidade independente, feedback usa liveRegion e operações desabilitam múltiplos envios.

Screenshots acima são escala 1 e sem teclado nativo. Texto ampliado e teclado foram verificados automaticamente, não homologados visualmente no Android. TalkBack, teclado Android, rotação, persistência entre reinícios e sessão real do navegador permanecem para roteiro M4.6 autorizado. Estas evidências não substituem o aceite visual do usuário para M4.5.
