import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D1A),
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('api_key');

  runApp(ClassRecorderApp(savedApiKey: apiKey));
}

class ClassRecorderApp extends StatelessWidget {
  final String? savedApiKey;
  const ClassRecorderApp({super.key, this.savedApiKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassRecord AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4A4AFF),
          surface: const Color(0xFF0D0D1A),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      ),
      home: savedApiKey != null && savedApiKey!.isNotEmpty
          ? HomeScreen(apiKey: savedApiKey!)
          : const SetupScreen(),
    );
  }
}