import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/telegram/telegram_web_app_service.dart';

/// Состояния анимации Совёнка-Методиста
enum OwlState {
  /// Покой: мягкое дыхание, моргание, покачивание кисточки
  idle,

  /// Слушает: наклон головы, широко раскрытые внимательные глаза, золотая аура
  listening,

  /// Думает: задумчивый взгляд вверх, вращение волшебных искорок, пульсация пера
  thinking,

  /// Говорит / отвечает: радостное покачивание крыльями, кивание, подмигивание
  speaking,
}

/// Высокодетализированный анимированный маскот Совёнок-Методист
class AnimatedOwlWidget extends StatefulWidget {
  final OwlState state;
  final double size;
  final VoidCallback? onTap;
  final bool showSpeechBubble;
  final String? speechText;

  const AnimatedOwlWidget({
    super.key,
    this.state = OwlState.idle,
    this.size = 120.0,
    this.onTap,
    this.showSpeechBubble = false,
    this.speechText,
  });

  @override
  State<AnimatedOwlWidget> createState() => _AnimatedOwlWidgetState();
}

class _AnimatedOwlWidgetState extends State<AnimatedOwlWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _blinkController;
  late AnimationController _thinkingController;
  late AnimationController _speakingController;
  Timer? _blinkTimer;
  Timer? _winkTimer;

  bool _isWinking = false;

  @override
  void initState() {
    super.initState();

    // 1. Контроллер дыхания (Idle) - постоянный синусоидальный цикл
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // 2. Контроллер моргания (периодическое быстрое смыкание век)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scheduleBlink();

    // 3. Контроллер размышления (вращение искорок и пульсация ауры)
    _thinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.state == OwlState.thinking) {
      _thinkingController.repeat();
    }

    // 4. Контроллер речи (махание крылышком и покачивание)
    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.state == OwlState.speaking) {
      _speakingController.repeat(reverse: true);
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      if (widget.state != OwlState.listening) {
        try {
          await _blinkController.forward();
          if (mounted) await _blinkController.reverse();
        } catch (_) {}
      }
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedOwlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == OwlState.thinking) {
        _thinkingController.repeat();
      } else {
        _thinkingController.stop();
      }

      if (widget.state == OwlState.speaking) {
        _speakingController.repeat(reverse: true);
      } else {
        _speakingController.stop();
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _winkTimer?.cancel();
    _idleController.dispose();
    _blinkController.dispose();
    _thinkingController.dispose();
    _speakingController.dispose();
    super.dispose();
  }

  void _handleTap() {
    TelegramWebAppService().hapticImpact('medium');
    setState(() => _isWinking = true);
    _winkTimer?.cancel();
    _winkTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isWinking = false);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _blinkController,
          _thinkingController,
          _speakingController,
        ]),
        builder: (context, child) {
          final breath = math.sin(_idleController.value * math.pi * 2);
          final breathScale = 1.0 + (breath * 0.025);
          final tasselAngle = breath * 0.12;

          double headTilt = 0.0;
          double eyeOpenness = 1.0 - _blinkController.value;
          double wingFlap = 0.0;
          double sparkleRotation = _thinkingController.value * math.pi * 2;

          if (_isWinking) {
            eyeOpenness = 0.2;
            headTilt = 0.08;
          } else if (widget.state == OwlState.listening) {
            headTilt = 0.06;
            eyeOpenness = 1.15; // Широко открытые внимательные глаза
          } else if (widget.state == OwlState.thinking) {
            headTilt = -0.07;
            eyeOpenness = 0.85;
          } else if (widget.state == OwlState.speaking) {
            headTilt = math.sin(_speakingController.value * math.pi) * 0.05;
            wingFlap = _speakingController.value;
          }

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Аура свечения при размышлении или слушании
              if (widget.state == OwlState.thinking || widget.state == OwlState.listening)
                Container(
                  width: widget.size * 1.15,
                  height: widget.size * 1.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.state == OwlState.thinking
                            ? const Color(0xFF6366F1).withOpacity(0.4)
                            : const Color(0xFFF59E0B).withOpacity(0.4),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),

              // 2. Векторный холст Совёнка
              Transform.scale(
                scale: breathScale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _OwlPainter(
                      state: widget.state,
                      headTilt: headTilt,
                      eyeOpenness: eyeOpenness,
                      tasselAngle: tasselAngle,
                      wingFlap: wingFlap,
                      sparkleRotation: sparkleRotation,
                      isWinking: _isWinking,
                    ),
                  ),
                ),
              ),

              // 3. Всплывающее облачко реплики (если передано)
              if (widget.showSpeechBubble && widget.speechText != null)
                Positioned(
                  top: -24,
                  right: -widget.size * 0.4,
                  child: _buildSpeechBubble(widget.speechText!),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpeechBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Высокоточный CustomPainter с детализированными слоями Совёнка
class _OwlPainter extends CustomPainter {
  final OwlState state;
  final double headTilt;
  final double eyeOpenness;
  final double tasselAngle;
  final double wingFlap;
  final double sparkleRotation;
  final bool isWinking;

  _OwlPainter({
    required this.state,
    required this.headTilt,
    required this.eyeOpenness,
    required this.tasselAngle,
    required this.wingFlap,
    required this.sparkleRotation,
    required this.isWinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 120.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // 0. Тень под совенком
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 48), width: 72, height: 16),
      shadowPaint,
    );

    // 1. Тело и животик
    _drawBody(canvas);

    // 2. Крылья (с учетом махания при разговоре)
    _drawWings(canvas);

    // 3. Золотое перо в правом крыле
    _drawMagicFeather(canvas);

    // 4. Голова с поворотом / наклоном
    canvas.save();
    canvas.rotate(headTilt);

    _drawHeadAndEars(canvas);
    _drawEyes(canvas);
    _drawBeak(canvas);
    _drawGlasses(canvas);
    _drawMortarboard(canvas);

    canvas.restore();

    // 5. Волшебные искры при размышлении (Thinking)
    if (state == OwlState.thinking) {
      _drawSparkles(canvas);
    }

    canvas.restore();
  }

  void _drawBody(Canvas canvas) {
    // Основной градиент оперения тела (глубокий изумрудно-лесной / шоколадный)
    final bodyRect = Rect.fromCenter(center: const Offset(0, 16), width: 68, height: 60);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF047857), Color(0xFF064E3B), Color(0xFF022C22)],
      ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(28)),
      bodyPaint,
    );

    // Золотистая окантовка животика
    final strokePaint = Paint()
      ..color = const Color(0xFFD97706).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(28)),
      strokePaint,
    );

    // Светлый пузико-манишка (бежево-кремовый с рябью перьев)
    final tummyRect = Rect.fromCenter(center: const Offset(0, 22), width: 44, height: 42);
    final tummyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
      ).createShader(tummyRect);

    canvas.drawOval(tummyRect, tummyPaint);

    // Перьевые шевроны на грудке (декоративная текстура)
    final chevronPaint = Paint()
      ..color = const Color(0xFFD97706).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final y = 14.0 + (i * 7.0);
      final p = Path()
        ..moveTo(-8, y)
        ..quadraticBezierTo(0, y + 4, 8, y);
      canvas.drawPath(p, chevronPaint);
    }

    // Лапки (оранжевые коготки)
    final footPaint = Paint()..color = const Color(0xFFEA580C);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-14, 44), width: 16, height: 8), footPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(14, 44), width: 16, height: 8), footPaint);
  }

  void _drawWings(Canvas canvas) {
    final wingPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF065F46), Color(0xFF064E3B)],
      ).createShader(const Rect.fromLTWH(-45, 0, 90, 45));

    // Левое крыло
    canvas.save();
    canvas.translate(-30, 14);
    canvas.rotate(-0.15 - (wingFlap * 0.25));
    final leftWingPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-12, 12, -4, 28)
      ..quadraticBezierTo(8, 20, 6, 2)
      ..close();
    canvas.drawPath(leftWingPath, wingPaint);
    canvas.restore();

    // Правое крыло (с пером)
    canvas.save();
    canvas.translate(30, 14);
    canvas.rotate(0.15 + (wingFlap * 0.35));
    final rightWingPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(12, 12, 4, 28)
      ..quadraticBezierTo(-8, 20, -6, 2)
      ..close();
    canvas.drawPath(rightWingPath, wingPaint);
    canvas.restore();
  }

  void _drawMagicFeather(Canvas canvas) {
    // Золотое перо в правом крыле
    canvas.save();
    canvas.translate(34, 18);
    canvas.rotate(0.45 + (wingFlap * 0.2));

    final quillPaint = Paint()..color = const Color(0xFFF59E0B);
    final quillPath = Path()
      ..moveTo(0, -18)
      ..quadraticBezierTo(4, -8, 2, 8)
      ..lineTo(0, 16)
      ..lineTo(-1, 8)
      ..quadraticBezierTo(-4, -8, 0, -18)
      ..close();
    canvas.drawPath(quillPath, quillPaint);

    // Стержень пера
    canvas.drawLine(
      const Offset(0, -16),
      const Offset(0, 16),
      Paint()..color = Colors.white.withOpacity(0.9)..strokeWidth = 1.0,
    );
    canvas.restore();
  }

  void _drawHeadAndEars(Canvas canvas) {
    // Ушки-кисточки
    final earPaint = Paint()..color = const Color(0xFF047857);
    final earLeft = Path()
      ..moveTo(-26, -18)
      ..lineTo(-32, -40)
      ..lineTo(-14, -28)
      ..close();
    canvas.drawPath(earLeft, earPaint);

    final earRight = Path()
      ..moveTo(26, -18)
      ..lineTo(32, -40)
      ..lineTo(14, -28)
      ..close();
    canvas.drawPath(earRight, earPaint);

    // Оперение внутри ушек
    final innerEarPaint = Paint()..color = const Color(0xFFFEF3C7);
    final innerEarLeft = Path()
      ..moveTo(-24, -20)
      ..lineTo(-29, -36)
      ..lineTo(-16, -26)
      ..close();
    canvas.drawPath(innerEarLeft, innerEarPaint);

    final innerEarRight = Path()
      ..moveTo(24, -20)
      ..lineTo(29, -36)
      ..lineTo(16, -26)
      ..close();
    canvas.drawPath(innerEarRight, innerEarPaint);

    // Голова (большой округлый круг)
    final headRect = Rect.fromCenter(center: const Offset(0, -12), width: 66, height: 56);
    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF064E3B)],
      ).createShader(headRect);

    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(26)), headPaint);
  }

  void _drawEyes(Canvas canvas) {
    final eyeY = -12.0;
    final leftX = -15.0;
    final rightX = 15.0;
    final eyeRadius = 14.0;

    // Белки глаз
    final scleraPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(leftX, eyeY), eyeRadius, scleraPaint);
    canvas.drawCircle(Offset(rightX, eyeY), eyeRadius, scleraPaint);

    // Золотистая радужка
    final irisPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromCircle(center: Offset(leftX, eyeY), radius: eyeRadius));

    canvas.drawCircle(Offset(leftX, eyeY), 10.5, irisPaint);
    canvas.drawCircle(Offset(rightX, eyeY), 10.5, irisPaint);

    // Зрачки с направлением взгляда
    double pupilOffsetX = (state == OwlState.listening) ? 1.5 : 0.0;
    double pupilOffsetY = (state == OwlState.thinking) ? -3.0 : 0.5;

    final pupilPaint = Paint()..color = const Color(0xFF0F172A);
    final pupilRadius = 6.0;

    canvas.drawCircle(Offset(leftX + pupilOffsetX, eyeY + pupilOffsetY), pupilRadius, pupilPaint);
    canvas.drawCircle(Offset(rightX + pupilOffsetX, eyeY + pupilOffsetY), pupilRadius, pupilPaint);

    // Блики в глазах (живой блеск Pixar)
    final gleamPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(leftX - 2.5, eyeY - 2.5), 2.8, gleamPaint);
    canvas.drawCircle(Offset(rightX - 2.5, eyeY - 2.5), 2.8, gleamPaint);
    canvas.drawCircle(Offset(leftX + 2.5, eyeY + 2.0), 1.2, gleamPaint);
    canvas.drawCircle(Offset(rightX + 2.5, eyeY + 2.0), 1.2, gleamPaint);

    // Веки (моргание и подмигивание)
    if (eyeOpenness < 0.98 || isWinking) {
      final eyelidPaint = Paint()..color = const Color(0xFF047857);

      // Левое веко
      final leftEyelidHeight = eyeRadius * 2 * (1.0 - (isWinking ? 0.2 : eyeOpenness));
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCircle(center: Offset(leftX, eyeY), radius: eyeRadius),
        Radius.circular(eyeRadius),
      ));
      canvas.drawRect(
        Rect.fromLTWH(leftX - eyeRadius, eyeY - eyeRadius, eyeRadius * 2, leftEyelidHeight),
        eyelidPaint,
      );
      canvas.restore();

      // Правое веко (подмигивание)
      final rightEyeOpen = isWinking ? 0.15 : eyeOpenness;
      final rightEyelidHeight = eyeRadius * 2 * (1.0 - rightEyeOpen);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCircle(center: Offset(rightX, eyeY), radius: eyeRadius),
        Radius.circular(eyeRadius),
      ));
      canvas.drawRect(
        Rect.fromLTWH(rightX - eyeRadius, eyeY - eyeRadius, eyeRadius * 2, rightEyelidHeight),
        eyelidPaint,
      );
      canvas.restore();
    }
  }

  void _drawGlasses(Canvas canvas) {
    // Золотые круглые профессорские очки
    final eyeY = -12.0;
    final rimPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawCircle(Offset(-15, eyeY), 14, rimPaint);
    canvas.drawCircle(Offset(15, eyeY), 14, rimPaint);

    // Переносица очков
    final bridgePath = Path()
      ..moveTo(-1, eyeY - 1)
      ..quadraticBezierTo(0, eyeY - 4, 1, eyeY - 1);
    canvas.drawPath(bridgePath, rimPaint);

    // Блик на стеклышках
    final glassGlare = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-22, eyeY - 7), Offset(-17, eyeY - 12), glassGlare);
    canvas.drawLine(Offset(8, eyeY - 7), Offset(13, eyeY - 12), glassGlare);
  }

  void _drawBeak(Canvas canvas) {
    // Треугольный янтарно-оранжевый клюв
    final beakPaint = Paint()..color = const Color(0xFFF97316);
    final beakPath = Path()
      ..moveTo(-5, -6)
      ..lineTo(5, -6)
      ..lineTo(0, 3)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Блик на кончике клюва
    final highlightPaint = Paint()..color = const Color(0xFFFDBA74);
    canvas.drawCircle(const Offset(0, -3), 1.2, highlightPaint);
  }

  void _drawMortarboard(Canvas canvas) {
    // Академическая шапочка (Mortarboard) магистра/профессора
    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
      ).createShader(const Rect.fromLTWH(-36, -48, 72, 24));

    // Нижняя посадочная лента шапочки
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -32), width: 34, height: 10),
      capPaint,
    );

    // Верхний ромб шапочки
    final diamondPath = Path()
      ..moveTo(0, -48) // верх
      ..lineTo(36, -37) // право
      ..lineTo(0, -30) // низ
      ..lineTo(-36, -37) // лево
      ..close();
    canvas.drawPath(diamondPath, capPaint);

    // Золотая окантовка ромба
    final capBorder = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(diamondPath, capBorder);

    // Центральная пуговица шапочки
    final buttonPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(const Offset(0, -38), 3.2, buttonPaint);

    // Золотая кисточка (Tassel) с качанием от дыхания
    canvas.save();
    canvas.translate(0, -38);
    canvas.rotate(0.35 + tasselAngle);

    final tasselLine = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset.zero, const Offset(24, 8), tasselLine);

    // Пучок кисточки
    final tasselBrush = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(26, 12), width: 7, height: 12),
      tasselBrush,
    );
    canvas.restore();
  }

  void _drawSparkles(Canvas canvas) {
    // Вращающиеся волшебные искорки вокруг головы
    final sparklePaint = Paint()..color = const Color(0xFFF59E0B);
    final count = 4;
    final radius = 42.0;

    for (int i = 0; i < count; i++) {
      final angle = sparkleRotation + (i * (math.pi * 2 / count));
      final x = math.cos(angle) * radius;
      final y = -14.0 + (math.sin(angle) * (radius * 0.45));

      // Рисуем 4-лучевую звездочку
      final star = Path()
        ..moveTo(x, y - 4)
        ..lineTo(x + 1.2, y - 1.2)
        ..lineTo(x + 4, y)
        ..lineTo(x + 1.2, y + 1.2)
        ..lineTo(x, y + 4)
        ..lineTo(x - 1.2, y + 1.2)
        ..lineTo(x - 4, y)
        ..lineTo(x - 1.2, y - 1.2)
        ..close();
      canvas.drawPath(star, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OwlPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.headTilt != headTilt ||
        oldDelegate.eyeOpenness != eyeOpenness ||
        oldDelegate.tasselAngle != tasselAngle ||
        oldDelegate.wingFlap != wingFlap ||
        oldDelegate.sparkleRotation != sparkleRotation ||
        oldDelegate.isWinking != isWinking;
  }
}
