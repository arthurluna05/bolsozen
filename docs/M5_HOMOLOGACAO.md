# M5 — Encerramento com ressalvas

**Aprovado pelo usuário após teste manual do aplicativo integrado.** M5 encerrado por autorização expressa. A homologação extensa M5.6 foi dispensada, não executada; não há aprovação automática de verificações que permanecem sem evidência.

Entregues Dashboard e Histórico, cadastro de receitas/despesas, navegação privada Início/Transações/Perfil, FinancialController compartilhado, proteção de identidade por UID/expectedUserId e correção da precisão monetária Web. Dinheiro permanece em centavos inteiros, parser usa BigInt antes da conversão e fronteiras de entrada/persistência rejeitam valores incompatíveis explicitamente. Formulário confirma escrita e recarga, diferenciando atualização pendente e resultado incerto sem replay automático.

## Evidências preservadas

| Evidência | Resultado e alcance |
|---|---|
| Aceite do usuário | Fluxo financeiro integrado testado e aprovado manualmente; não informa uma bateria discriminada por plataforma/dispositivo |
| Última suíte Flutter M5.5 | 475 aprovados; domínio/dados/controllers/widgets, usando fakes quando indicado |
| Último analyzer M5.5 | 41 informes de depreciação; zero erros/warnings; exit 1 pelos informes |
| Formatação M5.5 | 102 arquivos, zero alterados na execução final; exit 0 |
| Capturas integradas M5.5 | Um teste opt-in aprovado, oito screenshots do renderer Flutter com fixtures locais, sem SDK Firebase ou escritas |
| Precisão Web M5.1 | Probe Dart VM/dart2js/Chrome documentado em PLANO_M5/PROGRESSO; não equivale a homologação completa do aplicativo Web |

Nenhum desses testes foi reexecutado nesta tarefa de encerramento. Evidências e limites mantidos em M5_3_VALIDACAO_VISUAL.md, M5_4_VALIDACAO_VISUAL.md e M5_5_VALIDACAO_VISUAL.md. Não declarar validação remota nova, pixel-perfect ou homologação nativa com base no renderer de testes.

## Transferência ao M9

1. Integrações adicionais com plugins reais Firebase Auth/Firestore nos emuladores locais, paginação/CRUD e erros de sessão/rede.
2. Verificações Android/Web ainda não realizadas e persistência financeira/sessão após reinício real onde não comprovada.
3. Teclado nativo, foco, TalkBack e acessibilidade manual; preservar a evidência limitada dos testes com texto ampliado/insets.
4. Revisar 41 informes atuais do analyzer, sem supressão ou migração de dependências não autorizada.
5. Preservar todas as ressalvas M4: Android autenticado após reinício, bateria Chrome automatizada interrompida por OOM, teclado/TalkBack e histórico dos diagnósticos. Referências: M4_HOMOLOGACAO.md e backlog M9 em PLANO.md. Os informes M4 estão contidos no total atual, não são uma contagem adicional.

Essas ressalvas não impedem o encerramento aprovado e não autorizam executar M9 agora. Não houve operações Firebase remotas, alteração de regras/índices, Gradle, dependências, exclusão de dados, push ou deploy. Commit local do M5 autorizado com mensagem `feat: implementar dashboard e transacoes essenciais`; excluído o JSON redundante. Planejamento M6 posterior ao commit, sem código novo.
