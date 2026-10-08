import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/local_storage.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/core/services/login/email_login.dart';
import 'package:tic_tac_toe/core/services/login/guest_login.dart';
import 'package:tic_tac_toe/core/services/login/login.dart';
import 'package:tic_tac_toe/commons/models/user_model.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

// Bloc: owns the user's sign-in/session state (guest or full account),
// syncs it with Firebase Auth + local flags, and streams live user updates.
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  // Live subscription to the signed-in user's Firestore doc; re-created by
  // _listenToUser() and cancelled on close() so it never leaks or duplicates.
  StreamSubscription<UserModel>? _userSubscription;

  AuthenticationBloc() : super(UnAuthorizedState()) {
    on<CheckAuthenticationEvent>((event, emit) async {
      // Firebase restores a persisted session asynchronously, so `currentUser`
      // can still be null at this point. Wait for the first auth-state event
      // before trusting the local flags — otherwise reading the user's uid
      // throws a null-check error.
      final User? firebaseUser = FirebaseAuth.instance.currentUser ??
          await FirebaseAuth.instance.authStateChanges().first;

      if (firebaseUser == null) {
        // Local flags are stale (no real session); force re-authentication.
        emit(UnAuthorizedState());
        return;
      }

      final bool authenticated = await LocalStorage.checkAuthentication();
      final bool isGuest = await LocalStorage.isGuest();
      try {
        if (authenticated) {
          final UserModel user = await DatabaseService.instance.getUser();

          emit(AuthenticatedState(user));
          _listenToUser();
        } else {
          if (isGuest) {
            final UserModel user = await DatabaseService.instance.getUser();
            emit(AuthenticatedAsGuestState(user));
            _listenToUser();
          } else {
            emit(UnAuthorizedState());
          }
        }
      } catch (e) {
        emit(UnAuthorizedState());
      }
    });
    on<SigninEvent>((SigninEvent event, emit) async {
      try {
        emit(SigninInProgressState(event.authProvider.type));
        await event.authProvider.init();
        final UserCredential? userCredential = await event.authProvider.login();
        UserModel? user;

        // First-time sign-in for this uid: create the profile doc; otherwise
        // just load the existing one.
        if (!(await DatabaseService.instance.checkIsUserExists())) {
          String username = (userCredential!.user!.displayName ?? '').trim();
          if (username.isEmpty) {
            username = userCredential.user!.email ?? '';
          }

          // Email signup carries a username the user typed explicitly; prefer
          // it over the displayName/email fallback above, since Firebase's
          // displayName isn't set until updateDisplayName runs further below.
          if (event.authProvider.runtimeType == EmailLogin &&
              (event.authProvider.parameters as EmailLoginParameters).type ==
                  EmailLoginType.signup) {
            username = (event.authProvider.parameters as EmailLoginParameters)
                .username!;
          }
          user = UserModel(
              username: username,
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              profilePic: userCredential.user!.photoURL ?? '',
              email: userCredential.user!.email,
              type: 'AUTHENTICATED');

          await FirebaseAuth.instance.currentUser?.updateDisplayName(username);

          await DatabaseService.instance.createUser(user);
        } else {
          user = await DatabaseService.instance.getUser();
        }

        await LocalStorage.setUserAuthenticated();
        await LocalStorage.setUserIsNotGuest();

        if (userCredential?.user != null) {
          emit(AuthenticatedState(user));
          _listenToUser();
        } else {
          emit(AuthenticationFailedState('somethingWentWrongTryAgain'));
        }
      } catch (e) {
        emit(AuthenticationFailedState(e));
      }
    });

    on<GuestLoginEvent>((event, emit) async {
      try {
        emit(GuestLoginInProgressState());
        await event.guestLogin.init();
        final UserCredential? userCredential = await event.guestLogin.login();
        await LocalStorage.setUserIsGuest();

        if (userCredential?.user != null) {
          final String username = 'Guest_${Uuid().v1()}';
          await userCredential?.user?.updateDisplayName(username);
          final UserModel user = UserModel(
              username: username,
              userId: userCredential!.user!.uid,
              profilePic: userCredential.user!.photoURL ?? '',
              email: null, //Not setting email because guest user would not have
              type: 'GUEST');

          await DatabaseService.instance.createUser(user);

          emit(AuthenticatedAsGuestState(user));
          _listenToUser();
        } else {
          emit(AuthenticationFailedState('somethingWentWrongTryAgain'));
        }
      } catch (e) {
        emit(AuthenticationFailedState(e));
      }
    });
    on<SendForgotPasswordEmailEvent>((event, emit) async {
      try {
        emit(SendForgotPasswordEmailInProgressState());
        await FirebaseAuth.instance.sendPasswordResetEmail(email: event.email);
        emit(SendForgotPasswordEmailSuccessState());
      } catch (e) {
        emit(AuthenticationFailedState(e));
      }
    });

    on<_UserDataChangedEvent>((event, emit) {
      if (state is AuthenticatedAsGuestState) {
        emit(AuthenticatedAsGuestState(event.user));
      } else if (state is AuthenticatedState) {
        emit(AuthenticatedState(event.user));
      }
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }

  void _listenToUser() {
    _userSubscription?.cancel();
    _userSubscription = DatabaseService.instance.streamUser().listen(
          (user) => add(_UserDataChangedEvent(user)),
        );
  }

  UserModel? get user {
    if (state is AuthenticatedState) {
      return (state as AuthenticatedState).user;
    } else if (state is AuthenticatedAsGuestState) {
      return (state as AuthenticatedAsGuestState).user;
    }
    return null;
  }

  bool get isGuest => state is AuthenticatedAsGuestState;
}
