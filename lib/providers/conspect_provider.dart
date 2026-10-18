import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/yandex_gpt_service.dart';

class ConspectProvider extends ChangeNotifier {
  final StorageService _storageService;
  final YandexGptService _gptService;

  String _result = '';
  String? _errorMessage;
  bool _isLoading = false;

  ConspectProvider({
    StorageService? storageService,
    YandexGptService? gptService,
  })  : _storageService = storageService ?? StorageService(),
        _gptService = gptService ??
            YandexGptService(
              storageService: storageService ?? StorageService(),
            );

  String get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasResult => _result.isNotEmpty;

  /// Проверяет, заполнены ли ключи в хранилище.
  Future<bool> hasCredentials() async {
    final key = await _storageService.getApiKey();
    final folder = await _storageService.getFolderId();
    return key != null && key.isNotEmpty && folder != null && folder.isNotEmpty;
  }

  /// Генерация конспекта
  Future<void> generateConspect(
    String userPrompt, {
    String? systemPrompt,
    String? model,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _result = '';
    notifyListeners();

    try {
      final defaultSys = systemPrompt ??
          'Вы — опытный методист и педагог начальных и средних классов. '
          'Составьте подробный, структурированный конспект урока с целями, задачами, '
          'этапами занятия, методическими приемами, активностями для учеников и критериями оценки. '
          'Оформляйте ответ красиво с использованием заголовков, списков и Markdown.';

      final response = await _gptService.generateConspect(
        systemPrompt: defaultSys,
        userPrompt: userPrompt,
        model: model ?? YandexGptService.defaultModel,
      );

      _result = response;
    } catch (e) {
      if (e is YandexGptException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Очистить результат
  void clearResult() {
    _result = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Скопировать конспект в буфер обмена
  Future<void> copyToClipboard() async {
    if (_result.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _result));
    }
  }
}
