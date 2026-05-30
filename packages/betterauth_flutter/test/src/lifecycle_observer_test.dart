import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(LifecycleObserver, () {
    late int callCount;
    late LifecycleObserver observer;

    setUp(() {
      callCount = 0;
      observer = LifecycleObserver(() => callCount++);
    });

    test('invokes onResume when state is resumed', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(callCount, 1);
    });

    test('does not invoke onResume when state is paused', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(callCount, 0);
    });

    test('does not invoke onResume when state is inactive', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);

      expect(callCount, 0);
    });

    test('does not invoke onResume when state is detached', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);

      expect(callCount, 0);
    });

    test('does not invoke onResume when state is hidden', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.hidden);

      expect(callCount, 0);
    });
  });
}
