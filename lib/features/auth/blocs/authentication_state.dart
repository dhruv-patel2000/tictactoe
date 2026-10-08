part of 'authentication_bloc.dart';

// States emitted by AuthenticationBloc; UI screens branch on these to
// decide whether to show login, a loader, or the authenticated app.
class AuthenticationState {}

class UnAuthorizedState extends AuthenticationState {}

class SigninInProgressState extends AuthenticationState {
  /// Which provider the sign-in is running for, so a screen offering several
  /// login methods can show a loader only on the one that was tapped.
  final AuthenticationType provider;
  SigninInProgressState(this.provider);
}

class GuestLoginInProgressState extends AuthenticationState {}

class AuthenticatedState extends AuthenticationState {
  final UserModel user;
  AuthenticatedState(this.user);
}

class AuthenticationFailedState<T> extends AuthenticationState {
  final T error;
  AuthenticationFailedState(this.error);
}

class AuthenticatedAsGuestState extends AuthenticationState {
  final UserModel user;
  AuthenticatedAsGuestState(this.user);
}

abstract class SendForgotPasswordEmailState extends AuthenticationState {}

class SendForgotPasswordEmailInProgressState
    extends SendForgotPasswordEmailState {}

class SendForgotPasswordEmailFailState extends SendForgotPasswordEmailState {
  final String error;
  SendForgotPasswordEmailFailState(this.error);
}

class SendForgotPasswordEmailSuccessState
    extends SendForgotPasswordEmailState {}
