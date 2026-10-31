import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/thematic_world.dart';

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

  /// Генерация панорамной шапки для тематического мира (аспект 4:1)
  Future<String?> generateWorldBanner(ThematicWorld world, String topic) async {
    final prompt = '${world.bannerPrompt}, тема урока "$topic"';
    return generateImage(
      prompt: prompt,
      widthRatio: 4,
      heightRatio: 1,
      type: 'world_banner_${world.id}',
      label: world.title,
    );
  }

  /// Генерация значка маскота тематического мира (аспект 1:1)
  Future<String?> generateWorldMascot(ThematicWorld world) async {
    return generateImage(
      prompt: world.mascotPrompt,
      widthRatio: 1,
      heightRatio: 1,
      type: 'world_mascot_${world.id}',
      label: world.mascotName,
    );
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
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map) {
            if (data['done'] == true && data['image'] != null && data['image'].toString().isNotEmpty) {
              return data['image'].toString();
            }

            final operationId = data['operationId']?.toString();
            if (operationId != null && operationId.isNotEmpty) {
              final polledImage = await _pollOperation(uri, operationId);
              if (polledImage != null) return polledImage;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('YandexArtService network call info: $e');
    }

    if (allowFallback) {
      return await generateFallbackEducationalArt(
        type: type,
        label: label.isNotEmpty ? label : prompt,
        width: widthRatio == 4 && heightRatio == 1 ? 640 : (widthRatio == 4 ? 320 : 260),
        height: widthRatio == 4 && heightRatio == 1 ? 160 : (heightRatio == 3 ? 240 : 260),
      );
    }
    return null;
  }

  /// Опрос статуса операции YandexART
  Future<String?> _pollOperation(Uri uri, String operationId) async {
    for (int i = 0; i < 6; i++) {
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
            .timeout(const Duration(seconds: 8));

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
    int width = 260,
    int height = 260,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      // 1. Белый фон для идеальной чистоты печати
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

      final cx = width / 2;
      final cy = height / 2 - 14;

      if (type.startsWith('world_banner')) {
        _drawWorldBanner(canvas, width.toDouble(), height.toDouble(), type);
      } else if (type.startsWith('world_mascot')) {
        _drawWorldMascot(canvas, cx, cy, type);
      } else if (type == 'reward') {
        _drawRewardMedal(canvas, cx, cy);
      } else if (type == 'coloring') {
        _drawColoringShapes(canvas, cx, cy);
      } else if (type == 'mascot') {
        _drawMascotTeacher(canvas, cx, cy);
      } else {
        // Обучающая иллюстрация для карточки по содержанию label
        _drawCardArtwork(canvas, cx, cy, label);
      }

      if (!type.startsWith('world_banner') && !type.startsWith('world_mascot')) {
        // Текстовая подпись внизу
      final cleanLabel = label.replaceAll(RegExp(r'^(?:💡|рисунок|карточка|изображение)[:\s]*', caseSensitive: false), '').trim();
      final displayLabel = cleanLabel.isNotEmpty ? cleanLabel : label;
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayLabel.length > 22 ? '${displayLabel.substring(0, 20)}...' : displayLabel,
          style: TextStyle(
            color: type == 'coloring' ? const Color(0xFF1F2937) : const Color(0xFF1E1B4B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 24.0);
      textPainter.paint(canvas, Offset((width - textPainter.width) / 2, height - 32.0));
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return base64Encode(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Fallback canvas generation error: $e');
    }

    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
  }

  // =========================================================================
  // Стилизованные векторные иллюстраторы для дошкольников и 1-2 классов
  // =========================================================================

  static void _drawCardArtwork(Canvas canvas, double cx, double cy, String label) {
    final lower = label.toLowerCase();

    // 1. Котик / кот / кошка
    if (lower.contains('кот') || lower.contains('кош') || lower.contains('котен')) {
      _drawCuteCat(canvas, cx, cy);
      return;
    }

    // 2. Аист / птица
    if (lower.contains('аист') || lower.contains('птиц') || lower.contains('воробей') || lower.contains('ласточк')) {
      _drawStorkBird(canvas, cx, cy);
      return;
    }

    // 3. Дом / домик
    if (lower.contains('дом') || lower.contains('здание') || lower.contains('теремок')) {
      _drawHouse(canvas, cx, cy);
      return;
    }

    // 4. Солнце
    if (lower.contains('солн') || lower.contains('лучик')) {
      _drawSun(canvas, cx, cy);
      return;
    }

    // 5. Дерево / лес
    if (lower.contains('дерев') || lower.contains('дуб') || lower.contains('берез') || lower.contains('лес')) {
      _drawTree(canvas, cx, cy);
      return;
    }

    // 6. Яблоко / фрукт
    if (lower.contains('яблок') || lower.contains('груш') || lower.contains('фрукт')) {
      _drawApple(canvas, cx, cy);
      return;
    }

    // 7. Рыба
    if (lower.contains('рыб') || lower.contains('окунь') || lower.contains('щук')) {
      _drawFish(canvas, cx, cy);
      return;
    }

    // 8. Цветок
    if (lower.contains('цвет') || lower.contains('ромашк') || lower.contains('тюльпан')) {
      _drawFlower(canvas, cx, cy);
      return;
    }

    // 9. Книга
    if (lower.contains('книг') || lower.contains('буквар') || lower.contains('азбук') || lower.contains('учебник')) {
      _drawBook(canvas, cx, cy);
      return;
    }

    // 10. Мяч
    if (lower.contains('мяч') || lower.contains('шар') || lower.contains('игра')) {
      _drawBall(canvas, cx, cy);
      return;
    }

    // 11. Одиночная буква (например А, О, К, М, У...)
    final clean = label.trim().replaceAll(RegExp(r'[^а-яёА-ЯЁa-zA-Z0-9]'), '');
    if (clean.length == 1 || clean.length == 2) {
      _drawBigLetterBadge(canvas, cx, cy, clean.toUpperCase());
      return;
    }

    // 12. Универсальная привлекательная карточка со звездой и эмблемой
    _drawUniversalEducationalEmblem(canvas, cx, cy, label);
  }

  // --- Милый котик ---
  static void _drawCuteCat(Canvas canvas, double cx, double cy) {
    final headPaint = Paint()..color = const Color(0xFFF97316); // Рыжий
    final earInsidePaint = Paint()..color = const Color(0xFFFCA5A5);
    final strokePaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Ушки
    final leftEar = Path()
      ..moveTo(cx - 42, cy - 10)
      ..lineTo(cx - 36, cy - 52)
      ..lineTo(cx - 10, cy - 35)
      ..close();
    final rightEar = Path()
      ..moveTo(cx + 42, cy - 10)
      ..lineTo(cx + 36, cy - 52)
      ..lineTo(cx + 10, cy - 35)
      ..close();
    canvas.drawPath(leftEar, headPaint);
    canvas.drawPath(leftEar, strokePaint);
    canvas.drawPath(rightEar, headPaint);
    canvas.drawPath(rightEar, strokePaint);

    // Внутренние треугольнички ушек
    final leftInner = Path()
      ..moveTo(cx - 38, cy - 14)
      ..lineTo(cx - 34, cy - 44)
      ..lineTo(cx - 15, cy - 33)
      ..close();
    final rightInner = Path()
      ..moveTo(cx + 38, cy - 14)
      ..lineTo(cx + 34, cy - 44)
      ..lineTo(cx + 15, cy - 33)
      ..close();
    canvas.drawPath(leftInner, earInsidePaint);
    canvas.drawPath(rightInner, earInsidePaint);

    // Голова
    canvas.drawCircle(Offset(cx, cy), 42, headPaint);
    canvas.drawCircle(Offset(cx, cy), 42, strokePaint);

    // Белые щечки
    final cheekPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 14, cy + 12), 16, cheekPaint);
    canvas.drawCircle(Offset(cx + 14, cy + 12), 16, cheekPaint);

    // Глазки
    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    final glintPaint = Paint()..color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 16, cy - 4), width: 14, height: 18), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 16, cy - 4), width: 14, height: 18), eyePaint);
    canvas.drawCircle(Offset(cx - 18, cy - 7), 3.5, glintPaint);
    canvas.drawCircle(Offset(cx + 14, cy - 7), 3.5, glintPaint);

    // Носик
    final nosePaint = Paint()..color = const Color(0xFFEF4444);
    final nosePath = Path()
      ..moveTo(cx - 6, cy + 8)
      ..lineTo(cx + 6, cy + 8)
      ..lineTo(cx, cy + 14)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Усики
    final whiskerPaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cx - 24, cy + 10), Offset(cx - 52, cy + 6), whiskerPaint);
    canvas.drawLine(Offset(cx - 24, cy + 15), Offset(cx - 50, cy + 18), whiskerPaint);
    canvas.drawLine(Offset(cx + 24, cy + 10), Offset(cx + 52, cy + 6), whiskerPaint);
    canvas.drawLine(Offset(cx + 24, cy + 15), Offset(cx + 50, cy + 18), whiskerPaint);
  }

  // --- Аист / птичка ---
  static void _drawStorkBird(Canvas canvas, double cx, double cy) {
    final bodyPaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Шея и туловище
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10), width: 54, height: 42), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10), width: 54, height: 42), strokePaint);

    // Черное крыло с перышками
    final wingPaint = Paint()..color = const Color(0xFF334155);
    final wingPath = Path()
      ..moveTo(cx - 16, cy + 4)
      ..quadraticBezierTo(cx + 18, cy - 4, cx + 28, cy + 16)
      ..quadraticBezierTo(cx + 8, cy + 28, cx - 16, cy + 4)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    // Голова
    canvas.drawCircle(Offset(cx - 22, cy - 24), 18, bodyPaint);
    canvas.drawCircle(Offset(cx - 22, cy - 24), 18, strokePaint);

    // Глаз
    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(cx - 24, cy - 26), 4, eyePaint);
    canvas.drawCircle(Offset(cx - 25, cy - 28), 1.5, Paint()..color = Colors.white);

    // Длинный красный клюв аиста
    final beakPaint = Paint()..color = const Color(0xFFEA580C);
    final beakPath = Path()
      ..moveTo(cx - 36, cy - 26)
      ..lineTo(cx - 68, cy - 21)
      ..lineTo(cx - 36, cy - 19)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    canvas.drawPath(beakPath, strokePaint);

    // Ножки
    final legPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(cx - 6, cy + 30), Offset(cx - 6, cy + 54), legPaint);
    canvas.drawLine(Offset(cx + 8, cy + 30), Offset(cx + 8, cy + 54), legPaint);
  }

  // --- Домик ---
  static void _drawHouse(Canvas canvas, double cx, double cy) {
    final wallPaint = Paint()..color = const Color(0xFFFDE047);
    final strokePaint = Paint()
      ..color = const Color(0xFF854D0E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Стены
    final wallRect = Rect.fromCenter(center: Offset(cx, cy + 15), width: 68, height: 55);
    canvas.drawRRect(RRect.fromRectAndRadius(wallRect, const Radius.circular(6)), wallPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(wallRect, const Radius.circular(6)), strokePaint);

    // Труба
    final chimneyPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawRect(Rect.fromLTWH(cx + 14, cy - 42, 14, 25), chimneyPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 14, cy - 42, 14, 25), strokePaint);

    // Крыша
    final roofPaint = Paint()..color = const Color(0xFFDC2626);
    final roofPath = Path()
      ..moveTo(cx - 44, cy - 10)
      ..lineTo(cx, cy - 46)
      ..lineTo(cx + 44, cy - 10)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
    canvas.drawPath(roofPath, strokePaint);

    // Окошко с рамой
    final windowPaint = Paint()..color = const Color(0xFF38BDF8);
    final windowRect = Rect.fromCenter(center: Offset(cx - 14, cy + 12), width: 22, height: 22);
    canvas.drawRect(windowRect, windowPaint);
    canvas.drawRect(windowRect, strokePaint);
    canvas.drawLine(Offset(cx - 14, cy + 1), Offset(cx - 14, cy + 23), strokePaint);
    canvas.drawLine(Offset(cx - 25, cy + 12), Offset(cx - 3, cy + 12), strokePaint);

    // Дверь
    final doorPaint = Paint()..color = const Color(0xFFB45309);
    final doorRect = Rect.fromLTWH(cx + 6, cy + 8, 20, 34);
    canvas.drawRect(doorRect, doorPaint);
    canvas.drawRect(doorRect, strokePaint);
    canvas.drawCircle(Offset(cx + 22, cy + 25), 2.5, Paint()..color = const Color(0xFFFDE047));
  }

  // --- Солнышко ---
  static void _drawSun(Canvas canvas, double cx, double cy) {
    final sunPaint = Paint()..color = const Color(0xFFFBBF24);
    final rayPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Лучи
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final x1 = cx + math.cos(angle) * 36;
      final y1 = cy + math.sin(angle) * 36;
      final x2 = cx + math.cos(angle) * 52;
      final y2 = cy + math.sin(angle) * 52;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    // Круг
    canvas.drawCircle(Offset(cx, cy), 32, sunPaint);
    canvas.drawCircle(Offset(cx, cy), 32, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Улыбка и глазки
    final eyePaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawCircle(Offset(cx - 10, cy - 6), 3.5, eyePaint);
    canvas.drawCircle(Offset(cx + 10, cy - 6), 3.5, eyePaint);

    final smilePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + 6), width: 22, height: 16), 0.2, math.pi - 0.4, false, smilePaint);
  }

  // --- Дерево ---
  static void _drawTree(Canvas canvas, double cx, double cy) {
    // Ствол
    final trunkPaint = Paint()..color = const Color(0xFF92400E);
    final trunkPath = Path()
      ..moveTo(cx - 10, cy + 48)
      ..lineTo(cx - 7, cy + 8)
      ..lineTo(cx + 7, cy + 8)
      ..lineTo(cx + 10, cy + 48)
      ..close();
    canvas.drawPath(trunkPath, trunkPaint);

    // Листва (зеленые облака)
    final leafPaint = Paint()..color = const Color(0xFF22C55E);
    final strokePaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(cx, cy - 14), 28, leafPaint);
    canvas.drawCircle(Offset(cx - 22, cy + 4), 22, leafPaint);
    canvas.drawCircle(Offset(cx + 22, cy + 4), 22, leafPaint);
    canvas.drawCircle(Offset(cx, cy + 12), 24, leafPaint);

    canvas.drawCircle(Offset(cx, cy - 14), 28, strokePaint);
    canvas.drawCircle(Offset(cx - 22, cy + 4), 22, strokePaint);
    canvas.drawCircle(Offset(cx + 22, cy + 4), 22, strokePaint);

    // Красные яблочки
    final applePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(Offset(cx - 10, cy - 4), 5, applePaint);
    canvas.drawCircle(Offset(cx + 14, cy - 8), 5, applePaint);
    canvas.drawCircle(Offset(cx + 6, cy + 12), 5, applePaint);
  }

  // --- Яблоко ---
  static void _drawApple(Canvas canvas, double cx, double cy) {
    final applePaint = Paint()..color = const Color(0xFFEF4444);
    final strokePaint = Paint()..color = const Color(0xFF991B1B)..style = PaintingStyle.stroke..strokeWidth = 2.5;

    canvas.drawCircle(Offset(cx - 14, cy + 4), 28, applePaint);
    canvas.drawCircle(Offset(cx + 14, cy + 4), 28, applePaint);
    canvas.drawCircle(Offset(cx - 14, cy + 4), 28, strokePaint);
    canvas.drawCircle(Offset(cx + 14, cy + 4), 28, strokePaint);

    // Черенок
    final stemPaint = Paint()..color = const Color(0xFF78350F)..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 24), Offset(cx - 4, cy - 42), stemPaint);

    // Зеленый листочек
    final leafPaint = Paint()..color = const Color(0xFF22C55E);
    final leafPath = Path()
      ..moveTo(cx - 2, cy - 36)
      ..quadraticBezierTo(cx + 20, cy - 46, cx + 24, cy - 34)
      ..quadraticBezierTo(cx + 14, cy - 24, cx - 2, cy - 36)
      ..close();
    canvas.drawPath(leafPath, leafPaint);
  }

  // --- Рыбка ---
  static void _drawFish(Canvas canvas, double cx, double cy) {
    final fishPaint = Paint()..color = const Color(0xFF38BDF8);
    final strokePaint = Paint()..color = const Color(0xFF0284C7)..style = PaintingStyle.stroke..strokeWidth = 2.5;

    // Хвостик
    final tailPath = Path()
      ..moveTo(cx + 24, cy)
      ..lineTo(cx + 52, cy - 24)
      ..lineTo(cx + 44, cy)
      ..lineTo(cx + 52, cy + 24)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFFF97316));
    canvas.drawPath(tailPath, strokePaint);

    // Тельце
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 6, cy), width: 62, height: 42), fishPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 6, cy), width: 62, height: 42), strokePaint);

    // Глаз
    canvas.drawCircle(Offset(cx - 22, cy - 6), 5, Colors.white as Paint? ?? Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - 23, cy - 6), 3, Paint()..color = const Color(0xFF0F172A));

    // Улыбка
    final smilePaint = Paint()..color = const Color(0xFF0284C7)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 30, cy + 2), width: 10, height: 8), 0, math.pi, false, smilePaint);
  }

  // --- Цветок ---
  static void _drawFlower(Canvas canvas, double cx, double cy) {
    // Стебель и листья
    final stemPaint = Paint()..color = const Color(0xFF16A34A)..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy + 12), Offset(cx, cy + 52), stemPaint);

    final petalPaint = Paint()..color = const Color(0xFFEC4899);
    for (int i = 0; i < 6; i++) {
      final angle = i * (math.pi / 3);
      final px = cx + math.cos(angle) * 22;
      final py = cy + math.sin(angle) * 22;
      canvas.drawCircle(Offset(px, py), 16, petalPaint);
      canvas.drawCircle(Offset(px, py), 16, Paint()..color = const Color(0xFFBE185D)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Серединка
    canvas.drawCircle(Offset(cx, cy), 16, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(Offset(cx, cy), 16, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  // --- Книга ---
  static void _drawBook(Canvas canvas, double cx, double cy) {
    final bookPaint = Paint()..color = const Color(0xFF6366F1);
    final pagePaint = Paint()..color = Colors.white;
    final strokePaint = Paint()..color = const Color(0xFF312E81)..style = PaintingStyle.stroke..strokeWidth = 2.5;

    final leftPage = Rect.fromLTWH(cx - 44, cy - 24, 42, 54);
    final rightPage = Rect.fromLTWH(cx + 2, cy - 24, 42, 54);

    canvas.drawRRect(RRect.fromRectAndRadius(leftPage.inflate(3), const Radius.circular(4)), bookPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightPage.inflate(3), const Radius.circular(4)), bookPaint);

    canvas.drawRect(leftPage, pagePaint);
    canvas.drawRect(rightPage, pagePaint);
    canvas.drawRect(leftPage, strokePaint);
    canvas.drawRect(rightPage, strokePaint);

    // Строки текста
    final linePaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 2.5;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(cx - 36, cy - 14 + i * 11), Offset(cx - 10, cy - 14 + i * 11), linePaint);
      canvas.drawLine(Offset(cx + 10, cy - 14 + i * 11), Offset(cx + 36, cy - 14 + i * 11), linePaint);
    }
  }

  // --- Мяч ---
  static void _drawBall(Canvas canvas, double cx, double cy) {
    final ballPaint = Paint()..color = const Color(0xFFEF4444);
    final strokePaint = Paint()..color = const Color(0xFF991B1B)..style = PaintingStyle.stroke..strokeWidth = 2.5;

    canvas.drawCircle(Offset(cx, cy), 38, ballPaint);
    canvas.drawCircle(Offset(cx, cy), 38, strokePaint);

    final stripePaint = Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.stroke..strokeWidth = 12;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: 76, height: 76), -0.8, 1.6, false, stripePaint);
  }

  // --- Крупная 3D обучающая буква ---
  static void _drawBigLetterBadge(Canvas canvas, double cx, double cy, String letter) {
    final bgPaint = Paint()..color = const Color(0xFFEEF2FF);
    final strokePaint = Paint()..color = const Color(0xFF6366F1)..style = PaintingStyle.stroke..strokeWidth = 3;

    final badgeRect = Rect.fromCenter(center: Offset(cx, cy), width: 96, height: 96);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(24)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(24)), strokePaint);

    // 3D Тень буквы
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          color: Color(0xFFC7D2FE),
          fontSize: 56,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    shadowPainter.layout();
    shadowPainter.paint(canvas, Offset(cx - shadowPainter.width / 2 + 3, cy - shadowPainter.height / 2 + 3));

    // Сама буква
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          color: Color(0xFF4F46E5),
          fontSize: 56,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
  }

  // --- Универсальная карточка с сияющей звездой ---
  static void _drawUniversalEducationalEmblem(Canvas canvas, double cx, double cy, String label) {
    final bgPaint = Paint()..color = const Color(0xFFF0FDF4);
    final strokePaint = Paint()..color = const Color(0xFF22C55E)..style = PaintingStyle.stroke..strokeWidth = 2.5;

    final badgeRect = Rect.fromCenter(center: Offset(cx, cy), width: 88, height: 88);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(20)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(20)), strokePaint);

    // Золотая звездочка в центре
    final starPaint = Paint()..color = const Color(0xFFEAB308);
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;
      final ox = cx + math.cos(outerAngle) * 26;
      final oy = cy + math.sin(outerAngle) * 26;
      final ix = cx + math.cos(innerAngle) * 12;
      final iy = cy + math.sin(innerAngle) * 12;
      if (i == 0) {
        starPath.moveTo(ox, oy);
      } else {
        starPath.lineTo(ox, oy);
      }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);
    canvas.drawPath(starPath, Paint()..color = const Color(0xFFCA8A04)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  // --- Маскот Сова-Учитель ---
  static void _drawMascotTeacher(Canvas canvas, double cx, double cy) {
    // Тельце совы
    final bodyPaint = Paint()..color = const Color(0xFF4F46E5);
    final strokePaint = Paint()..color = const Color(0xFF312E81)..style = PaintingStyle.stroke..strokeWidth = 2.5;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 72, height: 84), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 72, height: 84), strokePaint);

    // Белое брюшко
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 14), width: 44, height: 52), Paint()..color = const Color(0xFFEEF2FF));

    // Огромные круглые глаза
    canvas.drawCircle(Offset(cx - 16, cy - 10), 16, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 16, cy - 10), 16, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - 16, cy - 10), 16, strokePaint);
    canvas.drawCircle(Offset(cx + 16, cy - 10), 16, strokePaint);

    // Зрачки
    canvas.drawCircle(Offset(cx - 14, cy - 10), 8, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(Offset(cx + 14, cy - 10), 8, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(Offset(cx - 16, cy - 12), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 12, cy - 12), 2.5, Paint()..color = Colors.white);

    // Клювик
    final beakPath = Path()
      ..moveTo(cx - 6, cy)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 10)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFF59E0B));

    // Шапочка бакалавра
    final capPath = Path()
      ..moveTo(cx, cy - 48)
      ..lineTo(cx + 34, cy - 36)
      ..lineTo(cx, cy - 24)
      ..lineTo(cx - 34, cy - 36)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFF1E1B4B));
  }

  // --- Наградная медаль ---
  static void _drawRewardMedal(Canvas canvas, double cx, double cy) {
    // Ленточки
    final ribbonPaint = Paint()..color = const Color(0xFFDC2626);
    final leftRibbon = Path()
      ..moveTo(cx - 14, cy + 18)
      ..lineTo(cx - 32, cy + 68)
      ..lineTo(cx - 18, cy + 62)
      ..lineTo(cx - 6, cy + 68)
      ..lineTo(cx - 4, cy + 22)
      ..close();
    final rightRibbon = Path()
      ..moveTo(cx + 14, cy + 18)
      ..lineTo(cx + 32, cy + 68)
      ..lineTo(cx + 18, cy + 62)
      ..lineTo(cx + 6, cy + 68)
      ..lineTo(cx + 4, cy + 22)
      ..close();
    canvas.drawPath(leftRibbon, ribbonPaint);
    canvas.drawPath(rightRibbon, ribbonPaint);

    // Золотой диск
    canvas.drawCircle(Offset(cx, cy), 46, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(Offset(cx, cy), 46, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 36, Paint()..color = const Color(0xFFF59E0B));

    // Звезда на медали
    final starPaint = Paint()..color = Colors.white;
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;
      final ox = cx + math.cos(outerAngle) * 20;
      final oy = cy + math.sin(outerAngle) * 20;
      final ix = cx + math.cos(innerAngle) * 9;
      final iy = cy + math.sin(innerAngle) * 9;
      if (i == 0) { starPath.moveTo(ox, oy); } else { starPath.lineTo(ox, oy); }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);
  }

  // --- Раскраска (черно-белые контуры) ---
  static void _drawColoringShapes(Canvas canvas, double cx, double cy) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Контурный домик и солнышко для раскрашивания
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 14), width: 64, height: 50), strokePaint);
    final roof = Path()
      ..moveTo(cx - 40, cy - 11)
      ..lineTo(cx, cy - 44)
      ..lineTo(cx + 40, cy - 11)
      ..close();
    canvas.drawPath(roof, strokePaint);

    canvas.drawCircle(Offset(cx - 70, cy - 30), 22, strokePaint);
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        Offset(cx - 70 + math.cos(a) * 26, cy - 30 + math.sin(a) * 26),
        Offset(cx - 70 + math.cos(a) * 36, cy - 30 + math.sin(a) * 36),
        strokePaint,
      );
    }
  }

  // =========================================================================
  // Панорамные иллюстрации 5 миров (YandexART Panoramic Banners)
  // =========================================================================

  static void _drawWorldBanner(Canvas canvas, double width, double height, String type) {
    if (type.contains('space')) {
      _drawSpaceBanner(canvas, width, height);
    } else if (type.contains('forest')) {
      _drawForestBanner(canvas, width, height);
    } else if (type.contains('detective')) {
      _drawDetectiveBanner(canvas, width, height);
    } else if (type.contains('workshop')) {
      _drawWorkshopBanner(canvas, width, height);
    } else {
      _drawMeadowBanner(canvas, width, height);
    }
  }

  static void _drawSpaceBanner(Canvas canvas, double width, double height) {
    // 1. Космический глубокий градиент
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width, height),
        [const Color(0xFF090A1A), const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4C1D95)],
        [0.0, 0.33, 0.66, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. Туманности
    final nebulaPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(width * 0.75, height * 0.4), 60, nebulaPaint);
    final nebulaPink = Paint()
      ..color = const Color(0xFFEC4899).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    canvas.drawCircle(Offset(width * 0.25, height * 0.6), 55, nebulaPink);

    // 3. Звезды
    final starPaint = Paint()..color = Colors.white;
    final starGlow = Paint()..color = const Color(0xFFFDE047);
    final starCoords = [
      Offset(width * 0.08, height * 0.3), Offset(width * 0.15, height * 0.7),
      Offset(width * 0.22, height * 0.2), Offset(width * 0.35, height * 0.5),
      Offset(width * 0.45, height * 0.25), Offset(width * 0.55, height * 0.8),
      Offset(width * 0.62, height * 0.35), Offset(width * 0.72, height * 0.65),
      Offset(width * 0.82, height * 0.22), Offset(width * 0.92, height * 0.45),
      Offset(width * 0.96, height * 0.75), Offset(width * 0.50, height * 0.15),
    ];
    for (int i = 0; i < starCoords.length; i++) {
      final pt = starCoords[i];
      final r = (i % 3 == 0) ? 2.5 : 1.5;
      canvas.drawCircle(pt, r, (i % 2 == 0) ? starGlow : starPaint);
      if (i % 4 == 0) {
        // 4-конечная лучистая звездочка
        canvas.drawLine(Offset(pt.dx - 5, pt.dy), Offset(pt.dx + 5, pt.dy), starPaint..strokeWidth = 1.0);
        canvas.drawLine(Offset(pt.dx, pt.dy - 5), Offset(pt.dx, pt.dy + 5), starPaint..strokeWidth = 1.0);
      }
    }

    // 4. Планета Сатурн справа
    final planetCenter = Offset(width * 0.85, height * 0.45);
    final planetPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(planetCenter, 22, planetPaint);
    final planetShadow = Paint()..color = const Color(0xFFD97706);
    canvas.drawArc(Rect.fromCircle(center: planetCenter, radius: 22), 0.5, math.pi, true, planetShadow);
    // Кольцо планеты
    final ringPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(const Rect.fromLTWH(-36, -8, 72, 16), ringPaint);
    canvas.restore();

    // 5. Луна / Месяц слева
    final moonCenter = Offset(width * 0.12, height * 0.35);
    final moonPaint = Paint()..color = const Color(0xFFFEF08A);
    final moonPath = Path()
      ..addArc(Rect.fromCircle(center: moonCenter, radius: 18), -math.pi / 2, math.pi * 1.5)
      ..arcTo(Rect.fromCircle(center: Offset(moonCenter.dx + 8, moonCenter.dy), radius: 15), math.pi, -math.pi, false)
      ..close();
    canvas.drawPath(moonPath, moonPaint);

    // 6. Ракета
    final rocketX = width * 0.65;
    final rocketY = height * 0.50;
    canvas.save();
    canvas.translate(rocketX, rocketY);
    canvas.rotate(-0.4);

    // Огонь из сопла
    final flamePaint = Paint()..color = const Color(0xFFEF4444);
    final flamePath = Path()
      ..moveTo(-18, 0)
      ..lineTo(-32, -6)
      ..lineTo(-26, 0)
      ..lineTo(-34, 6)
      ..close();
    canvas.drawPath(flamePath, flamePaint);
    final innerFlame = Path()
      ..moveTo(-18, 0)
      ..lineTo(-25, -3)
      ..lineTo(-22, 0)
      ..lineTo(-27, 3)
      ..close();
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFBBF24));

    // Корпус ракеты
    final bodyPath = Path()
      ..moveTo(22, 0)
      ..quadraticBezierTo(0, -11, -16, -9)
      ..lineTo(-16, 9)
      ..quadraticBezierTo(0, 11, 22, 0)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = Colors.white);

    // Носовой конус
    final nosePath = Path()
      ..moveTo(22, 0)
      ..quadraticBezierTo(12, -7, 6, -6)
      ..lineTo(6, 6)
      ..quadraticBezierTo(12, 7, 22, 0)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFEF4444));

    // Иллюминатор
    canvas.drawCircle(const Offset(3, 0), 5, Paint()..color = const Color(0xFF0284C7));
    canvas.drawCircle(const Offset(3, 0), 3.5, Paint()..color = const Color(0xFF38BDF8));

    // Крылья
    final wingTop = Path()..moveTo(-6, -8)..lineTo(-15, -18)..lineTo(-16, -7)..close();
    final wingBottom = Path()..moveTo(-6, 8)..lineTo(-15, 18)..lineTo(-16, 7)..close();
    canvas.drawPath(wingTop, Paint()..color = const Color(0xFFDC2626));
    canvas.drawPath(wingBottom, Paint()..color = const Color(0xFFDC2626));
    canvas.restore();
  }

  static void _drawForestBanner(Canvas canvas, double width, double height) {
    // 1. Изумрудный лесной градиент
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width, height),
        [const Color(0xFF042F2E), const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF0D9488)],
        [0.0, 0.33, 0.66, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. Солнечные лучи сквозь кроны
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final ray = Path()
        ..moveTo(width * 0.1 + i * 20, 0)
        ..lineTo(width * 0.15 + i * 35, 0)
        ..lineTo(width * 0.35 + i * 50, height)
        ..lineTo(width * 0.25 + i * 40, height)
        ..close();
      canvas.drawPath(ray, rayPaint);
    }

    // 3. Силуэты деревьев на горизонте
    final treePaint = Paint()..color = const Color(0xFF022C22).withValues(alpha: 0.7);
    final treeCenters = [width * 0.05, width * 0.18, width * 0.32, width * 0.58, width * 0.76, width * 0.92];
    for (final tx in treeCenters) {
      final treeH = height * 0.75;
      canvas.drawRect(Rect.fromLTWH(tx - 3, height - treeH * 0.4, 6, treeH * 0.4), Paint()..color = const Color(0xFF78350F));
      for (int level = 0; level < 3; level++) {
        final yTop = height - treeH + level * (treeH * 0.22);
        final wLevel = 18.0 + level * 10;
        final fir = Path()
          ..moveTo(tx, yTop)
          ..lineTo(tx - wLevel, yTop + treeH * 0.28)
          ..lineTo(tx + wLevel, yTop + treeH * 0.28)
          ..close();
        canvas.drawPath(fir, treePaint);
      }
    }

    // 4. Листва и дубовые листочки
    final leafPaint = Paint()..color = const Color(0xFFF59E0B);
    final leafGreen = Paint()..color = const Color(0xFF10B981);
    final leaves = [
      Offset(width * 0.12, height * 0.2), Offset(width * 0.42, height * 0.3),
      Offset(width * 0.68, height * 0.25), Offset(width * 0.85, height * 0.2),
    ];
    for (int i = 0; i < leaves.length; i++) {
      final lp = leaves[i];
      canvas.save();
      canvas.translate(lp.dx, lp.dy);
      canvas.rotate(i * 0.6);
      canvas.drawOval(const Rect.fromLTWH(-8, -4, 16, 8), i % 2 == 0 ? leafPaint : leafGreen);
      canvas.restore();
    }

    // 5. Мухоморчик на поляне справа
    final mushX = width * 0.88;
    final mushY = height * 0.78;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mushX - 4, mushY, 8, 18), const Radius.circular(3)), Paint()..color = Colors.white);
    final cap = Path()
      ..addArc(Rect.fromCircle(center: Offset(mushX, mushY + 2), radius: 14), math.pi, math.pi)
      ..close();
    canvas.drawPath(cap, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(mushX - 5, mushY - 4), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(mushX + 4, mushY - 5), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(mushX, mushY - 8), 1.8, Paint()..color = Colors.white);
  }

  static void _drawDetectiveBanner(Canvas canvas, double width, double height) {
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width, height),
        [const Color(0xFF2E1065), const Color(0xFF451A03), const Color(0xFF78350F), const Color(0xFFB45309)],
        [0.0, 0.33, 0.66, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final lx = width * 0.82;
    final ly = height * 0.45;
    canvas.save();
    canvas.translate(lx, ly);
    canvas.rotate(0.35);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, -3, 30, 7), const Radius.circular(3)), Paint()..color = const Color(0xFF78350F));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, -4, 5, 9), const Radius.circular(2)), Paint()..color = const Color(0xFFFBBF24));

    final rimPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(Offset.zero, 24, rimPaint);

    final glassPaint = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.35);
    canvas.drawCircle(Offset.zero, 22, glassPaint);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(const Rect.fromLTWH(-16, -16, 32, 32), -math.pi * 0.75, math.pi * 0.5, false, highlightPaint);
    canvas.restore();

    final pawPaint = Paint()..color = const Color(0xFFFDE68A).withValues(alpha: 0.45);
    for (int i = 0; i < 5; i++) {
      final px = width * 0.12 + i * 45;
      final py = height * 0.45 + (i % 2 == 0 ? -8 : 8);
      canvas.drawOval(Rect.fromCenter(center: Offset(px, py), width: 8, height: 6), pawPaint);
      canvas.drawCircle(Offset(px - 4, py - 6), 2, pawPaint);
      canvas.drawCircle(Offset(px, py - 8), 2.2, pawPaint);
      canvas.drawCircle(Offset(px + 4, py - 6), 2, pawPaint);
    }

    final scrollX = width * 0.48;
    final scrollY = height * 0.48;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(scrollX, scrollY), width: 44, height: 32), const Radius.circular(3)), Paint()..color = const Color(0xFFFEF3C7));
    final linePaint = Paint()..color = const Color(0xFFB45309)..strokeWidth = 2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(scrollX - 16, scrollY - 8), Offset(scrollX + 16, scrollY - 8), linePaint);
    canvas.drawLine(Offset(scrollX - 16, scrollY), Offset(scrollX + 10, scrollY), linePaint);
    canvas.drawLine(Offset(scrollX - 16, scrollY + 8), Offset(scrollX + 14, scrollY + 8), linePaint);

    final qPainter = TextPainter(
      text: const TextSpan(text: '?', style: TextStyle(color: Color(0xFFFDE047), fontSize: 24, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    qPainter.paint(canvas, Offset(width * 0.65, height * 0.25));
  }

  static void _drawWorkshopBanner(Canvas canvas, double width, double height) {
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width, height),
        [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF2563EB)],
        [0.0, 0.33, 0.66, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double x = 0; x < width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    _drawGear(canvas, width * 0.85, height * 0.5, 30, const Color(0xFFF59E0B), 8);
    _drawGear(canvas, width * 0.72, height * 0.65, 20, const Color(0xFF93C5FD), 6);
    _drawGear(canvas, width * 0.74, height * 0.28, 16, const Color(0xFFE2E8F0), 6);

    final rulerX = width * 0.12;
    final rulerY = height * 0.55;
    final rulerPaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rulerX, rulerY - 6, 70, 12), const Radius.circular(2)), rulerPaint);
    final markPaint = Paint()..color = const Color(0xFF1E3A8A)..strokeWidth = 1.5;
    for (int i = 0; i < 12; i++) {
      final hMark = (i % 5 == 0) ? 8.0 : 4.0;
      canvas.drawLine(Offset(rulerX + 6 + i * 5, rulerY - 6), Offset(rulerX + 6 + i * 5, rulerY - 6 + hMark), markPaint);
    }

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(Rect.fromCircle(center: Offset(width * 0.35, height * 0.5), radius: 26), -math.pi, math.pi, false, arcPaint);
  }

  static void _drawGear(Canvas canvas, double cx, double cy, double radius, Color color, int teeth) {
    final gearPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius * 0.8, gearPaint);
    for (int i = 0; i < teeth; i++) {
      final angle = (i * 2 * math.pi) / teeth;
      final toothX = cx + math.cos(angle) * radius * 0.9;
      final toothY = cy + math.sin(angle) * radius * 0.9;
      canvas.drawCircle(Offset(toothX, toothY), radius * 0.22, gearPaint);
    }
    canvas.drawCircle(Offset(cx, cy), radius * 0.35, Paint()..color = const Color(0xFF0F172A));
  }

  static void _drawMeadowBanner(Canvas canvas, double width, double height) {
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, height),
        [const Color(0xFF38BDF8), const Color(0xFFBAE6FD), const Color(0xFFFEF08A)],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), skyPaint);

    final sunCenter = Offset(width * 0.12, height * 0.35);
    final sunPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(sunCenter, 24, sunPaint);
    final rayPaint = Paint()..color = const Color(0xFFF59E0B)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(sunCenter.dx + math.cos(a) * 28, sunCenter.dy + math.sin(a) * 28),
        Offset(sunCenter.dx + math.cos(a) * 38, sunCenter.dy + math.sin(a) * 38),
        rayPaint,
      );
    }

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    void drawCloud(double x, double y) {
      canvas.drawCircle(Offset(x, y), 12, cloudPaint);
      canvas.drawCircle(Offset(x + 10, y - 4), 14, cloudPaint);
      canvas.drawCircle(Offset(x + 22, y), 12, cloudPaint);
      canvas.drawRect(Rect.fromLTWH(x - 4, y, 28, 12), cloudPaint);
    }
    drawCloud(width * 0.35, height * 0.25);
    drawCloud(width * 0.65, height * 0.20);

    final hillPath = Path()
      ..moveTo(0, height)
      ..lineTo(0, height * 0.65)
      ..quadraticBezierTo(width * 0.25, height * 0.45, width * 0.55, height * 0.60)
      ..quadraticBezierTo(width * 0.8, height * 0.72, width, height * 0.55)
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF22C55E));

    final frontHill = Path()
      ..moveTo(0, height)
      ..lineTo(0, height * 0.8)
      ..quadraticBezierTo(width * 0.4, height * 0.65, width * 0.75, height * 0.85)
      ..lineTo(width, height * 0.82)
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(frontHill, Paint()..color = const Color(0xFF16A34A));

    void drawDaisy(double fx, double fy) {
      final petalPaint = Paint()..color = Colors.white;
      for (int i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        canvas.drawCircle(Offset(fx + math.cos(a) * 5, fy + math.sin(a) * 5), 3, petalPaint);
      }
      canvas.drawCircle(Offset(fx, fy), 3.5, Paint()..color = const Color(0xFFFBBF24));
    }
    drawDaisy(width * 0.25, height * 0.82);
    drawDaisy(width * 0.48, height * 0.86);
    drawDaisy(width * 0.78, height * 0.88);
    drawDaisy(width * 0.88, height * 0.78);

    final beeX = width * 0.84;
    final beeY = height * 0.35;
    canvas.drawOval(Rect.fromCenter(center: Offset(beeX - 2, beeY - 8), width: 8, height: 12), Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawOval(Rect.fromCenter(center: Offset(beeX + 4, beeY - 8), width: 8, height: 12), Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawOval(Rect.fromCenter(center: Offset(beeX, beeY), width: 16, height: 11), Paint()..color = const Color(0xFFFBBF24));
    canvas.drawRect(Rect.fromCenter(center: Offset(beeX - 2, beeY), width: 3, height: 11), Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromCenter(center: Offset(beeX + 3, beeY), width: 3, height: 11), Paint()..color = Colors.black);
  }

  // =========================================================================
  // Маскоты 5 миров (YandexART Mascots Avatars)
  // =========================================================================

  static void _drawWorldMascot(Canvas canvas, double cx, double cy, String type) {
    if (type.contains('space')) {
      _drawAstroFoxMascot(canvas, cx, cy);
    } else if (type.contains('forest')) {
      _drawOwlProfessorMascot(canvas, cx, cy);
    } else if (type.contains('detective')) {
      _drawDetectiveRaccoonMascot(canvas, cx, cy);
    } else if (type.contains('workshop')) {
      _drawEngineerBeaverMascot(canvas, cx, cy);
    } else {
      _drawBearCubMascot(canvas, cx, cy);
    }
  }

  // 1. Лисёнок Астро (Космонавт)
  static void _drawAstroFoxMascot(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 60, Paint()..color = const Color(0xFF1E1B4B));
    canvas.drawCircle(Offset(cx, cy), 58, Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF312E81));

    final earLeft = Path()..moveTo(cx - 34, cy - 25)..lineTo(cx - 24, cy - 54)..lineTo(cx - 8, cy - 35)..close();
    final earRight = Path()..moveTo(cx + 8, cy - 35)..lineTo(cx + 24, cy - 54)..lineTo(cx + 34, cy - 25)..close();
    canvas.drawPath(earLeft, Paint()..color = const Color(0xFFEA580C));
    canvas.drawPath(earRight, Paint()..color = const Color(0xFFEA580C));

    final innerEarLeft = Path()..moveTo(cx - 30, cy - 28)..lineTo(cx - 24, cy - 48)..lineTo(cx - 12, cy - 35)..close();
    final innerEarRight = Path()..moveTo(cx + 12, cy - 35)..lineTo(cx + 24, cy - 48)..lineTo(cx + 30, cy - 28)..close();
    canvas.drawPath(innerEarLeft, Paint()..color = const Color(0xFFFED7AA));
    canvas.drawPath(innerEarRight, Paint()..color = const Color(0xFFFED7AA));

    canvas.drawCircle(Offset(cx, cy - 4), 32, Paint()..color = const Color(0xFFF97316));
    final cheekLeft = Path()..moveTo(cx - 32, cy - 4)..quadraticBezierTo(cx - 28, cy + 18, cx, cy + 20)..lineTo(cx, cy - 4)..close();
    final cheekRight = Path()..moveTo(cx + 32, cy - 4)..quadraticBezierTo(cx + 28, cy + 18, cx, cy + 20)..lineTo(cx, cy - 4)..close();
    canvas.drawPath(cheekLeft, Paint()..color = Colors.white);
    canvas.drawPath(cheekRight, Paint()..color = Colors.white);

    canvas.drawCircle(Offset(cx, cy + 6), 4.5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx - 12, cy - 6), 5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx + 12, cy - 6), 5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx - 13.5, cy - 7.5), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 10.5, cy - 7.5), 2, Paint()..color = Colors.white);

    final smile = Path()..moveTo(cx - 7, cy + 13)..quadraticBezierTo(cx, cy + 18, cx + 7, cy + 13);
    canvas.drawPath(smile, Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);

    final visorPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(cx, cy - 4), 42, visorPaint);
  }

  // 2. Сова-Профессор Филя
  static void _drawOwlProfessorMascot(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 60, Paint()..color = const Color(0xFF064E3B));
    canvas.drawCircle(Offset(cx, cy), 58, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF047857));

    canvas.drawCircle(Offset(cx, cy + 4), 36, Paint()..color = const Color(0xFF92400E));
    canvas.drawCircle(Offset(cx, cy + 8), 28, Paint()..color = const Color(0xFFFEF3C7));

    canvas.drawCircle(Offset(cx - 14, cy - 4), 16, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 14, cy - 4), 16, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - 14, cy - 4), 12, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(Offset(cx + 14, cy - 4), 12, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(Offset(cx - 14, cy - 4), 6, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx + 14, cy - 4), 6, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx - 16, cy - 6), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 12, cy - 6), 2.5, Paint()..color = Colors.white);

    final glassRim = Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx - 14, cy - 4), 16, glassRim);
    canvas.drawCircle(Offset(cx + 14, cy - 4), 16, glassRim);
    canvas.drawLine(Offset(cx + 2, cy - 4), Offset(cx - 2, cy - 4), glassRim);

    final beak = Path()..moveTo(cx - 5, cy + 4)..lineTo(cx + 5, cy + 4)..lineTo(cx, cy + 14)..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFEA580C));

    final capX = cx;
    final capY = cy - 36;
    final capPath = Path()
      ..moveTo(capX, capY - 10)
      ..lineTo(capX + 28, capY)
      ..lineTo(capX, capY + 10)
      ..lineTo(capX - 28, capY)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFF1F2937));
    canvas.drawLine(Offset(capX, capY), Offset(capX + 22, capY + 12), Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 2);
    canvas.drawCircle(Offset(capX + 22, capY + 13), 3, Paint()..color = const Color(0xFFFBBF24));
  }

  // 3. Енот-Следопыт Шерлок
  static void _drawDetectiveRaccoonMascot(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 60, Paint()..color = const Color(0xFF451A03));
    canvas.drawCircle(Offset(cx, cy), 58, Paint()..color = const Color(0xFFEAB308)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF78350F));

    canvas.drawCircle(Offset(cx - 28, cy - 24), 13, Paint()..color = const Color(0xFF4B5563));
    canvas.drawCircle(Offset(cx + 28, cy - 24), 13, Paint()..color = const Color(0xFF4B5563));
    canvas.drawCircle(Offset(cx - 28, cy - 24), 8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 28, cy - 24), 8, Paint()..color = Colors.white);

    canvas.drawCircle(Offset(cx, cy), 35, Paint()..color = const Color(0xFF9CA3AF));

    final maskLeft = Path()
      ..moveTo(cx - 33, cy - 6)
      ..quadraticBezierTo(cx - 16, cy - 14, cx - 2, cy - 4)
      ..quadraticBezierTo(cx - 16, cy + 12, cx - 33, cy + 6)
      ..close();
    final maskRight = Path()
      ..moveTo(cx + 33, cy - 6)
      ..quadraticBezierTo(cx + 16, cy - 14, cx + 2, cy - 4)
      ..quadraticBezierTo(cx + 16, cy + 12, cx + 33, cy + 6)
      ..close();
    canvas.drawPath(maskLeft, Paint()..color = const Color(0xFF1F2937));
    canvas.drawPath(maskRight, Paint()..color = const Color(0xFF1F2937));

    canvas.drawCircle(Offset(cx - 15, cy - 2), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 15, cy - 2), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - 15, cy - 2), 3, Paint()..color = const Color(0xFF111827));
    canvas.drawCircle(Offset(cx + 15, cy - 2), 3, Paint()..color = const Color(0xFF111827));

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 12), width: 24, height: 16), Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, cy + 8), 4, Paint()..color = Colors.black);

    final hatPath = Path()
      ..moveTo(cx - 28, cy - 20)
      ..quadraticBezierTo(cx, cy - 40, cx + 28, cy - 20)
      ..quadraticBezierTo(cx, cy - 24, cx - 28, cy - 20)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = const Color(0xFF78350F));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 30, cy - 22, 60, 6), const Radius.circular(3)), Paint()..color = const Color(0xFFB45309));
  }

  // 4. Бобрёнок-Инженер Винтик
  static void _drawEngineerBeaverMascot(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 60, Paint()..color = const Color(0xFF1E3A8A));
    canvas.drawCircle(Offset(cx, cy), 58, Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF1D4ED8));

    canvas.drawCircle(Offset(cx - 28, cy - 20), 10, Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(Offset(cx + 28, cy - 20), 10, Paint()..color = const Color(0xFF78350F));

    canvas.drawCircle(Offset(cx, cy + 2), 34, Paint()..color = const Color(0xFF92400E));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 12), width: 34, height: 22), Paint()..color = const Color(0xFFFDE68A));

    final toothPaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 6, cy + 16, 5.5, 9), const Radius.circular(1.5)), toothPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 0.5, cy + 16, 5.5, 9), const Radius.circular(1.5)), toothPaint);
    final toothBorder = Paint()..color = const Color(0xFF78350F)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(cx - 6, cy + 16, 5.5, 9), toothBorder);
    canvas.drawRect(Rect.fromLTWH(cx + 0.5, cy + 16, 5.5, 9), toothBorder);

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 9), width: 12, height: 8), Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx - 13, cy - 2), 4.5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx + 13, cy - 2), 4.5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx - 14, cy - 3.5), 1.8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 12, cy - 3.5), 1.8, Paint()..color = Colors.white);

    final helmetPath = Path()
      ..addArc(Rect.fromCircle(center: Offset(cx, cy - 16), radius: 27), math.pi, math.pi)
      ..close();
    canvas.drawPath(helmetPath, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 31, cy - 18, 62, 7), const Radius.circular(3)), Paint()..color = const Color(0xFFF59E0B));
  }

  // 5. Медвежонок Миша и Пчёлка
  static void _drawBearCubMascot(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 60, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(Offset(cx, cy), 58, Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF16A34A));

    canvas.drawCircle(Offset(cx - 26, cy - 24), 14, Paint()..color = const Color(0xFFB45309));
    canvas.drawCircle(Offset(cx + 26, cy - 24), 14, Paint()..color = const Color(0xFFB45309));
    canvas.drawCircle(Offset(cx - 26, cy - 24), 8, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(Offset(cx + 26, cy - 24), 8, Paint()..color = const Color(0xFFFDE68A));

    canvas.drawCircle(Offset(cx, cy + 2), 35, Paint()..color = const Color(0xFFD97706));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 12), width: 34, height: 24), Paint()..color = const Color(0xFFFEF3C7));

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8), width: 13, height: 9), Paint()..color = const Color(0xFF1F2937));

    final blush = Paint()..color = const Color(0xFFF87171).withValues(alpha: 0.45);
    canvas.drawCircle(Offset(cx - 22, cy + 10), 7, blush);
    canvas.drawCircle(Offset(cx + 22, cy + 10), 7, blush);

    canvas.drawCircle(Offset(cx - 12, cy - 2), 4.5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx + 12, cy - 2), 4.5, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(cx - 13.5, cy - 3.5), 1.8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 10.5, cy - 3.5), 1.8, Paint()..color = Colors.white);

    final smile = Path()..moveTo(cx - 8, cy + 15)..quadraticBezierTo(cx, cy + 21, cx + 8, cy + 15);
    canvas.drawPath(smile, Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round);

    final beeX = cx + 34;
    final beeY = cy - 26;
    canvas.drawOval(Rect.fromCenter(center: Offset(beeX, beeY - 5), width: 6, height: 9), Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawOval(Rect.fromCenter(center: Offset(beeX, beeY), width: 13, height: 9), Paint()..color = const Color(0xFFFBBF24));
    canvas.drawRect(Rect.fromCenter(center: Offset(beeX, beeY), width: 2.5, height: 9), Paint()..color = Colors.black);
  }
}
