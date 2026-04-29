import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';

// 퀴즈 단계
enum QuizPhase { setup, playing, result }

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  QuizPhase _phase = QuizPhase.setup;

  // 설정
  String _selectedCategory = '전체';
  int _totalQuestions = 10;

  // 진행
  int _currentQ = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _isCorrect = false;
  List<FlashcardItem> _pool = [];
  List<FlashcardItem> _questionItems = [];
  List<String> _options = [];

  late AnimationController _resultController;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _resultScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _resultController, curve: Curves.elasticOut));
    _resultFade =
        CurvedAnimation(parent: _resultController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  void _startQuiz(List<FlashcardCategory> categories) {
    List<FlashcardItem> pool;
    if (_selectedCategory == '전체') {
      pool = categories.expand((c) => c.items).toList();
    } else {
      pool = categories
          .where((c) => c.korName == _selectedCategory || c.engName == _selectedCategory)
          .expand((c) => c.items)
          .toList();
    }
    pool.shuffle(Random());
    final count = min(_totalQuestions, pool.length);
    setState(() {
      _pool = pool;
      _questionItems = pool.take(count).toList();
      _totalQuestions = count;
      _currentQ = 0;
      _score = 0;
      _phase = QuizPhase.playing;
    });
    _buildQuestion();
  }

  void _buildQuestion() {
    if (_currentQ >= _questionItems.length) return;
    final correct = _questionItems[_currentQ];
    final wrongItems = [..._pool]..remove(correct);
    wrongItems.shuffle(Random());
    final wrongs = wrongItems.take(3).map((e) => e.wordFor(_language)).toList();
    _options = [...wrongs, correct.wordFor(_language)]..shuffle(Random());
    _selectedAnswer = null;
    _answered = false;
    _isCorrect = false;
    _resultController.reset();
  }

  String get _language =>
      ref.read(flashcardNotifierProvider).language;

  void _answer(int idx) {
    if (_answered) return;
    final correct = _questionItems[_currentQ];
    final isCorrect = _options[idx] == correct.wordFor(_language);
    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      _isCorrect = isCorrect;
      if (isCorrect) _score++;
    });
    _resultController.forward();
  }

  void _nextQuestion() {
    if (_currentQ + 1 >= _questionItems.length) {
      setState(() => _phase = QuizPhase.result);
    } else {
      setState(() {
        _currentQ++;
        _buildQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final state = ref.watch(flashcardNotifierProvider);
    final notifier = ref.read(flashcardNotifierProvider.notifier);
    final isKor = state.language == 'kor';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          isKor ? '퀴즈 게임' : 'Quiz Game',
          style: const TextStyle(
              color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.setLanguage(isKor ? 'eng' : 'kor');
              if (_phase == QuizPhase.playing) {
                setState(() => _buildQuestion());
              }
            },
            child: Text(isKor ? '한글' : 'English',
                style: TextStyle(
                    color: isKor ? Colors.orange : Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (categories) {
          if (_phase == QuizPhase.setup) {
            return _buildSetup(categories, isKor);
          } else if (_phase == QuizPhase.result) {
            return _buildResult(isKor, categories);
          } else {
            return _buildPlaying(isKor);
          }
        },
      ),
    );
  }

  // ── 설정 화면 ──────────────────────────────
  Widget _buildSetup(List<FlashcardCategory> categories, bool isKor) {
    final categoryNames = [
      if (isKor) '전체' else 'All',
      ...categories.map((c) => isKor ? c.korName : c.engName),
    ];
    if (_selectedCategory == '전체' && !isKor) _selectedCategory = 'All';
    if (_selectedCategory == 'All' && isKor) _selectedCategory = '전체';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 캐릭터
          Center(
            child: Image.asset('assets/images/bear_character.png',
                width: 120,
                errorBuilder: (_, __, ___) =>
                const Text('🐻', style: TextStyle(fontSize: 72))),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isKor ? '퀴즈를 시작해볼까요?' : 'Ready for a quiz?',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 32),

          // 카테고리 선택
          Text(isKor ? '카테고리 선택' : 'Select Category',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryNames.map((name) {
              final selected = _selectedCategory == name ||
                  (_selectedCategory == '전체' && name == 'All') ||
                  (_selectedCategory == 'All' && name == '전체');
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6C63FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(name,
                      style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // 문제 수 선택
          Text(isKor ? '문제 수' : 'Number of Questions',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Row(
            children: [10, 20, 30].map((n) {
              final selected = _totalQuestions == n;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _totalQuestions = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('$n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF1E293B))),
                        Text(isKor ? '문제' : 'Q',
                            style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white70
                                    : const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // 시작 버튼
          GestureDetector(
            onTap: () {
              final cats = ref.read(categoriesProvider).value ?? [];
              _startQuiz(cats);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Text(
                isKor ? '퀴즈 시작! 🚀' : 'Start Quiz! 🚀',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 퀴즈 진행 화면 ─────────────────────────
  Widget _buildPlaying(bool isKor) {
    if (_questionItems.isEmpty) return const SizedBox();
    final correct = _questionItems[_currentQ];
    final progress = (_currentQ + 1) / _questionItems.length;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 프로그레스
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF6C63FF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentQ + 1} / ${_questionItems.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                        fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 점수
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isKor ? '정답 $_score개' : '$_score correct',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 12),

              // 이미지 카드
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CachedNetworkImage(
                      imageUrl: correct.image,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isKor ? '이 그림의 이름은?' : 'What is this?',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),

              // 보기 버튼
              Expanded(
                flex: 2,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: List.generate(_options.length, (i) {
                    Color bg = Colors.white;
                    Color fg = const Color(0xFF1E293B);
                    if (_answered) {
                      if (_options[i] == correct.wordFor(_language)) {
                        bg = const Color(0xFFDCFCE7);
                        fg = const Color(0xFF16A34A);
                      } else if (i == _selectedAnswer) {
                        bg = const Color(0xFFFFE4E6);
                        fg = const Color(0xFFDC2626);
                      }
                    }
                    return GestureDetector(
                      onTap: () => _answer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Center(
                          child: Text(_options[i],
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: fg)),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 다음 버튼
              if (_answered)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: GestureDetector(
                    onTap: _nextQuestion,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF06B6D4)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color:
                              const Color(0xFF6C63FF).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Text(
                        _currentQ + 1 >= _questionItems.length
                            ? (isKor ? '결과 보기 🎉' : 'See Results 🎉')
                            : (isKor ? '다음 문제 →' : 'Next →'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 정답/오답 오버레이 (화면 중앙)
        if (_answered)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: FadeTransition(
                  opacity: _resultFade,
                  child: ScaleTransition(
                    scale: _resultScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          _isCorrect
                              ? 'assets/images/quiz_correct.png'
                              : 'assets/images/quiz_incorrect.png',
                          width: 160,
                          errorBuilder: (_, __, ___) => Text(
                            _isCorrect ? '⭕' : '❌',
                            style: const TextStyle(fontSize: 90),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isCorrect
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (_isCorrect
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626))
                                    .withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            _isCorrect
                                ? (isKor ? '🎉 정답!' : '🎉 Correct!')
                                : (isKor ? '😢 오답!' : '😢 Wrong!'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── 결과 화면 ──────────────────────────────
  Widget _buildResult(bool isKor, List<FlashcardCategory> categories) {
    final rate = (_score / _questionItems.length * 100).round();

    // 비율별 이미지 (이미지 자체에 문구 포함)
    final String resultImage;
    final Color barColor;
    if (rate >= 95) {
      resultImage = 'assets/images/quiz_result_perfect.png';
      barColor = const Color(0xFF60A5FA); // 파란색 (perfect 이미지 배경색)
    } else if (rate >= 80) {
      resultImage = 'assets/images/quiz_result_great.png';
      barColor = const Color(0xFF4CAF50); // 초록색
    } else if (rate >= 60) {
      resultImage = 'assets/images/quiz_result_good.png';
      barColor = const Color(0xFFFFB800); // 노란색
    } else if (rate >= 40) {
      resultImage = 'assets/images/quiz_result_normal.png';
      barColor = const Color(0xFFFF8C42); // 주황색
    } else {
      resultImage = 'assets/images/quiz_result_bad.png';
      barColor = const Color(0xFFFF6B9D); // 핑크색
    }

    return Column(
      children: [
        // 결과 이미지 (꽉 차게)
        Expanded(
    child: Container(
      color: Colors.white, // ✅ 여기 추가
      width: double.infinity,
          child: Image.asset(
            resultImage,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                rate >= 95 ? '🏆' : rate >= 80 ? '🌟' : rate >= 60 ? '😊' : rate >= 40 ? '🙂' : '💪',
                style: const TextStyle(fontSize: 100),
              ),
            ),
            ),
          ),
        ),

        // 하단 버튼 영역
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 점수
              Text(
                '$_score / ${_questionItems.length}  ($rate%)',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: barColor),
              ),
              const SizedBox(height: 10),
              // 정답률 바
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _score / _questionItems.length,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
              const SizedBox(height: 16),
              // 다시하기
              GestureDetector(
                onTap: () => setState(() {
                  _phase = QuizPhase.setup;
                  _score = 0;
                  _currentQ = 0;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF06B6D4)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    isKor ? '다시 도전하기 🔄' : 'Try Again 🔄',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 홈으로
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isKor ? '홈으로 돌아가기' : 'Back to Home',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}