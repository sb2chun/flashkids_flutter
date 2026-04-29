class FlashcardCategory {
  final String path;
  final String korName;
  final String engName;
  final List<FlashcardItem> items;

  FlashcardCategory({
    required this.path,
    required this.korName,
    required this.engName,
    required this.items,
  });

  factory FlashcardCategory.fromJson(Map<String, dynamic> json) {
    return FlashcardCategory(
      path: json['path'] ?? '',
      korName: json['korName'] ?? '',
      engName: json['engName'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => FlashcardItem.fromJson(item))
          .toList(),
    );
  }
}

class FlashcardItem {
  final String korWord;
  final String engWord;
  final String image;
  final String categoryPath;

  FlashcardItem({
    required this.korWord,
    required this.engWord,
    required this.image,
    required this.categoryPath,
  });

  String wordFor(String language) =>
      language == 'kor' ? korWord : engWord;

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      korWord: json['kor_word'] ?? '',
      engWord: json['eng_word'] ?? '',
      image: json['image'] ?? '',
      categoryPath: json['category']?['path'] ?? '',
    );
  }
}