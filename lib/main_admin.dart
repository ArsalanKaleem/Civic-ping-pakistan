// Administrator desktop app entry point.
//
// Run:   flutter run -d windows -t lib/main_admin.dart \
//            --dart-define=API_BASE_URL=http://localhost:8000
//        (or -d macos / -d linux; also runs fine in Chrome with -d chrome)
//
// Sign in with a Firebase email/password account whose email is listed in
// the backend's ADMIN_EMAILS.

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import 'admin/admin_gate.dart';
import 'admin/admin_sign_in_screen.dart';
import 'core/bootstrap.dart';

Future<void> main() async {
  runApp(await bootstrap(
    title: 'CivicPing — Admin Console (Authorized Access Only',
    home: const _AdminRoot(),
  ));
}

class _AdminRoot extends StatelessWidget {
  const _AdminRoot();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == null
            ? const AdminSignInScreen()
            : AdminGate(key: ValueKey(snap.data!.uid));
      },
    );
  }
}
