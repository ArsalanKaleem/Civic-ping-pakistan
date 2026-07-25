import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase_options.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/report_service.dart';
import 'api_client.dart';
import 'theme.dart';

/// Initialises Firebase and wires up all providers. If firebase_options.dart
/// is still the placeholder, a setup screen with exact instructions is shown
/// instead of a cryptic crash.
Future<Widget> bootstrap({required Widget home, required String title}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (DefaultFirebaseOptions.isPlaceholder) {
    return MaterialApp(
      title: title,
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const _FirebaseSetupScreen(),
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final api = ApiClient();
  final auth = AuthService(api);
  await auth.restoreGuest();

  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      ChangeNotifierProvider<AuthService>.value(value: auth),
      Provider<ReportService>(create: (_) => ReportService(api)),
      Provider<AdminService>(create: (_) => AdminService(api)),
      Provider<LocationService>(create: (_) => LocationService()),
    ],
    child: _App(home: home, title: title),
  );
}

class _App extends StatelessWidget {
  const _App({required this.home, required this.title});
  final Widget home;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    const steps = '''
1.  Create a Firebase project at console.firebase.google.com
2.  Authentication → Sign-in method → enable Google and Email/Password
3.  Install the CLI:   dart pub global activate flutterfire_cli
4.  In the frontend folder run:
        flutterfire configure --out lib/firebase_options.dart
    (select web, windows and/or macos — it overwrites the placeholder)
5.  In the backend .env set:
        FIREBASE_PROJECT_ID=<your project id>
        ADMIN_EMAILS=<your email>
6.  Restart both apps.''';
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: LuxCard(
            padding: const EdgeInsets.all(36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_outlined,
                  size: 48, color: Lux.gold),
              const SizedBox(height: 16),
              Text('One step left: connect Firebase',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              const Text(
                  'Authentication needs your own Firebase project. '
                  'This takes about five minutes:'),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Lux.radiusSm),
                ),
                child: const SelectableText(steps,
                    style: TextStyle(fontFamily: 'monospace', height: 1.7)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
