import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
        width: widthRatio == 4 ? 320 : 260,
        height: heightRatio == 3 ? 240 : 260,
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

      if (type == 'reward') {
        _drawRewardMedal(canvas, cx, cy);
      } else if (type == 'coloring') {
        _drawColoringShapes(canvas, cx, cy);
      } else if (type == 'mascot') {
        _drawMascotTeacher(canvas, cx, cy);
      } else {
        // Обучающая иллюстрация для карточки по содержанию label
        _drawCardArtwork(canvas, cx, cy, label);
      }

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
}
