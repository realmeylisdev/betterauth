import 'package:betterauth_dart/src/models/session.dart';
import 'package:betterauth_dart/src/models/user.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template status_response}
/// A generic confirmation response.
///
/// Normalises better-auth's two confirmation shapes — `{ "status": true }` and
/// `{ "success": true }` — into a single [ok] flag, with an optional
/// server [message].
/// {@endtemplate}
@immutable
class StatusResponse extends Equatable {
  /// {@macro status_response}
  const StatusResponse({required this.ok, this.message});

  /// Parses a [StatusResponse]. A 2xx body without an explicit `status`/
  /// `success` key is treated as [ok] = `true`.
  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      ok: (json['status'] as bool?) ?? (json['success'] as bool?) ?? true,
      message: json['message'] as String?,
    );
  }

  /// Whether the operation succeeded.
  final bool ok;

  /// An optional human-readable message from the server.
  final String? message;

  @override
  List<Object?> get props => [ok, message];
}

/// {@template session_response}
/// The `{ session, user }` payload returned by `/get-session` and
/// `/magic-link/verify`.
/// {@endtemplate}
@immutable
class SessionResponse extends Equatable {
  /// {@macro session_response}
  const SessionResponse({required this.session, required this.user});

  /// Parses a [SessionResponse].
  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      session: Session.fromJson(json['session'] as Map<String, dynamic>),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// The active session.
  final Session session;

  /// The authenticated user.
  final User user;

  @override
  List<Object?> get props => [session, user];
}

/// {@template auth_session}
/// A `{ token, user }` payload returned by flows that always create a session
/// (email-OTP sign-in, phone-number sign-in, two-factor verification).
/// {@endtemplate}
@immutable
class AuthSession extends Equatable {
  /// {@macro auth_session}
  const AuthSession({required this.token, required this.user});

  /// Parses an [AuthSession].
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// The session token.
  final String token;

  /// The authenticated user.
  final User user;

  @override
  List<Object?> get props => [token, user];
}

/// {@template sign_up_response}
/// The `{ token, user }` payload returned by `/sign-up/email`. [token] is
/// `null` when email verification is required or auto-sign-in is disabled.
/// {@endtemplate}
@immutable
class SignUpResponse extends Equatable {
  /// {@macro sign_up_response}
  const SignUpResponse({required this.user, this.token});

  /// Parses a [SignUpResponse].
  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      token: json['token'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// The session token, or `null` when no session was created.
  final String? token;

  /// The created user.
  final User user;

  /// Whether a session was created (i.e. [token] is non-null).
  bool get hasSession => token != null;

  @override
  List<Object?> get props => [token, user];
}

/// {@template sign_in_response}
/// The result of a password sign-in (`/sign-in/email`, `/sign-in/username`):
/// either a [SignedIn] session, or a [TwoFactorRequired] challenge when the
/// account has two-factor enabled.
/// {@endtemplate}
@immutable
sealed class SignInResponse extends Equatable {
  /// {@macro sign_in_response}
  const SignInResponse();

