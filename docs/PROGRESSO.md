# BolsoZen — Progresso

## Estado atual — 17/11/2026

- Flutter 3.50.0 stable e Dart 3.14.0 identificados nos metadados locais.
- Cinco documentos e protótipo analisados; AGENTS.md lido.
- Tela de boas-vindas e fundação visual M1 implementadas. M2 entrega domínio financeiro puro testado, ainda sem integração à interface, persistência, autenticação ou Firebase.
- Na verificação inicial desta etapa: main limpa, um commit à frente da referência local origin/main; sem fetch.
- M0 criou somente os documentos. M1 altera a base Flutter e dependências conforme detalhado abaixo; sem commit.

## Marcos

- [x] Análise do repositório, documentos e protótipo.
- [x] M0 — Registrar planejamento técnico e progresso.
- [ ] M1 — Implementado / Não validado integralmente: testes automatizados aprovados; Android e revisão visual pendentes; avisos do SDK registrados abaixo.
- [x] M2 — Domínio financeiro e testes: concluído no escopo puro, 53 testes unitários aprovados.
- [ ] M3 — Firebase e segurança.
- [ ] M4 — Autenticação completa.
- [ ] M5 — Transações e dashboard essencial.
- [ ] M6 — Gestão e histórico completos.
- [ ] M7 — Orçamento mensal.
- [ ] M8 — Relatórios.
- [ ] M9 — Homologação e APK.

M1 autorizado e implementado, com pendências próprias. M2 autorizado e concluído no escopo de domínio. M3 a M9 aguardam autorização individual. Detalhes em PLANO.md.

## Evidências do M0

- Verificação de existência dos dois documentos antes da criação e inspeção do estado Git.
- Planejamento reconciliado com requisitos, jornadas, design e critérios de aceite já lidos.
- Validação desta entrega: revisão textual e diff limitado aos dois Markdown.
- Não executados dart format ., flutter analyze, flutter test ou build: alteração exclusivamente documental; nenhum comportamento implementado ou validado.

## Bloqueios e pendências

- Sem bloqueio para concluir o planejamento.
- Configuração real Firebase, acesso ao Console e emuladores ainda não validados.
- Logo fornecida em assets/branding/bolsozen_logo.png; nome diferente do inicialmente informado, confirmado pelo usuário para uso sem alteração.
- Testar escala do carregamento paginado completo e conversões de datas/fuso.
- Tratar perfil parcialmente criado e gravação offline sem sucesso falso.
- Decidir assinatura de release antes da entrega; atual configuração utiliza debug.
- Sem autorização para publicar regras/índices, habilitar serviços pagos, fazer push ou deploy.

## Próxima tarefa recomendada

Revisar a entrega do M2 e autorizar separadamente M3 antes de qualquer integração. Permanecem validação Android/visual do M1 e decisão sobre depreciações do SDK.

## Entrega M1

### Arquivos e funcionalidades

- lib/main.dart: inicializa BolsoZenApp; contador removido.
- lib/app/app.dart: MaterialApp, tema claro, pt_BR, delegados oficiais Material/Widgets/Cupertino e título BolsoZen.
- lib/core/theme/app_colors.dart: paleta centralizada do design system.
- lib/core/theme/app_spacing.dart: espaçamentos e raios.
- lib/core/theme/app_theme.dart: Material 3, Roboto, tipografia, botões, campos e cartões.
- lib/presentation/screens/welcome/welcome_screen.dart: logo oficial com BoxFit.contain, sem edição do PNG, proposta do app, SafeArea, largura limitada e rolagem. Botões Entrar/Criar conta abrem diálogo acessível sobre disponibilidade futura, sem autenticação ou páginas falsas.
- pubspec.yaml/pubspec.lock: material_ui removido, flutter_localizations e intl adicionados como dependências diretas; dependências transitivas desnecessárias removidas pelo resolvedor. Preservada alteração prévia do usuário cupertino_icons ^2.0.0. Corrigida declaração de assets para dentro de flutter.
- test/widget_test.dart: substitui teste do contador por 10 testes de marca/localização, ações, layout e disponibilidade de formatação BRL via intl; nenhuma regra financeira antecipada.
- assets/branding/bolsozen_logo.png: arquivo preexistente do usuário, apenas referenciado, sem edição ou renomeação.

