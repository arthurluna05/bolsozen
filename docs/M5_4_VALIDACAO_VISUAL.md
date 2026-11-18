# M5.4 — Formulário TEL-05 para revisão

Implementado exclusivamente cadastro de movimentação e quatro ajustes finais aprovados do M5.3. Não houve integração à navegação normal (M5.5), escrita remota, Firebase em captura, build Android ou alteração de dependências. Referências: AGENTS.md, PLANO_M5.md, requisitos, Design System e TEL-05 da prancha oficial. Onboarding, autenticação e Perfil permanecem intactos.

## Composição e auditoria

| Elemento | Referência | Implementação | Avaliação |
|---|---|---|---|
| Cabeçalho | Voltar e Nova transação centralizado | AppBar Material e retorno real quando há rota anterior | Aproximado; métricas nativas |
| Tipo | Receita menta / Despesa rosa | Controles com setas Material, seleção e borda visíveis | Aproximado; cor do texto Despesa ajustada para contraste AA |
| Valor | Campo em reais, símbolo verde | Entrada textual original validada com Money/BigInt; prefixo sem duplicar R$ colado | Fiel ao propósito; sem arredondamento |
| Categoria | Ícone e seleção | Catálogo real por tipo, cores oficiais, dropdown nativo | Aproximado; menu Material |
| Data | Campo com calendário | dd/MM/yyyy pt-BR e seletor real, aceita data futura | Adaptação para preservar leitura em texto ampliado |
| Descrição | Campo obrigatório | Texto multilinha e contador Unicode 1–120 | Contador/rótulo flutuante são diferenças explícitas |
| Conta | Conta principal | Informativa com carteira, sem seta ou seletor falso | Adaptação à conta única do MVP |
| Salvar | Botão verde inferior | SubmitButton existente com loading e validação | Aproximado; desloca-se com teclado/rolagem |

Reutilizados AppTheme/Roboto, AppColors/AppSpacing/AppRadii, Material 3, SubmitButton e CategoryIcon; nenhum asset, fonte ou pacote externo novo. Não afirmar medidas extraídas da prancha como tokens exatos nem fidelidade pixel-perfect. No texto ampliado, campos/cartões crescem e rolam; data abreviada evita o corte observado na primeira captura. Pastéis e aparência aprovada do Dashboard/Histórico preservados, com quatro alterações descritas no relatório M5.3.

## Capturas reais do renderer Flutter

| Condição | Evidência |
|---|---|
| 360 dp | [Formulário](evidencias/m5-4/nova-transacao-360-texto-1-teclado-0.png) |
| 390 dp, principal TEL-05 | [Formulário](evidencias/m5-4/nova-transacao-390-texto-1-teclado-0.png) |
| 412 dp | [Formulário](evidencias/m5-4/nova-transacao-412-texto-1-teclado-0.png) |
| 360 dp, texto 2 | [Texto ampliado](evidencias/m5-4/nova-transacao-360-texto-2-teclado-0.png) |
| 360 dp, inset teclado 300 | [Área disponível reduzida](evidencias/m5-4/nova-transacao-360-texto-1-teclado-300.png) |
| 390 dp, valores vazios | [Estado inicial](evidencias/m5-4/nova-transacao-390-texto-1-teclado-0-vazio.png) |

[Manifesto](evidencias/m5-4/manifest.json): fixtures em memória, sem escrita, banner de teste, relógio fixo somente no runner. Fonte carregada do SDK instalado; nada copiado ao app. A rota anterior técnica existe apenas na fixture para verificar o botão Voltar real. Nenhum clique em Salvar durante captura. Insets simulados não demonstram teclado Android/iPhone, foco nativo ou TalkBack.

```powershell
$env:BOLSOZEN_FONT_DIR='C:\dev\flutter\bin\cache\artifacts\material_fonts'
flutter test test/visual/m5_financial_capture.dart test/visual/m5_transaction_capture.dart --dart-define=M5_VISUAL_CAPTURE=true --concurrency=1
```

Runner desabilitado por padrão, fora da descoberta normal de testes. Sem Firebase inicializado. As capturas não são homologação Chrome/MSI; revisão visual do usuário continua necessária.

## Comportamento e testes

O controller chama create uma vez, valida expectedUserId e aguarda recarga completa posterior. Só encerra o formulário com sucesso atualizado após a leitura confirmar o ID gravado. Se commit foi confirmado mas refresh falhou, oferece apenas retry de leitura. Resultado desconhecido bloqueia replay do mesmo formulário e solicita conferência do histórico, sem afirmar que a gravação foi cancelada. Sessão invalidada remove formulário/dados; falhas definidas preservam a entrada para correção.

454 testes normais aprovados, preservando 414 anteriores. Os 40 novos cobrem validações puras, controller e widgets, concorrência, estados de falha/commit, proteção de identidade, calendário e responsividade 360/390/412 com fonte ampliada/insets. Dois testes separados de captura aprovados; 18 PNGs totais incluindo M5.3. Analyzer: 37 informes de depreciação, zero erros/warnings. Format e diff-check sem erro. Primeiras falhas e correções estão registradas em PROGRESSO.md, sem ocultar diagnósticos.

Limites: CRUD deste formulário ainda não homologado com repositório FlutterFire real nesta etapa; testes usam contrato real e fakes determinísticos, sem contas/dados remotos. Confirmação de persistência real e navegação compartilhada serão avaliadas somente nos escopos posteriormente autorizados. Sem timeout tratado como cancelamento, replay automático, edição/exclusão, orçamento ou relatórios. Aguardar revisão do M5.4 antes de M5.5.
