/// Internal constants shared across the betterauth_dart client.
///
/// These are deliberately not exported from the public barrel; they describe
/// wire-level details (header names, default paths, storage keys) that callers
/// should not need to depend on directly.
library;

/// The default base path a better-auth server mounts its routes under.
///
/// A consumer typically passes a full base URL that already includes this
/// segment (for example `https://api.example.com/api/auth`).
const String kDefaultBasePath = '/api/auth';

/// Response header that carries the session token when the server has the
/// `bearer` plugin enabled.
const String kSetAuthTokenHeader = 'set-auth-token';

/// Request header used to attach the session token in bearer mode.
const String kAuthorizationHeader = 'Authorization';

/// The scheme prefix for the [kAuthorizationHeader] value in bearer mode.
const String kBearerPrefix = 'Bearer ';

/// Standard `Set-Cookie` response header (cookie transport mode).
const String kSetCookieHeader = 'set-cookie';

/// Standard `Cookie` request header (cookie transport mode).
const String kCookieHeader = 'Cookie';

/// The cookie name better-auth uses for the session token.
const String kSessionCookieName = 'better-auth.session_token';

/// Storage key under which the session token is persisted.
const String kSessionTokenStorageKey = 'betterauth.session_token';

/// Storage key under which the serialized `Session`/`User` snapshot is
/// persisted, enabling optimistic restore at startup.
const String kSessionStorageKey = 'betterauth.session';

/// Default network timeout applied to connect, send and receive.
const Duration kDefaultTimeout = Duration(seconds: 30);

/// Default maximum number of retry attempts for transient failures.
const int kDefaultMaxRetries = 3;

/// Safety margin subtracted from `Session.expiresAt` when computing expiry,
/// mirroring gotrue's `expiryMargin`.
const Duration kExpiryMargin = Duration(seconds: 30);
