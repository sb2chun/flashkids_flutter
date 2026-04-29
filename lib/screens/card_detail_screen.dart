import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  String _searchQuery = '';
  String _selectedCategory = '통합';

  void _showCardDetail(BuildContext context, FlashcardItem item, String language) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDetailModal(item: item, language: language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final state = ref.watch(flashcardNotifierProvider);
    final notifier = ref.read(flashcardNotifierProvider.notifier);
    final language = state.language;
    final isKor = language == 'kor';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          isKor ? '카드 정보' : 'Card Details',
          style: const TextStyle(
              color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => notifier.setLanguage(isKor ? 'eng' : 'kor'),
            child: Text(
              isKor ? '한글' : 'English',
              style: TextStyle(
                  color: isKor ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (categories) {
          final allCategories = [
            FlashcardCategory(
                path: '통합', korName: '통합', engName: 'All', items: []),
            ...categories,
          ];
          final allItems = _selectedCategory == '통합'
              ? categories.expand((c) => c.items).toList()
              : categories
              .where((c) => c.path == _selectedCategory)
              .expand((c) => c.items)
              .toList();
          final filtered = _searchQuery.isEmpty
              ? allItems
              : allItems
              .where((item) =>
          item.korWord.contains(_searchQuery) ||
              item.engWord
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();

          return Column(
            children: [
              // 검색창
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: isKor ? '검색...' : 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              // 카테고리 탭
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: allCategories.length,
                  itemBuilder: (_, i) {
                    final cat = allCategories[i];
                    final isSelected = _selectedCategory == cat.path;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat.path),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isKor ? cat.korName : cat.engName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // 결과 수
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isKor ? '총 ${filtered.length}개' : '${filtered.length} cards',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              // 카드 그리드
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text(
                    isKor ? '검색 결과가 없습니다.' : 'No results found.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return GestureDetector(
                      onTap: () =>
                          _showCardDetail(context, item, language),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: item.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  errorWidget: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                item.wordFor(language),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 카드 상세 모달
class _CardDetailModal extends ConsumerWidget {
  final FlashcardItem item;
  final String language;

  const _CardDetailModal({required this.item, required this.language});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.read(ttsServiceProvider);
    final isKor = language == 'kor';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: item.image,
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),

          // 단어 정보 행
          Row(
            children: [
              // 한글
              Expanded(
                child: _WordChip(
                  label: '한국어',
                  word: item.korWord,
                  color: Colors.orange,
                  onTap: () => tts.speak(item.korWord, 'kor'),
                ),
              ),
              const SizedBox(width: 12),
              // 영어
              Expanded(
                child: _WordChip(
                  label: 'English',
                  word: item.engWord,
                  color: Colors.blue,
                  onTap: () => tts.speak(item.engWord, 'eng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 카테고리
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  isKor ? '카테고리: ${item.categoryPath}' : 'Category: ${item.categoryPath}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 현재 언어로 TTS 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => tts.speak(item.wordFor(language), language),
              icon: const Icon(Icons.volume_up),
              label: Text(
                isKor ? '발음 듣기' : 'Listen',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String label;
  final String word;
  final Color color;
  final VoidCallback onTap;

  const _WordChip({
    required this.label,
    required this.word,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(word,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.85))),
            const SizedBox(height: 4),
            Icon(Icons.volume_up, size: 16, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}