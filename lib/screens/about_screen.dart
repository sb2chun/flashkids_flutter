import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flashcard_provider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashcardNotifierProvider);
    final isKor = state.language == 'kor';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: CustomScrollView(
        slivers: [
          // 헤더
          SliverToBoxAdapter(
            child: _buildHero(isKor),
          ),
          // 섹션들
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                isKor ? _korSections() : _engSections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isKor) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF48B4E0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // 뒤로가기
              Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 앱 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/flashscreen_image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Center(child: Text('📚', style: TextStyle(fontSize: 40))),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'FlashKids',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isKor
                    ? '우리 아이 첫 번째 학습 친구 🐻'
                    : "Your child's first learning friend 🐻",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 14),
              ),
              const SizedBox(height: 16),
              // 버전 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _korSections() => [
    const SizedBox(height: 20),

    // 1. 앱 소개 + 플래시카드 효능
    _SectionCard(
      emoji: '🍼',
      title: 'FlashKids란?',
      color: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bodyText(
              'FlashKids는 아이들의 언어 발달을 돕는 스마트 플래시카드 앱입니다. '
                  '귀여운 이미지와 함께 한글과 영어를 동시에 배울 수 있어요.'),
          const SizedBox(height: 16),
          _subTitle('📖 플래시카드 학습의 효과'),
          const SizedBox(height: 8),
          _effectItem('🧠', '반복 노출로 장기 기억 형성',
              '이미지와 단어를 함께 보면 뇌에서 시각적 연상 작용이 활성화되어 기억력이 향상됩니다.'),
          _effectItem('🗣️', '자연스러운 이중 언어 습득',
              '한글과 영어를 동시에 접하면 언어 감각이 발달하고 발음 습득이 빨라집니다.'),
          _effectItem('⚡', '짧은 집중으로 높은 효율',
              '플래시카드는 짧은 시간 집중하는 방식으로 아이의 주의력에 최적화된 학습법입니다.'),
          _effectItem('🎮', '게임처럼 즐기는 학습',
              '퀴즈와 자동 재생 모드로 지루하지 않게 반복 학습이 가능합니다.'),
        ],
      ),
    ),

    // 2. 주요 기능
    _SectionCard(
      emoji: '✨',
      title: '주요 기능',
      color: const Color(0xFF06B6D4),
      child: Column(
        children: [
          _featureRow('📸', '플래시카드',
              '생생한 이미지와 단어로 자연스럽게 학습. 자동 재생 & 속도 조절 지원'),
          _featureRow('🎯', '퀴즈 게임',
              '카테고리/문제 수 선택 후 도전! 점수에 따라 귀여운 곰돌이가 반응해요'),
          _featureRow('🌍', '한글/영어 전환',
              '버튼 하나로 즉시 전환. 이중 언어 학습으로 글로벌 감각 키우기'),
          _featureRow('🔊', 'TTS 발음',
              '원어민 발음으로 정확한 발음 학습. 한국어/영어 모두 지원'),
          _featureRow('📂', '카테고리 선택',
              '동물/공룡/과일 등 10개 이상 카테고리. 다중 선택으로 내 맞춤 학습'),
          _featureRow('🖼️', '전체화면 모드',
              '이미지를 크게 보며 몰입감 있는 학습 가능'),
        ],
      ),
    ),

    // 3. 사용법
    _SectionCard(
      emoji: '📖',
      title: '이렇게 사용해요',
      color: const Color(0xFF10B981),
      child: Column(
        children: [
          _stepItem(1, '홈에서 시작',
              '플래시카드 또는 퀴즈 모드를 선택하세요'),
          _stepItem(2, '카테고리 선택',
              '오른쪽 사이드바에서 배우고 싶은 카테고리를 골라요'),
          _stepItem(3, '카드 넘기기',
              '이미지를 좌우로 스와이프하거나 탭해서 카드를 넘겨요'),
          _stepItem(4, 'TTS 활용',
              '상단 🔊 버튼을 켜면 자동으로 단어 발음을 들려줘요'),
          _stepItem(5, '퀴즈로 복습',
              '플래시카드로 익힌 후 퀴즈로 기억을 확인해요'),
          _stepItem(6, '? 버튼',
              '언제든 각 화면의 ? 버튼으로 도움말을 다시 볼 수 있어요'),
        ],
      ),
    ),

    // 4. 정보
    _SectionCard(
      emoji: '🔗',
      title: '앱 정보',
      color: const Color(0xFF8B5CF6),
      child: Column(
        children: [
          _infoRow('👨‍💻', '개발자', 'sb2chun'),
          _infoRow('📱', '버전', '1.0.0'),
          _infoRow('📧', '문의', 'sb2chun@gmail.com'),
          _infoRow('🌐', '데이터', 'GitHub Pages'),
        ],
      ),
    ),
  ];

  List<Widget> _engSections() => [
    const SizedBox(height: 20),

    // 1. About + Flashcard Benefits
    _SectionCard(
      emoji: '🍼',
      title: 'What is FlashKids?',
      color: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bodyText(
              'FlashKids is a smart flashcard app designed to support '
                  "children's language development. Learn Korean and English "
                  'together through vivid images and fun interactions.'),
          const SizedBox(height: 16),
          _subTitle('📖 Benefits of Flashcard Learning'),
          const SizedBox(height: 8),
          _effectItem('🧠', 'Long-term Memory Formation',
              'Pairing images with words activates visual association in the brain, significantly improving memory retention.'),
          _effectItem('🗣️', 'Natural Bilingual Acquisition',
              'Simultaneous exposure to Korean and English develops language sensitivity and accelerates pronunciation learning.'),
          _effectItem('⚡', 'High Efficiency in Short Sessions',
              'Flashcards are optimized for children\'s attention spans, delivering effective learning in short focused bursts.'),
          _effectItem('🎮', 'Learning Through Play',
              'Quiz mode and auto-play make repetition fun and engaging for young learners.'),
        ],
      ),
    ),

    // 2. Key Features
    _SectionCard(
      emoji: '✨',
      title: 'Key Features',
      color: const Color(0xFF06B6D4),
      child: Column(
        children: [
          _featureRow('📸', 'Flashcards',
              'Learn naturally with vivid images. Auto-play & speed control supported'),
          _featureRow('🎯', 'Quiz Game',
              'Choose category & question count! Bear character reacts to your score'),
          _featureRow('🌍', 'Korean/English Toggle',
              'Switch instantly with one tap. Build bilingual skills effortlessly'),
          _featureRow('🔊', 'TTS Pronunciation',
              'Hear native pronunciation in Korean & English'),
          _featureRow('📂', 'Category Selection',
              '10+ categories including Animals, Fruits & more. Multi-select supported'),
          _featureRow('🖼️', 'Fullscreen Mode',
              'Immersive learning with full-screen image display'),
        ],
      ),
    ),

    // 3. How to Use
    _SectionCard(
      emoji: '📖',
      title: 'How to Use',
      color: const Color(0xFF10B981),
      child: Column(
        children: [
          _stepItem(1, 'Start from Home',
              'Choose Flashcard or Quiz mode'),
          _stepItem(2, 'Select Category',
              'Pick your desired category from the right sidebar'),
          _stepItem(3, 'Navigate Cards',
              'Swipe or tap the image left/right to flip cards'),
          _stepItem(4, 'Use TTS',
              'Turn on 🔊 at the top to hear word pronunciation automatically'),
          _stepItem(5, 'Review with Quiz',
              'After flashcards, test your memory with the quiz'),
          _stepItem(6, '? Button',
              'Tap ? anytime on each screen to view the guide again'),
        ],
      ),
    ),

    // 4. Info
    _SectionCard(
      emoji: '🔗',
      title: 'App Info',
      color: const Color(0xFF8B5CF6),
      child: Column(
        children: [
          _infoRow('👨‍💻', 'Developer', 'sb2chun'),
          _infoRow('📱', 'Version', '1.0.0'),
          _infoRow('📧', 'Contact', 'sb2chun@gmail.com'),
          _infoRow('🌐', 'Data', 'GitHub Pages'),
        ],
      ),
    ),
  ];

  // ── 공통 위젯들 ──────────────────────────────

  Widget _bodyText(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF475569)),
  );

  Widget _subTitle(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
  );

  Widget _effectItem(String emoji, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, height: 1.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _featureRow(String emoji, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, height: 1.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _stepItem(int num, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$num',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, height: 1.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _infoRow(String emoji, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.15), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // 섹션 내용
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}