# BolsoZen

Aplicativo acadêmico de gerenciamento financeiro pessoal desenvolvido por **Arthur David Cardoso de Souza Luna**. Organiza receitas, despesas e limites mensais, com interface em português brasileiro e valores em reais.

## Funcionalidades

- Cadastro, login, recuperação de senha, sessão persistente e perfil real.
- Dashboard com saldo global, receitas/despesas do mês, gastos por categoria e transações recentes.
- Cadastro, edição e exclusão de movimentações com confirmação.
- Histórico com busca por descrição/categoria, filtros combinados e agrupamento por data.
- Orçamentos por categoria e competência, editor de limites, progresso e alertas de utilização.
- Relatórios em Visão geral, Categorias e Evolução: linha/área e rosca interativas, ranking, comparação mensal e últimos seis meses.
- Animações nativas, com respeito ao movimento reduzido.
- Tema claro/escuro global com controle sol/lua no Dashboard e preferência local persistente.
- Ocultação do saldo principal durante a sessão.

## Stack e arquitetura

Flutter/Dart, Material Design 3, Firebase Authentication, Cloud Firestore, `intl` e `shared_preferences`. Gráficos com CustomPainter, sem biblioteca adicional.

```text
lib/
  app/           # inicialização, composição, sessão e navegação
  core/theme/    # tokens, temas e preferência local
  domain/        # modelos, contratos, validações e cálculos puros
  data/          # repositórios Firebase e mapeadores
  presentation/  # telas, widgets, projeções e controladores
```

ChangeNotifier e ListenableBuilder compartilham uma instância financeira por sessão. Relatórios e orçamento reutilizam o histórico confirmado, sem consultar o Firestore por alternância de visualização.

## Segurança e precisão

Dados isolados em `users/{uid}` e suas subcoleções. O proprietário vem da sessão autenticada; verificações de identidade e Security Rules protegem os documentos e campos imutáveis. Senhas e tokens não são armazenados no Firestore nem em preferências próprias.

Dinheiro em centavos inteiros, com parsing exato por BigInt e validações para evitar arredondamentos silenciosos na Web. Saldo considera o histórico completo; totais mensais usam a data da movimentação. O orçamento global é derivado somente das categorias com limites configurados.

## Requisitos

- Flutter compatível com Dart `^3.14.0` e o `pubspec.lock` versionado. O desenvolvimento usa Flutter 3.50 pre-release; SDKs anteriores podem não oferecer todas as APIs utilizadas.
- Android SDK/JDK compatíveis com o Gradle do projeto, Android 7.0/API 24 ou superior; ou Chrome para Web.
- Projeto Firebase com Authentication por e-mail/senha e Cloud Firestore.
- Firebase CLI e FlutterFire CLI para gerar configurações próprias.

Android é a plataforma principal; Web é complementar. Diretórios das demais plataformas são preservados, mas não representam suporte Firebase homologado.

## Configurar Firebase

1. No Firebase Console, selecione/crie seu projeto e registre Android (`com.bolsozen.bolsozen`) e Web. Reutilize aplicativos existentes; não registre duplicados.
2. Habilite Authentication por e-mail/senha, crie Firestore em modo de produção e configure os domínios Web autorizados.
3. Autentique as CLIs e gere as opções do seu ambiente:

   ```sh
   firebase login
   flutterfire configure --project=SEU_PROJECT_ID --platforms=android,web
   ```

4. Confira `lib/firebase_options.dart` e `android/app/google-services.json`.
5. Revise `firestore.rules` e `firestore.indexes.json`. Publique-os apenas no projeto escolhido, com autorização do responsável, e aguarde os índices ficarem ativos.

A configuração Firebase versionada é pública e pertence ao ambiente de desenvolvimento. Para outro ambiente, gere suas próprias opções. Configuração pública não substitui regras de segurança. Nunca versione service accounts, chaves privadas, senhas, tokens ou arquivos `.env` com segredos.

## Executar

```sh
flutter pub get
flutter devices
flutter run
```

Selecione o dispositivo Android disponível. Para Web, mantenha uma origem estável para preservar sessão e preferências entre execuções:

```sh
flutter run -d chrome --web-port=7357
```

O app utiliza Firebase real por padrão; não é necessário iniciar servidor Firebase local. Ações na interface podem alterar dados do projeto configurado. Falhas de inicialização são exibidas explicitamente.

## Gerar builds

```sh
flutter build apk --release
flutter build web --release
```

Saídas: `build/app/outputs/flutter-apk/app-release.apk` e `build/web/`. Gerar build não realiza deploy. A assinatura release Android atual usa a configuração de desenvolvimento; configure uma chave privada apropriada fora do Git antes da distribuição em produção.

## Limitações relevantes

- Carregamento integral paginado: totais completos, com custo proporcional ao histórico, adequado ao MVP acadêmico.
- Transações e limites são leituras independentes, sem snapshot atômico ou sincronização em tempo real. Atualização explícita reconcilia mudanças externas.
- Salvamento de limites é sequencial e pode ser parcial. Resultado incerto exige reconciliação por leitura, sem reenvio automático.
- Sem herança automática de limites entre meses e sem limite global manual.
- Tema é uma preferência do dispositivo/origem. Limpeza de dados, navegação privada ou bloqueio do armazenamento podem impedir sua retenção.
- Homologação nativa completa, TalkBack e distribuição assinada ainda exigem validação final. Há informes de depreciação conhecidos no SDK pre-release.
- Google Login, notificações e BolsoZen Bot não estão implementados.

Testes automatizados e registros internos de validação permanecem no ambiente de desenvolvimento, fora do versionamento público.
