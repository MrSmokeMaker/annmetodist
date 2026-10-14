import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/conspect.dart';

class StorageService {
  static const String _conspectBoxName = 'conspects_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _apiKeyStorageKey = 'yandex_api_key';
  static const String _folderIdStorageKey = 'yandex_folder_id';
  static const String _themeModeKey = 'theme_mode';

  // Defaults provided by user
  static const String defaultApiKey = 'REMOVED_API_KEY';
  static const String defaultFolderId = 'REMOVED_FOLDER_ID';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box _conspectsBox;
  late Box _settingsBox;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _conspectsBox = await Hive.openBox(_conspectBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Seed defaults if empty
    final existingKey = await _secureStorage.read(key: _apiKeyStorageKey);
    if (existingKey == null || existingKey.isEmpty) {
      await _secureStorage.write(key: _apiKeyStorageKey, value: defaultApiKey);
    }
    final existingFolder = await _secureStorage.read(key: _folderIdStorageKey);
    if (existingFolder == null || existingFolder.isEmpty) {
      await _secureStorage.write(key: _folderIdStorageKey, value: defaultFolderId);
    }

    _isInitialized = true;
  }

  // --- API Key & Folder ID Management (Secure Storage) ---

  Future<String?> getApiKey() async {
    final key = await _secureStorage.read(key: _apiKeyStorageKey);
    return (key != null && key.isNotEmpty) ? key : defaultApiKey;
  }

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey.trim());
  }

  Future<String?> getFolderId() async {
    final folder = await _secureStorage.read(key: _folderIdStorageKey);
    return (folder != null && folder.isNotEmpty) ? folder : defaultFolderId;
  }

  Future<void> saveFolderId(String folderId) async {
    await _secureStorage.write(key: _folderIdStorageKey, value: folderId.trim());
  }

  Future<void> deleteCredentials() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
    await _secureStorage.delete(key: _folderIdStorageKey);
  }

  // --- Conspects Management (Hive Box) ---

  List<Conspect> getAllConspects() {
    final List<Conspect> list = [];
    for (var i = 0; i < _conspectsBox.length; i++) {
      final raw = _conspectsBox.getAt(i);
      if (raw != null) {
        if (raw is Map) {
          list.add(Conspect.fromMap(raw));
        }
      }
    }
    // Sort descending by creation date
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveConspect(Conspect conspect) async {
    await _conspectsBox.put(conspect.id, conspect.toMap());
  }

  Future<void> deleteConspect(String id) async {
    await _conspectsBox.delete(id);
  }

  Conspect? getConspectById(String id) {
    final raw = _conspectsBox.get(id);
    if (raw != null && raw is Map) {
      return Conspect.fromMap(raw);
    }
    return null;
  }

  // --- Settings & Theme Mode ---

  bool get isDarkMode {
    return _settingsBox.get(_themeModeKey, defaultValue: true) as bool;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put(_themeModeKey, isDark);
  }
}
