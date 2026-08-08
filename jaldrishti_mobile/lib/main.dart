import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/farm_plot_provider.dart';
import 'providers/irrigation_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'core/constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConstants.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FarmPlotProvider()),
        ChangeNotifierProvider(create: (_) => IrrigationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const JalDrishtiApp(),
    ),
  );
}

class JalDrishtiApp extends StatelessWidget {
  const JalDrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'JalDrishti AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isCheckingAuth) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return const MainNavigationScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}