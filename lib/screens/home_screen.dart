import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/flashcard_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _showCoachMark = false;
  int _coachStep = 0;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('coach_mark_seen') ?? false;
    if (!seen && mounted) setState(() => _showCoachMark = true);
  }

  Future<void> _finishCoachMark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coach_mark_seen', true);
    setState(() => _showCoachMark = false);
  }

  List<Map<String, dynamic>> _buildContents(bool isKor) => [
    {
      'title': isKor ? '플래시카드' : 'Flashcards',
      'desc': isKor ? '이미지로 배워요' : 'Learn with images',
      'coach': isKor
          ? '이미지와 단어를 함께 보며\n자동/수동으로 학습해요 📖'
          : 'View images and words together\nand learn at your own pace 📖',
      'emoji': '📚',
      'gradient': [const Color(0xFF6C63FF), const Color(0xFF4F46E5)],
      'path': '/flashcards',
    },
    {
      'title': isKor ? '퀴즈' : 'Quiz',
      'desc': isKor ? '맞춰봐요!' : "Let's guess!",
      'coach': isKor
          ? '배운 단어를 퀴즈로 복습하고\n실력을 확인해봐요 🎯'
          : 'Review learned words with quizzes\nand test your knowledge 🎯',
      'emoji': '🎯',
      'gradient': [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      'path': '/quiz',
    },
    {
      'title': isKor ? '카드 목록' : 'Cards',
      'desc': isKor ? '전체 카드 보기' : 'Browse all cards',
      'coach': isKor
          ? '카테고리별로 전체 카드를\n한눈에 확인할 수 있어요 📋'
          : 'Browse all cards by category\nat a glance 📋',
      'emoji': '🗂️',
      'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'path': '/detail',
    },
    {
      'title': isKor ? '소개' : 'About',
      'desc': isKor ? '앱 정보 및 도움말' : 'App info & help',
      'coach': isKor
          ? '앱 소개와 사용 방법을\n확인할 수 있어요 ℹ️'
          : 'Learn about the app\nand how to use it ℹ️',
      'emoji': 'ℹ️',
      'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      'path': '/about',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardNotifierProvider);
    final notifier = ref.read(flashcardNotifierProvider.notifier);
    final isKor = state.language == 'kor';
    final contents = _buildContents(isKor);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF0F2FF),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroSection(
                  isKor: isKor,
                  floatAnim: _floatAnim,
                  onLangToggle: () {
                    if (!mounted) return;
                    notifier.setLanguage(isKor ? 'eng' : 'kor');
                  },
                  onHelp: () {
                    if (!mounted) return;
                    setState(() {
                      _showCoachMark = true;
                      _coachStep = 0;
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKor ? '빠르게 시작하기' : 'Quick Start',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildListDelegate([
                    _QuickCard(
                      title: contents[0]['title'] as String,
                      desc: contents[0]['desc'] as String,
                      emoji: contents[0]['emoji'] as String,
                      gradient: contents[0]['gradient'] as List<Color>,
                      onTap: () => context.push(contents[0]['path'] as String),
                    ),
                    _QuickCard(
                      title: contents[1]['title'] as String,
                      desc: contents[1]['desc'] as String,
                      emoji: contents[1]['emoji'] as String,
                      gradient: contents[1]['gradient'] as List<Color>,
                      onTap: () => context.push(contents[1]['path'] as String),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    isKor ? '더보기' : 'More',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ListCard(
                      title: contents[2]['title'] as String,
                      desc: contents[2]['desc'] as String,
                      gradient: contents[2]['gradient'] as List<Color>,
                      emoji: contents[2]['emoji'] as String,
                      onTap: () => context.push(contents[2]['path'] as String),
                    ),
                    const SizedBox(height: 10),
                    _ListCard(
                      title: contents[3]['title'] as String,
                      desc: contents[3]['desc'] as String,
                      gradient: contents[3]['gradient'] as List<Color>,
                      emoji: contents[3]['emoji'] as String,
                      onTap: () => context.push(contents[3]['path'] as String),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (_showCoachMark)
          Material(
            color: Colors.transparent,
            child: _buildCoachMark(contents, isKor),
          ),
      ],
    );
  }

  Widget _buildCoachMark(List<Map<String, dynamic>> contents, bool isKor) {
    if (_coachStep >= contents.length) {
      return GestureDetector(
        onTap: _finishCoachMark,
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/bear_character.png',
                  width: 120,
                  errorBuilder: (_, __, ___) =>
                  const Text('🐻', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 16),
                Text(
                  isKor
                      ? '준비 완료!\n즐겁게 학습을 시작해봐요'
                      : "All set!\nLet's start learning!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _finishCoachMark,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      isKor ? '시작하기 🚀' : 'Get Started 🚀',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final c = contents[_coachStep];
    return GestureDetector(
      onTap: () => setState(() => _coachStep++),
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity! < 0) {
          setState(() => _coachStep++);
        } else if (d.primaryVelocity! > 0 && _coachStep > 0) {
          setState(() => _coachStep--);
        }
      },
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(c['emoji'] as String,
                          style: const TextStyle(
                              fontSize: 52,
                              decoration: TextDecoration.none)),
                      const SizedBox(height: 12),
                      Text(
                        c['title'] as String,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c['coach'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.6,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    contents.length + 1,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _coachStep ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _coachStep
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isKor ? '탭하거나 스와이프하여 이동' : 'Tap or swipe to navigate',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isKor;
  final Animation<double> floatAnim;
  final VoidCallback onLangToggle;
  final VoidCallback onHelp;

  const _HeroSection({
    required this.isKor,
    required this.floatAnim,
    required this.onLangToggle,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8E6FF), Color(0xFFD4D0FF), Color(0xFFDCF0FF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // ★ 수정 1: fill → cover 로 비율 유지
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Image.asset(
                'assets/images/main_screen_image_cutted.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                color: Colors.white.withOpacity(0.3),
                colorBlendMode: BlendMode.lighten,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onHelp,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.help_outline,
                          color: Colors.grey, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: onLangToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(isKor ? '🇰🇷' : '🇺🇸',
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            isKor ? '한글' : 'English',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKor ? '안녕하세요! 👋' : 'Hello! 👋',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  isKor ? '오늘도 같이\n배워볼까요?' : 'Ready to learn\ntoday?',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // ★ 수정 2: 곰돌이 위치 - bottom 올리고 right 줄여서 카드와 안 겹치게
          Positioned(
            right: 12,
            bottom: 20,
            child: AnimatedBuilder(
              animation: floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, floatAnim.value),
                child: child,
              ),
              child: Image.asset(
                'assets/images/bear_character.png',
                width: 110,
                errorBuilder: (_, __, ___) =>
                const Text('🐻', style: TextStyle(fontSize: 72)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String desc;
  final String emoji;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22))),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 3),
            Text(desc,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final String desc;
  final String emoji;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ListCard({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}