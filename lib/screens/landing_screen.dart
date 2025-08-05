import 'package:flutter/material.dart';
import 'package:public_transportation/screens/unified_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));

    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    ));

    // Start animations with delays
    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _buttonController.forward();
  }

  void _navigateToMainApp() async {
    // Animate out before navigation
    await _fadeController.reverse();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              UnifiedNavigationScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_fadeController, _slideController, _buttonController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Background Image with fade in
                Positioned.fill(
                  child: Image.asset(
                    'assets/publictransport.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),

                // Main Content with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Title text with fade in
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 150, 0, 19),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Welcome to PATH',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Color(0xff003B73),
                              fontSize: 32,
                              fontFamily: 'inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // Subtitle text
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                        child: Text(
                          'The perfect companion for your public transportation trips!',
                          style: TextStyle(
                            color: Color(0xff003B73),
                            fontSize: 18,
                            fontFamily: 'inter',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      // Animated Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 400, 30, 0),
                        child: FadeTransition(
                          opacity: _buttonFadeAnimation,
                          child: ScaleTransition(
                            scale: _buttonScaleAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              height: 71,
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      spreadRadius: 0,
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 255, 167, 38),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _navigateToMainApp,
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 59, 115),
                                      fontSize: 18,
                                      fontFamily: 'inter',
                                      fontWeight: FontWeight.w600,
                                    ),
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
          );
        },
      ),
    );
  }
}
