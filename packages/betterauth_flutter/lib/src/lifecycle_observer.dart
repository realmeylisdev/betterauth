import 'package:flutter/widgets.dart';

/// {@template lifecycle_observer}
/// A [WidgetsBindingObserver] that invokes [onResume] whenever the app returns
/// to the foreground, used to re-validate the session on resume.
/// {@endtemplate}
class LifecycleObserver with WidgetsBindingObserver {
  /// {@macro lifecycle_observer}
  LifecycleObserver(this.onResume);

  /// Called when the app is resumed.
  final void Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
