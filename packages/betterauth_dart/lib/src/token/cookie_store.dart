/// {@template cookie_store}
/// A minimal in-memory cookie jar.
///
/// better-auth carries some state in cookies even for native clients — notably
/// the `two_factor` challenge cookie and the `trust_device` cookie — and the
/// whole session in [cookie transport mode]. This store captures `Set-Cookie`
/// response headers and replays them as a single `Cookie` request header.
///
/// It intentionally ignores cookie attributes (domain, path, expiry) because
/// the client talks to a single known base URL; only `name=value` pairs are
/// retained.
/// {@endtemplate}
class CookieStore {
  /// {@macro cookie_store}
  CookieStore();

  final Map<String, String> _cookies = <String, String>{};

  /// The current cookies, keyed by name (an unmodifiable view).
  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  /// Replaces all stored cookies with [cookies] (used to restore from
  /// persistence).
  void loadFromMap(Map<String, String> cookies) {
    _cookies
      ..clear()
      ..addAll(cookies);
  }

  /// Whether any cookies are stored.
  bool get isEmpty => _cookies.isEmpty;

  /// Captures every `name=value` pair from a list of `Set-Cookie` header
  /// values, overwriting any existing cookie with the same name.
  void storeFromSetCookie(List<String> setCookieHeaders) {
    for (final header in setCookieHeaders) {
      final firstPair = header.split(';').first.trim();
      final eq = firstPair.indexOf('=');
      if (eq <= 0) continue;
      final name = firstPair.substring(0, eq).trim();
      final value = firstPair.substring(eq + 1).trim();
      if (name.isEmpty) continue;
      _cookies[name] = value;
    }
  }

  /// The value to send in the `Cookie` request header, or `null` when empty.
  String? get header {
    if (_cookies.isEmpty) return null;
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Removes the cookie with [name], if present.
  void remove(String name) => _cookies.remove(name);

  /// Clears all stored cookies.
  void clear() => _cookies.clear();
}
