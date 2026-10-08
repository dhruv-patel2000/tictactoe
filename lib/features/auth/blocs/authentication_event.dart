// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authentication_bloc.dart';

// Events consumed by AuthenticationBloc to drive sign-in/sign-out flows.
@immutable
sealed class AuthenticationEvent {}

class CheckAuthenticationEvent extends AuthenticationEvent {}

class SendForgotPasswordEmailEvent extends AuthenticationEvent {
  final String email;
  SendForgotPasswordEmailEvent({required this.email});
}

class SigninEvent extends AuthenticationEvent {
  final Login authProvider;
  SigninEvent({
    required this.authProvider,
  });
}

class GuestLoginEvent extends AuthenticationEvent {
  // Instantiated per-event rather than injected, since a guest login carries
  // no state of its own.
  final GuestLogin guestLogin = GuestLogin();
  GuestLoginEvent();
}

/// Internal event fired by the live user stream so the authenticated state is
/// re-emitted with fresh score/coin/match values.
class _UserDataChangedEvent extends AuthenticationEvent {
  final UserModel user;
  _UserDataChangedEvent(this.user);
}
