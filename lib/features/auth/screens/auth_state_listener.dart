import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';

/// Shared reaction to an auth result for the sign-in screens.
///
/// Only the screen currently on top of the stack acts on the state. The bloc
/// keeps emitting [AuthenticatedState] for the whole session — the live user
/// stream re-emits it on every coin/score change — so an auth screen left
/// behind in the stack would otherwise keep yanking the player back to the
/// home screen mid-game.
void onAuthenticationStateChanged(
    BuildContext context, AuthenticationState state) {
  if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

  if (state is AuthenticationFailedState) {
    // state.error is a translation key when known, otherwise fall back to a generic message.
    final message = state.error is String
        ? context.tr(state.error as String)
        : context.tr('somethingWentWrongTryAgain');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  if (state is AuthenticatedState || state is AuthenticatedAsGuestState) {
    // Clear the whole auth flow: once the player is home, back must exit the
    // app instead of walking back into a login screen.
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.homeScreen, (route) => false);
  }
}
