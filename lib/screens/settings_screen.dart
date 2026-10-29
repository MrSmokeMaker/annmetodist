import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../widgets/auth_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _proxyUrlController = TextEditingController();
  final TextEditingController _openRouterKeyController = TextEditingController();
  final TextEditingController _mistralKeyController = TextEditingController();
  String _selectedProvider = 'yandex';
  String _selectedOpenRouterModel = 'deepseek/deepseek-chat:free';
  String _selectedMistralModel = 'mistral-large-latest';
  bool _isChecking = false;
  String? _checkStatus;
  bool? _isCheckSuccessful;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _proxyUrlController.dispose();
    _openRouterKeyController.dispose();
    _mistralKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final provider = context.read<AppProvider>();
    final url = await provider.getProxyUrl();
    setState(() {
      _proxyUrlController.text = url ?? '';
      _selectedProvider = provider.activeAiProvider;
      final savedModel = provider.openRouterModel;
      _selectedOpenRouterModel = AiService.availableOpenRouterModels.containsKey(savedModel)
          ? savedModel
          : 'deepseek/deepseek-chat:free';
      _openRouterKeyController.text = provider.openRouterApiKey ?? '';
      _selectedMistralModel = provider.mistralModel;
      _mistralKeyController.text = provider.mistralApiKey ?? '';
    });
  }

  Future<void> _saveAiSettings() async {
    final provider = context.read<AppProvider>();
    final url = _proxyUrlController.text.trim();
    await provider.saveProxyUrl(url);
    await provider.setAiProvider(_selectedProvider);
    await provider.setOpenRouterApiKey(_openRouterKeyController.text.trim());
    await provider.setOpenRouterModel(_selectedOpenRouterModel);
    await provider.setMistralApiKey(_mistralKeyController.text.trim());
    await provider.setMistralModel(_selectedMistralModel);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки ИИ успешно сохранены.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
      _checkStatus = null;
      _isCheckSuccessful = null;
    });
    final provider = context.read<AppProvider>();
    await provider.saveProxyUrl(_proxyUrlController.text.trim());
    await provider.setAiProvider(_selectedProvider);
    await provider.setOpenRouterApiKey(_openRouterKeyController.text.trim());
    await provider.setOpenRouterModel(_selectedOpenRouterModel);
    await provider.setMistralApiKey(_mistralKeyController.text.trim());
    await provider.setMistralModel(_selectedMistralModel);
    final result = await provider.verifyCredentials();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _isCheckSuccessful = result['success'] == true;
      _checkStatus = result['message'] as String? ?? 'Неизвестная ошибка';
    });
  }


  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportLibrary() async {
    setState(() => _isExporting = true);
    try {
      final provider = context.read<AppProvider>();
      final bytes = await provider.exportLibraryZip();
      final filename = 'metodist_library_${DateTime.now().toIso8601String().substring(0, 10)}.zip';
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'application/zip',
        name: filename,
      );
      await Share.shareXFiles(
        [xFile],
        text: 'Экспорт библиотеки Методист (конспекты, методики, шаблоны, приёмы)',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ZIP-архив библиотеки успешно сформирован.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта библиотеки: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importLibrary() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final provider = context.read<AppProvider>();
          final report = await provider.importLibraryZip(bytes);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Импорт завершён! Добавлено/обновлено: ${report['conspects']} конспектов, ${report['prompts']} версий промптов.',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при импорте ZIP-архива: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Supabase Account / Cloud Sync Card
              Builder(
                builder: (context) {
                  final user = SupabaseService().currentUser;
                  return GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    borderRadius: AppRadii.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppGradients.violetMagenta,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: const Icon(
                                Icons.cloud_sync_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user != null ? 'Облачный аккаунт' : 'Синхронизация с облаком',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    user != null
                                        ? (user.email ?? 'Авторизован')
                                        : 'Войдите для сохранения конспектов на всех устройствах',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (user != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await provider.storageService.syncConspectsFromSupabase();
                                    await provider.initialize();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Конспекты синхронизированы с Supabase!')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.sync_rounded, size: 18),
                                  label: const Text('Синхронизировать'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await SupabaseService().signOut();
                                  if (context.mounted) {
                                    (context as Element).markNeedsBuild();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Вы вышли из аккаунта')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                                label: const Text('Выйти', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                AuthDialog.show(context, onAuthSuccess: () async {
                                  await provider.storageService.syncConspectsFromSupabase();
                                  await provider.initialize();
                                  if (context.mounted) (context as Element).markNeedsBuild();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                ),
                              ),
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text('Войти или создать аккаунт'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),
              // Theme Toggle Card
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                borderRadius: AppRadii.lg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Icon(
                            provider.isDarkMode
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Тёмная тема',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              provider.isDarkMode ? 'Включена' : 'Выключена',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: provider.isDarkMode,
                      activeColor: AppColors.primaryIndigo,
                      onChanged: (val) {
                        provider.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // AI Provider and Credentials Card
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                borderRadius: AppRadii.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppGradients.indigoViolet,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Искусственный интеллект',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                _selectedProvider == 'mistral'
                                    ? 'Mistral AI (Large 2 / NeMo)'
                                    : (_selectedProvider == 'openrouter'
                                        ? 'OpenRouter (Qwen / DeepSeek)'
                                        : 'YandexGPT (Яндекс Облако)'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Provider switcher tabs (Yandex / Mistral / OpenRouter)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedProvider = 'yandex';
                                  _checkStatus = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedProvider == 'yandex'
                                      ? AppColors.primaryIndigo
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Center(
                                  child: Text(
                                    '🤖 Yandex',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedProvider == 'yandex'
                                          ? Colors.white
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedProvider = 'mistral';
                                  _checkStatus = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedProvider == 'mistral'
                                      ? AppColors.primaryIndigo
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Center(
                                  child: Text(
                                    '🌪️ Mistral',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedProvider == 'mistral'
                                          ? Colors.white
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedProvider = 'openrouter';
                                  _checkStatus = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedProvider == 'openrouter'
                                      ? AppColors.primaryIndigo
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Center(
                                  child: Text(
                                    '⚡ OpenRouter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedProvider == 'openrouter'
                                          ? Colors.white
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_selectedProvider == 'yandex') ...[
                      Text(
                        'Запросы направляются через серверную функцию для обхода CORS и защиты ключей.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassTextField(
                        controller: _proxyUrlController,
                        label: 'URL прокси‑функции',
                        hintText: 'https://<region>.cloud.yandex.net/...',
                        prefixIcon: Icons.link_outlined,
                      ),
                    ] else if (_selectedProvider == 'mistral') ...[
                      Text(
                        'Mistral AI — открытая европейская модель с первоклассным следованием структуре JSON, высокой скоростью и образцовым оформлением карточек и раздаточных листов.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMistralModel,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                            items: AiService.availableMistralModels.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMistralModel = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassTextField(
                        controller: _mistralKeyController,
                        label: 'API-ключ Mistral AI',
                        hintText: 'Введите ключ (получите на console.mistral.ai/api-keys)',
                        prefixIcon: Icons.vpn_key_outlined,
                        obscureText: true,
                      ),
                    ] else ...[
                      Text(
                        'OpenRouter дает доступ к мощным открытым моделям с глубоким рассуждением и богатой вариативностью заданий (рекомендуется Qwen 2.5 72B Instruct).',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedOpenRouterModel,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                            items: AiService.availableOpenRouterModels.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedOpenRouterModel = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassTextField(
                        controller: _openRouterKeyController,
                        label: 'API-ключ OpenRouter',
                        hintText: 'sk-or-v1-... (получите на openrouter.ai/keys)',
                        prefixIcon: Icons.vpn_key_outlined,
                        obscureText: true,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Test Connection & Save Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            icon: _isChecking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_tethering_rounded, size: 18),
                            label: const Text('Проверить связь'),
                            onPressed: _isChecking ? null : _checkConnection,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryIndigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Сохранить'),
                            onPressed: _saveAiSettings,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Status Message
                    if (_checkStatus != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _isCheckSuccessful == true
                              ? AppColors.success.withOpacity(0.12)
                              : AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: _isCheckSuccessful == true
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isCheckSuccessful == true
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: _isCheckSuccessful == true
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _checkStatus!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: _isCheckSuccessful == true
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Backup & Library ZIP Card
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                borderRadius: AppRadii.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppGradients.cyanBlue,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: const Icon(
                            Icons.archive_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Резервная копия и библиотека',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                'ZIP-архив конспектов, методик и версий промптов',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Выгрузите всю базу конспектов, версионные промпты и каталоги в единый ZIP-архив для переноса на другое устройство или восстановите библиотеку из ранее сохранённого архива.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            icon: _isImporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.file_upload_outlined, size: 18),
                            label: const Text('Импорт ZIP'),
                            onPressed: _isImporting ? null : _importLibrary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryIndigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Экспорт ZIP'),
                            onPressed: _isExporting ? null : _exportLibrary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // About App Card
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                borderRadius: AppRadii.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'О приложении',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Методист — персональный ассистент педагога для генерации авторских поурочных планов и конспектов по классическим отечественным методикам на базе нейросети YandexGPT (Яндекс Облако).',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Версия 1.0.0 (Личное использование)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
