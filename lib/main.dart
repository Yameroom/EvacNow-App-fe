import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/user_home_page.dart';
import 'screens/evacuation_page.dart' as evac;
import 'screens/help_request_page.dart'; // Import halaman HelpRequestPage
import 'admin/admin_page_screen.dart';
import 'admin/help_request.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? username = prefs.getString('username');

  runApp(MyApp(initialRoute: username == null ? '/login' : '/user_home'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EvacNow',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/user_home': (context) => const EvacNowHomePage(),
        '/admin_home': (context) => const AdminPageScreen(),
        '/evacuation': (context) => const evac.EvacuationPage(),
        '/help_request': (context) => const HelpRequestPage(),
        '/admin_updates':(context) => const  HelpRequest(),// Tambahkan rute HelpRequestPage
      },
    );
  }
}