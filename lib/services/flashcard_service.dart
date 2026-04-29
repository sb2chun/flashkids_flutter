
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/flashcard_model.dart';

class FlashcardService {
  final Dio _dio = Dio();

  Future<List<FlashcardCategory>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(AppConstants.cacheKey);
    final timestamp = prefs.getInt('${AppConstants.cacheKey}_timestamp');

    // 유효한 캐시 확인
    if (cached != null && timestamp != null) {
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age < AppConstants.cacheDuration.inMilliseconds) {
        return _parseCategories(jsonDecode(cached));
      }
    }

    // 새 데이터 fetch
    final response = await _dio.get(AppConstants.githubPagesUrl);
    final data = response.data;

    // 캐시 저장
    await prefs.setString(AppConstants.cacheKey, jsonEncode(data));
    await prefs.setInt(
      '${AppConstants.cacheKey}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );

    return _parseCategories(data);
  }

  List<FlashcardCategory> _parseCategories(Map<String, dynamic> data) {
    return (data['categories'] as List<dynamic>)
        .map((cat) => FlashcardCategory.fromJson(cat))
        .toList();
  }
}