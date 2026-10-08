import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/core/services/login/login.dart';

// Wraps Sign in with Apple and exchanges the resulting identity token for a
// Firebase credential.
class AppleLogin extends Login {
  OAuthCredential?
      credential; // Firebase credential built from Apple's ID token, used to sign in
  OAuthProvider?
      oAuthProvider; // Firebase's 'apple.com' OAuth provider, used to build [credential]

  @override
  AuthenticationType get type => AuthenticationType.apple;

  @override
  void init() async {}

  @override
  Future<UserCredential?> login() async {
    final AuthorizationCredentialAppleID appleIdCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    oAuthProvider = OAuthProvider('apple.com');
    credential = oAuthProvider!.credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential!);

    // Apple only returns the name on first sign-in, so it must be saved
    // to Firebase now or it's lost on subsequent logins.
    if (userCredential.additionalUserInfo!.isNewUser) {
      final String givenName = appleIdCredential.givenName ?? "";
      final String familyName = appleIdCredential.familyName ?? "";

      await userCredential.user!.updateDisplayName("$givenName $familyName");
      await userCredential.user!.reload();
    }

    return userCredential;
  }
}
