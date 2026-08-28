import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'widgets/map_screen.dart';

/// Entry point of the Flutter application.
void main() async {
  // Ensures that the Flutter engine's widget binding is fully initialized
  // before running asynchronous initialization tasks (like Firebase).
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase services with platform-specific options (Android/iOS/Web).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initializes locale-specific date formatting data (French locale 'fr_FR')
  // used by the intl package for date display.
  await initializeDateFormatting('fr_FR', null);

  // Launches the root widget of the application.
  runApp(const TravelMapApp());
}

/// Root widget of the application configuring the global MaterialApp settings.
class TravelMapApp extends StatelessWidget {
  const TravelMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application title displayed in task switchers and web tabs
      title: 'Chatons Voyageurs',
      // Disables the debug banner in the top right corner
      debugShowCheckedModeBanner: false,
      // Defines global theme styling and Material 3 design system support
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Sets the initial screen to MapScreen
      home: const MapScreen(),
    );
  }
}