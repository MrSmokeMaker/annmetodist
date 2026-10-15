import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/method_repository.dart';
import '../models/activity_technique.dart';
import '../models/conspect.dart';
import '../models/printable_card.dart';
import '../models/prompt_version.dart';
import '../models/method_prompt.dart';
import '../models/situation_template.dart';
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
  List<SituationTemplate> get situationTemplates =>
      _methodRepository.situationTemplates;
  List<ActivityTechnique> get activityLibrary =>
      _methodRepository.activityLibrary;
  MethodRepository get methodRepository => _methodRepository;
  StorageService get storageService => _storageService;
  YandexGptService get yandexGptService => _yandexGptService;

  // Шаг 5: Возрастная палитра
  bool _isPreschoolPalette = true;
  bool get isPreschoolPalette => _isPreschoolPalette;

  void setPreschoolPalette(bool isPreschool) {
    if (_isPreschoolPalette != isPreschool) {
      _isPreschoolPalette = isPreschool;
      notifyListeners();
    }
  }

  // Шаг 5: Данные для мини-дашборда из Hive
  int get todayConspectsCount {
    final now = DateTime.now();
    return _conspects.where((c) {
      return c.createdAt.year == now.year &&
          c.createdAt.month == now.month &&
          c.createdAt.day == now.day;
    }).length;
  }

  int get completedTopicsCount {
    final uniqueTopics = _conspects.map((c) => c.topic.trim().toLowerCase()).toSet();
    return uniqueTopics.length;
  }

  int get averageDurationMinutes {
    if (_conspects.isEmpty) return 20;
    int totalMins = 0;
    int count = 0;
    for (final c in _conspects) {
      final match = RegExp(r'(\d+)').firstMatch(c.duration);
      if (match != null) {
        totalMins += int.tryParse(match.group(1)!) ?? 20;
        count++;
      }
    }
    return count > 0 ? (totalMins / count).round() : 20;
  }

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

  // Шаг 2: Получение истории тегов обратной связи для адаптации промпта
  List<String> getRecentFeedbackTags() {
    final Set<String> tags = {};
    for (final c in _conspects) {
      tags.addAll(c.feedbackTags);
    }
    return tags.toList();
  }

  // Шаг 2: Одиночная или пакетная генерация
  Future<Conspect> generateConspect({
    required MethodPrompt method,
    required String ageGroup,
    required String topicTitle,
    required String duration,
    String? review,
    String? notes,
    SituationTemplate? situation,
    List<ActivityTechnique>? activities,
    int variantIndex = 1,
    int totalVariants = 1,
    String? batchGroupId,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final historyTags = getRecentFeedbackTags();

      final systemPrompt = PromptBuilder.buildSystemPrompt(
        methodBlock: method.promptBlock,
        topic: topicTitle,
        ageGroup: Topic.getAgeGroupLabel(ageGroup),
        duration: duration,
        review: review,
        notes: notes,
        situationRules: situation?.extraPromptRules,
        activitySamples: activities?.map((a) => a.sampleText).toList(),
        historicalFeedbackTags: historyTags,
        variantIndex: variantIndex,
        totalVariants: totalVariants,
      );

      final userPrompt = PromptBuilder.buildUserPrompt(
        methodName: method.name,
        topic: topicTitle,
        ageGroup: Topic.getAgeGroupLabel(ageGroup),
        duration: duration,
        situationTitle: situation?.title,
        variantIndex: totalVariants > 1 ? variantIndex : null,
      );

      final generatedText = await _yandexGptService.generateConspect(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      final titleSuffix = totalVariants > 1 ? ' (Вариант $variantIndex)' : '';

      final cards = PromptBuilder.extractPrintableCards(generatedText);
      final parentAudio = PromptBuilder.extractParentAudioScript(generatedText);

      // Шаг 6: Кэширование версии промпта в prompt_versions
      final existingPv = _storageService.getLatestPromptVersion(method.id);
      final nextVersion = (existingPv?.version ?? 0) + 1;
      final promptVersion = PromptVersion(
        id: '${method.id}_v$nextVersion',
        methodId: method.id,
        version: nextVersion,
        content: systemPrompt,
        createdAt: DateTime.now(),
      );
      await _storageService.savePromptVersion(promptVersion);

      final conspect = Conspect(
        id: '${DateTime.now().millisecondsSinceEpoch}_$variantIndex',
        title: '$topicTitle$titleSuffix',
        methodId: method.id,
        methodName: method.name,
        subject: method.subject,
        ageGroup: ageGroup,
        topic: topicTitle,
        duration: duration,
        review: review ?? '',
        notes: notes ?? '',
        content: generatedText,
        variantIndex: variantIndex,
        batchGroupId: batchGroupId,
        cards: cards.isNotEmpty ? cards : null,
        parentAudioScript: parentAudio,
        promptVersionId: promptVersion.id,
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

  // Шаг 2: Пакетная генерация 3 вариантов подряд
  Future<List<Conspect>> generateBatchConspects({
    required MethodPrompt method,
    required String ageGroup,
    required String topicTitle,
    required String duration,
    String? review,
    String? notes,
    SituationTemplate? situation,
    List<ActivityTechnique>? activities,
    int variantsCount = 3,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    final List<Conspect> variants = [];
    final batchGroupId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      for (int i = 1; i <= variantsCount; i++) {
        final variant = await generateConspect(
          method: method,
          ageGroup: ageGroup,
          topicTitle: topicTitle,
          duration: duration,
          review: review,
          notes: notes,
          situation: situation,
          activities: activities,
          variantIndex: i,
          totalVariants: variantsCount,
          batchGroupId: batchGroupId,
        );
        variants.add(variant);
        await saveConspect(variant);
      }
      return variants;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Шаг 2: Переключение тегов обратной связи («Было трудно», «Справился легко», «Слишком много письма»)
  Future<void> toggleFeedbackTag(String conspectId, String tag) async {
    final index = _conspects.indexWhere((c) => c.id == conspectId);
    if (index == -1) return;

    final current = _conspects[index];
    final List<String> updatedTags = List.from(current.feedbackTags);

    if (updatedTags.contains(tag)) {
      updatedTags.remove(tag);
    } else {
      updatedTags.add(tag);
    }

    final updated = current.copyWith(
      feedbackTags: updatedTags,
      updatedAt: DateTime.now(),
    );

    await saveConspect(updated);
  }

  // Шаг 3: Генерация карточек для существующего конспекта
  Future<List<PrintableCard>> generateCardsForConspect(String conspectId) async {
    final index = _conspects.indexWhere((c) => c.id == conspectId);
    if (index == -1) return [];

    final conspect = _conspects[index];
    final prompts = PromptBuilder.buildCardsOnlyPrompt(
      topic: conspect.topic,
      ageGroup: Topic.getAgeGroupLabel(conspect.ageGroup),
      conspectContent: conspect.content,
    );

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _yandexGptService.generateConspect(
        systemPrompt: prompts['systemPrompt']!,
        userPrompt: prompts['userPrompt']!,
      );

      final cards = PromptBuilder.extractPrintableCards(response);
      if (cards.isNotEmpty) {
        final updated = conspect.copyWith(
          cards: cards,
          updatedAt: DateTime.now(),
        );
        await saveConspect(updated);
        return cards;
      }
      return [];
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

  // Шаг 6: Обновление заметок родителя
  Future<void> updateParentNotes(String conspectId, String notes) async {
    final index = _conspects.indexWhere((c) => c.id == conspectId);
    if (index == -1) return;

    final updated = _conspects[index].copyWith(
      parentNotes: notes,
      updatedAt: DateTime.now(),
    );
    await saveConspect(updated);
  }

  // Шаг 6: Экспорт библиотеки в ZIP
  Uint8List exportLibraryZip() {
    return _storageService.exportLibraryZip(
      methodsData: _methodRepository.methods.map((m) => m.toJson()).toList(),
      topicsData: _methodRepository.topics.map((t) => t.toJson()).toList(),
      situationsData: _methodRepository.situationTemplates.map((s) => s.toJson()).toList(),
      activitiesData: _methodRepository.activityLibrary.map((a) => a.toJson()).toList(),
    );
  }

  // Шаг 6: Импорт библиотеки из ZIP
  Future<Map<String, int>> importLibraryZip(List<int> bytes) async {
    final result = await _storageService.importLibraryZip(bytes);
    _conspects = _storageService.getAllConspects();
    notifyListeners();
    return result;
  }
}
