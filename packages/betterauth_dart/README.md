# betterauth_dart

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]
[![coverage][coverage_badge]][very_good_analysis_link]

A pure-Dart client SDK for the [better-auth][better_auth_link] authentication
server. Zero Flutter dependencies — usable from Flutter, Dart CLIs, and
server-side Dart.

For Flutter apps, use [`betterauth_flutter`][betterauth_flutter_link], which adds
secure storage, native social sign-in, lifecycle-driven refresh and a
`flutter_bloc` integration on top of this package.

## Features

- Email / password sign-up & sign-in
- Native social sign-in (id-token) and browser-redirect social flows
- Email OTP, magic link, phone-number OTP, username, and two-factor (TOTP /
  OTP / backup codes) plugins
- Session and account management, password reset/change, email verification
- A reactive `Stream<AuthState>` with the current session/user
- Bearer-token transport (with a cookie fallback), powered by `dio`
- A typed, sealed `AuthResult<T>` — no exceptions thrown across the API

## Installation 💻

```sh
dart pub add betterauth_dart
```

> The server must enable the [`bearer`][bearer_plugin_link] plugin for the
> default transport mode.

## Quick start 🚀

```dart
import 'package:betterauth_dart/betterauth_dart.dart';

final client = BetterAuthClient(
  baseUrl: Uri.parse('https://api.example.com/api/auth'),
);

// React to session changes.
client.onAuthStateChange.listen((state) {
  print('${state.event}: ${state.user?.email}');
});

Future<void> signIn() async {
  final result = await client.signIn.email(
    email: 'ada@example.com',
    password: 'super-secret',
  );

  switch (result) {
    case AuthSuccess(data: final SignedIn signedIn):
      print('Signed in as ${signedIn.user.email}');
    case AuthSuccess(data: final TwoFactorRequired challenge):
      print('2FA required: ${challenge.methods}');
    case AuthFailure(:final error):
      print('Failed (${error.code}): ${error.message}');
  }
}
```

## Results & errors

Every call returns an `AuthResult<T>` — `AuthSuccess<T>` or `AuthFailure<T>` —
so you pattern-match instead of catching exceptions:

```dart
final result = await client.session.get();
final user = result.dataOrNull?.user; // null on failure or no session
```

`AuthFailure.error` is a sealed `AuthException`: `AuthApiException` (4xx with a
mapped `AuthErrorCode`), `AuthSessionMissingException` (401),
`AuthRetryableFetchException` (network / 5xx), or `AuthUnknownException`.

## API groups

| Group | Highlights |
|---|---|
| `client.signUp` | `email` |
| `client.signIn` | `email`, `username`, `phoneNumber`, `social`, `emailOtp`, `magicLink`, `passkey`, `anonymous` |
| `client.session` | `get`, `list`, `revoke`, `revokeAll`, `revokeOthers` |
| `client.user` | `update`, `changeEmail`, `delete` |
| `client.account` | `list`, `unlink`, `linkSocial` |
| `client.password` | `requestReset`, `reset`, `change` |
| `client.emailVerification` | `send`, `verify` |
| `client.emailOtp` | `sendVerificationOtp`, `verifyEmail`, `requestPasswordReset`, `resetPassword`, `checkVerificationOtp` |
| `client.magicLink` | `verify` |
| `client.phoneNumber` | `sendOtp`, `verify`, `requestPasswordReset`, `resetPassword` |
| `client.username` | `isAvailable` |
| `client.twoFactor` | `enable`, `disable`, `getTotpUri`, `verifyTotp`, `sendOtp`, `verifyOtp`, `generateBackupCodes`, `verifyBackupCode` |
| `client.anonymous` | `deleteUser` |
| `client.passkey` | `generateRegisterOptions`, `verifyRegistration`, `generateAuthenticateOptions`, `listUserPasskeys`, `updatePasskey`, `deletePasskey` |
| `client.organization` | organizations, `members`, invitations and teams (`create`, `list`, `setActive`, `inviteMember`, `listMembers`, `createTeam`, …) |

## Configuration

```dart
BetterAuthClient(
  baseUrl: Uri.parse('https://api.example.com/api/auth'),
  options: const BetterAuthClientOptions(
    transportMode: AuthTransportMode.bearer, // or .cookie
    timeout: Duration(seconds: 30),
    maxRetries: 3,
    autoRefresh: true,
  ),
  storage: InMemoryAsyncStorage(), // inject your own AsyncStorage
  onUnauthorized: () => print('signed out by the server'),
);
```

## Running Tests 🧪

```sh
dart pub global activate very_good_cli
very_good test --coverage --min-coverage 100
```

[better_auth_link]: https://www.better-auth.com
[bearer_plugin_link]: https://www.better-auth.com/docs/plugins/bearer
[betterauth_flutter_link]: https://pub.dev/packages/betterauth_flutter
[coverage_badge]: https://img.shields.io/badge/coverage-100%25-brightgreen.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
