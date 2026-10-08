import 'package:flutter/material.dart';

/// Lets a screen find out when it is covered by another screen and when it is
/// revealed again. Registered on the app's navigator in `App`, so anything
/// mixing in [RouteAware] can subscribe to its own [PageRoute].
///
/// Typed to [PageRoute] on purpose: dialogs are [ModalRoute]s but not
/// [PageRoute]s, so opening and closing a dialog does not count as leaving the
/// screen.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
