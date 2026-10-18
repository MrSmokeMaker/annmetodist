import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/yandex_gpt_service.dart';
import '../services/storage_service.dart';

class ConspectProvider extends ChangeNotifier {
  final YandexGptService _service = YandexGptService(storageService: StorageService());
  String _result = '';
  bool _isLoading = false;
  String get result => _result;
  bool get isLoading => _isLoading;

  Future<void> generateConspect(String userPrompt) async {
    _isLoading = true;
    _result = '';
    notifyListeners();
    try {
      final response = await _service.generateConspect(
        systemPrompt: 'You are a helpful assistant.',
        userPrompt: userPrompt,
      );
      _result = response;
    } catch (e) {
      _result = 'Ошибка: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
