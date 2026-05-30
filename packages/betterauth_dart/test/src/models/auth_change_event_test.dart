import 'package:betterauth_dart/src/models/auth_change_event.dart';
import 'package:test/test.dart';

void main() {
  group(AuthChangeEvent, () {
    test('exposes exactly five values in declared order', () {
      expect(AuthChangeEvent.values, hasLength(5));
      expect(
        AuthChangeEvent.values,
        equals(<AuthChangeEvent>[
          AuthChangeEvent.initialSession,
          AuthChangeEvent.signedIn,
          AuthChangeEvent.signedOut,
          AuthChangeEvent.sessionRefreshed,
          AuthChangeEvent.userUpdated,
        ]),
      );
    });

    test('each value has a distinct name', () {
      final names = AuthChangeEvent.values.map((event) => event.name).toSet();
      expect(names, hasLength(AuthChangeEvent.values.length));
    });
  });
}
