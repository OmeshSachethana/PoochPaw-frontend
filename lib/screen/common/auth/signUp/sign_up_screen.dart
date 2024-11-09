import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/common/nav/nav.dart';
import 'package:poochpaw/core/services/helper.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/auth/login/login_screen.dart';
import 'package:poochpaw/screen/common/auth/signUp/sign_up_bloc.dart';
import 'package:poochpaw/screen/common/loading_cubit.dart';
import 'package:poochpaw/core/utils/next_screen.dart';
import 'package:poochpaw/screen/common/role/role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  Uint8List? _imageData; // Variable to hold image data
  final TextEditingController _passwordController =
      TextEditingController(); // Controller for password input
  final GlobalKey<FormState> _key = GlobalKey(); // Form key for validation
  String? name,
      lastName,
      email,
      password,
      confirmPassword; // Variables for form input
  AutovalidateMode _validate =
      AutovalidateMode.disabled; // Initial autovalidate mode
  bool acceptEULA = false; // EULA acceptance status

  Future<void> saveDataToSharedPreferences(
      Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userData.forEach((key, value) {
        if (value is String) {
          prefs.setString(key, value);
        } else if (value is int) {
          prefs.setInt(key, value);
        } else if (value is bool) {
          prefs.setBool(key, value);
        } else if (value is double) {
          prefs.setDouble(key, value);
        } else if (value is List<String>) {
          prefs.setStringList(key, value);
        }
      });
    } catch (e) {
      print("Error saving data to SharedPreferences: $e");
      showSnackBar(context, 'Failed to save user data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (context) => SignUpBloc(), // Create a SignUpBloc
      child: Builder(
        builder: (context) {
          if (!kIsWeb && Platform.isAndroid) {
            context.read<SignUpBloc>().add(
                RetrieveLostDataEvent()); // Retrieve lost data if on Android
          }
          return MultiBlocListener(
            listeners: [
              BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) async {
                  context.read<LoadingCubit>().hideLoading();

                  if (state.authState == AuthState.authenticated) {
                    // Fetch the user role from Firestore
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get();

                      if (userDoc.exists && userDoc.data() != null) {
                        final userData = userDoc.data();
                        final userRole = userData?['role'];

                        if (userRole == null || userRole.isEmpty) {
                          // Navigate to the role selection page
                          pushAndRemoveUntil(
                              context, ProfileCompleteScreen(), false);
                        } else {
                          // Navigate to the main navigation page
                          // Save user data in shared preferences
                          saveDataToSharedPreferences(
                              userData as Map<String, dynamic>);
                          pushAndRemoveUntil(context, Nav(), false);
                        }
                      } else {
                        showSnackBar(context, 'User data not found.');
                      }
                    } else {
                      showSnackBar(context, 'User ID not found.');
                    }
                  } else {
                    showSnackBar(
                        context,
                        state.message ??
                            'Couldn\'t sign up, Please try again.');
                  }
                },
              ),
              BlocListener<SignUpBloc, SignUpState>(
                listener: (context, state) async {
                  if (state is ValidFields) {
                    await context.read<LoadingCubit>().showLoading(
                        context, 'Creating new account, Please wait...', false);
                    if (!mounted) return;
                    context.read<AuthenticationBloc>().add(
                        SignupWithEmailAndPasswordEvent(
                            emailAddress: email!,
                            password: password!,
                            imageData: _imageData,
                            lastName: lastName,
                            name: name));
                  } else if (state is SignUpFailureState) {
                    showSnackBar(context, state.errorMessage);
                  }
                },
              ),
            ],
            child: Scaffold(
              appBar: CustomAppBar(
                title: 'Create new account',
                leadingImage: 'assets/icons/Back.png',
                actionImage: null,
                onLeadingPressed: () {
                  nextScreenReplace(context, const LoginScreen());
                },
                onActionPressed: () {
                  print("Action icon pressed");
                },
              ),
              extendBodyBehindAppBar: true,
              body: Stack(
                children: [
                  BackgroundWithBlur(
                    child: SizedBox
                        .expand(), // Makes the blur cover the entire screen
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 90.0,
                      bottom: 50.0,
                    ),
                    child: BlocBuilder<SignUpBloc, SignUpState>(
                      buildWhen: (old, current) =>
                          current is SignUpFailureState && old != current,
                      builder: (context, state) {
                        if (state is SignUpFailureState) {
                          _validate = AutovalidateMode.onUserInteraction;
                        }
                        return Form(
                          key: _key,
                          autovalidateMode: _validate,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, top: 32, right: 8, bottom: 8),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    BlocBuilder<SignUpBloc, SignUpState>(
                                      buildWhen: (old, current) =>
                                          current is PictureSelectedState &&
                                          old != current,
                                      builder: (context, state) {
                                        if (state is PictureSelectedState) {
                                          _imageData = state.imageData;
                                        }
                                        return state is PictureSelectedState
                                            ? SizedBox(
                                                height: 130,
                                                width: 130,
                                                child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            65),
                                                    child: state.imageData ==
                                                            null
                                                        ? Image.asset(
                                                            'assets/images/placeholder.png',
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.memory(
                                                            state.imageData!,
                                                            fit: BoxFit.cover,
                                                          )),
                                              )
                                            : SizedBox(
                                                height: 130,
                                                width: 130,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(65),
                                                  child: Image.asset(
                                                    'assets/images/placeholder.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                      },
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: FloatingActionButton(
                                        backgroundColor:
                                            const Color(colorPrimary),
                                        mini: true,
                                        onPressed: () =>
                                            _onCameraClick(context),
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: isDarkMode(context)
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  textCapitalization: TextCapitalization.words,
                                  validator: validateName,
                                  onSaved: (String? val) {
                                    name = val;
                                  },
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.white),
                                  decoration: getInputDecoration(
                                      hint: 'First Name',
                                      darkMode: isDarkMode(context),
                                      errorColor: Theme.of(context).errorColor),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  textCapitalization: TextCapitalization.words,
                                  validator: validateName,
                                  onSaved: (String? val) {
                                    lastName = val;
                                  },
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.white),
                                  decoration: getInputDecoration(
                                      hint: 'Last Name',
                                      darkMode: isDarkMode(context),
                                      errorColor: Theme.of(context).errorColor),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.white),
                                  validator: validateEmail,
                                  onSaved: (String? val) {
                                    email = val;
                                  },
                                  decoration: getInputDecoration(
                                      hint: 'Email',
                                      darkMode: isDarkMode(context),
                                      errorColor: Theme.of(context).errorColor),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.white),
                                  controller: _passwordController,
                                  validator: validatePassword,
                                  onSaved: (String? val) {
                                    password = val;
                                  },
                                  cursorColor: const Color(colorPrimary),
                                  decoration: getInputDecoration(
                                      hint: 'Password',
                                      darkMode: isDarkMode(context),
                                      errorColor: Theme.of(context).errorColor),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) =>
                                      context.read<SignUpBloc>().add(
                                            ValidateFieldsEvent(_key,
                                                acceptEula: acceptEULA),
                                          ),
                                  obscureText: true,
                                  validator: (val) => validateConfirmPassword(
                                      _passwordController.text, val),
                                  onSaved: (String? val) {
                                    confirmPassword = val;
                                  },
                                  style: const TextStyle(
                                      height: 0.8,
                                      fontSize: 18.0,
                                      color: Colors.white),
                                  cursorColor: const Color(colorPrimary),
                                  decoration: getInputDecoration(
                                      hint: 'Confirm Password',
                                      darkMode: isDarkMode(context),
                                      errorColor: Theme.of(context).errorColor),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ListTile(
                                trailing: BlocBuilder<SignUpBloc, SignUpState>(
                                  buildWhen: (old, current) =>
                                      current is EulaToggleState &&
                                      old != current,
                                  builder: (context, state) {
                                    if (state is EulaToggleState) {
                                      acceptEULA = state.eulaAccepted;
                                    }
                                    return Checkbox(
                                      onChanged: (value) =>
                                          context.read<SignUpBloc>().add(
                                                ToggleEulaCheckboxEvent(
                                                  eulaAccepted: value!,
                                                ),
                                              ),
                                      activeColor: const Color(colorPrimary),
                                      value: acceptEULA,
                                    );
                                  },
                                ),
                                title: RichText(
                                  textAlign: TextAlign.left,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'By creating an account you agree to our ',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7)),
                                      ),
                                      TextSpan(
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        text: 'Terms of Use',
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            if (await canLaunchUrl(
                                                Uri.parse(eula))) {
                                              await launchUrl(
                                                Uri.parse(eula),
                                              );
                                            }
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
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
                                          Icons.person,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 20),
                                        Text("Sign Up",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    onPressed: () =>
                                        context.read<SignUpBloc>().add(
                                              ValidateFieldsEvent(_key,
                                                  acceptEula: acceptEULA),
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to handle camera click action
  _onCameraClick(BuildContext context) {
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      context.read<SignUpBloc>().add(
          ChooseImageFromGalleryEvent()); // Choose image from gallery on supported platforms
    } else {
      final action = CupertinoActionSheet(
        title: const Text(
          'Add Profile Picture',
          style: TextStyle(fontSize: 15.0),
        ),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: false,
            onPressed: () async {
              Navigator.pop(context);
              context.read<SignUpBloc>().add(
                  ChooseImageFromGalleryEvent()); // Choose image from gallery
            },
            child: const Text('Choose from gallery'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () async {
              Navigator.pop(context);
              context.read<SignUpBloc>().add(
                  CaptureImageByCameraEvent()); // Capture image using camera
            },
            child: const Text('Take a picture'),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context)), // Cancel action
      );
      showCupertinoModalPopup(
          context: context, builder: (context) => action); // Show action sheet
    }
  }

  @override
  void dispose() {
    _passwordController.dispose(); // Dispose password controller
    _imageData = null; // Clear image data
    super.dispose();
  }
}
