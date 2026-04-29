class AppConstants {
  static const String repoOwner = 'sb2chun';
  static const String repoName = 'baby-flashcard';
  static const String githubPagesUrl =
      'https://$repoOwner.github.io/$repoName/flashcards.json';
  static const String cacheKey = 'flashcards_data';
  static const Duration cacheDuration = Duration(hours: 1);
}