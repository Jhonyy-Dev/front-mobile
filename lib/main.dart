import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';  // Comentado para iOS
import 'package:flutter/foundation.dart';
import 'welcome_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization commented out for iOS compatibility
  // if (kIsWeb) {
  //   try {
  //     await Firebase.initializeApp(
  //       options: const FirebaseOptions(
  //         apiKey: "YOUR_API_KEY",
  //         authDomain: "YOUR_AUTH_DOMAIN",
  //         projectId: "YOUR_PROJECT_ID",
  //         storageBucket: "YOUR_STORAGE_BUCKET",
  //         messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  //         appId: "YOUR_APP_ID",
  //       ),
  //     );
  //   } catch (e) {
  //     print('Failed to initialize Firebase: $e');
  //     // Continue without Firebase for development
  //   }
  // } else {
  //   await Firebase.initializeApp();
  // }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: const Color(0xFF4A9B7F),
              scaffoldBackgroundColor: Colors.white,
              fontFamily: 'Poppins',
              brightness: themeProvider.darkModeEnabled ? Brightness.dark : Brightness.light,
            ),
            home: const WelcomeScreen(),
          );
        }
      ),
    );
  }
}