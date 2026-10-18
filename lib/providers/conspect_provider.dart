import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/yandex_gpt_service.dart';

class ConspectProvider extends ChangeNotifier {
  final YandexGptService _service = YandexGptService();
  String _result = '';
  bool _isLoading = false;
  String get result => _result;
  bool get isLoading => _isLoading;

  Future<void> generateConspect(String prompt) async {
    _isLoading = true;
    _result = '';
    notifyListeners();
    try {
      final response = await _service.generate(prompt);
      _result = response;
    } catch (e) {
      _result = 'Ошибка: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
