import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:poochpaw/core/services/internet_provider.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/auth/signUp/sign_up_bloc.dart';
import 'package:poochpaw/screen/common/auth/splash/splash_screen.dart';
import 'package:poochpaw/screen/common/loading_cubit.dart';

import 'shared/routes/routes.dart';

late final FlutterLocalNotificationsPlugin _notificationsPlugin;

// Handles background messages when the app is not in the foreground
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  // Print message ID to console for debugging
  print('Handling a background message: ${message.messageId}');
}

// Main entry point for the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: 'lib/config/.env');

  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Clear Firestore local persistence to avoid issues with old data
  await FirebaseFirestore.instance.clearPersistence();

  // Initialize local notifications settings for Android
  var initializationSettingsAndroid =
      AndroidInitializationSettings('drawable/logo');
  var initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  _notificationsPlugin = FlutterLocalNotificationsPlugin();
  await _notificationsPlugin.initialize(initializationSettings);

  // Set up Firestore listeners if a user is already signed in
  if (FirebaseAuth.instance.currentUser != null) {
    _setupFirestoreListener();
    _setupFirestoreListenerForMissingDogs();
  }

  // Listen for authentication state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      _setupFirestoreListener();
      _setupFirestoreListenerForMissingDogs();
    }
  });

  // Run the app with the initial locale set to English
  runApp(MyApp(initialLocale: Locale('en')));
}

// Sets up Firestore listener for stray dog matches
void _setupFirestoreListener() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String uid = user.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('strayDogMatches')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // Print new stray dog match data
          print("New stray dog match added: ${change.doc.data()}");
          // Check user notification preferences and show notification if needed
          _checkNotificationPreferenceAndNotify(
              change.doc.data() as Map<String, dynamic>);
        }
      }
    });
  } else {
    print("No user is currently signed in.");
  }
}

// Checks user preferences and shows notification for new stray dog matches
Future<void> _checkNotificationPreferenceAndNotify(
    Map<String, dynamic> dogData) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String uid = user.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Show notification if user has enabled push notifications
    if (userDoc.exists && userDoc['receivePushNotifications'] == true) {
      _showNotification("New Stray Dog Matched.",
          "A new stray dog named ${dogData['name']} has been added.");
    }
  }
}

// Sets up Firestore listener for missing dogs
void _setupFirestoreListenerForMissingDogs() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String uid = user.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('strayDogs')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // Print new stray dog data
          print("New stray dog added: ${change.doc.data()}");
          // Check user notification preferences and show notification if needed
          _checkNotificationPreferenceAndNotifyMissingDogs(
              change.doc.data() as Map<String, dynamic>);
        }
      }
    });
  } else {
    print("No user is currently signed in.");
  }
}

// Checks user preferences and shows notification for missing dogs
Future<void> _checkNotificationPreferenceAndNotifyMissingDogs(
    Map<String, dynamic> dogData) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String uid = user.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Show notification if user has enabled notifications for missing dogs
    if (userDoc.exists && userDoc['receiveMissingDogNotifications'] == true) {
      _showNotification("New Stray Dog Added",
          "A new stray dog named ${dogData['name']} has been added.");
    }
  }
}

// Shows a notification with the given title and subtitle
Future<void> _showNotification(String title, String subtitle) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', 'your_channel_name',
      importance: Importance.max, priority: Priority.high, showWhen: false);
  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await _notificationsPlugin.show(0, title, subtitle, platformChannelSpecifics);
}

// Main app widget
class MyApp extends StatefulWidget {
  final Locale initialLocale; // Initial locale for the app

  const MyApp({Key? key, required this.initialLocale}) : super(key: key);

  @override
  MyAppState createState() => MyAppState(); // Creates the state for MyApp
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _error = false; // Flag to check if there is an error
  late Locale _locale; // Variable to store the locale

  @override
  void initState() {
    super.initState();
    _locale =
        widget.initialLocale; // Initializes the locale with the initial locale
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      // Display an error message if there was an initialization error
      return MaterialApp(
          theme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: Scaffold(
              body: Center(child: Text('Failed to initialise firebase!'))));
    }

    // Set up the app with various providers and Bloc pattern
    return BlocProvider<AuthenticationBloc>(
      create: (_) => AuthenticationBloc(), // Provides the AuthenticationBloc
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => SignInProvider()), // Provides the SignInProvider
          ChangeNotifierProvider(
              create: (_) =>
                  InternetProvider()), // Provides the InternetProvider
          BlocProvider<LoadingCubit>(
            create: (context) => LoadingCubit(), // Provides the LoadingCubit
          ),
          BlocProvider<SignUpBloc>(
            create: (context) => SignUpBloc(), // Provides the SignUpBloc
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(
              375, 812), // Initializes ScreenUtil with the design size
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false, // Hides the debug banner
            locale: _locale, // Sets the locale for the app
            initialRoute: SplashScreen
                .routeName, // Sets the initial route to SplashScreen
            routes: routes, // Sets the routes for the app
          ),
        ),
      ),
    );
  }
}
