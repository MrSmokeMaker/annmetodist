import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/conspect.dart';
import '../models/prompt_version.dart';

class StorageService {
  static const String _conspectBoxName = 'conspects_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _promptVersionsBoxName = 'prompt_versions';
  static const String _apiKeyStorageKey = 'yandex_api_key';
  static const String _folderIdStorageKey = 'yandex_folder_id';
  static const String _themeModeKey = 'theme_mode';

  // Defaults provided by user
  static const String defaultApiKey = 'REMOVED_API_KEY';
  static const String defaultFolderId = 'REMOVED_FOLDER_ID';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box _conspectsBox;
  late Box _settingsBox;
  late Box _promptVersionsBox;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _conspectsBox = await Hive.openBox(_conspectBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _promptVersionsBox = await Hive.openBox(_promptVersionsBoxName);

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

  // --- Шаг 6: Таблица prompt_versions (Кэш версий промптов) ---

  Future<void> savePromptVersion(PromptVersion version) async {
    await _promptVersionsBox.put(version.id, version.toMap());
  }

  List<PromptVersion> getPromptVersionsForMethod(String methodId) {
    final List<PromptVersion> list = [];
    for (var i = 0; i < _promptVersionsBox.length; i++) {
      final raw = _promptVersionsBox.getAt(i);
      if (raw != null && raw is Map) {
        final pv = PromptVersion.fromMap(raw);
        if (pv.methodId == methodId) {
          list.add(pv);
        }
      }
    }
    list.sort((a, b) => b.version.compareTo(a.version));
    return list;
  }

  PromptVersion? getLatestPromptVersion(String methodId) {
    final list = getPromptVersionsForMethod(methodId);
    return list.isNotEmpty ? list.first : null;
  }

  List<PromptVersion> getAllPromptVersions() {
    final List<PromptVersion> list = [];
    for (var i = 0; i < _promptVersionsBox.length; i++) {
      final raw = _promptVersionsBox.getAt(i);
      if (raw != null && raw is Map) {
        list.add(PromptVersion.fromMap(raw));
      }
    }
    return list;
  }

  // --- Шаг 6: Экспорт и Импорт библиотеки (ZIP-архив) ---

  /// Экспорт всей библиотеки в бинарный ZIP-архив
  Uint8List exportLibraryZip({
    required List<Map<String, dynamic>> methodsData,
    required List<Map<String, dynamic>> topicsData,
    required List<Map<String, dynamic>> situationsData,
    required List<Map<String, dynamic>> activitiesData,
  }) {
    final archive = Archive();

    // 1. conspects.json
    final conspects = getAllConspects().map((c) => c.toMap()).toList();
    final conspectsBytes = utf8.encode(jsonEncode(conspects));
    archive.addFile(ArchiveFile('conspects.json', conspectsBytes.length, conspectsBytes));

    // 2. prompt_versions.json
    final promptVersions = getAllPromptVersions().map((p) => p.toMap()).toList();
    final promptVersionsBytes = utf8.encode(jsonEncode(promptVersions));
    archive.addFile(ArchiveFile('prompt_versions.json', promptVersionsBytes.length, promptVersionsBytes));

    // 3. methods.json, topics.json, situations.json, activities.json
    final methodsBytes = utf8.encode(jsonEncode(methodsData));
    archive.addFile(ArchiveFile('methods.json', methodsBytes.length, methodsBytes));

    final topicsBytes = utf8.encode(jsonEncode(topicsData));
    archive.addFile(ArchiveFile('topics.json', topicsBytes.length, topicsBytes));

    final situationsBytes = utf8.encode(jsonEncode(situationsData));
    archive.addFile(ArchiveFile('situations.json', situationsBytes.length, situationsBytes));

    final activitiesBytes = utf8.encode(jsonEncode(activitiesData));
    archive.addFile(ArchiveFile('activities.json', activitiesBytes.length, activitiesBytes));

    // 4. library_manifest.json
    final manifest = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Методист',
      'version': '1.0.0',
      'conspects_count': conspects.length,
      'prompt_versions_count': promptVersions.length,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('library_manifest.json', manifestBytes.length, manifestBytes));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// Импорт библиотеки из бинарного ZIP-архива с валидацией и обновлением Hive
  Future<Map<String, int>> importLibraryZip(List<int> zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    int importedConspects = 0;
    int importedPrompts = 0;

    for (final file in archive) {
      if (file.isFile) {
        final contentStr = utf8.decode(file.content as List<int>);

        if (file.name == 'conspects.json') {
          final decoded = jsonDecode(contentStr);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                final conspect = Conspect.fromMap(item);
                await saveConspect(conspect);
                importedConspects++;
              }
            }
          }
        } else if (file.name == 'prompt_versions.json') {
          final decoded = jsonDecode(contentStr);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                final pv = PromptVersion.fromMap(item);
                await savePromptVersion(pv);
                importedPrompts++;
              }
            }
          }
        }
      }
    }

    return {
      'conspects': importedConspects,
      'prompt_versions': importedPrompts,
    };
  }
}
