import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/helper.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/resetPasswordScreen/reset_password_cubit.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/common/loading_cubit.dart';

// Stateful widget for the reset password screen
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _key = GlobalKey(); // Form key for validation
  AutovalidateMode _validate =
      AutovalidateMode.disabled; // Initial autovalidate mode
  String _emailAddress = ''; // Variable to hold email address

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordCubit>(
      create: (context) => ResetPasswordCubit(), // Create a ResetPasswordCubit
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'Create new account',
              leadingImage: 'assets/icons/Back.png',
              onLeadingPressed: () {
                Navigator.of(context).pop();
              },
              actionImage: null,
              onActionPressed: () {
                print("Action icon pressed");
              },
            ),
            extendBodyBehindAppBar: true,
            body: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
              listenWhen: (old, current) =>
                  old != current, // Listen for state changes
              listener: (context, state) async {
                if (state is ResetPasswordDone) {
                  context
                      .read<LoadingCubit>()
                      .hideLoading(); // Hide loading indicator
                  showSnackBar(context,
                      'Reset password email has been sent, Please check your email.'); // Show success message
                  Navigator.pop(context); // Navigate back
                } else if (state is ValidResetPasswordField) {
                  await context.read<LoadingCubit>().showLoading(context,
                      'Sending Email...', false); // Show loading indicator
                  if (!mounted) return;
                  context
                      .read<ResetPasswordCubit>()
                      .resetPassword(_emailAddress); // Trigger password reset
                } else if (state is ResetPasswordFailureState) {
                  showSnackBar(
                      context, state.errorMessage); // Show error message
                }
              },
              buildWhen: (old, current) =>
                  current is ResetPasswordFailureState &&
                  old != current, // Rebuild only on failure state
              builder: (context, state) {
                if (state is ResetPasswordFailureState) {
                  _validate = AutovalidateMode
                      .onUserInteraction; // Enable autovalidation on user interaction
                }
                return Stack(
                  children: [
                    BackgroundWithBlur(
                      child: SizedBox
                          .expand(), // Makes the blur cover the entire screen
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 24.0, right: 24.0, top: 90.0, bottom: 50.0),
                      child: Form(
                        autovalidateMode: _validate,
                        key: _key,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(
                                    top: 32.0, right: 16.0, left: 16.0),
                                child: Text(
                                  'Reset Password',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 32.0, right: 24.0, left: 24.0),
                                child: TextFormField(
                                  textAlignVertical: TextAlignVertical.center,
                                  textInputAction: TextInputAction.done,
                                  validator:
                                      validateEmail, // Email validation function
                                  onFieldSubmitted: (_) => context
                                      .read<ResetPasswordCubit>()
                                      .checkValidField(
                                          _key), // Check if field is valid
                                  onSaved: (val) => _emailAddress =
                                      val!, // Save email address
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: const Color(colorPrimary),
                                  decoration: getInputDecoration(
                                      hint: 'E-mail',
                                      darkMode: isDarkMode(context),
                                      errorColor: Theme.of(context)
                                          .errorColor), // Input decoration
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 40.0, left: 40.0, top: 40),
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
                                  child: const Text(
                                    'Send Email',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () => context
                                      .read<ResetPasswordCubit>()
                                      .checkValidField(
                                          _key), // Trigger field validation
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
          );
        },
      ),
    );
  }
}