### Verificações executadas

- flutter pub get: sucesso.
- dart format .: sucesso; última execução, 7 arquivos verificados, 0 alterações.
- flutter analyze: executado, saída 1 com 8 informações de deprecated_member_use, sem erros de compilação ou warnings. SDK local deprecia flutter/material.dart, flutter/cupertino.dart e GlobalMaterialLocalizations em favor dos pacotes separados. Não suprimidos diagnósticos nem reintroduzida dependência sem autorização. Esta divergência não era conhecida no planejamento.
- flutter test: última execução aprovada, 10/10. Corrigidos dois testes de toque para rolar até os botões quando a viewport é baixa.
- Responsividade automatizada: 360, 390 e 412 dp, altura 640, escala de texto 1 e 2; botões acessíveis por rolagem, sem exceções de layout. Isso não constitui comparação visual por screenshots.
- flutter devices: nenhum Android conectado inicialmente. flutter emulators encontrou Pixel_8 e Medium_Phone_API_37.0.
- flutter emulators --launch Pixel_8: comando aceito; dispositivo emulator-5554 permaneceu offline nas verificações seguintes.
- flutter run -d emulator-5554 --no-pub: falhou, nenhum dispositivo suportado correspondente. Sem evidência de renderização Android ou screenshot real; não declarar aprovação visual.

### Diferenças e validação manual pendente na entrega inicial

- Usada a logo oficial fornecida, diferente da carteira da prancha; nome já integrado ao PNG, sem duplicá-lo como texto visual. Sem recorte, distorção ou substituição.
- Ilustração secundária de gráfico/moedas ausente por não haver asset fornecido; não foi inventada. Pontos decorativos de carrossel omitidos conforme design system.
- Título explicativo e conteúdo centralizado, botões após o conteúdo e rolagem em telas compactas; hierarquia adaptada à logo fornecida, sem alegação pixel-perfect.
- Roboto declarada no tema, sem download de fontes ou dependência adicional; confirmar aparência no Android.
- Abrir emulador funcional ou conectar Android com depuração USB; executar flutter devices e flutter run -d <id>. Conferir proporções/transparência da logo, cores, espaçamentos, rolagem, diálogos, TalkBack, texto ampliado e comparar screenshot com prancha.
- Decidir se manter imports depreciados conforme autorização original ou revisar a remoção de material_ui para alinhar ao SDK atual. Não alterar SDK, reintroduzir pacotes ou ocultar diagnósticos sem decisão.
- M1 permanece Implementado / Não validado integralmente até revisão visual/Android e resolução da pendência do analisador. Nenhum M2+, Firebase, commit, push ou deploy realizado.

### Ajuste visual M1 — carrossel e hierarquia

- Ajuste autorizado explicitamente pelo usuário: carrossel funcional simples, apesar de o design system permitir pontos meramente decorativos. Documentos de requisitos e protótipo preservados.
- Arquivos alterados nesta revisão: lib/presentation/screens/welcome/welcome_screen.dart, pubspec.yaml, test/widget_test.dart e docs/PROGRESSO.md. Mantidas as demais alterações preexistentes do M1.
- Confirmados e inspecionados visualmente onboarding01.png, onboarding02.png e onboarding03.png. Corrigida declaração para assets/illustrations/ dentro de flutter/assets; sem editar imagens, adicionar pacotes ou alterar lockfile nesta revisão.
- Removido título “Suas finanças com mais tranquilidade”. Ordem atual: logo oficial em 128 × 128 com proporção preservada, nome BolsoZen, único subtítulo solicitado, carrossel e botões. O PNG original já contém o nome da marca; foi preservado integralmente, com nome textual separado conforme solicitado.
- Carrossel com PageView nativo, três páginas, swipe horizontal, sem autoplay e sem textos específicos por slide. Área responsiva com AspectRatio e BoxFit.contain; três pontos atualizados por onPageChanged e anúncio semântico “Ilustração N de 3”. Estado limitado ao widget privado do carrossel.
- Botões mantêm estilos existentes e diálogos de disponibilidade futura; sem autenticação, rotas falsas ou lógica financeira.
- dart format .: aprovado, 7 arquivos processados na última execução.
- flutter analyze: executado; saída 1, mesmos 8 diagnósticos informativos deprecated_member_use do SDK, sem novos diagnósticos. Não suprimidos nem alteradas dependências fora do pedido.
- flutter test: aprovado, 11/11. Teste novo verifica swipe até as três imagens, retorno à segunda, três pontos presentes e anúncio da página; mantidos testes de botões/localização e layout em 360/390/412 dp com texto 1× e 2×. Corrigido descarte do handle semântico do teste antes do encerramento.
- Diferenças restantes: logo e ilustrações são os arquivos oficiais fornecidos, com composição própria diferente da prancha; dimensões adaptadas ao layout Flutter, rolagem para alturas compactas/texto ampliado. Não houve captura ou comparação de screenshots reais nesta revisão, portanto não se afirma fidelidade pixel-perfect.
- Validações manuais pendentes: renderização Android, aparência/transparência das imagens em fundo branco, proporções/espaçamentos, swipe real, indicador e TalkBack, comparação com o protótipo. Permanece a decisão sobre depreciações do SDK antes de encerrar integralmente M1. Não iniciar M2 sem autorização; sem commit.

