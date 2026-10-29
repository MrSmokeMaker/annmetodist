import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class YandexArtService {
  final StorageService _storageService;
  final http.Client _client;

  YandexArtService({
    StorageService? storageService,
    http.Client? client,
  })  : _storageService = storageService ?? StorageService(),
        _client = client ?? http.Client();

  /// Генерация иллюстрации для дидактической карточки
  Future<String?> generateCardIllustration(String hint, {String? word}) async {
    final query = hint.trim().isNotEmpty ? hint : (word ?? 'учебный предмет');
    final prompt = 'детская обучающая карточка, рисунок: $query, чистый белый фон, векторная книжная графика, яркие сочные цвета, четкие контуры, изолировано, без текста';
    return generateImage(prompt: prompt, widthRatio: 1, heightRatio: 1, type: 'card', label: query);
  }

  /// Генерация маскота-персонажа для шапки конспекта и рабочего листа
  Future<String?> generateMascotBanner(String topic, String ageGroup) async {
    final prompt = 'детский персонаж маскот учитель для урока на тему "$topic" для детей $ageGroup, дружелюбный мультяшный герой с книгой или указкой, чистый белый фон, детская книжная иллюстрация, яркие цвета';
    return generateImage(prompt: prompt, widthRatio: 1, heightRatio: 1, type: 'mascot', label: topic);
  }

  /// Генерация контурного задания-раскраски для рабочего листа
  Future<String?> generateColoringActivity(String topic) async {
    final prompt = 'детская контурная раскраска для урока "$topic", четкие черные контуры, белый фон, без заливки, контурный рисунок для раскрашивания карандашами, книжная графика для детей';
    return generateImage(prompt: prompt, widthRatio: 4, heightRatio: 3, type: 'coloring', label: topic);
  }

  /// Генерация наградной медали/стикера для домашней работы
  Future<String?> generateRewardSticker(String topic) async {
    final prompt = 'круглая наградная медаль стикер для детей за отличную учебу на тему "$topic", золотая звездочка, яркая лента, знак отличия, мультяшный стиль, чистый белый фон';
    return generateImage(prompt: prompt, widthRatio: 1, heightRatio: 1, type: 'reward', label: 'Молодец!');
  }

  /// Базовый метод генерации изображения через прокси YandexART с fallback-генератором
  Future<String?> generateImage({
    required String prompt,
    int widthRatio = 1,
    int heightRatio = 1,
    String type = 'card',
    String label = '',
    bool allowFallback = true,
  }) async {
    try {
      final proxyUrl = await _storageService.getProxyUrl();
      if (proxyUrl != null && proxyUrl.isNotEmpty) {
        final uri = Uri.parse(proxyUrl);
        final payload = jsonEncode({
          'action': 'generate_image',
          'prompt': prompt,
          'aspectRatio': {
            'widthRatio': widthRatio,
            'heightRatio': heightRatio,
          },
        });

        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map) {
            // Если генерация завершена на стороне прокси
            if (data['done'] == true && data['image'] != null && data['image'].toString().isNotEmpty) {
              return data['image'].toString();
            }

            // Если операция еще выполняется, опрашиваем get_operation
            final operationId = data['operationId']?.toString();
            if (operationId != null && operationId.isNotEmpty) {
              final polledImage = await _pollOperation(uri, operationId);
              if (polledImage != null) return polledImage;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('YandexArtService network/proxy call error: $e');
    }

    // Если сеть недоступна или прокси еще не обновлен, генерируем векторный обучающий арт
    if (allowFallback) {
      return await generateFallbackEducationalArt(
        type: type,
        label: label.isNotEmpty ? label : prompt,
        width: widthRatio == 4 ? 320 : 240,
        height: heightRatio == 3 ? 240 : 240,
      );
    }
    return null;
  }

  /// Опрос статуса операции YandexART
  Future<String?> _pollOperation(Uri uri, String operationId) async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final res = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'action': 'get_operation',
                'operationId': operationId,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data is Map && data['done'] == true && data['image'] != null) {
            return data['image'].toString();
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Высококачественный векторный арт-генератор на чистом Canvas
  static Future<String> generateFallbackEducationalArt({
    required String type,
    required String label,
    int width = 240,
    int height = 240,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      // Белый фон (для экономии чернил и чистоты печати)
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

      // Рамка карточки
      final borderPaint = Paint()
        ..color = type == 'reward'
            ? const Color(0xFFF59E0B)
            : (type == 'coloring' ? const Color(0xFF374151) : const Color(0xFF6366F1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = type == 'coloring' ? 2.0 : 1.5;

      final RRect outerRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, width.toDouble() - 12, height.toDouble() - 12),
        const Radius.circular(16),
      );
      canvas.drawRRect(outerRRect, borderPaint);

      // Внутренняя подложка
      final innerBgPaint = Paint()
        ..color = type == 'reward'
            ? const Color(0xFFFEF3C7)
            : (type == 'coloring' ? const Color(0xFFF9FAFB) : const Color(0xFFEEF2FF));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 10, width.toDouble() - 20, height.toDouble() - 20),
          const Radius.circular(12),
        ),
        innerBgPaint,
      );

      // Отрисовка центрального тематического элемента
      final centerPaint = Paint()..style = PaintingStyle.fill;
      final cx = width / 2;
      final cy = height / 2 - 12;

      if (type == 'reward') {
        // Золотая медаль
        centerPaint.color = const Color(0xFFFBBF24);
        canvas.drawCircle(Offset(cx, cy), 42, centerPaint);
        centerPaint.color = const Color(0xFFD97706);
        canvas.drawCircle(Offset(cx, cy), 34, centerPaint);

        // Звездочка
        final starPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx, cy), 14, starPaint);
      } else if (type == 'coloring') {
        // Контурные геометрические фигуры для раскрашивания
        final contourPaint = Paint()
          ..color = const Color(0xFF1F2937)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        canvas.drawCircle(Offset(cx - 35, cy), 25, contourPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + 35, cy), width: 45, height: 45), contourPaint);
      } else if (type == 'mascot') {
        // Персонаж/маскот (сова / котик / книга)
        centerPaint.color = const Color(0xFF4F46E5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 64, height: 50),
            const Radius.circular(12),
          ),
          centerPaint,
        );
        // Глазки
        final eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx - 15, cy - 6), 7, eyePaint);
        canvas.drawCircle(Offset(cx + 15, cy - 6), 7, eyePaint);
        eyePaint.color = const Color(0xFF1E1B4B);
        canvas.drawCircle(Offset(cx - 15, cy - 6), 3, eyePaint);
        canvas.drawCircle(Offset(cx + 15, cy - 6), 3, eyePaint);
      } else {
        // Карточка: акцентная фигура
        centerPaint.color = const Color(0xFF818CF8);
        canvas.drawCircle(Offset(cx, cy), 38, centerPaint);
        centerPaint.color = Colors.white;
        canvas.drawCircle(Offset(cx, cy), 28, centerPaint);
      }

      // Текстовая подпись
      final textPainter = TextPainter(
        text: TextSpan(
          text: label.length > 24 ? '${label.substring(0, 22)}...' : label,
          style: TextStyle(
            color: type == 'coloring' ? const Color(0xFF111827) : const Color(0xFF312E81),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 24.0);
      textPainter.paint(canvas, Offset((width - textPainter.width) / 2, height - 38.0));

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return base64Encode(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Fallback canvas generation error: $e');
    }

    // Минимальный резервный 1x1 белый PNG
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
  }
}
