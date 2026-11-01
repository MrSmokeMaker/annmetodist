import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/conspect.dart';
import '../models/tariff.dart';
import '../providers/app_provider.dart';
import '../services/audio_speech_service.dart';
import '../services/prompt_builder.dart';
import '../theme.dart';
import '../screens/profile_screen.dart';

/// Полноценная студия «Аудио-заметка для родителей» с синтезатором речи Совёнка
class ParentAudioStudioModal extends StatefulWidget {
  final Conspect conspect;

  const ParentAudioStudioModal({
    super.key,
    required this.conspect,
  });

  static void show(BuildContext context, Conspect conspect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ParentAudioStudioModal(conspect: conspect),
    );
  }

  @override
  State<ParentAudioStudioModal> createState() => _ParentAudioStudioModalState();
}

class _ParentAudioStudioModalState extends State<ParentAudioStudioModal> with SingleTickerProviderStateMixin {
  late String _audioScript;
  double _speed = 1.0;
  bool _isPlaying = false;
  StreamSubscription<bool>? _speechSub;

  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _audioScript = widget.conspect.parentAudioScript ??
        PromptBuilder.extractParentAudioScript(widget.conspect.content) ??
        'Сегодня на уроке мы изучили тему «${widget.conspect.topic}». Пожалуйста, похвалите ребёнка за старание и закрепите результат в спокойной домашней обстановке.';

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _speechSub = AudioSpeechService.instance.onSpeakingChanged.listen((speaking) {
      if (mounted) {
        setState(() {
          _isPlaying = speaking;
        });
      }
    });
  }

  @override
  void dispose() {
    AudioSpeechService.instance.stop();
    _speechSub?.cancel();
    _waveAnimController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      AudioSpeechService.instance.pause();
      setState(() => _isPlaying = false);
    } else {
      AudioSpeechService.instance.speak(
        _audioScript,
        rate: _speed,
        onStart: () {
          if (mounted) setState(() => _isPlaying = true);
        },
        onEnd: () {
          if (mounted) setState(() => _isPlaying = false);
        },
      );
      setState(() => _isPlaying = true);
    }
  }

  void _replay() {
    AudioSpeechService.instance.stop();
    AudioSpeechService.instance.speak(
      _audioScript,
      rate: _speed,
      onStart: () {
        if (mounted) setState(() => _isPlaying = true);
      },
      onEnd: () {
        if (mounted) setState(() => _isPlaying = false);
      },
    );
    setState(() => _isPlaying = true);
  }

  void _setSpeed(double newSpeed) {
    setState(() => _speed = newSpeed);
    if (_isPlaying) {
      _replay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final hasAccess = provider.currentTariff.canUseAudioSpeechStudio;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cyanBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Студия аудио-заметок',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppGradients.amberOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO & ДИРЕКТОР',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Синтезатор речи и 60-сек аудио-гид родителю',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasAccess) ...[
              // Tariff Gate / Upsell banner
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: AppGradients.amberOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Функция доступна в тарифах Pro и Директор',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Синтезатор речи позволяет озвучивать памятки для родителей голосом Совёнка, генерировать аудио-скрипты и проводить интерактивные слуховые диктанты.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                          label: const Text('Смотреть тарифы Pro и Директор'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(FadeSlidePageRoute(page: const ProfileScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Waveform and Mascot Studio Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF1E2436),
                            const Color(0xFF161B2B),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.indigo.shade50,
                            Colors.blue.shade50,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.indigo.shade100,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Mascot badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.glowCyan,
                          ),
                          child: const Center(
                            child: Text('🦉', style: TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Голос Совёнка (Web Speech TTS)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  if (_isPlaying)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'LIVE',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isPlaying
                                    ? 'Воспроизведение памятки спокойным голосом...'
                                    : 'Нажмите Play для прослушивания голосового скрипта',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Animated Equalizer Wave Bars
                    AnimatedBuilder(
                      animation: _waveAnimController,
                      builder: (context, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(18, (index) {
                            final factor = _isPlaying
                                ? ((index % 3 == 0)
                                    ? _waveAnimController.value
                                    : 1.0 - _waveAnimController.value)
                                : 0.2;
                            final height = (factor * 26).clamp(4.0, 32.0);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 3.5,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: _isPlaying ? AppGradients.cyanBlue : null,
                                color: _isPlaying ? null : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rewind / Replay
                        IconButton(
                          tooltip: 'Повторить сначала',
                          icon: const Icon(Icons.replay_rounded, size: 24),
                          onPressed: _replay,
                        ),
                        const SizedBox(width: 12),
                        // Main Play/Pause Button
                        InkWell(
                          onTap: _togglePlayPause,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: _isPlaying ? AppGradients.amberOrange : AppGradients.cyanBlue,
                              shape: BoxShape.circle,
                              boxShadow: _isPlaying ? AppShadows.glowAmber : AppShadows.glowCyan,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Stop Button
                        IconButton(
                          tooltip: 'Остановить',
                          icon: const Icon(Icons.stop_rounded, size: 24),
                          onPressed: () {
                            AudioSpeechService.instance.stop();
                            setState(() => _isPlaying = false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Speed Pill Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Скорость:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        for (final s in [0.8, 1.0, 1.2])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Text('${s}x', style: const TextStyle(fontSize: 11)),
                              selected: _speed == s,
                              selectedColor: AppColors.primaryIndigo,
                              labelStyle: TextStyle(
                                color: _speed == s ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: _speed == s ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => _setSpeed(s),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Script Card & Teleprompter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Текст голосового сообщения для родителя:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Копировать текст', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _audioScript));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Текст скопирован! Можно надиктовать или отправить в WhatsApp/Telegram.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      _audioScript,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.55,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
