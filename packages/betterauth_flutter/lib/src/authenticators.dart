import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Obtains a Google [IdToken] via the native sign-in flow. Returns `null` if
/// the user cancels. Implementations are injected into `BetterAuth` so the
/// flow can be faked in tests.
typedef GoogleAuthenticator = Future<IdToken?> Function({List<String>? scopes});

/// Obtains an Apple [IdToken] via the native sign-in flow. Returns `null` if
/// the user cancels.
typedef AppleAuthenticator = Future<IdToken?> Function({List<String>? scopes});

/// Drives a browser-based OAuth flow, returning the final callback [Uri].
typedef WebAuthenticator =
    Future<Uri> Function({
      required String url,
      required String callbackUrlScheme,
    });

/// Performs the native WebAuthn registration ceremony: given the server's
/// creation-options map, returns the attestation map to send back (or `null`
/// if the user cancels).
typedef PasskeyRegistrar =
    Future<Map<String, dynamic>?> Function(Map<String, dynamic> options);

/// Performs the native WebAuthn authentication ceremony: given the server's
/// request-options map, returns the assertion map to send back (or `null` if
/// the user cancels).
typedef PasskeyAssertor =
    Future<Map<String, dynamic>?> Function(Map<String, dynamic> options);

// The default implementations below call platform plugins that cannot run in a
// pure unit test, so they are excluded from coverage. Their behaviour is
// covered by injecting fakes into `BetterAuth`.

// coverage:ignore-start

/// The default Google authenticator using `google_sign_in`.
Future<IdToken?> defaultGoogleAuthenticator({List<String>? scopes}) async {
  final googleSignIn = GoogleSignIn(scopes: scopes ?? const ['email']);
  final account = await googleSignIn.signIn();
  if (account == null) return null;
  final auth = await account.authentication;
  final idToken = auth.idToken;
  if (idToken == null) return null;
  return IdToken(token: idToken, accessToken: auth.accessToken);
}

/// The default Apple authenticator using `sign_in_with_apple`.
Future<IdToken?> defaultAppleAuthenticator({List<String>? scopes}) async {
  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: const [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
  );
  final idToken = credential.identityToken;
  if (idToken == null) return null;
  return IdToken(token: idToken);
}

/// The default web authenticator using `flutter_web_auth_2`.
Future<Uri> defaultWebAuthenticator({
  required String url,
  required String callbackUrlScheme,
}) async {
  final result = await FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackUrlScheme,
  );
  return Uri.parse(result);
}

/// The default passkey registrar using the `passkeys` package. Maps the
/// server's WebAuthn creation options to a native ceremony and returns the
/// attestation map.
Future<Map<String, dynamic>?> defaultPasskeyRegistrar(
  Map<String, dynamic> options,
) async {
  final response = await PasskeyAuthenticator().register(
    RegisterRequestType.fromJson(options),
  );
  return response.toJson();
}

/// The default passkey assertor using the `passkeys` package. Maps the
/// server's WebAuthn request options to a native ceremony and returns the
/// assertion map.
Future<Map<String, dynamic>?> defaultPasskeyAssertor(
  Map<String, dynamic> options,
) async {
  final response = await PasskeyAuthenticator().authenticate(
    AuthenticateRequestType.fromJson(options),
  );
  return response.toJson();
}

// coverage:ignore-end