  /// Parses the polymorphic sign-in response, dispatching on
  /// `twoFactorRedirect`.
  factory SignInResponse.fromJson(Map<String, dynamic> json) {
    if (json['twoFactorRedirect'] == true) {
      return TwoFactorRequired(
        methods:
            (json['twoFactorMethods'] as List<dynamic>?)
                ?.map((dynamic e) => e as String)
                .toList() ??
            const [],
      );
    }
    return SignedIn(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// {@template signed_in}
/// A successful password sign-in carrying the session [token] and [user].
/// {@endtemplate}
@immutable
final class SignedIn extends SignInResponse {
  /// {@macro signed_in}
  const SignedIn({required this.token, required this.user});

  /// The session token.
  final String token;

  /// The authenticated user.
  final User user;

  @override
  List<Object?> get props => [token, user];
}

/// {@template two_factor_required}
/// A sign-in that requires a second factor. [methods] lists the available
/// challenge methods (among `totp`, `otp`).
/// {@endtemplate}
@immutable
final class TwoFactorRequired extends SignInResponse {
  /// {@macro two_factor_required}
  const TwoFactorRequired({this.methods = const []});

  /// The available second-factor methods.
  final List<String> methods;

  @override
  List<Object?> get props => [methods];
}

/// {@template social_sign_in_response}
/// The result of `/sign-in/social`: either a [SocialRedirect] (open the URL in
/// a browser) or a [SocialSignedIn] session (native id-token flow).
/// {@endtemplate}
@immutable
sealed class SocialSignInResponse extends Equatable {
  /// {@macro social_sign_in_response}
  const SocialSignInResponse();

  /// Parses the polymorphic social sign-in response, dispatching on `redirect`.
  factory SocialSignInResponse.fromJson(Map<String, dynamic> json) {
    if (json['redirect'] == true) {
      return SocialRedirect(url: json['url'] as String);
    }
    return SocialSignedIn(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// {@template social_redirect}
/// A social sign-in that must continue in a browser at [url].
/// {@endtemplate}
@immutable
final class SocialRedirect extends SocialSignInResponse {
  /// {@macro social_redirect}
  const SocialRedirect({required this.url});

  /// The authorization URL to open.
  final String url;

  @override
  List<Object?> get props => [url];
}

/// {@template social_signed_in}
/// A completed native social sign-in carrying the session [token] and [user].
/// {@endtemplate}
@immutable
final class SocialSignedIn extends SocialSignInResponse {
  /// {@macro social_signed_in}
  const SocialSignedIn({required this.token, required this.user});

  /// The session token.
  final String token;

  /// The authenticated user.
  final User user;

  @override
  List<Object?> get props => [token, user];
}

/// {@template change_password_response}
/// The `{ token, user }` payload returned by `/change-password`. [token] is
/// non-null only when `revokeOtherSessions` issued a fresh session.
/// {@endtemplate}
@immutable
class ChangePasswordResponse extends Equatable {
  /// {@macro change_password_response}
  const ChangePasswordResponse({required this.user, this.token});

  /// Parses a [ChangePasswordResponse].
  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      token: json['token'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// A refreshed session token, if one was issued.
  final String? token;

  /// The updated user.
  final User user;

  @override
  List<Object?> get props => [token, user];
}

/// {@template verify_email_response}
/// The `{ status, user? }` payload returned by `GET /verify-email`.
/// {@endtemplate}
@immutable
class VerifyEmailResponse extends Equatable {
  /// {@macro verify_email_response}
  const VerifyEmailResponse({required this.ok, this.user});

  /// Parses a [VerifyEmailResponse].
  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return VerifyEmailResponse(
      ok: (json['status'] as bool?) ?? true,
      user: user is Map<String, dynamic> ? User.fromJson(user) : null,
    );
  }

  /// Whether verification succeeded.
  final bool ok;

  /// The verified user, when returned.
  final User? user;

  @override
  List<Object?> get props => [ok, user];
}

/// {@template email_otp_verify_response}
/// The `{ status, token?, user }` payload returned by
/// `/email-otp/verify-email`.
/// {@endtemplate}
@immutable
class EmailOtpVerifyResponse extends Equatable {
  /// {@macro email_otp_verify_response}
  const EmailOtpVerifyResponse({
    required this.ok,
    required this.user,
    this.token,
  });

  /// Parses an [EmailOtpVerifyResponse].
  factory EmailOtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return EmailOtpVerifyResponse(
      ok: (json['status'] as bool?) ?? true,
      token: json['token'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Whether verification succeeded.
  final bool ok;

  /// A session token, if a session was created.
  final String? token;

  /// The verified user.
  final User user;

  @override
  List<Object?> get props => [ok, token, user];
}

/// {@template phone_verify_response}
/// The `{ status, token?, user? }` payload returned by `/phone-number/verify`.
/// [user]/[token] are `null` when verifying without creating a session.
/// {@endtemplate}
@immutable
class PhoneVerifyResponse extends Equatable {
  /// {@macro phone_verify_response}
  const PhoneVerifyResponse({required this.ok, this.token, this.user});

  /// Parses a [PhoneVerifyResponse].
  factory PhoneVerifyResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return PhoneVerifyResponse(
      ok: (json['status'] as bool?) ?? true,
      token: json['token'] as String?,
      user: user is Map<String, dynamic> ? User.fromJson(user) : null,
    );
  }

  /// Whether verification succeeded.
  final bool ok;

  /// A session token, if a session was created.
  final String? token;

  /// The user, if one was created or updated.
  final User? user;

  @override
  List<Object?> get props => [ok, token, user];
}

/// {@template two_factor_enable_response}
/// The `{ totpURI, backupCodes }` payload returned by `/two-factor/enable`.
/// {@endtemplate}
@immutable
class TwoFactorEnableResponse extends Equatable {
  /// {@macro two_factor_enable_response}
  const TwoFactorEnableResponse({
    required this.totpUri,
    this.backupCodes = const [],
  });

  /// Parses a [TwoFactorEnableResponse].
  factory TwoFactorEnableResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorEnableResponse(
      totpUri: json['totpURI'] as String,
      backupCodes:
          (json['backupCodes'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// The TOTP provisioning URI to render as a QR code.
  final String totpUri;

  /// One-time backup codes.
  final List<String> backupCodes;

  @override
  List<Object?> get props => [totpUri, backupCodes];
}

/// {@template totp_uri_response}
/// The `{ totpURI }` payload returned by `/two-factor/get-totp-uri`.
/// {@endtemplate}
@immutable
class TotpUriResponse extends Equatable {
  /// {@macro totp_uri_response}
  const TotpUriResponse({required this.totpUri});

  /// Parses a [TotpUriResponse].
  factory TotpUriResponse.fromJson(Map<String, dynamic> json) {
    return TotpUriResponse(totpUri: json['totpURI'] as String);
  }

  /// The TOTP provisioning URI.
  final String totpUri;

  @override
  List<Object?> get props => [totpUri];
}

/// {@template backup_codes_response}
/// The `{ status, backupCodes }` payload returned by
/// `/two-factor/generate-backup-codes`.
/// {@endtemplate}
@immutable
class BackupCodesResponse extends Equatable {
  /// {@macro backup_codes_response}
  const BackupCodesResponse({required this.ok, this.backupCodes = const []});

  /// Parses a [BackupCodesResponse].
  factory BackupCodesResponse.fromJson(Map<String, dynamic> json) {
    return BackupCodesResponse(
      ok: (json['status'] as bool?) ?? true,
      backupCodes:
          (json['backupCodes'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// Whether generation succeeded.
  final bool ok;

  /// The newly generated backup codes.
  final List<String> backupCodes;

  @override
  List<Object?> get props => [ok, backupCodes];
}

/// {@template verify_backup_code_response}
/// The `{ user, session? }` payload returned by
/// `/two-factor/verify-backup-code`. [session] is omitted when
/// `disableSession` was set.
/// {@endtemplate}
@immutable
class VerifyBackupCodeResponse extends Equatable {
  /// {@macro verify_backup_code_response}
  const VerifyBackupCodeResponse({required this.user, this.session});

  /// Parses a [VerifyBackupCodeResponse].
  factory VerifyBackupCodeResponse.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    return VerifyBackupCodeResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      session: session is Map<String, dynamic>
          ? Session.fromJson(session)
          : null,
    );
  }

  /// The authenticated user.
  final User user;

  /// The created session, if one was created.
  final Session? session;

  @override
  List<Object?> get props => [user, session];
}
