import 'package:flutter/widgets.dart';

import '../domain/models/user_profile.dart';
import '../presentation/controllers/session_controller.dart';

typedef SessionViewBuilder = Widget Function(
  BuildContext context,
  SessionController session,
);
typedef ReadySessionBuilder = Widget Function(
  BuildContext context,
  SessionController session,
  UserProfile profile,
);

/// Fornecer telas reais quando disponíveis; nenhum destino provisório embutido.
/// Cria/inicia uma única vez e descarta seu controller. Não compartilhar instância
/// com outro gate. Para substituir dependências, substituir a key deste widget.
class SessionGate extends StatefulWidget {
  const SessionGate({
    required this.createController,
    required this.publicBuilder,
    required this.loadingBuilder,
    required this.readyBuilder,
    required this.missingProfileBuilder,
    required this.errorBuilder,
    super.key,
  });

  final SessionController Function() createController;
  final SessionViewBuilder publicBuilder,
      loadingBuilder,
      missingProfileBuilder,
      errorBuilder;
  final ReadySessionBuilder readyBuilder;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final SessionController _session;
  GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  (int, String)? _tree;

  @override
  void initState() {
    super.initState();
    _session = widget.createController();
    _session.start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _session,
    builder: (context, _) {
      final readyProfile = _session.profile;
      final (String area, WidgetBuilder builder) = switch (_session.phase) {
        SessionPhase.public => (
          'public',
          (context) => widget.publicBuilder(context, _session),
        ),
        // Mantém formulário e senha em memória enquanto não há UID confirmado.
        // Assim uma falha de login não apaga campos nem retorna à boas-vindas.
        SessionPhase.authenticating when _session.user == null => (
          'public',
          (context) => widget.publicBuilder(context, _session),
        ),
        SessionPhase.ready when _session.isReady => (
          'private',
          (context) => widget.readyBuilder(context, _session, readyProfile!),
        ),
        SessionPhase.missingProfile => (
          'missing',
          (context) => widget.missingProfileBuilder(context, _session),
        ),
        SessionPhase.profileError ||
        SessionPhase.sessionError ||
        SessionPhase.ready => (
          'error',
          (context) => widget.errorBuilder(context, _session),
        ),
        _ => ('loading', (context) => widget.loadingBuilder(context, _session)),
      };
      final tree = (_session.navigationVersion, area);
      if (tree != _tree) {
        _tree = tree;
        _navigator = GlobalKey<NavigatorState>();
      }
      // Toda rota criada pelo contexto dos builders pertence a este Navigator.
      // Trocar identidade/área destrói a pilha inteira, inclusive pushes pendentes.
      return NavigatorPopHandler<Object?>(
        onPopWithResult: (result) => _navigator.currentState?.pop(result),
        child: Navigator(
          key: _navigator,
          pages: [
            _SessionPage(
              key: ValueKey(tree),
              child: Builder(builder: builder),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      );
    },
  );
}

class _SessionPage extends Page<void> {
  const _SessionPage({required this.child, required super.key});
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => Builder(
      builder: (context) =>
          (ModalRoute.settingsOf(context)! as _SessionPage).child,
    ),
  );
}
