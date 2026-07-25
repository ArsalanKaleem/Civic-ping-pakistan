import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/badges.dart';
import 'admin_shell.dart';

/// After Firebase sign-in, verifies with the backend that this account is an
/// admin (is_admin, granted via ADMIN_EMAILS). Non-admins see a polite wall.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late Future<Map<String, dynamic>> _me;

  @override
  void initState() {
    super.initState();
    _me = context.read<AuthService>().me();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _me,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not reach the CivicPing API',
              subtitle:
                  'Check that the backend is running and API_BASE_URL is '
                  'correct.\n${snap.error}',
            ),
          );
        }
        final isAdmin = snap.data?['is_admin'] == true;
        if (!isAdmin) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    icon: Icons.lock_outline,
                    title: 'This account is not an administrator',
                    subtitle:
                        'Add this email to ADMIN_EMAILS in the backend .env '
                        'and sign in again.',
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<AuthService>().signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        }
        return const AdminShell();
      },
    );
  }
}
