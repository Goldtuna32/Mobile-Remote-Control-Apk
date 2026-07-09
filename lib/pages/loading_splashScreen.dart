import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingSplashscreen extends StatelessWidget {
  const LoadingSplashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/remote.json',
              width: 250,
              height: 250,
              fit: BoxFit.fill,
            ),
            const SizedBox(height: 20),
            const Text(
              "Loading Universal Remote Controller",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
