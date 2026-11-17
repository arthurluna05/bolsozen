# AGENTS.md — BolsoZen

## Contexto do projeto

BolsoZen é um aplicativo acadêmico de gerenciamento
financeiro pessoal desenvolvido em Flutter.

Objetivo: entregar um MVP Android funcional, simples,
seguro, organizado e visualmente fiel ao protótipo.

Idioma da interface e mensagens: português brasileiro.

## Tecnologias

- Flutter e Dart
- Material Design 3
- Firebase Authentication
- Cloud Firestore
- Gerenciamento de estado simples e consistente

Priorize soluções oficiais e dependências mínimas.
Não introduza arquiteturas excessivamente complexas.

## Fontes de verdade

Consulte, conforme a tarefa:

- docs/01-visao-geral.md
- docs/02-requisitos.md
- docs/03-jornadas.md
- docs/04-design-system.md
- docs/05-criterios-aceite.md
- design/telas/bolsozen_prototipo.png

Os documentos definem comportamento e regras.
O protótipo define a referência visual.

Em caso de conflito, registre a divergência
e solicite uma decisão antes de alterar o escopo.

Não invente funcionalidades não especificadas.

## Organização do código

- Separe apresentação, domínio e acesso aos dados.
- Prefira widgets pequenos e reutilizáveis.
- Use nomes claros e consistentes.
- Arquivos Dart em snake_case.
- Classes em PascalCase.
- Evite duplicação.
- Centralize cores, tipografia e estilos no tema.
- Não modifique código não relacionado à tarefa.

## Regras financeiras

- Trate valores monetários com precisão.
- Evite usar double para armazenar dinheiro.
- Prefira valores inteiros em centavos.
- Utilize a documentação para os cálculos.
- Recalcule indicadores após mudanças nos dados.
- Não apresente dados simulados como dados reais.

## Design e interface

- Siga a identidade visual documentada.
- Utilize os protótipos como referência.
- Preserve cores, espaçamentos e hierarquia visual.
- Implemente estados vazios, carregamento e erro.
- Respeite diferentes tamanhos de tela.
- Reutilize componentes visuais.

Sempre que possível, compare screenshots reais
do aplicativo com o protótipo.

## Firebase

- Utilize Firebase Authentication.
- Utilize Cloud Firestore para os dados financeiros.
- Isole os dados por usuário autenticado.
- Implemente regras de segurança adequadas.
- Nunca inclua credenciais administrativas no código.
- Nunca solicite senhas ou tokens privados no chat.

Configurações externas que exijam minha participação
devem ser explicadas passo a passo.

Não configure serviços pagos sem minha aprovação.

## Testes e qualidade

Após alterações relevantes, execute:

- dart format .
- flutter analyze
- flutter test

Adicione testes para regras financeiras e
funcionalidades importantes.

Não declare uma funcionalidade concluída sem
verificar o comportamento e documentar limitações.

## Planejamento e execução

Antes de grandes implementações, consulte:

- docs/PLANO.md
- docs/PROGRESSO.md

Se esses arquivos não existirem, proponha sua criação
durante o planejamento inicial.

Trabalhe por fases incrementais.

Dentro de cada fase:

1. Analise os requisitos.
2. Planeje as alterações.
3. Implemente a funcionalidade.
4. Execute os testes relevantes.
5. Corrija os erros identificados.
6. Atualize o progresso.
7. Resuma os resultados.

Não avance automaticamente para a próxima fase
sem minha autorização.

## Segurança e Git

- Preserve funcionalidades existentes.
- Não execute comandos destrutivos sem aprovação.
- Não sobrescreva alterações minhas sem verificar.
- Não faça push, deploy ou publicações sem autorização.
- Não inclua arquivos sensíveis no repositório.
- Informe alterações importantes de dependências.

## Comunicação

Explique resultados em português brasileiro.

Ao concluir cada tarefa, informe:

- O que foi implementado.
- Quais arquivos foram alterados.
- Quais testes foram executados.
- Quais problemas permanecem.
- O que devo validar manualmente.

Em caso de bloqueio, informe a causa e proponha
a próxima ação, sem inventar resultados.

## Objetivo final

Entregar o BolsoZen com:

- Autenticação real.
- Persistência segura de dados.
- Gestão de receitas e despesas.
- Categorias e limites de orçamento.
- Dashboard e relatórios.
- Interface consistente com o protótipo.
- Testes e documentação.
- APK Android funcional.
