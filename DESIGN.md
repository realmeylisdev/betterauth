# betterauth_dart / betterauth_flutter — Design Document

> A Very Good Ventures–compliant Flutter & Dart client SDK for
> [better-auth](https://github.com/better-auth/better-auth).
>
> Status: **Design approved, implementation pending** · Date: 2026-05-30 ·
> Publisher: `realmeylisdev`

---

## 0. What we are building

A client SDK (not a server) that talks to a **better-auth** server over JSON
HTTP, split into two publishable packages plus a runnable example app:

| Package | Type | Role |
|---|---|---|
| `betterauth_dart` | Pure Dart | Transport (dio), models, `BetterAuthClient`, auth-state stream, error model. Zero Flutter imports. |
| `betterauth_flutter` | Flutter | Secure storage, lifecycle-driven refresh, native social sign-in, browser OAuth, `BetterAuth` singleton, **`AuthCubit`** (Bloc). |
| `betterauth_flutter/example` | Flutter app | Full demo exercising every v1 flow. |

Monorepo at `flutter_projects/betterauth/`, **VGV-native** layout (no melos):
per-package reusable GitHub workflows + `very_good test --recursive`.

```
betterauth/
├── DESIGN.md                  (this file)
├── README.md                  (monorepo overview)
├── .github/workflows/
│   ├── betterauth_dart.yaml    (working_directory: packages/betterauth_dart)
│   └── betterauth_flutter.yaml (working_directory: packages/betterauth_flutter)
└── packages/
    ├── betterauth_dart/
    └── betterauth_flutter/
```

---

## 1. Locked decisions (from scoping rounds)

| # | Decision | Choice |
|---|---|---|
| Scope | v1 auth surface | Core + **email-OTP + magic-link + phone OTP + username + two-factor** |
| Models | Serialization | **Hand-written** `fromJson`/`toJson`/`copyWith` + **Equatable** |
| Transport | HTTP layer | **dio** (pure-Dart core) |
| Repo | Monorepo tooling | **VGV-native** (no melos) |
| Names | Packages | **`betterauth_dart`** + **`betterauth_flutter`** |
| Identity | Publisher | **realmeylisdev** (`github.com/realmeylisdev/...`) |
| Platforms | Targets | **iOS + Android** only |
| SDK | Dart floor | **`^3.11.0`** |
| dio | Config | Internal default Dio + **optional override + custom interceptors** |
| Logging | Interceptor | **Redacting logger, auto-on in debug** (assert-detection), silent in release |
| Retry | Policy | **Retry all transient** (network + 5xx) with exponential backoff *(double-submit caveat documented)* |
| Timeouts | Defaults | **30s** connect/receive/send, all overridable |
| Refresh | Strategy | **Proactive timer** + on app-resume |
| Transport mode | Auth | **Both bearer + cookie** (bearer default, cookie fallback selectable) |
| Startup | Restore | **Optimistic** (emit cached session instantly) + background validate |
| 401 | Handling | **Auto sign-out + `onUnauthorized` hook**, then throw/Failure |
| Storage | Persistence | **Pluggable** `AsyncStorage`, `flutter_secure_storage` default |
| Social | Strategy | **Native idToken** (google_sign_in + sign_in_with_apple) + browser fallback |
| OAuth | Redirect | **flutter_web_auth_2** (ASWebAuthenticationSession / Custom Tabs) |
| Bindings | State management | **First-class Bloc** — `AuthCubit` shipped **inside** `betterauth_flutter` |
| Results | Error style | **`Result` / sealed type** (`AuthResult<T>` → `AuthSuccess` / `AuthFailure`) |
| API | Shape | **Namespaced groups** (`client.signIn.email()`, `client.twoFactor.verifyTotp()`) |
| Example | Deliverable | **Full demo app** |

### Defaults chosen for un-asked details (amendable)

- **Plugin depth = full** for each chosen plugin (every documented client method).
- **JSON casing = camelCase** (better-auth wire format; confirmed by wire-contract workflow).
- **Dates** parsed as ISO-8601 → `DateTime` (UTC-normalized); `Session.isExpired`
  uses a 30s safety margin via injectable `clock`.
- **Open shapes**: `User`/`Session` keep a `Map<String, Object?> additionalFields`
  passthrough for server `additionalFields` + plugin extensions.
- **Publishing**: per-package CI (`dart_package.yml` / `flutter_package.yml` + `pana`)
  already scaffolded; add a tag-triggered `dart pub publish` workflow (pub.dev OIDC)
  gated on pana. `release-please` optional.
- **Auth-state stream**: dependency-free broadcast `Stream<AuthState>` + `currentSession`
  getter (no rxdart); `AuthCubit` seeds from `currentSession` then listens.

---

## 2. `betterauth_dart` (pure-Dart core)

### 2.1 Dependencies

```yaml
dependencies:
  dio: ^5.7.0          # transport
  meta: ^1.15.0        # @immutable, @visibleForTesting
  equatable: ^2.0.7    # value equality on models
  collection: ^1.19.0  # DeepCollectionEquality for additionalFields
  clock: ^1.1.1        # testable time for session expiry
dev_dependencies:
  http_mock_adapter: ^0.6.1   # mock dio at the adapter layer
  mocktail: ^1.0.5
  test: ^1.31.1
  coverage: ^1.11.0
  very_good_analysis: ^10.2.0
```

### 2.2 File layout

```
lib/betterauth_dart.dart                 # export barrel (ONLY public surface)
lib/src/
  better_auth_client.dart                # BetterAuthClient (composes groups)
  client_options.dart                    # BetterAuthClientOptions (baseUrl, mode, timeouts, …)
  constants.dart                         # default paths, header names, storage keys
  http/
    better_auth_http.dart                # thin dio wrapper (request -> AuthResult)
    auth_interceptor.dart                # attach bearer/cookie + capture set-auth-token
    retry_interceptor.dart               # retry-all-transient + backoff
    logging_interceptor.dart             # redacting, debug-only
  token/
    token_store.dart                     # in-memory token+session holder, seam for bearer/cookie
  groups/
    sign_up_group.dart                   # client.signUp.*
    sign_in_group.dart                   # client.signIn.*  (email/social/username/phoneNumber/magicLink/emailOtp/anonymous?)
    session_group.dart                   # client.session.*  (get/list/revoke*)
    user_group.dart                      # client.user.*  (update/changeEmail/delete)
    account_group.dart                   # client.account.* (list/unlink/linkSocial)
    password_group.dart                  # client.password.* (requestReset/reset/change)
    email_verification_group.dart        # client.emailVerification.*
    email_otp_group.dart                 # client.emailOtp.*
    magic_link_group.dart                # client.magicLink.*
    phone_number_group.dart              # client.phoneNumber.*
    username_group.dart                  # client.username.*  (isAvailable)
    two_factor_group.dart                # client.twoFactor.*
  models/
    models.dart                          # folder barrel
    user.dart  session.dart  account.dart
    auth_state.dart  auth_change_event.dart
    responses.dart                       # SignInResponse, SignUpResponse, SocialSignInResponse, …
  result/
    auth_result.dart                     # sealed AuthResult<T> { AuthSuccess, AuthFailure }
  exceptions/
    auth_exception.dart                  # exception hierarchy
    auth_error_code.dart                 # enum AuthErrorCode + fromWire
  storage/
    async_storage.dart                   # abstract AsyncStorage + InMemoryAsyncStorage
```

`test/src/...` mirrors `lib/src/...` 1:1. Barrels are not tested.

### 2.3 Result type (sealed)

```dart
sealed class AuthResult<T> {
  const AuthResult();

  /// True when this is an [AuthSuccess].
  bool get isSuccess => this is AuthSuccess<T>;

  /// The data if success, else null.
  T? get dataOrNull => switch (this) { AuthSuccess(:final data) => data, _ => null };

  /// The error if failure, else null.
  AuthException? get errorOrNull =>
      switch (this) { AuthFailure(:final error) => error, _ => null };

  /// Fold both cases.
  R when<R>({
    required R Function(T data) success,
    required R Function(AuthException error) failure,
  }) => switch (this) {
        AuthSuccess(:final data) => success(data),
        AuthFailure(:final error) => failure(error),
      };
}

final class AuthSuccess<T> extends AuthResult<T> {
  const AuthSuccess(this.data);
  final T data;
}

final class AuthFailure<T> extends AuthResult<T> {
  const AuthFailure(this.error);
  final AuthException error;
}
```

Every client method returns `Future<AuthResult<T>>`. The transport catches dio
errors + maps non-2xx bodies to `AuthException`, never throwing across the public
API. (Auth-state side-effects — token persist, stream emit — still fire on success.)

### 2.4 Exceptions & error codes

```dart
sealed class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode, this.code, this.details});
  final String message;
  final int? statusCode;          // HTTP status
  final AuthErrorCode code;       // mapped from wire `code`, .unknown if unmatched
  final Map<String, Object?>? details;
}

final class AuthApiException extends AuthException {}            // structured 4xx
final class AuthRetryableFetchException extends AuthException {} // network/timeout/5xx
final class AuthSessionMissingException extends AuthException {} // 401 / get-session null on protected call
final class AuthUnknownException extends AuthException {         // non-JSON / unexpected
  final Object originalError;
}
```

`enum AuthErrorCode` enumerates the full better-auth `BASE_ERROR_CODES` + per-plugin
codes (finalized from the wire-contract workflow), with
`AuthErrorCode.fromWire(String)` → `.unknown` fallback.

### 2.5 Models (hand-written + Equatable, camelCase wire)

`User`: `id, name, email, emailVerified, image?, createdAt, updatedAt,
username?, displayUsername?, phoneNumber?, phoneNumberVerified?, twoFactorEnabled?,
isAnonymous?, additionalFields`.

`Session`: `id, token, userId, expiresAt, createdAt, updatedAt, ipAddress?,
userAgent?, additionalFields` + `bool get isExpired` (30s margin via `clock`).

`Account`: `id, providerId, accountId, userId, scopes, createdAt, updatedAt`.

Each: `final` fields, `const` ctor, `fromJson`, `toJson`, `copyWith`, Equatable `props`
(deep-equal on `additionalFields`). Response wrappers in `responses.dart`.

### 2.6 Transport & interceptors (dio)

`BetterAuthClientOptions { Uri baseUrl; AuthTransportMode mode = bearer; Duration timeout = 30s;
bool? enableLogging; int maxRetries = 3; ... }`.

Interceptor order: **AuthInterceptor** (attach `Authorization: Bearer <token>` or
`Cookie:` per mode; on response capture `set-auth-token` / `Set-Cookie` → `TokenStore`;
on 401 → clear + emit `signedOut` + `onUnauthorized`) → **RetryInterceptor**
(retry all transient: `DioExceptionType.connection*/unknown` + 5xx, exp backoff, max 3) →
**LoggingInterceptor** (redacts `password`, `token`, `otp`, `code`, `secret`; debug-only).
Consumers may inject their own `Dio` and append `interceptors`.

### 2.7 Auth-state stream

```dart
enum AuthChangeEvent { initialSession, signedIn, signedOut, sessionRefreshed, userUpdated }
class AuthState extends Equatable { final AuthChangeEvent event; final Session? session; final User? user; }
```

`Stream<AuthState> get onAuthStateChange` (broadcast), `Session? get currentSession`,
`User? get currentUser`. `_notify(event)` emits on every transition. `dispose()` closes
the controller + cancels timers.

---

## 3. API surface (namespaced groups)

> Exact request/response keys finalized by the running wire-contract workflow;
> shapes below are the contract we implement against.

```
client.signUp.email({name, email, password, image?, username?, callbackURL?, fields?})
client.signIn.email({email, password, rememberMe = true, callbackURL?})
client.signIn.username({username, password, rememberMe = true})
client.signIn.social({provider, idToken?, callbackURL?, scopes?, requestSignUp?, …})
client.signIn.phoneNumber({phoneNumber, password})           // if password phone-login enabled
client.signIn.magicLink({email, name?, callbackURL?})
client.signIn.emailOtp({email, otp})
client.signOut()

client.session.get({disableCookieCache?, disableRefresh?})    // null when no session
client.session.list()
client.session.revoke({token})
client.session.revokeAll()
client.session.revokeOthers()

client.user.update({name?, image?, fields?})
client.user.changeEmail({newEmail, callbackURL?})
client.user.delete({password?, token?, callbackURL?})

client.account.list()
client.account.unlink({providerId, accountId?})
client.account.linkSocial({provider, callbackURL?})           // (deferred-friendly)

client.password.requestReset({email, redirectTo?})
client.password.reset({newPassword, token})
client.password.change({newPassword, currentPassword, revokeOtherSessions?})

client.emailVerification.send({email, callbackURL?})
client.emailVerification.verify({token, callbackURL?})

client.emailOtp.sendVerificationOtp({email, type})            // sign-in | email-verification | forget-password
client.emailOtp.verifyEmail({email, otp})
client.emailOtp.resetPassword({email, otp, password})
client.emailOtp.checkVerificationOtp({email, otp, type})

client.magicLink.verify({token, callbackURL?})

client.phoneNumber.sendOtp({phoneNumber})
client.phoneNumber.verify({phoneNumber, code, disableSession?, updatePhoneNumber?})
client.phoneNumber.requestPasswordReset({phoneNumber})
client.phoneNumber.resetPassword({otp, phoneNumber, newPassword})

client.username.isAvailable({username})

client.twoFactor.enable({password})                           // -> totpURI + backupCodes
client.twoFactor.disable({password})
client.twoFactor.getTotpUri({password})
client.twoFactor.verifyTotp({code, trustDevice?})
client.twoFactor.sendOtp()
client.twoFactor.verifyOtp({code, trustDevice?})
client.twoFactor.generateBackupCodes({password})
client.twoFactor.verifyBackupCode({code, trustDevice?})
```

`signIn.email` may return a **two-factor challenge** (`twoFactorRedirect`) instead of a
session; `signIn.social` may return a **redirect URL** instead of a session. Both surface
as typed response variants the caller (or `AuthCubit`) branches on.

---

## 4. `betterauth_flutter` (Flutter wrapper)

### 4.1 Dependencies

```yaml
dependencies:
  betterauth_dart: { path: ../betterauth_dart }   # ^version at publish
  flutter_bloc: ^9.0.0
  flutter_secure_storage: ^9.2.0
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.3
  flutter_web_auth_2: ^4.1.0
  app_links: ^6.3.2          # deep-link completion for redirect flows
  equatable: ^2.0.7
dev_dependencies:
  bloc_test: ^10.0.0
  mocktail: ^1.0.5
```

### 4.2 Pieces

- **`BetterAuth.initialize({baseUrl, AsyncStorage? storage, options})`** — static
  singleton (`BetterAuth.instance.client`). Defaults storage to
  `SecureStorageAdapter` (Keychain/Keystore). On init: read persisted token+session,
  emit cached `AuthState` synchronously (optimistic), then validate via
  `session.get()` in the background.
- **`SecureStorageAdapter implements AsyncStorage`** over `flutter_secure_storage`;
  persists token + serialized session JSON.
- **`SessionRefreshController`** — proactive `Timer` re-calling `session.get()` before
  `expiresAt`, plus `WidgetsBindingObserver` re-fetch on `resumed`.
- **Social** — `signInWithGoogle()` (google_sign_in → idToken → `signIn.social`),
  `signInWithApple()` (sign_in_with_apple → idToken), and `signInWithProvider(provider)`
  (flutter_web_auth_2 browser redirect → completion).
- **`AuthCubit` / `AuthState`** (flutter_bloc) — seeded from `currentSession`, listens to
  `onAuthStateChange`; exposes `signInEmail`, `signUpEmail`, `signInWithGoogle`,
  `signInWithApple`, `verifyTotp`, `signOut`, … each mapping `AuthResult` →
  `AuthCubitState` (`unknown / authenticated / unauthenticated / twoFactorRequired / failure`).

---

## 5. Testing, docs, CI (VGV)

- **100% coverage** both packages: `very_good test --coverage --min-coverage 100`.
  dio mocked via `http_mock_adapter`; storage/cubit via `mocktail`/`bloc_test`.
  `test/` mirrors `lib/` 1:1.
- **Docs**: every public member dartdoc'd (`public_member_api_docs` on) using
  `{@template}` / `{@macro}`. READMEs: usage + quick-start + the 3 VGV badges; CHANGELOG
  (Keep a Changelog); example linked.
- **CI**: scaffolded `main.yaml` (semantic PR + spell-check + `dart_package`/`flutter_package`
  + `pana`) + `license_check.yaml` + `dependabot.yaml` + `cspell.json`. Add SDK words
  (`betterauth`, `totp`, `otp`, `dio`) to cspell. Repo-root per-package workflows for the
  monorepo. Tag-triggered publish workflow (OIDC) gated on pana.

---

## 6. Build phases

1. **Foundations** — pubspecs (deps), barrels, constants, `AsyncStorage`, `AuthResult`,
   exceptions, `AuthErrorCode`.
2. **Models** — `User`, `Session`, `Account`, responses, `AuthState` (+ tests, 100%).
3. **Transport** — `BetterAuthHttp`, interceptors (auth/retry/logging), `TokenStore` (+ tests).
4. **Core client** — `BetterAuthClient` + all groups, auth-state stream (+ tests).
5. **betterauth_flutter** — storage adapter, singleton, refresh controller, social, OAuth,
   `AuthCubit` (+ tests).
6. **Example app** — full demo of every flow.
7. **Polish** — READMEs, CHANGELOGs, dartdoc pass, cspell, publish workflow, `pana` check,
   `--recursive` analyze+test to green.

Each phase ends green (`analyze` clean, tests pass, coverage 100%) before the next.
