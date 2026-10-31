import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Модальное окно новостей и истории версий в элегантном стиле Apple (Mobbin design)
class AppNewsModal extends StatefulWidget {
  const AppNewsModal({super.key});

  /// Открывает окно новостей с плавной анимацией
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрыть новости',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) => const AppNewsModal(),
    );
  }

  @override
  State<AppNewsModal> createState() => _AppNewsModalState();
}

class _AppNewsModalState extends State<AppNewsModal> {
  Map<String, dynamic>? _newsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final jsonString = await rootBundle.loadString('assets/news.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _newsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? size.width * 0.94 : 560,
          maxHeight: size.height * 0.85,
        ),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xE6141721) : const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Apple-style Header
                    _buildHeader(context, isDark),

                    // Releases Content
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator.adaptive())
                          : _buildReleasesList(context, isDark),
                    ),

                    // Bottom Action Bar
                    _buildFooter(context, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final currentVer = _newsData?['currentVersion'] ?? 'v0.3.0';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.indigoViolet,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryIndigo.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Что нового в Методисте',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cyanBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentVer,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'История обновлений и технологических улучшений',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Закрыть',
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildReleasesList(BuildContext context, bool isDark) {
    final releases = (_newsData?['releases'] as List<dynamic>?) ?? [];
    if (releases.isEmpty) {
      return const Center(child: Text('Нет информации об обновлениях'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      itemCount: releases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (ctx, idx) {
        final rel = releases[idx] as Map<String, dynamic>;
        final version = rel['version'] ?? '';
        final date = rel['date'] ?? '';
        final title = rel['title'] ?? '';
        final badge = rel['badge'] ?? '';
        final highlights = (rel['highlights'] as List<dynamic>?) ?? [];

        final isLatest = idx == 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLatest
                ? (isDark ? const Color(0x1A6366F1) : const Color(0xFFF0F3FF))
                : (isDark ? const Color(0x10FFFFFF) : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLatest
                  ? AppColors.primaryIndigo.withOpacity(0.4)
                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
              width: isLatest ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version & Badge Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: isLatest ? AppGradients.indigoViolet : null,
                      color: isLatest ? null : (isDark ? const Color(0x20FFFFFF) : Colors.black.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      version,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isLatest ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? const Color(0xFF10B981).withOpacity(0.18)
                            : (isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isLatest ? const Color(0xFF10B981) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              // Highlights bullet list
              ...highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isLatest ? AppColors.primaryIndigo : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        h.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Все модули активны',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Отлично', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
