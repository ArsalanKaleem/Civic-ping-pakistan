import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/badges.dart';

/// Split-hero sign-in: brand story on the left, auth card on the right.
/// Collapses to a single column on narrow screens.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      body: wide
          ? Row(children: const [
              Expanded(child: _HeroPanel()),
              Expanded(child: Center(child: _AuthCard())),
            ])
          : ListView(children: const [
              SizedBox(height: 48),
              Center(child: BrandMark(size: 26)),
              SizedBox(height: 32),
              Center(child: _AuthCard()),
              SizedBox(height: 48),
            ]),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Lux.emeraldDeep,
      padding: const EdgeInsets.all(64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 26, light: true),
          const Spacer(),
          Text('Your city.\nYour voice.\nThirty seconds.',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Colors.white, height: 1.15)),
          const SizedBox(height: 24),
          Text(
            'Photograph a civic issue, and CivicPing routes a formal '
            'complaint to the responsible authority — then tracks it on a '
            'public map until it is fixed.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 16,
                height: 1.6),
          ),
          const Spacer(),
          Row(children: [
            _stat(context, '8', 'major cities'),
            const SizedBox(width: 40),
            _stat(context, '7', 'issue types'),
            const SizedBox(width: 40),
            _stat(context, '1', 'public map'),
          ]),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String n, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Lux.gold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
        ],
      );
}

class _AuthCard extends StatefulWidget {
  const _AuthCard();

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() op) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await op();
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: LuxCard(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_registering ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              _registering
                  ? 'Join thousands of citizens improving their cities.'
                  : 'Sign in to report and track civic issues.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
              icon: const Icon(Icons.g_mobiledata, size: 30),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 20),
            if (_registering) ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              onSubmitted: (_) => _submit(auth),
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (!_registering)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await auth.sendPasswordReset(_email.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Password reset email sent.')));
                            }
                          }),
                  child: const Text('Forgot password?'),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _submit(auth),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_registering ? 'Create account' : 'Sign in'),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _registering = !_registering;
                        _error = null;
                      }),
              child: Text(_registering
                  ? 'Already have an account? Sign in'
                  : 'New here? Create an account'),
            ),
            const Divider(height: 32),
            TextButton.icon(
              onPressed: _busy ? null : () => _run(auth.continueAsGuest),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Continue as guest'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(AuthService auth) => _run(() => _registering
      ? auth.registerWithEmail(_email.text, _password.text, _name.text)
      : auth.signInWithEmail(_email.text, _password.text));
}
