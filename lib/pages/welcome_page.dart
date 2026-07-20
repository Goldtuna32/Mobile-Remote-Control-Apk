import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

const _bg = Color(0xFF080810);
// const _surface = Color(0xFF10101C);
const _border = Color(0xFF22223A);
const _textPri = Color(0xFFF2F2FA);
const _textSec = Color(0xFF7070A0);

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  // IR ring animation on page 2 (control slide)
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  final List<_Slide> _slides = const [
    _Slide(
      accent: Color(0xFF6C63FF),
      title: 'All your remotes\nin one place',
      body:
          'TV, AC, fan — add any device in seconds and control it from your phone.',
      type: _SlideType.devices,
    ),
    _Slide(
      accent: Color(0xFFFFB547),
      title: 'Infrared that\njust works',
      body: 'No Wi-Fi, no pairing, no setup. Point your phone and it responds.',
      type: _SlideType.ir,
    ),
    _Slide(
      accent: Color(0xFF3ECF8E),
      title: 'Ready when\nyou are',
      body:
          'Open the app, pick a device, and control. Every room, every device.',
      type: _SlideType.ready,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut);

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _contentCtrl.reset();
    _contentCtrl.forward();
    HapticFeedback.selectionClick();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: _bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              // ── Skip ──
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 20),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: _textSec, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Page view ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideView(
                    slide: _slides[i],
                    fadeAnim: _contentFade,
                    slideAnim: _contentSlide,
                    ringAnim: _ringAnim,
                    isActive: i == _currentPage,
                  ),
                ),
              ),

              // ── Dots + CTA ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? slide.accent : _border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 28),

                    // CTA button
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: slide.accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: slide.accent.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: isLast
                                ? const Row(
                                    key: ValueKey('start'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get started',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  )
                                : const Row(
                                    key: ValueKey('next'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Next',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slide view ───────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final _Slide slide;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Animation<double> ringAnim;
  final bool isActive;

  const _SlideView({
    required this.slide,
    required this.fadeAnim,
    required this.slideAnim,
    required this.ringAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              _SlideIllustration(slide: slide, ringAnim: ringAnim),
              const SizedBox(height: 48),

              // Title — deliberate line breaks in copy
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textPri,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textSec,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Illustration ─────────────────────────────────────────────────
class _SlideIllustration extends StatelessWidget {
  final _Slide slide;
  final Animation<double> ringAnim;

  const _SlideIllustration({required this.slide, required this.ringAnim});

  @override
  Widget build(BuildContext context) {
    // IR slide gets the animated ring — the signature element
    if (slide.type == _SlideType.ir) {
      return AnimatedBuilder(
        animation: ringAnim,
        builder: (_, __) {
          return SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding ring 1
                _Ring(
                  size: 80 + ringAnim.value * 110,
                  opacity: (1 - ringAnim.value) * 0.5,
                  color: slide.accent,
                  width: 1.0,
                ),
                // Expanding ring 2 (offset phase)
                _Ring(
                  size: 80 + ((ringAnim.value + 0.5) % 1.0) * 110,
                  opacity: (1 - (ringAnim.value + 0.5) % 1.0) * 0.35,
                  color: slide.accent,
                  width: 1.0,
                ),
                // Static middle ring
                _Ring(
                  size: 100,
                  opacity: 0.15,
                  color: slide.accent,
                  width: 1.5,
                ),
                // Core
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: slide.accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    color: slide.accent,
                    size: 32,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Other slides: static layered icon composition
    final icons = _iconsForType(slide.type);
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  slide.accent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _Ring(size: 160, opacity: 0.1, color: slide.accent, width: 1),
          // Core
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accent.withValues(alpha: 0.12),
              border: Border.all(
                color: slide.accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icons[0], color: slide.accent, size: 36),
          ),
          // Orbiting badges
          if (icons.length > 1)
            Positioned(
              top: 24,
              right: 24,
              child: _SmallBadge(icon: icons[1], color: slide.accent),
            ),
          if (icons.length > 2)
            Positioned(
              bottom: 24,
              left: 24,
              child: _SmallBadge(icon: icons[2], color: slide.accent),
            ),
          if (icons.length > 3)
            Positioned(
              top: 24,
              left: 24,
              child: _SmallBadge(icon: icons[3], color: slide.accent),
            ),
        ],
      ),
    );
  }

  List<IconData> _iconsForType(_SlideType type) {
    switch (type) {
      case _SlideType.devices:
        return [
          Icons.devices_rounded,
          Icons.tv_rounded,
          Icons.air_rounded,
          Icons.thermostat_rounded,
        ];
      case _SlideType.ready:
        return [
          Icons.check_circle_rounded,
          Icons.bolt_rounded,
          Icons.star_rounded,
        ];
      case _SlideType.ir:
        return [Icons.sensors_rounded];
    }
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;
  final double width;

  const _Ring({
    required this.size,
    required this.opacity,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: width,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SmallBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────
enum _SlideType { devices, ir, ready }

class _Slide {
  final Color accent;
  final String title;
  final String body;
  final _SlideType type;

  const _Slide({
    required this.accent,
    required this.title,
    required this.body,
    required this.type,
  });
}