## Registro das próximas fases

## Entrega M2 — domínio financeiro

Estado: Concluído no escopo autorizado de domínio puro. Nenhuma alteração na UI, configuração Firebase, implementação de persistência, autenticação, dependência nova ou commit.

### Arquivos criados

- lib/domain/models/category.dart: TransactionType e catálogo fechado de dez categorias, IDs estáveis, rótulos pt-BR e compatibilidade por tipo.
- lib/domain/models/financial_month.dart: competência com chave YYYY-MM, igualdade por valor, deslocamento mensal e agrupamento pelo calendário local.
- lib/domain/models/financial_transaction.dart: modelo imutável validado, centavos positivos, descrição trim de 1–120 caracteres, categoria compatível e copyWith preservando identidade/criação.
- lib/domain/models/monthly_budget.dart: limite imutável por usuário/mês/categoria de despesa, valor positivo e ID determinístico.
- lib/domain/models/financial_summary.dart: resultados imutáveis de totais mensais, utilização, distribuição, evolução e histórico. Percentuais são double derivados; dinheiro continua int. Coleções de saída não modificáveis.
- lib/domain/repositories/transaction_repository.dart: contrato financeiro por UID, consulta paginada com cursor de domínio e operações criar/editar/excluir; sem tipos Firebase. Criação retorna ID gerado pela implementação futura.
- lib/domain/repositories/budget_repository.dart: contrato financeiro por UID, consulta, salvar/substituir e remover limite mensal. Sem implementações, mocks ou contratos de autenticação antecipados.
- lib/domain/services/money.dart: parsing estrito de valores positivos pt-BR com agrupamento opcional, R$ e 1–2 casas decimais; formatação exata em BRL, inclusive saldo zero/negativo. Sem conversão monetária para double.
- lib/domain/services/financial_calculator.dart: funções puras, sem Flutter/Firebase/relógio. Recebem UID, competência, transações completas e limites; ignoram dados de outros UIDs. Saldo global, totais mensais, ordenação, categorias, orçamento, comparação e evolução de seis meses. Agregações protegem contra overflow do inteiro nativo com BigInt intermediário, retornando int ou erro explícito.
- test/domain/fixtures.dart: conjuntos controlados apenas para testes.
- test/domain/money_test.dart, models_test.dart e financial_calculator_test.dart: 53 testes unitários do domínio.
- docs/PROGRESSO.md atualizado; demais arquivos preexistentes preservados.

### Regras e evidências

