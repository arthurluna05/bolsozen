import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app/app.dart';
import 'app/firebase_startup.dart';
import 'app/app_dependencies.dart';
import 'app/auth_experience.dart';
import 'firebase_options.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeController(store: LocalThemePreferences());
  await theme.load();
  late AppDependencies dependencies;
  runApp(
    BolsoZenApp(
      themeController: theme,
      home: FirebaseStartup(
        initialize: () async {
          final app = await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          dependencies = await AppDependencies.create(
            auth: FirebaseAuth.instanceFor(app: app),
            firestore: FirebaseFirestore.instanceFor(app: app),
          );
        },
        childBuilder: (_) => AuthExperience(
          createController: dependencies.createSessionController,
          transactions: dependencies.transactions,
          budgets: dependencies.budgets,
        ),
      ),
    ),
  );
}
