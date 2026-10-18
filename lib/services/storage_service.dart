import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _apiKeyKey = 'yandex_api_key';
  static const _folderIdKey = 'yandex_folder_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  Future<void> setFolderId(String folderId) async {
    await _secureStorage.write(key: _folderIdKey, value: folderId);
  }

  Future<String?> getFolderId() async {
    return await _secureStorage.read(key: _folderIdKey);
  }
}
