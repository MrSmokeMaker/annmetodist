import 'package:flutter/material.dart';
import '../data/method_repository.dart';
import '../models/conspect.dart';
import '../models/method_prompt.dart';
import '../models/topic.dart';
import '../services/prompt_builder.dart';
import '../services/storage_service.dart';
import '../services/yandex_gpt_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final MethodRepository _methodRepository;
  late final YandexGptService _yandexGptService;

  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  List<Conspect> _conspects = [];
  bool _isDarkMode = true;

  AppProvider({
    required StorageService storageService,
    required MethodRepository methodRepository,
  })  : _storageService = storageService,
        _methodRepository = methodRepository {
    _yandexGptService = YandexGptService(storageService: _storageService);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  List<Conspect> get conspects => _conspects;
  bool get isDarkMode => _isDarkMode;
  List<MethodPrompt> get methods => _methodRepository.methods;
  List<Topic> get topics => _methodRepository.topics;
  MethodRepository get methodRepository => _methodRepository;
  StorageService get storageService => _storageService;
  YandexGptService get yandexGptService => _yandexGptService;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.init();
      _isDarkMode = _storageService.isDarkMode;
      await _methodRepository.loadData();
      _conspects = _storageService.getAllConspects();
    } catch (e) {
      _errorMessage = 'Ошибка инициализации приложения: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Theme Toggle
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  // Credentials Management
  Future<String?> getApiKey() => _storageService.getApiKey();

  Future<void> saveApiKey(String key) async {
    await _storageService.saveApiKey(key);
    notifyListeners();
  }

  Future<String?> getFolderId() => _storageService.getFolderId();

  Future<void> saveFolderId(String folderId) async {
    await _storageService.saveFolderId(folderId);
    notifyListeners();
  }

  Future<Map<String, dynamic>> verifyCredentials({
    String? apiKey,
    String? folderId,
  }) async {
    return await _yandexGptService.testConnection(
      apiKey: apiKey,
      folderId: folderId,
    );
  }

  // Topics Filter
  List<Topic> getTopicsFor(String methodId, String ageGroup) {
    return _methodRepository.getTopicsByFilter(
      methodId: methodId,
      ageGroup: ageGroup,
    );
  }

  // Conspect Generation
  Future<Conspect> generateConspect({
    required MethodPrompt method,
    required String ageGroup,
    required String topicTitle,
    required String duration,
    String? review,
    String? notes,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final systemPrompt = PromptBuilder.buildSystemPrompt(
        methodBlock: method.promptBlock,
        topic: topicTitle,
        ageGroup: Topic.getAgeGroupLabel(ageGroup),
        duration: duration,
        review: review,
        notes: notes,
      );

      final userPrompt = PromptBuilder.buildUserPrompt(
        methodName: method.name,
        topic: topicTitle,
        ageGroup: Topic.getAgeGroupLabel(ageGroup),
        duration: duration,
      );

      final generatedText = await _yandexGptService.generateConspect(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      final conspect = Conspect(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: topicTitle,
        methodId: method.id,
        methodName: method.name,
        subject: method.subject,
        ageGroup: ageGroup,
        topic: topicTitle,
        duration: duration,
        review: review ?? '',
        notes: notes ?? '',
        content: generatedText,
        createdAt: DateTime.now(),
      );

      return conspect;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Library / Conspects CRUD
  Future<void> saveConspect(Conspect conspect) async {
    await _storageService.saveConspect(conspect);
    _conspects = _storageService.getAllConspects();
    notifyListeners();
  }

  Future<void> deleteConspect(String id) async {
    await _storageService.deleteConspect(id);
    _conspects = _storageService.getAllConspects();
    notifyListeners();
  }
}
