# betterauth_flutter

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]
[![coverage][coverage_badge]][very_good_analysis_link]

Flutter bindings for the [better-auth][better_auth_link] client: secure-storage
persistence, native Google / Apple sign-in, browser OAuth, lifecycle-driven
session refresh, and a [`flutter_bloc`][bloc_link] integration.

Built on the pure-Dart [`betterauth_dart`][betterauth_dart_link] package, whose
full API is re-exported here — a single import is enough.

## Installation 💻

```sh
flutter pub add betterauth_flutter
```

Supported platforms: **iOS** and **Android**. The server must enable the
[`bearer`][bearer_plugin_link] plugin.

## Quick start 🚀

```dart
import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BetterAuth.initialize(
    baseUrl: Uri.parse('https://api.example.com/api/auth'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(BetterAuth.instance.client),
      child: MaterialApp(
        home: BlocBuilder<AuthCubit, AuthCubitState>(
          builder: (context, state) => switch (state.status) {
            AuthStatus.authenticated => const HomePage(),
            _ => const SignInPage(),
          },
        ),
      ),
    );
  }
}
```

## What it adds

- **`BetterAuth.initialize`** — a singleton wrapper that persists the session to
  `flutter_secure_storage` (Keychain / Keystore), restores it optimistically at
  startup, and re-validates the session when the app returns to the foreground.
- **Native social sign-in** — `BetterAuth.instance.signInWithGoogle()` and
  `signInWithApple()` use `google_sign_in` / `sign_in_with_apple` to obtain an
  id token; `signInWithProvider(...)` runs a browser flow via
  `flutter_web_auth_2`.
- **`AuthCubit`** — a `Cubit<AuthCubitState>` that mirrors the auth-state stream
  and exposes `signUpEmail`, `signInEmail`, `signInUsername`, `signInEmailOtp`,
  `verifyTotp`, `verifyTwoFactorOtp`, `signOut`, and surfaces a
  `twoFactorRequired` status.
- **Custom storage** — pass any `AsyncStorage` to `BetterAuth.initialize`.

```dart
// Native social sign-in updates the AuthCubit automatically via the stream.
await BetterAuth.instance.signInWithGoogle();
```

## Running Tests 🧪

```sh
dart pub global activate very_good_cli
very_good test --coverage --min-coverage 100
```

See the [`example`](example/) app for a full demo (email, social, two-factor,
and sign-out).

[better_auth_link]: https://www.better-auth.com
[bearer_plugin_link]: https://www.better-auth.com/docs/plugins/bearer
[betterauth_dart_link]: https://pub.dev/packages/betterauth_dart
[bloc_link]: https://pub.dev/packages/flutter_bloc
[coverage_badge]: https://img.shields.io/badge/coverage-100%25-brightgreen.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
