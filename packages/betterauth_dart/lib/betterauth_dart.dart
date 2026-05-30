/// A pure-Dart client SDK for the better-auth authentication server.
///
/// Create a `BetterAuthClient` with the server's auth base URL and call the
/// namespaced groups (`signIn`, `signUp`, `session`, …). Every call returns an
/// `AuthResult`; listen to `BetterAuthClient.onAuthStateChange` for session
/// transitions.
library;

export 'src/better_auth_client.dart';
export 'src/client_options.dart';
export 'src/exceptions/auth_error_code.dart';
export 'src/exceptions/auth_exception.dart';
export 'src/groups/account_group.dart';
export 'src/groups/anonymous_group.dart';
export 'src/groups/email_otp_group.dart';
export 'src/groups/email_verification_group.dart';
export 'src/groups/magic_link_group.dart';
export 'src/groups/organization_group.dart';
export 'src/groups/passkey_group.dart';
export 'src/groups/password_group.dart';
export 'src/groups/phone_number_group.dart';
export 'src/groups/session_group.dart';
export 'src/groups/sign_in_group.dart';
export 'src/groups/sign_up_group.dart';
export 'src/groups/two_factor_group.dart';
export 'src/groups/user_group.dart';
export 'src/groups/username_group.dart';
export 'src/models/models.dart';
export 'src/result/auth_result.dart';
export 'src/storage/async_storage.dart';
