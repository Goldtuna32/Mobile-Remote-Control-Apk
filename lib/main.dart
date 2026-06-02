import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_control/pages/home_page.dart';
import 'package:remote_control/pages/loading_splash_screen.dart';
import 'package:remote_control/pages/remote_control_page.dart';
import 'package:remote_control/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool showWelcome = await OnBoardingService.shouldShowWelcomePage();

  runApp(
    ProviderScope(
      child: DevicePreview(
        builder: (context) => MyApp(showWelcomePage: showWelcome),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showWelcomePage;
  const MyApp({super.key, required this.showWelcomePage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remote Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _SplashGate(showWelcomePage: showWelcomePage),
      routes: {
        '/home': (context) => const HomePage(),
        '/remote-control': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return RemoteControlPage(
            categoryId: args['categoryId'] as String,
            brand: args['brand'] as String,
            configIndex: args['configIndex'] as int,
          );
        },
      },
    );
  }
}

class _SplashGate extends StatefulWidget {
  final bool showWelcomePage;
  const _SplashGate({required this.showWelcomePage});

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingSplashscreen();
    }
    return widget.showWelcomePage ? const WelcomePage() : const HomePage();
  }
}

class OnBoardingService {
  static const String _kOnboardedAtKey = 'user_onboarded_at';

  static Future<bool> shouldShowWelcomePage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? onboardedTime = prefs.getString(_kOnboardedAtKey);

    return onboardedTime == null;
  }

  static Future<void> markWelcomePageAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOnboardedAtKey, DateTime.now().toIso8601String());
  }
}
