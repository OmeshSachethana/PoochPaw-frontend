part of 'authentication_bloc.dart';

enum AuthState { firstRun, authenticated, unauthenticated, vet, client }

class AuthenticationState {
  final AuthState authState;
  final User? user;
  final String? message;

  const AuthenticationState._(this.authState, {this.user, this.message});

  const AuthenticationState.authenticated(User user)
      : this._(AuthState.authenticated, user: user);

  const AuthenticationState.unauthenticated({String? message})
      : this._(AuthState.unauthenticated,
            message: message ?? 'Unauthenticated');

  const AuthenticationState.onboarding() : this._(AuthState.firstRun);

  const AuthenticationState.vet() : this._(AuthState.vet);

  const AuthenticationState.client() : this._(AuthState.client);
}
