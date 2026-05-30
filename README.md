# better-auth for Dart & Flutter

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A client SDK for the [better-auth][better_auth_link] authentication server,
following [Very Good Ventures][vgv_link] engineering conventions (strict
analysis, 100% test coverage, narrow public APIs).

## Packages

| Package | Description | |
|---|---|---|
| [`betterauth_dart`](packages/betterauth_dart) | Pure-Dart client (transport, models, API groups, auth-state stream). | [![pub][dart_pub_badge]][dart_pub_link] |
| [`betterauth_flutter`](packages/betterauth_flutter) | Flutter bindings: secure storage, native social sign-in, lifecycle refresh, `flutter_bloc`. | [![pub][flutter_pub_badge]][flutter_pub_link] |

Most apps depend on **`betterauth_flutter`** (it re-exports the full
`betterauth_dart` API). Pure-Dart / server / CLI consumers use
**`betterauth_dart`** directly.

## Layout

```
betterauth/
├── packages/
│   ├── betterauth_dart/      # pure Dart core
│   └── betterauth_flutter/   # Flutter wrapper + example app
└── .github/workflows/        # per-package CI (Very Good Workflows)
```

The Flutter package consumes the core via a `^` version constraint plus a local
`dependency_overrides` path during development.

## Development

```sh
dart pub global activate very_good_cli

# Resolve + test both packages
very_good packages get --recursive
very_good test --recursive --coverage --min-coverage 100
```

See [`DESIGN.md`](DESIGN.md) for the full architecture and the decisions behind
it.

[better_auth_link]: https://www.better-auth.com
[vgv_link]: https://verygood.ventures
[dart_pub_badge]: https://img.shields.io/pub/v/betterauth_dart.svg
[dart_pub_link]: https://pub.dev/packages/betterauth_dart
[flutter_pub_badge]: https://img.shields.io/pub/v/betterauth_flutter.svg
[flutter_pub_link]: https://pub.dev/packages/betterauth_flutter
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
