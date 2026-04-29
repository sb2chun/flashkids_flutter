import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';
import '../services/tts_service.dart';
import 'dart:math';

final flashcardServiceProvider = Provider((_) => FlashcardService());
final ttsServiceProvider = Provider((_) => TtsService());

final categoriesProvider = FutureProvider<List<FlashcardCategory>>((ref) {
  return ref.read(flashcardServiceProvider).fetchCategories();
});

class FlashcardState {
  final String language;
  final Set<String> selectedCategories;
  final bool isAutoPlay;
  final int intervalSeconds;
  final bool isTtsEnabled;
  final bool hideWord;
  final bool isRandom;
  final int currentIndex;
  final List<FlashcardItem> shuffledItems;

  const FlashcardState({
    this.language = 'kor',
    this.selectedCategories = const {'통합'},
    this.isAutoPlay = true,
    this.intervalSeconds = 4,
    this.isTtsEnabled = true,   // TTS on
    this.hideWord = false,       // 단어 보임
    this.isRandom = true,        // Shuffle on
    this.currentIndex = 0,
    this.shuffledItems = const [],
  });

  FlashcardState copyWith({
    String? language,
    Set<String>? selectedCategories,
    bool? isAutoPlay,
    int? intervalSeconds,
    bool? isTtsEnabled,
    bool? hideWord,
    bool? isRandom,
    int? currentIndex,
    List<FlashcardItem>? shuffledItems,
  }) {
    return FlashcardState(
      language: language ?? this.language,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      isAutoPlay: isAutoPlay ?? this.isAutoPlay,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      hideWord: hideWord ?? this.hideWord,
      isRandom: isRandom ?? this.isRandom,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffledItems: shuffledItems ?? this.shuffledItems,
    );
  }
}

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier() : super(const FlashcardState());

  void setLanguage(String lang) => state = state.copyWith(language: lang);

  // 카테고리 토글
  // 전체 선택 → 모두 체크 / 전체 상태에서 전체 다시 누르면 → 유지(변화없음)
  // 전체 상태에서 개별 누르면 → 해당만 해제, 나머지 유지
  // 개별 모두 선택되면 → 통합 자동 체크
  // 아무것도 없으면 → 전체로 복귀
  void toggleCategory(String cat, List<FlashcardCategory> allCategories) {
    final allPaths = allCategories.map((c) => c.path).toSet();
    final isCurrentlyAll = state.selectedCategories.contains('통합');
    Set<String> next;

    if (cat == '통합') {
      if (isCurrentlyAll) {
        // 전체 상태에서 전체 다시 누르면 → 첫 카테고리만 선택
        next = allPaths.isNotEmpty ? {allPaths.first} : {'통합', ...allPaths};
      } else {
        next = {'통합', ...allPaths};
      }
    } else {
      final current = Set<String>.from(state.selectedCategories);

      if (isCurrentlyAll) {
        // 전체 상태에서 개별 누르면 → 해당만 해제, 나머지 유지
        current.remove('통합');
        current.addAll(allPaths);
        current.remove(cat);
      } else {
        if (current.contains(cat)) {
          current.remove(cat);
          if (current.isEmpty) {
            next = {'통합', ...allPaths};
            final items = _buildItems(next, allCategories, state.isRandom);
            state = state.copyWith(
                selectedCategories: next, currentIndex: 0, shuffledItems: items);
            return;
          }
        } else {
          current.add(cat);
          if (allPaths.every((p) => current.contains(p))) {
            current.add('통합');
          }
        }
      }
      next = current;
    }

    final items = _buildItems(next, allCategories, state.isRandom);
    state = state.copyWith(
        selectedCategories: next, currentIndex: 0, shuffledItems: items);
  }

  void toggleAutoPlay() =>
      state = state.copyWith(isAutoPlay: !state.isAutoPlay);
  void setInterval(int sec) => state = state.copyWith(intervalSeconds: sec);
  void toggleTts() => state = state.copyWith(isTtsEnabled: !state.isTtsEnabled);
  void toggleHideWord() => state = state.copyWith(hideWord: !state.hideWord);

  void toggleRandom(List<FlashcardCategory> allCategories) {
    final newRandom = !state.isRandom;
    final items = _buildItems(state.selectedCategories, allCategories, newRandom);
    state = state.copyWith(isRandom: newRandom, currentIndex: 0, shuffledItems: items);
  }

  void setIndex(int index) => state = state.copyWith(currentIndex: index);

  // 초기 로드 - 항상 전체(통합)로 시작
  void initItems(List<FlashcardCategory> allCategories) {
    if (state.shuffledItems.isEmpty) {
      final allPaths = allCategories.map((c) => c.path).toSet();
      final initialCategories = {'통합', ...allPaths};
      final items = _buildItems(initialCategories, allCategories, state.isRandom);
      state = state.copyWith(
          selectedCategories: initialCategories, shuffledItems: items);
    }
  }

  List<FlashcardItem> _buildItems(
      Set<String> selectedCategories,
      List<FlashcardCategory> allCategories,
      bool isRandom) {
    List<FlashcardItem> items;
    if (selectedCategories.contains('통합')) {
      items = allCategories.expand((c) => c.items).toList();
    } else {
      items = allCategories
          .where((c) => selectedCategories.contains(c.path))
          .expand((c) => c.items)
          .toList();
    }
    if (isRandom) {
      final list = [...items];
      list.shuffle(Random());
      return list;
    }
    return items;
  }
}

final flashcardNotifierProvider =
StateNotifierProvider<FlashcardNotifier, FlashcardState>(
      (_) => FlashcardNotifier(),
);