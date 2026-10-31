import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';

/// Полноэкранная страница новостей и истории релизов для мобильной и десктопной версий
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
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
    } catch (_) {
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
    final currentVersion = _newsData?['currentVersion'] ?? 'v0.5.6';
    final releases = (_newsData?['releases'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.cyanBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Что нового',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
              ),
              child: Text(
                currentVersion,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        // Welcome Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                                  : [const Color(0xFFEFF6FF), const Color(0xFFF5F3FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.indigoViolet,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'История обновлений платформы',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Актуальная версия $currentVersion. Мы постоянно развиваем «Методист Pro» и добавляем новые возможности для педагогов.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Releases
                        ...releases.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final rel = entry.value as Map<String, dynamic>;
                          final version = rel['version'] ?? '';
                          final date = rel['date'] ?? '';
                          final title = rel['title'] ?? '';
                          final badge = rel['badge'] ?? '';
                          final highlights = (rel['highlights'] as List<dynamic>?) ?? [];
                          final isLatest = idx == 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? (isDark ? const Color(0xFF161B2E) : const Color(0xFFF8FAFC))
                                    : (isDark ? const Color(0xFF111422) : const Color(0xFFFAFAFA)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isLatest
                                      ? const Color(0xFF4F46E5).withOpacity(0.55)
                                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                                  width: isLatest ? 1.6 : 1.0,
                                ),
                                boxShadow: isLatest
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withOpacity(0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top version header using Wrap to prevent flex overflow on narrow screens
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              gradient: isLatest ? AppGradients.indigoViolet : null,
                                              color: isLatest
                                                  ? null
                                                  : (isDark ? const Color(0x20FFFFFF) : Colors.black.withOpacity(0.08)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              version,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isLatest
                                                    ? Colors.white
                                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (badge.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isLatest
                                                    ? const Color(0xFF10B981).withOpacity(0.18)
                                                    : (isDark ? const Color(0x18FFFFFF) : Colors.black.withOpacity(0.05)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                badge,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isLatest
                                                      ? const Color(0xFF10B981)
                                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        date,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  ...highlights.map((h) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(top: 5, right: 10),
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: isLatest
                                                    ? AppColors.primaryIndigo
                                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                h.toString(),
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  height: 1.4,
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
