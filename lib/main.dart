import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/flashcard_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/card_detail_screen.dart';
import 'screens/about_screen.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/flashcards', builder: (_, __) => const FlashcardScreen()),
    GoRoute(path: '/quiz', builder: (_, __) => const QuizScreen()),
    GoRoute(path: '/detail', builder: (_, __) => const CardDetailScreen()),
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Baby Flashcards',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: true,
          child: child!,
        );
      },
    );
  }
}