import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // 2초 후 홈으로 이동
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 아이콘
                  // Container(
                  //   width: 110,
                  //   height: 110,
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(28),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.blue.withOpacity(0.2),
                  //         blurRadius: 24,
                  //         offset: const Offset(0, 8),
                  //       ),
                  //     ],
                  //   ),
                  //   child: const Center(
                  //     child: Text('🍼', style: TextStyle(fontSize: 56)),
                  //   ),
                  // ),
                  Image.asset(
                    'assets/images/flashscreen_image.jpg',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'FlashKids',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '우리 아이 첫 번째 학습 친구',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF93C5FD),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}