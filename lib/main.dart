import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:waterfinder/screens/home_screen.dart';
import 'package:waterfinder/screens/map_screen.dart';
import 'package:waterfinder/screens/add_source_screen.dart';
import 'package:waterfinder/screens/report_screen.dart';
import 'package:waterfinder/screens/login_screen.dart';
import 'package:waterfinder/screens/register_screen.dart';
import 'package:waterfinder/services/water_source_service.dart';
import 'package:waterfinder/services/notification_service.dart';
import 'package:waterfinder/services/location_service.dart';
import 'package:waterfinder/services/auth_service.dart';
import 'package:waterfinder/providers/water_source_provider.dart';
import 'package:waterfinder/widgets/error_boundary.dart';
import 'package:waterfinder/widgets/loading_indicator.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Create initial admin account
  final authService = AuthService();
  await authService.createInitialAdminAccount();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final locationService = LocationService();
  await locationService.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MultiProvider(
        providers: [
          Provider<WaterSourceService>(
            create: (_) => WaterSourceService(),
          ),
          Provider<NotificationService>(
            create: (_) => NotificationService(),
          ),
          Provider<LocationService>(
            create: (_) => LocationService(),
          ),
          Provider<AuthService>(
            create: (_) => AuthService(),
          ),
          Provider<FirebaseAnalytics>(
            create: (_) => FirebaseAnalytics.instance,
          ),
          ChangeNotifierProxyProvider<WaterSourceService, WaterSourceProvider>(
            create: (context) => WaterSourceProvider(
              context.read<WaterSourceService>(),
            ),
            update: (context, service, previous) => 
              previous ?? WaterSourceProvider(service),
          ),
        ],
        child: MaterialApp(
          title: 'WaterFinder',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
            fontFamily: 'Cairo',
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', ''),
            Locale('en', ''),
          ],
          locale: const Locale('ar', ''),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/map': (context) => const MapScreen(),
            '/add-source': (context) => const AddSourceScreen(),
            '/report': (context) => const ReportScreen(),
          },
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(
            message: 'جاري التحقق من حالة تسجيل الدخول...',
          );
        }

        if (snapshot.hasData) {
          return const ConnectivityWrapper();
        }

        return const LoginScreen();
      },
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  const ConnectivityWrapper({super.key});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
      connectivityBuilder: (
        BuildContext context,
        ConnectivityResult connectivity,
        Widget child,
      ) {
        final bool connected = connectivity != ConnectivityResult.none;
        if (!connected) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا يوجد اتصال بالإنترنت',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيتم عرض البيانات المحفوظة محلياً',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return child;
      },
      child: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const MapScreen(),
    const AddSourceScreen(),
    const ReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start location tracking when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService = context.read<LocationService>();
      final sourceProvider = context.read<WaterSourceProvider>();
      locationService.startTracking(sourceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'الخريطة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location),
            label: 'إضافة مصدر',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'بلاغ',
          ),
        ],
      ),
    );
  }
}
