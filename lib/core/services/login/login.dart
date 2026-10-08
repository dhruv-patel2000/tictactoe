import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';

/// Common interface implemented by each auth provider (email, Google, Apple,
/// guest) so the UI can drive sign-in without knowing which one is active.
abstract class Login {
  FutureOr<void> init();
  LoginParameters?
      parameters; // provider-specific input set via [setData], read back by login()

  /// Identifies the provider so the UI can show a loader only on the method
  /// the user actually tapped.
  AuthenticationType get type;

  void setData(LoginParameters data) {
    parameters = data;
  }

  Future<UserCredential?> login();
}

/// Base type for provider-specific login input (see [EmailLoginParameters]).
abstract class LoginParameters {
  Map<String, dynamic> toMap();
}
