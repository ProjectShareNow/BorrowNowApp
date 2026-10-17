import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app_config.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'services/service_registry.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/request_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/admin_provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with configured DefaultFirebaseOptions
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.isFirebaseInitialized = true;
    AppConfig.log(
      'Firebase successfully initialized with project borrownow-585b5!',
    );
  } catch (e) {
    AppConfig.isFirebaseInitialized = false;
    AppConfig.log('Firebase initialization fallback: $e');
  }

  // Initialize all application services
  await ServiceRegistry.init();

  runApp(const BorrowNowApp());
}

class BorrowNowApp extends StatelessWidget {
  const BorrowNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.lightTheme(),
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
