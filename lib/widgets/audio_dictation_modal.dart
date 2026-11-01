import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conspect.dart';
import '../models/dictation_exercise.dart';
import '../models/tariff.dart';
import '../providers/app_provider.dart';
import '../services/audio_speech_service.dart';
import '../services/dictation_service.dart';
import '../theme.dart';
import '../screens/profile_screen.dart';

/// Интерактивный тренажёр слухового диктанта (1–2 класс и дошкольники)
class AudioDictationModal extends StatefulWidget {
  final Conspect conspect;

  const AudioDictationModal({
    super.key,
    required this.conspect,
  });

  static void show(BuildContext context, Conspect conspect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudioDictationModal(conspect: conspect),
    );
  }

  @override
  State<AudioDictationModal> createState() => _AudioDictationModalState();
}

class _AudioDictationModalState extends State<AudioDictationModal> {
  late DictationExercise _exercise;
  int _currentStep = 0; // 0: Ознакомление, 1: Пошаговая диктовка, 2: Самопроверка
  int _currentItemIndex = 0;
  bool _isPlaying = false;
  bool _autoAdvance = true;

  Timer? _pauseTimer;
  int _remainingPauseSec = 0;

  @override
  void initState() {
    super.initState();
    _exercise = DictationService.extractDictation(
      content: widget.conspect.content,
      topic: widget.conspect.topic,
      subject: widget.conspect.subject ?? 'Русский язык',
      ageGroup: widget.conspect.ageGroup,
    );
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    AudioSpeechService.instance.stop();
    super.dispose();
  }

  void _startIntroListening() {
    setState(() => _isPlaying = true);
    final text = '${_exercise.introScript} В диктанте будут следующие слова: ${_exercise.fullTextForPreview}.';
    AudioSpeechService.instance.speak(
      text,
      rate: 0.95,
      onEnd: () {
        if (mounted) setState(() => _isPlaying = false);
      },
    );
  }

  void _dictateCurrentWord() {
    _pauseTimer?.cancel();
    if (_currentItemIndex >= _exercise.items.length) {
      _finishDictation();
      return;
    }

    final item = _exercise.items[_currentItemIndex];
    AudioSpeechService.instance.playClickGong();

    setState(() {
      _isPlaying = true;
      _remainingPauseSec = item.pauseSeconds;
    });

    AudioSpeechService.instance.speak(
      item.spokenText,
      rate: 0.9,
      onEnd: () {
        if (mounted) {
          setState(() => _isPlaying = false);
          _startPauseCountdown();
        }
      },
    );
  }

