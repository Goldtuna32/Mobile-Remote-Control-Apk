import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remote_control/pages/home_page.dart';
import 'package:remote_control/pages/loading_splashScreen.dart';
import 'package:remote_control/pages/remote_control_page.dart';
import 'package:remote_control/pages/welcome_page.dart';

final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remote Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashGate(), // Now uses ConsumerStatefulWidget
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

class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key});

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> {
  bool _minDelayPassed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _minDelayPassed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingStatusProvider);

    return onboardingAsync.when(
      data: (isOnboardingDone) {
        if (!_minDelayPassed) return const LoadingSplashscreen();

        return isOnboardingDone ? const HomePage() : const WelcomePage();
      },
      loading: () => const LoadingSplashscreen(),
      error: (err, stack) => const WelcomePage(),
    );
  }
}
