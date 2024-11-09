import 'package:flutter/widgets.dart';
import 'package:poochpaw/screen/screen.dart';
import 'package:poochpaw/screen/common/auth/launcherScreen/launcher_screen.dart';
import 'package:poochpaw/screen/common/auth/login/login_screen.dart';

final Map<String, WidgetBuilder> routes = {
  LoginScreen.routeName: (context) => const LoginScreen(),
  SplashScreen.routeName: (context) => const SplashScreen(),
  ProfileScreen.routeName: (context) => ProfileScreen(),
  LauncherScreen.routeName: (context) => LauncherScreen(),
};

