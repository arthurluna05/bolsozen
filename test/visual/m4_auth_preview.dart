// Runner exclusivamente visual, com fakes locais e identificação explícita.
// Nenhum FirebaseApp, SDK de autenticação ou repositório remoto é instanciado.
import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/app/auth_experience.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:flutter/widgets.dart';

import '../presentation/session_fakes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final query = Uri.base.queryParameters;
  final h = SessionHarness();
  final screen = query['screen'] ?? 'public';
  final scale = double.tryParse(query['scale'] ?? '') ?? 1;
  final keyboard = double.tryParse(query['keyboard'] ?? '') ?? 0;
  h.users.profiles['visual'] = userProfile(
    'visual',
    name: 'Teste visual BolsoZen',
  );
  if (screen == 'missing' || screen == 'registration') h.users.profiles.clear();
  if (screen == 'error') {
    h.users.read = (_) async => throw const DataFailure(
      DataFailureKind.unavailable,
      'Não foi possível acessar os dados. Verifique sua conexão e tente novamente.',
    );
  }
  h.auth.login = () async {
    h.auth.events.add(authUser('visual'));
    return authUser('visual');
  };
  h.auth.registration = h.auth.login;
  runApp(
    BolsoZenApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: Banner(
            message: 'TESTE VISUAL',
            location: BannerLocation.topEnd,
            child: AuthExperience(createController: () => h.controller),
          ),
        ),
      ),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    h.auth.events.add(
      ['profile', 'missing', 'error'].contains(screen)
          ? authUser('visual')
          : null,
    );
  });
}
