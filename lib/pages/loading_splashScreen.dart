import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// ─── Design tokens (shared with app) ─────────────────────────────
const _bg = Color(0xFF0A0A0F);
const _accent = Color(0xFF6C63FF);
const _accentDim = Color(0x1A6C63FF);
const _textPrimary = Color(0xFFF0F0F8);
const _textSecondary = Color(0xFF8888AA);
// ─────────────────────────────────────────────────────────────────

class LoadingSplashscreen extends StatefulWidget {
  const LoadingSplashscreen({super.key});

  @override
  State<LoadingSplashscreen> createState() => _LoadingSplashscreenState();
}

class _LoadingSplashscreenState extends State<LoadingSplashscreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Cycles through subtle loading hints so the screen doesn't feel frozen
  final List<String> _hints = [
    'Loading device profiles…',
    'Calibrating IR frequencies…',
    'Preparing your remote…',
  ];
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Cycle hint text every 2 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return false;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      return true;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── Background glow orb ──────────────────────────────
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x226C63FF), Colors.transparent],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x1AFFB547), Colors.transparent],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Lottie animation inside a styled container
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentDim,
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: Lottie.asset(
                          'assets/animations/remote.json',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App name
                    const Text(
                      'MI REMOTE',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Universal Controller',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── Bottom loading section ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          // Thin progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              backgroundColor: Color(0xFF1C1C27),
                              valueColor: AlwaysStoppedAnimation(_accent),
                              minHeight: 2,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Animated hint text
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              _hints[_hintIndex],
                              key: ValueKey(_hintIndex),
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
