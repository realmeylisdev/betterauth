# Changelog

All notable changes to this project are documented here. This project adheres
to [Semantic Versioning](https://semver.org) and
[Keep a Changelog](https://keepachangelog.com).

## 0.2.0

- feat: native passkey support — `BetterAuth.signInWithPasskey()` and
  `registerPasskey()` via an injectable `PasskeyAuthenticator` (default uses the
  `passkeys` package)
- feat: anonymous sign-in — `BetterAuth.signInAnonymously()` and
  `AuthCubit.signInAnonymously()`
- feat: the full organization API is available via
  `BetterAuth.instance.client.organization`
- chore: the repo now uses Dart pub workspaces

## 0.1.0+1

- feat: initial release of the Flutter bindings for better-auth
  - `BetterAuth` singleton with secure-storage persistence, optimistic restore,
    and lifecycle-driven session refresh
  - native Google / Apple sign-in and a browser-redirect social flow
  - `AuthCubit` (`flutter_bloc`) mirroring the auth-state stream
  - `SecureStorageAdapter` over `flutter_secure_storage`
