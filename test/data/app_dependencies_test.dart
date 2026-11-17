import 'package:bolsozen/app/app_dependencies.dart';
import 'package:bolsozen/data/repositories/firebase_auth_repository.dart';
import 'package:bolsozen/data/repositories/firestore_budget_repository.dart';
import 'package:bolsozen/data/repositories/firestore_transaction_repository.dart';
import 'package:bolsozen/data/repositories/firestore_user_repository.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_fakes.dart';

void main() {
  test(
    'Composição reutiliza o mesmo app, sem autenticar ou ler documentos',
    () async {
      final auth = AuthTestFirebase();
      final dependencies = await AppDependencies.create(
        auth: auth,
        firestore: AuthTestFirestore(auth.app),
      );
      expect(dependencies.auth, isA<FirebaseAuthRepository>());
      expect(dependencies.users, isA<FirestoreUserRepository>());
      expect(dependencies.transactions, isA<FirestoreTransactionRepository>());
      expect(dependencies.budgets, isA<FirestoreBudgetRepository>());
      final controller = dependencies.createSessionController();
      expect(controller.user, isNull);
      expect(controller.profile, isNull);
      controller.dispose(); // Factory não assina nem consulta o perfil.
      expect(
        auth.loginCalls +
            auth.registerCalls +
            auth.logoutCalls +
            auth.resetCalls,
        0,
      );
      // Fake Firestore só implementa app: qualquer consulta acidental falharia.
    },
  );
  for (final app in [
    AuthTestApp(name: 'outro-app'),
    AuthTestApp(project: 'outro-projeto'),
  ]) {
    test(
      'Composição rejeita instâncias incompatíveis: ${app.name}/${app.options.projectId}',
      () async {
        await expectLater(
          AppDependencies.create(
            auth: AuthTestFirebase(),
            firestore: AuthTestFirestore(app),
          ),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.kind,
              'kind',
              AuthFailureKind.operationNotAllowed,
            ),
          ),
        );
      },
    );
  }
}
