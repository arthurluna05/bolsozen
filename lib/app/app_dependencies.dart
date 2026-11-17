import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase/firebase_session.dart';
import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/firestore_budget_repository.dart';
import '../data/repositories/firestore_transaction_repository.dart';
import '../data/repositories/firestore_user_repository.dart';
import '../domain/models/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../presentation/controllers/session_controller.dart';

/// Composição posterior ao FirebaseStartup, compartilhada pela árvore autenticada.
final class AppDependencies {
  AppDependencies._({
    required this.auth,
    required this.users,
    required this.transactions,
    required this.budgets,
  });

  final AuthRepository auth;
  final UserRepository users;
  final TransactionRepository transactions;
  final BudgetRepository budgets;

  /// Retorna um controller ainda não iniciado; SessionGate é dono do lifecycle.
  /// Usar somente depois do FirebaseStartup e da criação desta composição.
  SessionController createSessionController() =>
      SessionController(auth: auth, users: users);

  /// Reutiliza instâncias já inicializadas, inclusive nos emuladores locais.
  /// Não chama initializeApp, não assina sessão e não carrega/cria documentos.
  static Future<AppDependencies> create({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) async {
    if (auth.app.name != firestore.app.name ||
        auth.app.options.projectId != firestore.app.options.projectId) {
      throw const AuthFailure(AuthFailureKind.operationNotAllowed);
    }
    final repository = FirebaseAuthRepository(auth);
    await repository.initialize();
    final session = FirebaseSession(auth: auth, firestore: firestore);
    return AppDependencies._(
      auth: repository,
      users: FirestoreUserRepository(session),
      transactions: FirestoreTransactionRepository(session),
      budgets: FirestoreBudgetRepository(session),
    );
  }
}
