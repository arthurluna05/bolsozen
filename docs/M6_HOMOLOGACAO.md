# M6 — Encerramento com ressalvas

O usuário confirmou testes manuais suficientes e aprovou o funcionamento. **M6.6 foi dispensado por decisão do usuário e não foi executado.** Não houve nova bateria de homologação neste encerramento.

Entregas aprovadas:

- Cadastro de receitas/despesas existente preservado; edição reutilizando TEL-05.
- Exclusão somente após confirmação, com cancelamento sem escrita.
- Busca por descrição/categoria, tolerância aos acentos portugueses, filtros combinados e agrupamento do Histórico por dias locais.
- Ocultação somente do saldo principal em memória da sessão, sem anúncio semântico do valor oculto.
- Um recente confirmado atualizado após CRUD/recarga e reordenado por data.
- Identidade por UID/expectedUserId, descarte de sessões anteriores, operações serializadas, confirmação antes de atualizar dados e reconciliação por leitura sem repetir mutações automaticamente.

Evidência anteriormente executada: **656 testes Flutter aprovados**; analyzer com **52 informes de depreciação**, zero erros/warnings; format/diff-check aprovados. Testes locais com fakes e capturas reais do renderer não equivalem a integração SDK nativa/remota. Preservados relatórios M6_2/M6_3/M6_4/M6_5_VALIDACAO_VISUAL.md e suas limitações.

Transferir ao M9, mantendo ressalvas dos encerramentos M4/M5: integração adicional Auth/Firestore locais; validações nativas Android/Web de CRUD; teclado e TalkBack; persistência autenticada após reinício real ainda não comprovada; completar evidências Chrome após OOM; falhas de conexão/reconciliação em plataformas reais; revisar 52 informes. Aceite manual não permite afirmar execuções específicas não documentadas.

Essas ressalvas não bloqueiam o encerramento aprovado. Nenhum teste remoto, criação/exclusão de contas/dados, alteração de regras/índices, dependências/Gradle, push ou deploy nesta tarefa. Commit local M6 autorizado; M7 permanece somente planejamento, sujeito à revisão antes da implementação.
