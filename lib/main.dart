import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MpesaTrackerApp());
}

class MpesaTrackerApp extends StatelessWidget {
  const MpesaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Status bar icons need to flip with whichever theme actually
          // ends up on screen — including when themeProvider.mode is
          // "system", where the resolved brightness depends on the OS
          // setting rather than themeProvider itself.
          final platformBrightness =
              MediaQuery.platformBrightnessOf(context);
          final isDark = switch (themeProvider.mode) {
            ThemeMode.light => false,
            ThemeMode.dark => true,
            ThemeMode.system => platformBrightness == Brightness.dark,
          };

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ),
            child: MaterialApp(
              title: 'M-Pesa Tracker',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.mode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
