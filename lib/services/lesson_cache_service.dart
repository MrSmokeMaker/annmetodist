import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/conspect.dart';

/// Локальный сервис кеширования готовых методических уроков.
/// Исключает повторные затраты токенов YandexGPT Pro при повторном открытии
/// или генерации урока с идентичными параметрами.
class LessonCacheService {
  static final Map<String, Conspect> _memoryCache = {};

  /// Формирует стабильный MD5-хэш входных параметров урока
  static String computeCacheKey({
    required String methodId,
    required String topic,
    required String ageGroup,
    required String duration,
    bool isDeepLesson = true,
    List<String>? materials,
  }) {
    final cleanTopic = topic.trim().toLowerCase();
    final cleanAge = ageGroup.trim().toLowerCase();
    final cleanDuration = duration.trim().toLowerCase();
    final sortedMats = (materials != null ? (List<String>.from(materials)..sort()) : ['conspect']).join(',');

    final rawKey = '$methodId|$cleanTopic|$cleanAge|$cleanDuration|$isDeepLesson|$sortedMats';
    final bytes = utf8.encode(rawKey);
    return md5.convert(bytes).toString();
  }

  /// Получение урока из кеша (если существует)
  static Conspect? get(String cacheKey) {
    return _memoryCache[cacheKey];
  }

  /// Сохранение урока в кеш
  static void put(String cacheKey, Conspect conspect) {
    _memoryCache[cacheKey] = conspect;
  }

  /// Проверка наличия в кеше
  static bool contains(String cacheKey) {
    return _memoryCache.containsKey(cacheKey);
  }

  /// Очистка кеша
  static void clear() {
    _memoryCache.clear();
  }

  /// Количество закешированных уроков
  static int get count => _memoryCache.length;
}