- T1: saldo 60000 centavos, receita novembro 100000, despesa novembro 35000 e outubro 5000; seleção mensal não muda saldo global.
- T2: alimentação 83,33%, transporte 50%, indicador global 70%; despesas sem limite não entram no indicador. Percentuais acima de 100% não truncados; atenção em 80% e atingido em 100%, com comparação inteira dos limiares.
- Relatórios: participação alimentação ≈71,43% e transporte ≈28,57%, variação +600%, evolução de seis meses com virada de ano; redução pode ser negativa e base anterior zero retorna null.
- CA-07 reproduzido: edição para R$ 200 gera saldo R$ 650,00, novembro R$ 300,00 e alimentação 66,67%; mudança para outubro redistribui totais sem alterar saldo; exclusão de transporte eleva saldo a R$ 750,00.
- Cobertos: saldos positivo/zero/negativo, centavos além da precisão de double no runtime nativo, inválidos, categorias incompatíveis, valores zero/negativos, futura ocorrência, auditoria distinta da ocorrência, conversão UTC/local, ordenação por ocorrência/criação/ID ascendente, imutabilidade, remoção de limite e ausência de herança mensal.
- Sem limites: percentual/status null; sem despesas: distribuição vazia, nunca dados fictícios. Nenhuma divisão por zero. Duplicação de limites na mesma competência/categoria é recusada em vez de sobrescrever silenciosamente o cálculo.
- dart format .: aprovado, 20 arquivos processados na última execução, 0 alterações.
- dart analyze lib/domain: aprovado, No issues found.
- flutter analyze: executado; permanecem somente os 8 diagnósticos informativos preexistentes de deprecated_member_use do M1, saída 1; nenhum diagnóstico no M2. Seis apontamentos iniciais de estilo dos novos arquivos foram corrigidos e as verificações repetidas.
- flutter test: aprovado, 64/64 (53 domínio + 11 widgets preexistentes).
- git diff --check: aprovado. Nenhuma instalação, publicação ou alteração de dependências.

### Limitações e pendências antes de M3

- Contratos não têm implementação: geração de IDs/auditoria, paginação real, Firestore, índices e segurança de acesso devem ser implementados/testados apenas no M3 autorizado. Filtragem por UID no cálculo não substitui regras de segurança.
- Chamador deve fornecer histórico completo sem duplicatas; o domínio não infere se faltam páginas. Meses são agrupados pelo fuso local do runtime, sem fuso fixo adicional. Testes validam UTC/local no ambiente atual; variações entre dispositivos permanecem para integração.
- Valores monetários usam faixa de int do runtime Android/nativo; excesso é rejeitado, sem arredondamento silencioso. Web não é critério do MVP. Categorias/descrição são validadas por construtores, e dados inválidos vindos de serviços devem ser tratados na camada de dados futura.
- Autorização do usuário, acesso ao Console, região e ferramentas Firebase ainda pendentes para M3. Pendências visuais/Android e depreciações do M1 permanecem independentes desta entrega.
- Validação manual sugerida: revisar os contratos e os resultados T1/T2 antes de autorizar M3. Não há tela financeira a validar neste marco.

### Revisão M1 — logo ampliada e tipografia

- A pedido do usuário, removido nome BolsoZen em texto separado: o título visual agora é exclusivamente o nome incorporado à logo oficial.
- Logo ampliada de 128 para 280 dp, limitada pela largura disponível e com BoxFit.contain, sem modificar o PNG. Mantidos subtítulo único, carrossel e botões; rolagem preserva acesso em telas menores.
- Todos os estilos do TextTheme explicitam Roboto e seguem os tamanhos/pesos documentados: títulos 28/20/16, corpo 14 e legendas 12 sp. Ajustadas entrelinhas e espaçamento de letras para composição mais compacta e consistente com a referência. Diálogos também herdam a tipografia global.
- Arquivos alterados nesta revisão: lib/presentation/screens/welcome/welcome_screen.dart, lib/core/theme/app_theme.dart, test/widget_test.dart e docs/PROGRESSO.md. Sem novas dependências ou edição de assets.
- dart format .: aprovado, 7 arquivos processados. flutter test: 11/11 aprovados, incluindo carrossel e layouts em 360/390/412 dp com texto 1×/2×. flutter analyze: mesmos 8 diagnósticos informativos de depreciação preexistentes, sem novos diagnósticos.
- Continua pendente revisão visual no Android e comparação por screenshot; não se afirma correspondência exata da fonte rasterizada do protótipo. Roboto é a opção inicial aprovada, sem fonte Inter fornecida. M1 permanece não validado integralmente pelas pendências já registradas; sem M2 ou commit.

Para cada marco registrar: estado, checklist, arquivos alterados, comandos/resultados, evidências, limitações, problemas restantes e validação manual. Estados: Planejado, Em andamento, Implementado / Não validado, Bloqueado ou Concluído. Nunca marcar validação pendente como aprovada. Não avançar automaticamente entre marcos.
