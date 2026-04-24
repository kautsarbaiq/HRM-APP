import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/role_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ESSApp());
}

class ESSApp extends StatelessWidget {
  const ESSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: MaterialApp(
        title: 'ESS Malaysia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFF1E293B),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF06B6D4),
            secondary: Color(0xFF8B5CF6),
            surface: Color(0xFFFFFFFF),
            onSurface: Colors.white,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const ShellScreen(),
        },
      ),
    );
  }
}
