import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template sign_in_group}
/// Sign-in methods, exposed as `client.signIn`.
/// {@endtemplate}
final class SignInGroup extends BetterAuthGroup {
  /// {@macro sign_in_group}
  SignInGroup(super.http, super.sink);

  /// Signs in with email and password (`POST /sign-in/email`).
  ///
  /// Returns a [SignedIn] (the client adopts the session and emits
  /// [AuthChangeEvent.signedIn]) or a [TwoFactorRequired] challenge when the
  /// account has two-factor enabled.
  Future<AuthResult<SignInResponse>> email({
    required String email,
    required String password,
    bool rememberMe = true,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/sign-in/email',
      method: 'POST',
      body: body(<String, dynamic>{
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
        'callbackURL': callbackURL,
      }),
    );
    return _completeSignIn(decodeObject(raw, SignInResponse.fromJson));
  }

  /// Signs in with username and password (`POST /sign-in/username`).
  ///
  /// Requires the username plugin. Like [email], may return a
  /// [TwoFactorRequired] challenge.
  Future<AuthResult<SignInResponse>> username({
    required String username,
    required String password,
    bool rememberMe = true,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/sign-in/username',
      method: 'POST',
      body: body(<String, dynamic>{
        'username': username,
        'password': password,
        'rememberMe': rememberMe,
        'callbackURL': callbackURL,
      }),
    );
    return _completeSignIn(decodeObject(raw, SignInResponse.fromJson));
  }

  /// Signs in with a phone number and password (`POST /sign-in/phone-number`).
  ///
  /// Requires the phone-number plugin with password sign-in enabled. May return
  /// a [TwoFactorRequired] challenge.
  Future<AuthResult<SignInResponse>> phoneNumber({
    required String phoneNumber,
    required String password,
    bool rememberMe = true,
  }) async {
    final raw = await http.request(
      '/sign-in/phone-number',
      method: 'POST',
      body: body(<String, dynamic>{
        'phoneNumber': phoneNumber,
        'password': password,
        'rememberMe': rememberMe,
      }),
    );
    return _completeSignIn(decodeObject(raw, SignInResponse.fromJson));
  }

  /// Signs in with a social provider (`POST /sign-in/social`).
  ///
  /// Pass [idToken] for the native flow (the client adopts the session and
  /// emits [AuthChangeEvent.signedIn]); otherwise the server returns a
  /// [SocialRedirect] whose URL must be opened in a browser to continue.
  Future<AuthResult<SocialSignInResponse>> social({
    required String provider,
    IdToken? idToken,
    String? callbackURL,
    String? newUserCallbackURL,
    String? errorCallbackURL,
    bool? disableRedirect,
    List<String>? scopes,
    bool? requestSignUp,
    String? loginHint,
  }) async {
    final raw = await http.request(
      '/sign-in/social',
      method: 'POST',
      body: body(<String, dynamic>{
        'provider': provider,
        'idToken': idToken?.toJson(),
        'callbackURL': callbackURL,
        'newUserCallbackURL': newUserCallbackURL,
        'errorCallbackURL': errorCallbackURL,
        'disableRedirect': disableRedirect,
        'scopes': scopes,
        'requestSignUp': requestSignUp,
        'loginHint': loginHint,
      }),
    );
    final result = decodeObject(raw, SocialSignInResponse.fromJson);
    if (result case AuthSuccess<SocialSignInResponse>(
      data: final r,
    ) when r is SocialSignedIn) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }

  /// Signs in with an email one-time password (`POST /sign-in/email-otp`).
  ///
  /// Requires the email-OTP plugin. On success the client adopts the session.
  Future<AuthResult<AuthSession>> emailOtp({
    required String email,
    required String otp,
    String? name,
    String? image,
  }) async {
    final raw = await http.request(
      '/sign-in/email-otp',
      method: 'POST',
      body: body(<String, dynamic>{
        'email': email,
        'otp': otp,
        'name': name,
        'image': image,
      }),
    );
    final result = decodeObject(raw, AuthSession.fromJson);
    if (result case AuthSuccess<AuthSession>(data: final r)) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }

  /// Requests a magic-link sign-in email (`POST /sign-in/magic-link`).
  ///
  /// Requires the magic-link plugin. No session is created here; the link is
  /// emailed and completed via `client.magicLink.verify`.
  Future<AuthResult<StatusResponse>> magicLink({
    required String email,
    String? name,
    String? callbackURL,
    String? newUserCallbackURL,
    String? errorCallbackURL,
    Map<String, dynamic>? metadata,
  }) async {
    final raw = await http.request(
      '/sign-in/magic-link',
      method: 'POST',
      body: body(<String, dynamic>{
        'email': email,
        'name': name,
        'callbackURL': callbackURL,
        'newUserCallbackURL': newUserCallbackURL,
        'errorCallbackURL': errorCallbackURL,
        'metadata': metadata,
      }),
    );
    return decodeStatus(raw);
  }

  /// Signs in anonymously (`POST /sign-in/anonymous`).
  ///
  /// Requires the anonymous plugin. On success the client adopts the session
  /// and emits [AuthChangeEvent.signedIn]; the returned user has
  /// `isAnonymous == true`.
  Future<AuthResult<AuthSession>> anonymous() async {
    final raw = await http.request('/sign-in/anonymous', method: 'POST');
    final result = decodeObject(raw, AuthSession.fromJson);
    if (result case AuthSuccess<AuthSession>(data: final r)) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }

  /// Signs in with a passkey (`POST /sign-in/passkey`).
  ///
  /// Requires the passkey plugin. [response] is the assertion map produced by
  /// the native authenticator (obtained via
  /// `client.passkey.generateAuthenticateOptions` then the native ceremony).
  /// On success the client adopts the session.
  Future<AuthResult<AuthSession>> passkey({
    required Map<String, dynamic> response,
  }) async {
    final raw = await http.request(
      '/sign-in/passkey',
      method: 'POST',
      body: response,
    );
    final result = decodeObject(raw, AuthSession.fromJson);
    if (result case AuthSuccess<AuthSession>(data: final r)) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }

  Future<AuthResult<SignInResponse>> _completeSignIn(
    AuthResult<SignInResponse> result,
  ) async {
    if (result case AuthSuccess<SignInResponse>(
      data: final r,
    ) when r is SignedIn) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }
}
