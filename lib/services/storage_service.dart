import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conspect.dart';
import '../models/prompt_version.dart';
import '../models/scheduled_lesson.dart';

class StorageService {
  static const String _conspectsStorageKey = 'local_conspects_v2';
  static const String _scheduledLessonsStorageKey = 'scheduled_lessons_v1';
  static const String _promptVersionsStorageKey = 'local_prompt_versions_v2';
  static const String _apiKeyStorageKey = 'yandex_api_key';
  static const String _folderIdStorageKey = 'yandex_folder_id';
  static const String _themeModeKey = 'theme_mode';
  static const String _proxyUrlStorageKey = 'proxy_url';
  static const String _userTierStorageKey = 'user_subscription_tier';
  static const String _aiProviderStorageKey = 'active_ai_provider';
  static const String _openRouterApiKeyStorageKey = 'openrouter_api_key';
  static const String _openRouterModelStorageKey = 'openrouter_model';
  static const String _mistralApiKeyStorageKey = 'mistral_api_key';
  static const String _mistralModelStorageKey = 'mistral_model';

  String getAiProvider() {
    if (!_isInitialized) return 'yandex';
    return _sharedPreferences.getString(_aiProviderStorageKey) ?? 'yandex';
  }

  Future<void> saveAiProvider(String provider) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(_aiProviderStorageKey, provider);
  }

  String? getOpenRouterApiKey() {
    if (!_isInitialized) return null;
    return _sharedPreferences.getString(_openRouterApiKeyStorageKey);
  }

  Future<void> saveOpenRouterApiKey(String apiKey) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(_openRouterApiKeyStorageKey, apiKey);
  }

  String getOpenRouterModel() {
    if (!_isInitialized) return 'deepseek/deepseek-chat:free';
    return _sharedPreferences.getString(_openRouterModelStorageKey) ?? 'deepseek/deepseek-chat:free';
  }

  Future<void> saveOpenRouterModel(String model) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(_openRouterModelStorageKey, model);
  }

  String? getMistralApiKey() {
    if (!_isInitialized) return null;
    return _sharedPreferences.getString(_mistralApiKeyStorageKey);
  }

  Future<void> saveMistralApiKey(String apiKey) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(_mistralApiKeyStorageKey, apiKey);
  }

  String getMistralModel() {
    if (!_isInitialized) return 'mistral-large-latest';
    return _sharedPreferences.getString(_mistralModelStorageKey) ?? 'mistral-large-latest';
  }

  Future<void> saveMistralModel(String model) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(_mistralModelStorageKey, model);
  }

  String getUserTier() {
    if (!_isInitialized) return 'pro';
    return _sharedPreferences.getString(_userTierStorageKey) ?? 'pro';
  }

  Future<void> saveUserTier(String tier) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(_userTierStorageKey, tier);
  }

  bool get hasPackageBundleAccess {
    final tier = getUserTier();
    return tier == 'practice' || tier == 'pro' || tier == 'director' || tier == 'developer';
  }

  bool get hasDirectorAccess {
    final tier = getUserTier();
    return tier == 'director' || tier == 'developer';
  }

  Future<String?> getCustomString(String key) async {
    if (!_isInitialized) return null;
    return _sharedPreferences.getString(key);
  }

  Future<void> saveCustomString(String key, String value) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setString(key, value);
  }

  bool get hasProAccess {
    final tier = getUserTier();
    return tier == 'pro' || tier == 'director' || tier == 'developer';
  }


  // Defaults provided by user
  static const String defaultApiKey = 'REMOVED_API_KEY';
  static const String defaultFolderId = 'REMOVED_FOLDER_ID';
  static const String defaultProxyUrl = 'https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c';

  late SharedPreferences _sharedPreferences;
  final Map<String, Conspect> _conspectsCache = {};
  final Map<String, ScheduledLesson> _scheduledLessonsCache = {};
  final List<PromptVersion> _promptVersionsCache = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _sharedPreferences = await SharedPreferences.getInstance();

      // Load cached local conspects from SharedPreferences
      _loadLocalConspects();
      _loadLocalPromptVersions();
      _loadLocalScheduledLessons();

      _isInitialized = true;

      // Seed defaults if empty
      final existingKey = _sharedPreferences.getString(_apiKeyStorageKey);
      if (existingKey == null || existingKey.isEmpty) {
        await _sharedPreferences.setString(_apiKeyStorageKey, defaultApiKey);
      }
      final existingFolder = _sharedPreferences.getString(_folderIdStorageKey);
      if (existingFolder == null || existingFolder.isEmpty) {
        await _sharedPreferences.setString(_folderIdStorageKey, defaultFolderId);
      }
      final existingProxy = _sharedPreferences.getString(_proxyUrlStorageKey);
      if (existingProxy == null || existingProxy.isEmpty) {
        await _sharedPreferences.setString(_proxyUrlStorageKey, defaultProxyUrl);
      }
    } catch (e) {
      debugPrint('StorageService init error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  void _loadLocalConspects() {
    try {
      final raw = _sharedPreferences.getString(_conspectsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _conspectsCache.clear();
          for (final item in decoded) {
            if (item is Map) {
              final c = Conspect.fromMap(item);
              _conspectsCache[c.id] = c;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached conspects: $e');
    }
  }

  Future<void> _persistLocalConspects() async {
    try {
      final list = _conspectsCache.values.map((c) => c.toMap()).toList();
      await _sharedPreferences.setString(_conspectsStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting conspects: $e');
    }
  }

  void _loadLocalScheduledLessons() {
    try {
      final raw = _sharedPreferences.getString(_scheduledLessonsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _scheduledLessonsCache.clear();
          for (final item in decoded) {
            if (item is Map) {
              final l = ScheduledLesson.fromMap(Map<String, dynamic>.from(item));
              _scheduledLessonsCache[l.id] = l;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached scheduled lessons: $e');
    }
  }

  Future<void> _persistLocalScheduledLessons() async {
    try {
      final list = _scheduledLessonsCache.values.map((l) => l.toMap()).toList();
      await _sharedPreferences.setString(_scheduledLessonsStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting scheduled lessons: $e');
    }
  }

  List<ScheduledLesson> getAllScheduledLessons() {
    final list = _scheduledLessonsCache.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> saveScheduledLesson(ScheduledLesson lesson) async {
    _scheduledLessonsCache[lesson.id] = lesson;
    await _persistLocalScheduledLessons();
  }

  Future<void> deleteScheduledLesson(String id) async {
    _scheduledLessonsCache.remove(id);
    await _persistLocalScheduledLessons();
  }

  void _loadLocalPromptVersions() {
    try {
      final raw = _sharedPreferences.getString(_promptVersionsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _promptVersionsCache.clear();
          for (final item in decoded) {
            if (item is Map) {
              _promptVersionsCache.add(PromptVersion.fromMap(item));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached prompt versions: $e');
    }
  }

  Future<void> _persistLocalPromptVersions() async {
    try {
      final list = _promptVersionsCache.map((p) => p.toMap()).toList();
      await _sharedPreferences.setString(_promptVersionsStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting prompt versions: $e');
    }
  }

  // --- API Key & Folder ID Management ---

  Future<String?> getApiKey() async {
    try {
      final key = _sharedPreferences.getString(_apiKeyStorageKey);
      if (key != null && key.isNotEmpty) return key;
    } catch (_) {}
    return defaultApiKey;
  }

  Future<void> saveApiKey(String apiKey) async {
    try {
      await _sharedPreferences.setString(_apiKeyStorageKey, apiKey.trim());
    } catch (_) {}
  }

  Future<String?> getFolderId() async {
    try {
      final folder = _sharedPreferences.getString(_folderIdStorageKey);
      if (folder != null && folder.isNotEmpty) return folder;
    } catch (_) {}
    return defaultFolderId;
  }

  Future<void> saveFolderId(String folderId) async {
    try {
      await _sharedPreferences.setString(_folderIdStorageKey, folderId.trim());
    } catch (_) {}
  }

  Future<void> deleteCredentials() async {
    try {
      await _sharedPreferences.remove(_apiKeyStorageKey);
      await _sharedPreferences.remove(_folderIdStorageKey);
    } catch (_) {}
  }

  // --- Conspects Management (Supabase with Local Cache) ---

  List<Conspect> getAllConspects() {
    final list = _conspectsCache.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> syncConspectsFromSupabase() async {
    final client = _supabase;
    if (client == null || client.auth.currentUser == null) return;

    try {
      final userId = client.auth.currentUser!.id;
      final response = await client
          .from('conspects')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response is List) {
        _conspectsCache.clear();
        for (final item in response) {
          final c = Conspect.fromMap(item as Map<String, dynamic>);
          _conspectsCache[c.id] = c;
        }
        await _persistLocalConspects();
      }
    } catch (e) {
      debugPrint('Error syncing conspects from Supabase: $e');
    }
  }

  Future<void> saveConspect(Conspect conspect) async {
    _conspectsCache[conspect.id] = conspect;
    await _persistLocalConspects();

    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      try {
        final data = conspect.toMap();
        data['user_id'] = client.auth.currentUser!.id;
        await client.from('conspects').upsert(data);
      } catch (e) {
        debugPrint('Error saving conspect to Supabase: $e');
      }
    }
  }

  Future<void> deleteConspect(String id) async {
    _conspectsCache.remove(id);
    await _persistLocalConspects();

    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client.from('conspects').delete().eq('id', id);
      } catch (e) {
        debugPrint('Error deleting conspect from Supabase: $e');
      }
    }
  }

  Conspect? getConspectById(String id) {
    return _conspectsCache[id];
  }

  // --- Settings & Theme Mode ---

  bool get isDarkMode {
    if (!_isInitialized) return true;
    return _sharedPreferences.getBool(_themeModeKey) ?? true;
  }

  Future<void> setDarkMode(bool isDark) async {
    if (!_isInitialized) return;
    await _sharedPreferences.setBool(_themeModeKey, isDark);
  }

  Future<String?> getProxyUrl() async {
    try {
      final url = _sharedPreferences.getString(_proxyUrlStorageKey);
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
    return defaultProxyUrl;
  }

  Future<void> saveProxyUrl(String url) async {
    try {
      await _sharedPreferences.setString(_proxyUrlStorageKey, url.trim());
    } catch (_) {}
  }

  // --- Prompt Versions Cache & Supabase Sync ---

  Future<void> savePromptVersion(PromptVersion version) async {
    _promptVersionsCache.removeWhere((p) => p.id == version.id);
    _promptVersionsCache.add(version);
    await _persistLocalPromptVersions();

    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      try {
        final data = version.toMap();
        data['user_id'] = client.auth.currentUser!.id;
        await client.from('prompt_versions').upsert(data);
      } catch (e) {
        debugPrint('Error saving prompt version to Supabase: $e');
      }
    }
  }

  List<PromptVersion> getPromptVersionsForMethod(String methodId) {
    final list = _promptVersionsCache.where((pv) => pv.methodId == methodId).toList();
    list.sort((a, b) => b.version.compareTo(a.version));
    return list;
  }

  PromptVersion? getLatestPromptVersion(String methodId) {
    final list = getPromptVersionsForMethod(methodId);
    return list.isNotEmpty ? list.first : null;
  }

  List<PromptVersion> getAllPromptVersions() {
    return List.unmodifiable(_promptVersionsCache);
  }

  // --- Экспорт и Импорт библиотеки (ZIP-архив) ---

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
    return Uint8List.fromList(zipData ?? []);
  }

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
