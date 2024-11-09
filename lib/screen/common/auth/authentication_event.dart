part of 'authentication_bloc.dart';

// Abstract class representing the events in the authentication process
abstract class AuthenticationEvent {}

// Event to login with email and password
class LoginWithEmailAndPasswordEvent extends AuthenticationEvent {
  String email; // User's email
  String password; // User's password

  LoginWithEmailAndPasswordEvent({required this.email, required this.password}); // Constructor to initialize email and password
}

// Event to login with Facebook
class LoginWithFacebookEvent extends AuthenticationEvent {}

// Event to login with Apple
class LoginWithAppleEvent extends AuthenticationEvent {}

// Event to login with phone number
class LoginWithPhoneNumberEvent extends AuthenticationEvent {
  auth.PhoneAuthCredential credential; // Phone authentication credential
  String phoneNumber; // User's phone number
  String? name, lastName; // Optional user's name and last name
  Uint8List? imageData; // Optional user's profile image data

  LoginWithPhoneNumberEvent({
    required this.credential,
    required this.phoneNumber,
    this.name,
    this.lastName,
    this.imageData,
  }); // Constructor to initialize required and optional fields
}

// Event to sign up with email and password
class SignupWithEmailAndPasswordEvent extends AuthenticationEvent {
  String emailAddress; // User's email address
  String password; // User's password
  Uint8List? imageData; // Optional user's profile image data
  String? name; // Optional user's name
  String? lastName; // Optional user's last name

  SignupWithEmailAndPasswordEvent({
    required this.emailAddress,
    required this.password,
    this.imageData,
    this.name = 'Anonymous',
    this.lastName = 'User'
  }); // Constructor to initialize required and optional fields with default values for name and last name
}

// Event to logout
class LogoutEvent extends AuthenticationEvent {
  LogoutEvent(); // Constructor
}

// Event to mark onboarding as finished
class FinishedOnBoardingEvent extends AuthenticationEvent {}

// Event to check if it's the first run of the app
class CheckFirstRunEvent extends AuthenticationEvent {}
