import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/photo_provider.dart';
import 'presentation/providers/album_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env 파일 로드 성공');
  } catch (e) {
    print('⚠️ .env 파일 로드 실패: $e');
  }

  // API Check
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  
  // Mock 모드 확인
  final useMockData = dotenv.env['USE_MOCK_DATA'] == 'true';

  if (!useMockData) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase 초기화 성공');
    } catch (e) {
      print('❌ Firebase 초기화 실패: $e');
    }
  }

  // Initialize Notification Service (MUST be after Firebase.initializeApp)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // ServiceLocator 초기화
  ServiceLocator.init(useMock: useMockData);
  
  runApp(const KimchiJjimApp());
}

class KimchiJjimApp extends StatelessWidget {
  const KimchiJjimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
            ],
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black, // App Name visible
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              ),
            ),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFFF5F5F5), // Light Grey Surface
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black.withOpacity(0.8),
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Colors.black, // Primary Action Color
            onPrimary: Colors.white,
            secondary: Color(0xFFF5F5F5),
            onSecondary: Colors.black,
            surface: Color(0xFFF5F5F5),
            onSurface: Colors.black,
            background: Colors.white,
            onBackground: Colors.black,
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // High contrast button
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              ),
            ),
          ),
          cardTheme: CardTheme(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              borderSide: const BorderSide(color: Colors.white),
            ),
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixIconColor: AppColors.textSecondary,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white.withOpacity(0.8),
            contentTextStyle: const TextStyle(color: Colors.black),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white, // White as primary accent in dark mode
            onPrimary: Colors.black,
            secondary: AppColors.surfaceVariant,
            onSecondary: Colors.white,
            surface: AppColors.surface,
            onSurface: Colors.white,
            background: AppColors.background,
            onBackground: Colors.white,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.textPrimary),
            bodyMedium: TextStyle(color: AppColors.textPrimary),
            titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        home: const SplashScreen(),
          );
        },
      ),
    );
  }
}