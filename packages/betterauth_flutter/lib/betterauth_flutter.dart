/// Flutter bindings for the better-auth client: secure storage, native social
/// sign-in, lifecycle-driven refresh and a `flutter_bloc` integration.
///
/// Re-exports the full `betterauth_dart` API, so a single import is enough:
///
/// ```dart
/// import 'package:betterauth_flutter/betterauth_flutter.dart';
/// ```
library;

export 'package:betterauth_dart/betterauth_dart.dart';

export 'src/authenticators.dart';
export 'src/better_auth.dart';
export 'src/cubit/auth_cubit.dart';
export 'src/lifecycle_observer.dart';
export 'src/secure_storage_adapter.dart';
