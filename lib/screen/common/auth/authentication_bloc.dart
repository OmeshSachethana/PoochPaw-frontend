import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/models/user.dart';
import 'package:poochpaw/core/services/authenticate.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'authentication_event.dart'; // Import the event definitions
part 'authentication_state.dart'; // Import the state definitions

// AuthenticationBloc manages authentication state and events
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  User? user; // Current authenticated user
  late SharedPreferences prefs; // SharedPreferences instance for local storage
  late bool finishedOnBoarding; // Flag to check if onboarding is completed

  // Constructor initializes the BLoC with an optional user
  AuthenticationBloc({this.user})
      : super(const AuthenticationState.unauthenticated()) {
    // Initial state is unauthenticated
    // Handle CheckFirstRunEvent to determine the initial state based on onboarding
    on<CheckFirstRunEvent>((event, emit) async {
      // Get the SharedPreferences instance
      prefs = await SharedPreferences.getInstance();
      // Check if onboarding is completed
      finishedOnBoarding = prefs.getBool(finishedOnBoardingConst) ?? false;
      if (!finishedOnBoarding) {
        // If onboarding is not finished, emit onboarding state
        emit(const AuthenticationState.onboarding());
      } else {
        // If onboarding is finished, fetch the current authenticated user
        user = await FireStoreUtils.getAuthUser();
        if (user == null) {
          // If no user is found, emit unauthenticated state
          emit(const AuthenticationState.unauthenticated());
        } else {
          // Check if the user is a vet or client and emit the corresponding state
          bool isVet =
              checkIfUserIsVet(user!); // Replace with your actual logic
          if (isVet) {
            emit(const AuthenticationState.vet());
          } else {
            emit(const AuthenticationState.client());
          }
        }
      }
    });

    // Handle FinishedOnBoardingEvent to mark onboarding as completed
    on<FinishedOnBoardingEvent>((event, emit) async {
      await prefs.setBool(
          finishedOnBoardingConst, true); // Set onboarding completed flag
      emit(const AuthenticationState
          .unauthenticated()); // Emit unauthenticated state
    });

    // Handle LoginWithEmailAndPasswordEvent for email/password login
    on<LoginWithEmailAndPasswordEvent>((event, emit) async {
      dynamic result = await FireStoreUtils.loginWithEmailAndPassword(
          event.email, event.password); // Attempt to log in
      if (result != null && result is User) {
        // If login is successful, emit authenticated state with user
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        // If login fails with a message, emit unauthenticated state with the error message
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        // If login fails without a message, emit a generic unauthenticated state
        emit(const AuthenticationState.unauthenticated(
            message: 'Login failed, Please try again.'));
      }
    });

    // Handle LoginWithAppleEvent for Apple login
    on<LoginWithAppleEvent>((event, emit) async {
      dynamic result =
          await FireStoreUtils.loginWithApple(); // Attempt to log in with Apple
      if (result != null && result is User) {
        // If login is successful, emit authenticated state with user
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        // If login fails with a message, emit unauthenticated state with the error message
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        // If login fails without a message, emit a generic unauthenticated state
        emit(const AuthenticationState.unauthenticated(
            message: 'Apple login failed, Please try again.'));
      }
    });

    // Handle SignupWithEmailAndPasswordEvent for email/password signup
    on<SignupWithEmailAndPasswordEvent>((event, emit) async {
      dynamic result = await FireStoreUtils.signUpWithEmailAndPassword(
          emailAddress: event.emailAddress,
          password: event.password,
          imageData: event.imageData,
          name: event.name,
          lastName: event.lastName); // Attempt to sign up
      if (result != null && result is User) {
        // If signup is successful, emit authenticated state with user
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        // If signup fails with a message, emit unauthenticated state with the error message
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        // If signup fails without a message, emit a generic unauthenticated state
        emit(const AuthenticationState.unauthenticated(
            message: 'Couldn\'t sign up'));
      }
    });

    // Handle LogoutEvent to log out the user
    on<LogoutEvent>((event, emit) async {
      await FireStoreUtils.logout(); // Perform logout
      user = null; // Clear the current user
      emit(const AuthenticationState
          .unauthenticated()); // Emit unauthenticated state
    });
  }

  // Function to determine if the user is a vet based on their role
  bool checkIfUserIsVet(User user) {
    // Replace this with your actual logic to determine if the user is a vet
    return user.role == 'Vet';
  }
}