  void _startPauseCountdown() {
    _pauseTimer?.cancel();
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingPauseSec > 1) {
        setState(() => _remainingPauseSec--);
      } else {
        timer.cancel();
        setState(() => _remainingPauseSec = 0);
        if (_autoAdvance && _currentItemIndex < _exercise.items.length - 1) {
          setState(() => _currentItemIndex++);
          _dictateCurrentWord();
        } else if (_autoAdvance && _currentItemIndex >= _exercise.items.length - 1) {
          _finishDictation();
        }
      }
    });
  }

  void _nextWord() {
    _pauseTimer?.cancel();
    if (_currentItemIndex < _exercise.items.length - 1) {
      setState(() => _currentItemIndex++);
      _dictateCurrentWord();
    } else {
      _finishDictation();
    }
  }

  void _prevWord() {
    _pauseTimer?.cancel();
    if (_currentItemIndex > 0) {
      setState(() => _currentItemIndex--);
      _dictateCurrentWord();
    }
  }

  void _repeatWord() {
    _dictateCurrentWord();
  }

  void _finishDictation() {
    _pauseTimer?.cancel();
    AudioSpeechService.instance.playSchoolBell();
    setState(() {
      _currentStep = 2; // Переход к самопроверке
      _isPlaying = true;
    });

    AudioSpeechService.instance.speak(
      _exercise.conclusionScript,
      rate: 0.95,
      onEnd: () {
        if (mounted) setState(() => _isPlaying = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final hasAccess = provider.currentTariff.canUseAudioDictation;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppGradients.violetMagenta,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hearing_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Интерактивный аудио-диктант',
                                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.amberOrange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _exercise.title,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasAccess) ...[
              // Tariff Gate for Dictation
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
                          'Аудио-диктант доступен в тарифах Pro и Директор',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Интерактивный диктант проводит словарный или арифметический срез с академическими паузами для письма и мгновенной самопроверкой по методике «Зелёного карандаша».',
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
              // Step Indicators
              Row(
                children: [
                  _buildStepTab(0, '1. Знакомство', Icons.record_voice_over_outlined),
                  const SizedBox(width: 8),
                  _buildStepTab(1, '2. Диктовка (${_currentItemIndex + 1}/${_exercise.items.length})', Icons.edit_note_rounded),
                  const SizedBox(width: 8),
                  _buildStepTab(2, '3. Самопроверка', Icons.verified_outlined),
                ],
              ),
              const SizedBox(height: 14),

              // Step 0: Ознакомление
              if (_currentStep == 0) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🦉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 14),
                        const Text(
                          'Этап 1: Первичное прослушивание',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ученики внимательно слушают весь список слов целиком, не записывая, чтобы понять тему и смысл.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                          label: Text(_isPlaying ? 'Остановить' : 'Слушать весь диктант'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (_isPlaying) {
                              AudioSpeechService.instance.stop();
                              setState(() => _isPlaying = false);
                            } else {
                              _startIntroListening();
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Перейти к записи под диктовку →'),
                          onPressed: () {
                            AudioSpeechService.instance.stop();
                            setState(() {
                              _currentStep = 1;
                              _currentItemIndex = 0;
                            });
                            _dictateCurrentWord();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Step 1: Пошаговая диктовка
              if (_currentStep == 1) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(colors: [const Color(0xFF1E2436), const Color(0xFF161B2B)])
                          : LinearGradient(colors: [Colors.indigo.shade50, Colors.purple.shade50]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.indigo.shade100,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Word index badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppGradients.indigoViolet,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'СЛОВО ${_currentItemIndex + 1} ИЗ ${_exercise.items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Spoken text / word card
                        Text(
                          _exercise.items[_currentItemIndex].cleanWord,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Orthogram / rule hint
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryIndigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '💡 ${_exercise.items[_currentItemIndex].ruleHint}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryIndigo, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Writing Pause Countdown Ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: _exercise.items[_currentItemIndex].pauseSeconds > 0
                                    ? _remainingPauseSec / _exercise.items[_currentItemIndex].pauseSeconds
                                    : 0.0,
                                strokeWidth: 6,
                                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _remainingPauseSec > 0 ? const Color(0xFF10B981) : AppColors.primaryIndigo,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_remainingPauseSec',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const Text('сек', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _remainingPauseSec > 0 ? 'Пауза на запись в тетрадь' : 'Готовы к следующему слову',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Предыдущее слово',
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: _currentItemIndex > 0 ? _prevWord : null,
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: const Text('Повторить слово'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _repeatWord,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Следующее слово',
                              icon: const Icon(Icons.arrow_forward_rounded),
                              onPressed: _nextWord,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Auto-advance switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Авто-переход по таймеру:', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Switch.adaptive(
                              value: _autoAdvance,
                              activeColor: AppColors.primaryIndigo,
                              onChanged: (val) => setState(() => _autoAdvance = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Step 2: Самопроверка («Зелёный карандаш»)
              if (_currentStep == 2) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_rounded, color: Color(0xFF10B981), size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Самопроверка: Метод «Зелёного карандаша»',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                  Text(
                                    'Сверьте написание и найдите свою лучшую букву-королеву!',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _exercise.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final item = _exercise.items[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0x14FFFFFF) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${item.index}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.cleanWord,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Text(
                                            item.ruleHint,
                                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Завершить диктант', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab(int stepIndex, String title, IconData icon) {
    final isSelected = _currentStep == stepIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          AudioSpeechService.instance.stop();
          _pauseTimer?.cancel();
          setState(() {
            _currentStep = stepIndex;
            _isPlaying = false;
          });
          if (stepIndex == 1) {
            _dictateCurrentWord();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.indigoViolet : null,
            color: isSelected ? null : (isDark ? const Color(0x14FFFFFF) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
