import 'dart:async';

import 'package:flutter/foundation.dart';

// Simple tick-down timer exposing its remaining seconds as a ValueNotifier
// so widgets can rebuild on change, plus an end-of-timer callback.
class Countdown {
  // remaining seconds; widgets listen to this to rebuild
  final ValueNotifier<int> current;
  // how often current is decremented
  final Duration _interval;
  // handle to the running periodic tick, cancelled on reset/dispose
  Timer? _timer;
  // original start value, used to restore current on reset()
  int? _start;
  // invoked once when current reaches zero
  void Function()? endCallback;

  Countdown(int start, {Duration interval = const Duration(seconds: 1)})
      : current = ValueNotifier<int>(start),
        _interval = interval {
    _start = start;

    // Fire the end callback as soon as the value reaches zero, regardless
    // of whether it got there via the internal timer or an external set.
    current.addListener(() {
      if (current.value == 0) {
        endCallback?.call();
      }
    });
  }

  void onTimerEnd(void Function() callBack) {
    endCallback = callBack;
  }

  // Starts (or restarts) the periodic tick that decrements current.
  void start() {
    _timer?.cancel();

    _timer = Timer.periodic(_interval, (timer) {
      if (current.value > 0) {
        current.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // Restores current to the initial start value and stops any running timer.
  void reset() {
    current.value = _start!;
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    current.dispose();
  }
}
