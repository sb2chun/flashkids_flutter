import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isFullScreen = false;
  static const int _preloadWindow = 5;

  // Coach Mark
  bool _showCoachMark = false;
  int _coachStep = 0;

  late AnimationController _cardController;
  late Animation<double> _cardFade;

  // Coach Mark 각 단계 정의
  static const _coachSteps = [
    {
      'icon': Icons.swap_horiz,
      'titleKor': '스와이프로 넘기기',
      'titleEng': 'Swipe to Navigate',
      'descKor': '이미지를 좌우로 스와이프하면\n카드를 넘길 수 있어요 👈👉',
      'descEng': 'Swipe left or right on the image\nto navigate cards 👈👉',
    },
    {
      'icon': Icons.category_outlined,
      'titleKor': '카테고리 선택',
      'titleEng': 'Select Category',
      'descKor': '오른쪽 사이드바에서\n원하는 카테고리를 선택하세요 📂',
      'descEng': 'Tap the sidebar on the right\nto select categories 📂',
    },
    {
      'icon': Icons.volume_up_outlined,
      'titleKor': 'TTS 발음 듣기',
      'titleEng': 'Listen to Pronunciation',
      'descKor': '상단 🔊 버튼을 누르면\n단어 발음을 들을 수 있어요 🎵',
      'descEng': 'Tap 🔊 at the top\nto hear word pronunciation 🎵',
    },
    {
      'icon': Icons.play_circle_outline,
      'titleKor': '자동 재생',
      'titleEng': 'Auto Play',
      'descKor': '상단 ▶ 버튼으로 자동 재생!\n⏱ 버튼으로 속도 조절도 가능해요',
      'descEng': 'Tap ▶ for auto play!\nUse ⏱ to adjust speed',
    },
    {
      'icon': Icons.fullscreen,
      'titleKor': '전체화면 모드',
      'titleEng': 'Fullscreen Mode',
      'descKor': '상단 ⛶ 버튼으로\n이미지를 크게 볼 수 있어요 🖼️',
      'descEng': 'Tap ⛶ at the top\nfor fullscreen view 🖼️',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _cardController.value = 1.0;
    _checkCoachMark();
  }

  Future<void> _checkCoachMark() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('flashcard_coach_seen') ?? false;
    if (seen) return;
    // 오늘 하루 보지 않기 체크
    final hideUntil = prefs.getInt('flashcard_coach_hide_until') ?? 0;
    if (hideUntil > DateTime.now().millisecondsSinceEpoch) return;
    if (mounted) setState(() { _showCoachMark = true; _coachStep = 0; });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cardController.dispose();
    _timer?.cancel();
    ref.read(ttsServiceProvider).stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final state = ref.read(flashcardNotifierProvider);
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.inactive ||
        lifecycle == AppLifecycleState.detached) {
      _timer?.cancel();
      ref.read(ttsServiceProvider).stop();
    } else if (lifecycle == AppLifecycleState.resumed) {
      if (state.isAutoPlay) _resetTimer(state.shuffledItems, state);
    }
  }

  void _preloadImages(List<FlashcardItem> items, int currentIndex) {
    final length = items.length;
    if (length == 0) return;
    for (int offset = -_preloadWindow; offset <= _preloadWindow; offset++) {
      int idx = (currentIndex + offset) % length;
      if (idx < 0) idx += length;
      final url = items[idx].image;
      if (url.isNotEmpty) precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  void _resetTimer(List<FlashcardItem> items, FlashcardState state) {
    _timer?.cancel();
    if (!state.isAutoPlay || items.isEmpty) return;
    _timer = Timer.periodic(Duration(seconds: state.intervalSeconds), (_) {
      final s = ref.read(flashcardNotifierProvider);
      _navigateTo((s.currentIndex + 1) % items.length, items, s);
    });
  }

  void _navigateTo(int index, List<FlashcardItem> items, FlashcardState s) {
    _cardController.reverse().then((_) {
      ref.read(flashcardNotifierProvider.notifier).setIndex(index);
      _preloadImages(items, index);
      _cardController.forward();
      if (s.isTtsEnabled) {
        ref.read(ttsServiceProvider).speak(
            items[index].wordFor(s.language), s.language);
      }
    });
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    SystemChrome.setEnabledSystemUIMode(
      _isFullScreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _showTimerPicker(BuildContext context, FlashcardState state,
      FlashcardNotifier notifier, bool isKor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isKor ? '자동 넘김 간격' : 'Auto-play Interval',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((sec) {
                final selected = state.intervalSeconds == sec;
                return GestureDetector(
                  onTap: () {
                    notifier.setInterval(sec);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF6C63FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected ? [BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.35),
                          blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$sec', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : const Color(0xFF1E293B))),
                        Text(isKor ? '초' : 's', style: TextStyle(
                            fontSize: 10,
                            color: selected ? Colors.white70 : const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final state = ref.watch(flashcardNotifierProvider);
    final notifier = ref.read(flashcardNotifierProvider.notifier);
    final isKor = state.language == 'kor';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (categories) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notifier.initItems(categories);
              });

              final items = state.shuffledItems;
              if (items.isEmpty) return const Center(child: CircularProgressIndicator());

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _resetTimer(items, state);
                _preloadImages(items, state.currentIndex);
              });

              final safeIndex = state.currentIndex % items.length;
              final item = items[safeIndex];

              if (_isFullScreen) {
                return _buildFullScreen(items, safeIndex, item, state, notifier, isKor, categories);
              }

              return Column(
                children: [
                  _buildHeader(state, notifier, categories, isKor, items, safeIndex),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildCardArea(items, safeIndex, item, state, notifier)),
                        _CategorySidebar(categories: categories),
                      ],
                    ),
                  ),
                  _buildMinimalBottom(item, safeIndex, items.length, state),
                ],
              );
            },
          ),
        ),

        // Coach Mark
        if (_showCoachMark)
          Material(
            color: Colors.transparent,
            child: _buildCoachMark(isKor),
          ),
      ],
    );
  }

  // ── 헤더 ──────────────────────────────────────
  Widget _buildHeader(FlashcardState state, FlashcardNotifier notifier,
      List<FlashcardCategory> categories, bool isKor,
      List<FlashcardItem> items, int safeIndex) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF48B4E0)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              _hdrIconBtn(Icons.arrow_back_ios, () => Navigator.pop(context), false, size: 18),
              _langToggle(isKor, () => notifier.setLanguage(isKor ? 'eng' : 'kor')),
              const Spacer(),
              _hdrIconBtn(
                  state.isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                  notifier.toggleTts, state.isTtsEnabled),
              _hdrIconBtn(
                  state.hideWord ? Icons.visibility_off : Icons.visibility,
                  notifier.toggleHideWord, !state.hideWord),
              _hdrIconBtn(
                  Icons.shuffle,
                      () => notifier.toggleRandom(categories), state.isRandom),
              _timerBtn(state, notifier, isKor),
              _hdrIconBtn(
                  state.isAutoPlay ? Icons.pause_circle : Icons.play_circle,
                  notifier.toggleAutoPlay, state.isAutoPlay),
              _hdrIconBtn(Icons.fullscreen, _toggleFullScreen, false),
              _hdrIconBtn(Icons.help_outline, () => setState(() {
                _showCoachMark = true;
                _coachStep = 0;
              }), false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langToggle(bool isKor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(isKor ? '🇰🇷 KOR' : '🇺🇸 ENG',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _hdrIconBtn(IconData icon, VoidCallback onTap, bool active, {double size = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32, height: 40,
        child: Center(
          child: Icon(icon,
              color: active ? Colors.yellow.shade300 : Colors.white60, size: size),
        ),
      ),
    );
  }

  Widget _timerBtn(FlashcardState state, FlashcardNotifier notifier, bool isKor) {
    return GestureDetector(
      onTap: state.isAutoPlay
          ? () => _showTimerPicker(context, state, notifier, isKor)
          : null,
      child: SizedBox(
        width: 32, height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(Icons.timer_outlined,
                  color: state.isAutoPlay ? Colors.yellow.shade300 : Colors.white38, size: 20),
            ),
            if (state.isAutoPlay)
              Positioned(
                right: 0, top: 6,
                child: Container(
                  width: 13, height: 13,
                  decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${state.intervalSeconds}',
                        style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 카드 이미지 영역 ──────────────────────────
  Widget _buildCardArea(List<FlashcardItem> items, int safeIndex,
      FlashcardItem item, FlashcardState state, FlashcardNotifier notifier) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final s = ref.read(flashcardNotifierProvider);
        if (d.primaryVelocity! < 0) {
          _navigateTo((safeIndex + 1) % items.length, items, s);
        } else {
          _navigateTo((safeIndex - 1 + items.length) % items.length, items, s);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
        child: FadeTransition(
          opacity: _cardFade,
          child: GestureDetector(
            onTapUp: (details) {
              final sw = MediaQuery.of(context).size.width;
              final s = ref.read(flashcardNotifierProvider);
              if (details.globalPosition.dx < sw / 2) {
                _navigateTo((safeIndex - 1 + items.length) % items.length, items, s);
              } else {
                _navigateTo((safeIndex + 1) % items.length, items, s);
              }
            },
            // 그림자로만 이미지 구분
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 하단 (단어 + 도트) ────────────────────────
  Widget _buildMinimalBottom(FlashcardItem item, int safeIndex, int total, FlashcardState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!state.hideWord)
            Expanded(
              child: Text(
                item.wordFor(state.language),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B), letterSpacing: 0.5,
                ),
              ),
            ),
          if (state.hideWord) const Spacer(),
          _buildProgressDots(safeIndex, total),
          if (!state.hideWord) const SizedBox(width: 8),
          if (state.hideWord) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProgressDots(int current, int total) {
    const maxDots = 8;
    if (total <= maxDots) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: i == current ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == current ? const Color(0xFF6C63FF) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      );
    }
    return Text('${current + 1}/$total',
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500));
  }

  // ── 전체화면 ──────────────────────────────────
  Widget _buildFullScreen(List<FlashcardItem> items, int safeIndex, FlashcardItem item,
      FlashcardState state, FlashcardNotifier notifier, bool isKor,
      List<FlashcardCategory> categories) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 1번: 왼쪽 자리 invisible, 오른쪽에 fullscreen_exit
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF48B4E0)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    // 왼쪽 자리 유지 (invisible)
                    const SizedBox(width: 32, height: 40),
                    _langToggle(isKor, () => notifier.setLanguage(isKor ? 'eng' : 'kor')),
                    // Coach Mark 다시보기
                    GestureDetector(
                      onTap: () => setState(() { _showCoachMark = true; _coachStep = 0; }),
                      child: SizedBox(
                        width: 28, height: 40,
                        child: Center(
                          child: Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('?', style: TextStyle(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _hdrIconBtn(
                        state.isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                        notifier.toggleTts, state.isTtsEnabled),
                    _hdrIconBtn(
                        state.hideWord ? Icons.visibility_off : Icons.visibility,
                        notifier.toggleHideWord, !state.hideWord),
                    _hdrIconBtn(
                        Icons.shuffle,
                            () => notifier.toggleRandom(categories), state.isRandom),
                    _timerBtn(state, notifier, isKor),
                    _hdrIconBtn(
                        state.isAutoPlay ? Icons.pause_circle : Icons.play_circle,
                        notifier.toggleAutoPlay, state.isAutoPlay),
                    // 오른쪽에 fullscreen_exit
                    _hdrIconBtn(Icons.fullscreen_exit, _toggleFullScreen, false),
                    _hdrIconBtn(Icons.help_outline, () => setState(() {
                      _showCoachMark = true;
                      _coachStep = 0;
                    }), false),
                  ],
                ),
              ),
            ),
          ),

          // 이미지 (최대)
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                final s = ref.read(flashcardNotifierProvider);
                if (d.primaryVelocity! < 0) {
                  _navigateTo((safeIndex + 1) % items.length, items, s);
                } else {
                  _navigateTo((safeIndex - 1 + items.length) % items.length, items, s);
                }
              },
              onTapUp: (details) {
                final sw = MediaQuery.of(context).size.width;
                final s = ref.read(flashcardNotifierProvider);
                if (details.globalPosition.dx < sw / 2) {
                  _navigateTo((safeIndex - 1 + items.length) % items.length, items, s);
                } else {
                  _navigateTo((safeIndex + 1) % items.length, items, s);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: CachedNetworkImage(
                    imageUrl: item.image,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // 단어 + 도트
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!state.hideWord)
                  Expanded(
                    child: Text(item.wordFor(state.language),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                  ),
                _buildProgressDots(safeIndex, items.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4번: Coach Mark ───────────────────────────
  Widget _buildCoachMark(bool isKor) {
    final steps = _coachSteps;

    if (_coachStep >= steps.length) {
      // 완료 화면 - 홈과 동일한 스타일
      return GestureDetector(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('flashcard_coach_seen', true);
          setState(() => _showCoachMark = false);
        },
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
                  const Text('🐻', style: TextStyle(fontSize: 64, decoration: TextDecoration.none)),
                ),
                const SizedBox(height: 16),
                Text(
                  isKor ? '이제 시작해볼까요? 🎉\n즐거운 학습 되세요!' : 'Ready to go! 🎉\nHappy learning!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold, height: 1.6,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('flashcard_coach_seen', true);
                    setState(() => _showCoachMark = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      isKor ? '시작하기 🚀' : 'Let\'s Go 🚀',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16,
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

    final step = steps[_coachStep];
    return GestureDetector(
      onTap: () => setState(() => _coachStep++),
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity! < 0 && _coachStep < steps.length) {
          setState(() => _coachStep++);
        } else if (d.primaryVelocity! > 0 && _coachStep > 0) {
          setState(() => _coachStep--);
        }
      },
      child: Container(
        color: Colors.black.withOpacity(0.70),
        child: Column(
          children: [
            const Spacer(),
            // 설명 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24)],
                ),
                child: Column(
                  children: [
                    Icon(step['icon'] as IconData, color: const Color(0xFF6C63FF), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isKor ? step['titleKor'] as String : step['titleEng'] as String,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B), decoration: TextDecoration.none),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isKor ? step['descKor'] as String : step['descEng'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54,
                          height: 1.6, decoration: TextDecoration.none),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 도트 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length + 1, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _coachStep ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _coachStep ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 16),
            Text(
              isKor ? '탭하거나 스와이프하여 이동' : 'Tap or swipe to navigate',
              style: const TextStyle(color: Colors.white60, fontSize: 13,
                  decoration: TextDecoration.none),
            ),
            const Spacer(),

            // 하단 건너뛰기 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  // 오늘 하루 보지 않기
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final tomorrow = DateTime.now().add(const Duration(days: 1));
                        await prefs.setInt('flashcard_coach_hide_until',
                            tomorrow.millisecondsSinceEpoch);
                        setState(() => _showCoachMark = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          isKor ? '오늘 하루 보지 않기' : 'Hide for today',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13,
                              decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 건너뛰기 (다음에 또 보임)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showCoachMark = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isKor ? '건너뛰기' : 'Skip',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF6C63FF), fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none),
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
    );
  }
}

// ── 카테고리 사이드바 ─────────────────────────
class _CategorySidebar extends ConsumerWidget {
  final List<FlashcardCategory> categories;
  const _CategorySidebar({required this.categories});

  static String _emoji(String path, String korName) {
    const map = {
      '통합': '🌟', 'all': '🌟',
      '공룡': '🦕', 'dinosaur': '🦕',
      '과일': '🍎', 'fruit': '🍎',
      '교통수단': '🚗', 'transport': '🚗', '교통': '🚗',
      '국가': '🌍', 'country': '🌍',
      '꽃': '🌸', 'flower': '🌸',
      '날씨': '⛅', 'weather': '⛅',
      '동물': '🐻', 'animal': '🐻',
      '색깔': '🎨', 'color': '🎨', '색': '🎨',
      '숫자': '🔢', 'number': '🔢',
      '음식': '🍔', 'food': '🍔',
      '악기': '🎸', 'instrument': '🎸',
      '알파벳': '🔤', 'alphabet': '🔤',
      '직업': '👷', 'job': '👷',
      '채소': '🥦', 'vegetable': '🥦',
      '신체': '👤', 'body': '👤',
      '도형': '🔷', 'shape': '🔷',
    };
    return map[path] ?? map[korName] ?? '📚';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashcardNotifierProvider);
    final notifier = ref.read(flashcardNotifierProvider.notifier);
    final allCategories = [
      FlashcardCategory(path: '통합', korName: '전체', engName: 'All', items: []),
      ...categories,
    ];
    final isKor = state.language == 'kor';
    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 8, top: 10, bottom: 8),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: allCategories.length,
        itemBuilder: (_, i) {
          final cat = allCategories[i];
          final isSelected = state.selectedCategories.contains(cat.path);
          const color = Color(0xFF6C63FF);
          const selectedBg = Color(0xFFEEECFF);      // 연한 보라 배경
          const selectedText = Color(0xFF6C63FF);    // 보라 텍스트
          const unselectedText = Color(0xFFB0B8C8);  // 연한 회색
          final label = isKor ? cat.korName : cat.engName;
          final emoji = _emoji(cat.path, cat.korName);

          return GestureDetector(
            onTap: () => notifier.toggleCategory(cat.path, categories),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 6),
              height: 58,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEECFF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF6C63FF).withOpacity(0.08)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: TextStyle(fontSize: isSelected ? 20 : 18)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFFB0B8C8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}