import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Сервис хранения секретных данных (API-ключ и Folder ID).
/// Использует [FlutterSecureStorage] с автоматическим резервным переключением
/// на [Hive] при недоступности безопасного хранилища.
class StorageService {
  static const _apiKeyKey = 'yandex_api_key';
  static const _folderIdKey = 'yandex_folder_id';
  static const _hiveBoxName = 'metodist_settings';

  final FlutterSecureStorage _secureStorage;
  Box? _hiveBox;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Box?> _getHiveBox() async {
    try {
      if (_hiveBox != null && _hiveBox!.isOpen) {
        return _hiveBox;
      }
      _hiveBox = await Hive.openBox(_hiveBoxName);
      return _hiveBox;
    } catch (e) {
      return null;
    }
  }

  Future<void> setApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    try {
      await _secureStorage.write(key: _apiKeyKey, value: trimmed);
    } catch (e) {
      debugPrint('StorageService: FlutterSecureStorage.write failed: $e');
    }

    try {
      final box = await _getHiveBox();
      if (box != null) {
        await box.put(_apiKeyKey, trimmed);
      }
    } catch (_) {}
  }

  Future<String?> getApiKey() async {
    try {
      final key = await _secureStorage.read(key: _apiKeyKey);
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      debugPrint('StorageService: FlutterSecureStorage.read failed: $e');
    }

    try {
      final box = await _getHiveBox();
      if (box != null) {
        final key = box.get(_apiKeyKey) as String?;
        if (key != null && key.isNotEmpty) {
          return key;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> setFolderId(String folderId) async {
    final trimmed = folderId.trim();
    try {
      await _secureStorage.write(key: _folderIdKey, value: trimmed);
    } catch (e) {
      debugPrint('StorageService: FlutterSecureStorage.write failed: $e');
    }

    try {
      final box = await _getHiveBox();
      if (box != null) {
        await box.put(_folderIdKey, trimmed);
      }
    } catch (_) {}
  }

  Future<String?> getFolderId() async {
    try {
      final id = await _secureStorage.read(key: _folderIdKey);
      if (id != null && id.isNotEmpty) {
        return id;
      }
    } catch (e) {
      debugPrint('StorageService: FlutterSecureStorage.read failed: $e');
    }

    try {
      final box = await _getHiveBox();
      if (box != null) {
        final id = box.get(_folderIdKey) as String?;
        if (id != null && id.isNotEmpty) {
          return id;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> clear() async {
    try {
      await _secureStorage.delete(key: _apiKeyKey);
      await _secureStorage.delete(key: _folderIdKey);
    } catch (_) {}

    try {
      final box = await _getHiveBox();
      if (box != null) {
        await box.delete(_apiKeyKey);
        await box.delete(_folderIdKey);
      }
    } catch (_) {}
  }
}
