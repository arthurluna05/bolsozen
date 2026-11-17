import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../core/theme/app_spacing.dart';

/// Inicialização real injetada no ponto de entrada; testes não precisam de rede.
class FirebaseStartup extends StatefulWidget {
  const FirebaseStartup({
    required this.initialize,
    this.child,
    this.childBuilder,
    super.key,
  }) : assert((child == null) != (childBuilder == null));
  final Future<void> Function() initialize;
  final Widget? child;

  /// Permite construir o gate/composição somente após inicialização confirmada.
  final WidgetBuilder? childBuilder;
  @override
  State<FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<FirebaseStartup> {
  late Future<void> _initialization;
  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await widget.initialize();
    } catch (error, stack) {
      if (kDebugMode) {
        // Não imprimir mensagens arbitrárias que possam incluir credenciais.
        final detail = error is UnsupportedError
            ? error.message
            : error is FirebaseException
            ? error.code
            : error.runtimeType.toString();
        debugPrint(
          'Falha na inicialização Firebase: ${error.runtimeType}: $detail',
        );
        debugPrintStack(stackTrace: stack);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Inicializando BolsoZen',
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Não foi possível iniciar o BolsoZen',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    const Text(
                      'A conexão com os serviços não foi inicializada. Tente novamente.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {
                        final initialization = _initialize();
                        setState(() {
                          _initialization = initialization;
                        });
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return widget.childBuilder?.call(context) ?? widget.child!;
    },
  );
}
