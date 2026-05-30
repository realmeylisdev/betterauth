# Changelog

All notable changes to this project are documented here. This project adheres
to [Semantic Versioning](https://semver.org) and
[Keep a Changelog](https://keepachangelog.com).

## 0.2.0

- feat: anonymous plugin — `client.signIn.anonymous()`,
  `client.anonymous.deleteUser()`, and `User.isAnonymous`
- feat: passkey (WebAuthn) plugin — `client.passkey` (generate options, verify
  registration, list/update/delete) and `client.signIn.passkey()`, plus the
  `Passkey` model
- feat: organization plugin — `client.organization` covering organizations,
  members, invitations and teams, with `Organization`/`Member`/`Invitation`/
  `Team`/`TeamMember` models
- feat: additional `AuthErrorCode` values for the new plugins
- chore: link sibling packages from source via `pubspec_overrides.yaml`

## 0.1.0+1

- feat: initial release of the pure-Dart better-auth client SDK
  - `BetterAuthClient` with namespaced API groups (`signUp`, `signIn`,
    `session`, `user`, `account`, `password`, `emailVerification`, `emailOtp`,
    `magicLink`, `phoneNumber`, `username`, `twoFactor`)
  - sealed `AuthResult<T>` and `AuthException` hierarchy with `AuthErrorCode`
  - `dio`-based transport with bearer + cookie modes, retry and redacting
    logging interceptors
  - reactive `onAuthStateChange` stream, optimistic restore, proactive refresh,
    and pluggable `AsyncStorage`
