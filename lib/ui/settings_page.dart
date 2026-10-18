import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/yandex_gpt_service.dart';

class SettingsPage extends StatefulWidget {
  final StorageService? storageService;
  final YandexGptService? gptService;

  const SettingsPage({
    Key? key,
    this.storageService,
    this.gptService,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final StorageService _storage;
  late final YandexGptService _gptService;

  final _apiKeyController = TextEditingController();
  final _folderIdController = TextEditingController();

  bool _obscureApiKey = true;
  bool _isTesting = false;
  String? _testResultMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? StorageService();
    _gptService = widget.gptService ?? YandexGptService(storageService: _storage);
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final apiKey = await _storage.getApiKey();
    final folderId = await _storage.getFolderId();
    if (mounted) {
      setState(() {
        if (apiKey != null) _apiKeyController.text = apiKey;
        if (folderId != null) _folderIdController.text = folderId;
      });
    }
  }

  Future<void> _save() async {
    final apiKey = _apiKeyController.text.trim();
    final folderId = _folderIdController.text.trim();

    await _storage.setApiKey(apiKey);
    await _storage.setFolderId(folderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки успешно сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    final folderId = _folderIdController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testResultMessage = 'Пожалуйста, введите API-ключ перед проверкой.';
      });
      return;
    }

    if (folderId.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testResultMessage = 'Пожалуйста, введите Folder ID перед проверкой.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResultMessage = null;
    });

    try {
      final result = await _gptService.testConnection(
        apiKey: apiKey,
        folderId: folderId,
      );

      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = result['success'] == true;
          _testResultMessage = result['message'] as String? ?? 'Неизвестный результат';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResultMessage = 'Ошибка: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _folderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки YandexGPT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Инструкция по настройке',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Создайте сервисный аккаунт в Yandex Cloud.\n'
                      '2. Назначьте аккаунту роль "ai.languageModels.user".\n'
                      '3. Создайте API-ключ для этого аккаунта и укажите его ниже.\n'
                      '4. Укажите идентификатор каталога (Folder ID), в котором создан аккаунт.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API-ключ Yandex Cloud',
                hintText: 'AQVN...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _folderIdController,
              decoration: const InputDecoration(
                labelText: 'Идентификатор каталога (Folder ID)',
                hintText: 'b1g...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(_isTesting ? 'Проверка...' : 'Проверить связь'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (_testResultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error,
                      color: _testSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResultMessage!,
                        style: TextStyle(
                          color: _testSuccess
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
