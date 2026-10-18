import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _folderIdController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final apiKey = await _secureStorage.read(key: 'yandex_api_key');
    final folderId = await _secureStorage.read(key: 'yandex_folder_id');
    if (apiKey != null) _apiKeyController.text = apiKey;
    if (folderId != null) _folderIdController.text = folderId;
  }

  Future<void> _save() async {
    await _secureStorage.write(key: 'yandex_api_key', value: _apiKeyController.text.trim());
    await _secureStorage.write(key: 'yandex_folder_id', value: _folderIdController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Секреты сохранены')));
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
      appBar: AppBar(title: const Text('Настройки API')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API‑key Yandex',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _folderIdController,
              decoration: const InputDecoration(
                labelText: 'Folder ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
