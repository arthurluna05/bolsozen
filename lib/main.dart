import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'app/firebase_startup.dart';
import 'firebase_options.dart';
import 'presentation/screens/welcome/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    BolsoZenApp(
      home: FirebaseStartup(
        initialize: () async {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        },
        child: const WelcomeScreen(),
      ),
    ),
  );
}
