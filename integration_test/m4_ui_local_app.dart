// Entry point de homologação da UI real. Nunca importar main/firebase_options.
// Sem fakes, credenciais embutidas ou fallback para o projeto de produção.
import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/app/app_dependencies.dart';
import 'package:bolsozen/app/auth_experience.dart';
import 'package:bolsozen/app/firebase_startup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void main() {
  if (!const bool.fromEnvironment('M4_UI_LOCAL') ||
      !kIsWeb ||
      const String.fromEnvironment('M4_EMULATOR_PROJECT') != 'demo-bolsozen' ||
      const String.fromEnvironment('M4_AUTH_ENDPOINT') != '127.0.0.1:9099' ||
      const String.fromEnvironment('M4_FIRESTORE_ENDPOINT') !=
          '127.0.0.1:8080') {
    throw StateError('LOCAL_UI_ENDPOINT_GUARD');
  }
  WidgetsFlutterBinding.ensureInitialized();
  late AppDependencies dependencies;
  runApp(
    BolsoZenApp(
      home: Banner(
        message: 'TESTE LOCAL',
        location: BannerLocation.topEnd,
        child: FirebaseStartup(
          initialize: () async {
            final app = await Firebase.initializeApp(
              name: 'm4-ui-local',
              options: const FirebaseOptions(
                apiKey: 'demo-api-key',
                appId: '1:1234567890:web:m4uilocal',
                messagingSenderId: '1234567890',
                projectId: 'demo-bolsozen',
                authDomain: 'localhost',
              ),
            );
            final auth = FirebaseAuth.instanceFor(app: app);
            final firestore = FirebaseFirestore.instanceFor(app: app);
            await auth.useAuthEmulator(
              '127.0.0.1',
              9099,
              automaticHostMapping: false,
            );
            firestore.settings = const Settings(persistenceEnabled: false);
            firestore.useFirestoreEmulator(
              '127.0.0.1',
              8080,
              automaticHostMapping: false,
            );
            dependencies = await AppDependencies.create(
              auth: auth,
              firestore: firestore,
            );
          },
          childBuilder: (_) => AuthExperience(
            createController: dependencies.createSessionController,
          ),
        ),
      ),
    ),
  );
}
