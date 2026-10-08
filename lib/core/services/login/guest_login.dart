import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/core/services/login/login.dart';

// Anonymous Firebase sign-in for playing without creating an account.
class GuestLogin extends Login {
  @override
  AuthenticationType get type => AuthenticationType.guest;

  @override
  FutureOr<void> init() async {}

  @override
  Future<UserCredential?> login() async {
    return await FirebaseAuth.instance.signInAnonymously();
  }
}
