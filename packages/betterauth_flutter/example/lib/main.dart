import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Point this at your better-auth server's auth base URL.
final Uri kBaseUrl = Uri.parse('https://your-server.example.com/api/auth');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BetterAuth.initialize(baseUrl: kBaseUrl);
  runApp(const BetterAuthExampleApp());
}

class BetterAuthExampleApp extends StatelessWidget {
  const BetterAuthExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(BetterAuth.instance.client),
      child: MaterialApp(
        title: 'betterauth_flutter example',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Switches between the home and sign-in screens based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthCubitState>(
      builder: (context, state) {
        return switch (state.status) {
          AuthStatus.authenticated => HomeScreen(user: state.user),
          AuthStatus.twoFactorRequired => const TwoFactorScreen(),
          _ => const SignInScreen(),
        };
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController(text: 'ada@example.com');
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: BlocBuilder<AuthCubit, AuthCubitState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.error!.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => cubit.signInEmail(
                        email: _email.text,
                        password: _password.text,
                      ),
                child: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => cubit.signUpEmail(
                        name: 'New User',
                        email: _email.text,
                        password: _password.text,
                      ),
                child: const Text('Create account'),
              ),
              const Divider(height: 40),
              OutlinedButton.icon(
                onPressed: () => BetterAuth.instance.signInWithGoogle(),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => BetterAuth.instance.signInWithApple(),
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => BetterAuth.instance.signInWithPasskey(),
                icon: const Icon(Icons.key),
                label: const Text('Sign in with a passkey'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.isSubmitting ? null : cubit.signInAnonymously,
                child: const Text('Continue as guest'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Two-factor')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Enter the 6-digit code from your authenticator app.'),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            decoration: const InputDecoration(labelText: 'Code'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => cubit.verifyTotp(code: _code.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, super.key});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signed in'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Welcome, ${user?.name ?? 'user'}'),
            Text(user?.email ?? ''),
            if (user?.isAnonymous ?? false)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(label: Text('Guest')),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => BetterAuth.instance.registerPasskey(),
              icon: const Icon(Icons.key),
              label: const Text('Register a passkey'),
            ),
          ],
        ),
      ),
    );
  }
}
