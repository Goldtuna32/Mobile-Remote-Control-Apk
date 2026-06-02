import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      icon: Icons.add_circle_outline_rounded,
      accentColor: Color(0xFF42A5F5),
      title: 'Add Your Devices',
      description:
          'Choose from hundreds of brands across AC, TV, fans and more. '
          'Set up your device in seconds.',
      illustrationType: _IllustrationType.addDevice,
    ),
    _OnboardSlide(
      icon: Icons.wifi_tethering_rounded,
      accentColor: Color(0xFF66BB6A),
      title: 'Control with IR',
      description:
          'Point your phone at any device and take control. '
          'No Wi-Fi or Bluetooth needed — pure infrared.',
      illustrationType: _IllustrationType.control,
    ),
    _OnboardSlide(
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFFFFB74D),
      title: 'Enjoy the Comfort',
      description:
          'All your remotes in one place. Switch rooms, '
          'adjust temperature, and enjoy a seamless smart home.',
      illustrationType: _IllustrationType.enjoy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
    HapticFeedback.selectionClick();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();

    debugPrint('[Onboarding] Finishing wizard. Saving to SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_onboarded_at',
      DateTime.now().toIso8601String(),
    );
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

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
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
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _SlideContent(
                      slide: _slides[index],
                      fadeAnim: _fadeAnim,
                      slideAnim: _slideAnim,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? slide.accentColor
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Main action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: slide.accentColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _nextPage,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: isLast
                                    ? const Row(
                                        key: ValueKey('get_started'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Get Started',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
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
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                              ),
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

class _SlideContent extends StatelessWidget {
  final _OnboardSlide slide;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final bool isActive;

  const _SlideContent({
    required this.slide,
    required this.fadeAnim,
    required this.slideAnim,
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
              _Illustration(
                type: slide.illustrationType,
                color: slide.accentColor,
              ),

              const SizedBox(height: 52),

              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 16,
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

class _Illustration extends StatelessWidget {
  final _IllustrationType type;
  final Color color;

  const _Illustration({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.15), width: 1.5),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(_iconForType(type), color: color, size: 52),
          ),
          ..._badgesForType(type, color),
        ],
      ),
    );
  }

  IconData _iconForType(_IllustrationType type) {
    switch (type) {
      case _IllustrationType.addDevice:
        return Icons.add_circle_outline_rounded;
      case _IllustrationType.control:
        return Icons.wifi_tethering_rounded;
      case _IllustrationType.enjoy:
        return Icons.auto_awesome_rounded;
    }
  }

  List<Widget> _badgesForType(_IllustrationType type, Color color) {
    switch (type) {
      case _IllustrationType.addDevice:
        return [
          _floatingBadge(Icons.tv_rounded, color, top: 28, left: 28),
          _floatingBadge(Icons.air_rounded, color, top: 28, right: 28),
          _floatingBadge(Icons.album_rounded, color, bottom: 28, left: 28),
          _floatingBadge(
            Icons.speaker_group_rounded,
            color,
            bottom: 28,
            right: 28,
          ),
        ];
      case _IllustrationType.control:
        return [
          _floatingBadge(Icons.bolt_rounded, color, top: 32, right: 32),
          _floatingBadge(Icons.sensors_rounded, color, bottom: 32, left: 32),
        ];
      case _IllustrationType.enjoy:
        return [
          _floatingBadge(Icons.star_rounded, color, top: 30, left: 40),
          _floatingBadge(
            Icons.check_circle_outline_rounded,
            color,
            bottom: 30,
            right: 40,
          ),
        ];
    }
  }

  Widget _floatingBadge(
    IconData icon,
    Color color, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

enum _IllustrationType { addDevice, control, enjoy }

class _OnboardSlide {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final _IllustrationType illustrationType;

  const _OnboardSlide({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.illustrationType,
  });
}
