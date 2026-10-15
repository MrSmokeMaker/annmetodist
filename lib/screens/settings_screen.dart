import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';
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
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _folderIdController = TextEditingController();
  bool _obscureKey = true;
  bool _isChecking = false;
  String? _checkStatus;
  bool? _isCheckSuccessful;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _folderIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final provider = context.read<AppProvider>();
    final key = await provider.getApiKey();
    final folder = await provider.getFolderId();
    setState(() {
      _apiKeyController.text = key ?? StorageService.defaultApiKey;
      _folderIdController.text = folder ?? StorageService.defaultFolderId;
    });
  }

  Future<void> _saveCredentials() async {
    final provider = context.read<AppProvider>();
    final key = _apiKeyController.text.trim();
    final folder = _folderIdController.text.trim();

    await provider.saveApiKey(key);
    await provider.saveFolderId(folder);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Параметры YandexGPT сохранены в защищённом хранилище.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _verifyConnection() async {
    final key = _apiKeyController.text.trim();
    final folder = _folderIdController.text.trim();

    if (key.isEmpty) {
      setState(() {
        _checkStatus = 'Сначала введите API-ключ.';
        _isCheckSuccessful = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _checkStatus = null;
      _isCheckSuccessful = null;
    });

    final provider = context.read<AppProvider>();
    final result = await provider.verifyCredentials(
      apiKey: key,
      folderId: folder,
    );

    if (!mounted) return;

    final success = result['success'] == true;
    final message = result['message'] as String? ?? 'Неизвестная ошибка';

    setState(() {
      _isChecking = false;
      _isCheckSuccessful = success;
      _checkStatus = message;
    });

    if (success) {
      await provider.saveApiKey(key);
      await provider.saveFolderId(folder);
    }
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

              // YandexGPT API Credentials Card
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
                                'YandexGPT (Яндекс Облако)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                'Foundation Models API',
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
                    const SizedBox(height: AppSpacing.lg),

                    // 1. API Key Field
                    GlassTextField(
                      controller: _apiKeyController,
                      label: 'API-ключ сервисного аккаунта',
                      hintText: 'AQVN10Dn4tYMhRseIKesp...',
                      obscureText: _obscureKey,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureKey = !_obscureKey;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 2. Folder ID Field
                    GlassTextField(
                      controller: _folderIdController,
                      label: 'Идентификатор каталога (Folder ID)',
                      hintText: 'REMOVED_FOLDER_ID',
                      prefixIcon: Icons.folder_outlined,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Ключ и каталог сохраняются локально в зашифрованном виде (Secure Storage). Запросы отправляются напрямую в Yandex Cloud API.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

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
                            onPressed: _isChecking ? null : _verifyConnection,
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
                            onPressed: _saveCredentials,
                          ),
                        ),
                      ],
                    ),

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
