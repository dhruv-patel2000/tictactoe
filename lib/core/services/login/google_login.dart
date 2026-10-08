import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/core/services/login/login.dart';

/// Wraps Google Sign-In and exchanges the resulting ID token for a Firebase
/// credential.
class GoogleLogin extends Login {
  static bool _initialized =
      false; // set once ensureInitialized has run, so it stays idempotent

  @override
  AuthenticationType get type => AuthenticationType.google;

  /// Ensures [GoogleSignIn.instance] is initialized exactly once, since the
  /// underlying SDK treats repeated calls as undefined behavior.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  @override
  Future<void> init() => ensureInitialized();

  @override
  Future<UserCredential> login() async {
    try {
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = account.authentication;

      final AuthCredential authCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(authCredential);

      return userCredential;
    } on GoogleSignInException catch (e) {
      log('Issue $e');

      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          throw 'signInCancelled';
        case GoogleSignInExceptionCode.interrupted:
          throw 'networkErrorTryAgain';
        default:
          throw 'googleSignInFailedConfig';
      }
    } catch (e) {
      log('Issue $e');
      throw 'googleSignInFailedRetry';
    }
  }
}
