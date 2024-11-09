import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/internet_provider.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/common/nav/nav.dart';
import 'package:poochpaw/core/services/helper.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/auth/login/login_bloc.dart';
import 'package:poochpaw/screen/common/auth/resetPasswordScreen/reset_password_screen.dart';
import 'package:poochpaw/screen/common/auth/signUp/sign_up_screen.dart';
import 'package:poochpaw/screen/common/loading_cubit.dart';
import 'package:poochpaw/core/utils/next_screen.dart';
import 'package:poochpaw/core/utils/snack_bar.dart';
import 'package:poochpaw/screen/function_1/vet/vet.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final DateTime? selectedTime;
  const LoginScreen({Key? key, this.selectedTime}) : super(key: key);
  static String routeName = '/LoginScreen';

  @override
  State createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {
  final GlobalKey<FormState> _key = GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  String? email, password;

  // Define global keys for the scaffold and button controllers
  final RoundedLoadingButtonController googleController =
      RoundedLoadingButtonController();

  @override
  Widget build(BuildContext context) {
    final sp = context.read<SignInProvider>();
    return BlocProvider<LoginBloc>(
      create: (context) => LoginBloc(),
      child: Builder(builder: (context) {
        return Scaffold(
          body: MultiBlocListener(
            listeners: [
              // Listener for AuthenticationBloc state changes
              BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) async {
                  await context.read<LoadingCubit>().hideLoading();
                  if (state.authState == AuthState.authenticated) {
                    if (!mounted) return;

                    // Navigate based on user role
                    if (state.user != null) {
                      final role = state
                          .user!.role; // Assuming `role` is a field in `User`

                      if (role == 'Vet') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VetScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Nav()),
                        );
                      }
                    }
                  } else {
                    if (!mounted) return;
                    showSnackBar(context,
                        state.message ?? 'Couldn\'t login, Please try again.');
                  }
                },
              ),
              // Listener for LoginBloc state changes
              BlocListener<LoginBloc, LoginState>(
                listener: (context, state) async {
                  if (state is ValidLoginFields) {
                    await context.read<LoadingCubit>().showLoading(
                        context, 'Logging in, Please wait...', false);
                    if (!mounted) return;
                    context.read<AuthenticationBloc>().add(
                          LoginWithEmailAndPasswordEvent(
                            email: email!,
                            password: password!,
                          ),
                        );

                    // Save email and password to shared preferences
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setString('email', email!);
                    prefs.setString('password', password!);
                  }
                },
              ),
            ],
            child: BlocBuilder<LoginBloc, LoginState>(
              buildWhen: (old, current) =>
                  current is LoginFailureState && old != current,
              builder: (context, state) {
                if (state is LoginFailureState) {
                  _validate = AutovalidateMode.onUserInteraction;
                }
                return Stack(
                  children: [
                    BackgroundWithBlur(
                      child: SizedBox
                          .expand(), // Makes the blur cover the entire screen
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Form(
                        key: _key,
                        autovalidateMode: _validate,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/logo.png',
                                width: 100.0,
                                height: 100.0,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Welcome to PoochPaw!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Empower Canine Care, One Paw at a Time!',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.5)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextFormField(
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.next,
                                    validator: validateEmail,
                                    onSaved: (String? val) {
                                      email = val;
                                    },
                                    style: TextStyle(
                                        fontSize: 15.0, color: Colors.white),
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: Colors.white,
                                    decoration: getInputDecoration(
                                        hint: 'Email Address',
                                        darkMode: isDarkMode(context),
                                        errorColor:
                                            Theme.of(context).errorColor)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextFormField(
                                    textAlignVertical: TextAlignVertical.center,
                                    obscureText: true,
                                    validator: validatePassword,
                                    onSaved: (String? val) {
                                      password = val;
                                    },
                                    onFieldSubmitted: (password) => context
                                        .read<LoginBloc>()
                                        .add(ValidateLoginFieldsEvent(_key)),
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(fontSize: 15.0),
                                    cursorColor: const Color(colorPrimary),
                                    decoration: getInputDecoration(
                                        hint: 'Password',
                                        darkMode: isDarkMode(context),
                                        errorColor:
                                            Theme.of(context).errorColor)),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Container(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      primary: Colors.white.withOpacity(0.3),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: const Wrap(
                                      children: [
                                        Icon(
                                          Icons.login,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        Text("Login",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    onPressed: () => context
                                        .read<LoginBloc>()
                                        .add(ValidateLoginFieldsEvent(_key)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(
                                    20.0), // Adjust the padding value as needed
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey, // Set divider color
                                        thickness:
                                            1, // Set thickness of the divider
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              10), // Horizontal padding around the text
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.grey, // Set text color
                                          fontWeight: FontWeight
                                              .bold, // Set font weight
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey, // Set divider color
                                        thickness:
                                            1, // Set thickness of the divider
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google Sign In Button
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: RoundedLoadingButton(
                                      onPressed: () {
                                        handleGoogleSignIn();
                                      },
                                      controller: googleController,
                                      successColor: const Color(colorPrimary),
                                      width: double.infinity,
                                      elevation: 0,
                                      borderRadius: 25,
                                      color: Colors.white.withOpacity(0.3),
                                      child: const Wrap(
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.google,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: 15,
                                          ),
                                          Text("Continue with Google",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          primary:
                                              Colors.white.withOpacity(0.3),
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: const Wrap(
                                          children: [
                                            Icon(
                                              Icons.email,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 20),
                                            Text("Continue with email",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        ),
                                        onPressed: () {
                                          nextScreenReplace(
                                              context, const SignUpScreen());
                                        }),
                                  ),
                                ),
                              ),
                              FutureBuilder<bool>(
                                future: apple.TheAppleSignIn.isAvailable(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator
                                        .adaptive();
                                  }
                                  if (!snapshot.hasData ||
                                      (snapshot.data != true)) {
                                    return Container();
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 40.0, left: 40.0, bottom: 20),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.5),
                                        child: apple.AppleSignInButton(
                                            cornerRadius: 25.0,
                                            type: apple.ButtonType.signIn,
                                            style: isDarkMode(context)
                                                ? apple.ButtonStyle.white
                                                : apple.ButtonStyle.black,
                                            onPressed: () async {
                                              await context
                                                  .read<LoadingCubit>()
                                                  .showLoading(
                                                      context,
                                                      'Logging in, Please wait...',
                                                      false);
                                              if (!mounted) return;
                                              context
                                                  .read<AuthenticationBloc>()
                                                  .add(LoginWithAppleEvent());
                                            }),
                                      ),
                                    );
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(
                                    16.0), // Adjust the padding value as needed
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey, // Set divider color
                                        thickness:
                                            1, // Set thickness of the divider
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              10), // Horizontal padding around the text
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.grey, // Set text color
                                          fontWeight: FontWeight
                                              .bold, // Set font weight
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey, // Set divider color
                                        thickness:
                                            1, // Set thickness of the divider
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: 720, minWidth: 200),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 16, right: 24),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () => push(
                                          context, const ResetPasswordScreen()),
                                      child: const Wrap(
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.search,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: 15,
                                          ),
                                          Text("Find my account",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(
                                    20.0), // Adjust the padding value as needed
                                child: Text(
                                  'No worries! Just head to the Find my account Screen, enter your email, and follow the instructions we\'ll send to you. It\'s quick and easy, ensuring you can regain access to your account in no time!',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.5)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }

  // Function to handle Google Sign In
  Future handleGoogleSignIn() async {
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();

    if (ip.hasInternet == false) {
      openSnackbar(context, "Check your Internet connection", Colors.red);
      googleController.reset();
    } else {
      await sp.signInWithGoogle().then((value) {
        if (sp.hasError == true) {
          openSnackbar(context, sp.errorCode.toString(), Colors.red);
          googleController.reset();
        } else {
          // checking whether user exists or not
          sp.checkUserExists().then((value) async {
            if (value == true) {
              // user exists
              await sp.getUserDataFromFirestore(sp.uid).then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value) {
                        googleController.success();
                        handleAfterSignIn();
                      })));
            } else {
              final DateTime selectedTime = widget.selectedTime ??
                  DateTime(2000, 1,
                      1); // Use a default value if widget.selectedTime is null
              sp.saveDataToFirestore(selectedTime).then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value) {
                        googleController.success();
                        handleAfterSignIn();
                      })));
            }
          });
        }
      });
    }
  }

  // Function to handle actions after successful sign in
  handleAfterSignIn() {
    Future.delayed(const Duration(milliseconds: 1000)).then((value) {
      nextScreenReplace(context, const Nav());
    });
  }
}
