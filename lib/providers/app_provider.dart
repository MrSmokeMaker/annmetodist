import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../data/method_repository.dart';
import '../models/activity_technique.dart';
import '../models/conspect.dart';
import '../models/printable_card.dart';
import '../models/prompt_version.dart';
import '../models/scheduled_lesson.dart';
import '../models/recent_pdf.dart';
import '../models/method_prompt.dart';
import '../models/situation_template.dart';
import '../models/topic.dart';
import '../services/prompt_builder.dart';
import '../services/storage_service.dart';
import '../services/yandex_gpt_service.dart';
import '../services/ai_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final MethodRepository _methodRepository;
  late final YandexGptService _yandexGptService;
  late final AiService _aiService;

  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  List<Conspect> _conspects = [];
  final List<RecentPdf> _recentPdfs = [];
  List<ScheduledLesson> _scheduledLessons = [];
  bool _isDarkMode = true;

  AppProvider({
    required StorageService storageService,
    required MethodRepository methodRepository,
  })  : _storageService = storageService,
        _methodRepository = methodRepository {
    _yandexGptService = YandexGptService(storageService: _storageService);
    _aiService = AiService(
      storageService: _storageService,
      yandexGptService: _yandexGptService,
    );
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  List<Conspect> get conspects => _conspects;
  List<RecentPdf> get recentPdfs => List.unmodifiable(_recentPdfs);
  List<ScheduledLesson> get scheduledLessons => List.unmodifiable(_scheduledLessons);
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
  AiService get aiService => _aiService;
  String get activeAiProvider => _aiService.activeProvider;
  String get openRouterModel => _aiService.openRouterModel;
  String? get openRouterApiKey => _aiService.openRouterApiKey;
  String get mistralModel => _aiService.mistralModel;
  String? get mistralApiKey => _aiService.mistralApiKey;

  // Возрастная группа («Дошкольники», «1 класс», «2 класс»)
  String _selectedAgeGroup = 'preschool';
  String get selectedAgeGroup => _selectedAgeGroup;
  bool get isPreschoolPalette => _selectedAgeGroup == 'preschool';

  void setSelectedAgeGroup(String group) {
    if (_selectedAgeGroup != group) {
      _selectedAgeGroup = group;
      notifyListeners();
    }
  }

  void setPreschoolPalette(bool isPreschool) {
    setSelectedAgeGroup(isPreschool ? 'preschool' : 'grade_1');
  }

  // Данные для мини-дашборда
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

  int? get averageDurationMinutes {
    if (_conspects.isEmpty) return null;
    int totalMins = 0;
    int count = 0;
    for (final c in _conspects) {
      final match = RegExp(r'(\d+)').firstMatch(c.duration);
      if (match != null) {
        totalMins += int.tryParse(match.group(1)!) ?? 0;
        count++;
      }
    }
    return count > 0 ? (totalMins / count).round() : null;
  }

  String get averageDurationDisplay =>
      averageDurationMinutes != null ? '${averageDurationMinutes}м' : '—';

  bool get hasStatistics =>
      _conspects.isNotEmpty && (todayConspectsCount > 0 || completedTopicsCount > 0);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.init();
      _isDarkMode = _storageService.isDarkMode;
      await _methodRepository.loadData();
      _conspects = _storageService.getAllConspects();
      _scheduledLessons = _storageService.getAllScheduledLessons();
    } catch (e) {
      _errorMessage = 'Ошибка инициализации приложения: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ScheduledLesson> getLessonsForDate(DateTime date) {
    return _scheduledLessons.where((l) {
      return l.date.year == date.year &&
             l.date.month == date.month &&
             l.date.day == date.day;
    }).toList();
  }

  Future<void> addScheduledLesson(ScheduledLesson lesson) async {
    await _storageService.saveScheduledLesson(lesson);
    _scheduledLessons = _storageService.getAllScheduledLessons();
    notifyListeners();
  }

  Future<void> removeScheduledLesson(String id) async {
    await _storageService.deleteScheduledLesson(id);
    _scheduledLessons = _storageService.getAllScheduledLessons();
    notifyListeners();
  }

  // Theme Toggle
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  String get userTier => _storageService.getUserTier();
  bool get hasPackageBundleAccess => _storageService.hasPackageBundleAccess;

  Future<void> setUserTier(String tier) async {
    await _storageService.saveUserTier(tier);
    notifyListeners();
  }

    // Credentials Management
  Future<String?> getApiKey() => _storageService.getApiKey();

  Future<void> saveApiKey(String key) async {
    await _storageService.saveApiKey(key);
    notifyListeners();
  }

  Future<void> saveFolderId(String folderId) async {
    await _storageService.saveFolderId(folderId);
    notifyListeners();
  }


  Future<String?> getProxyUrl() => _storageService.getProxyUrl();

  Future<void> setAiProvider(String provider) async {
    await _aiService.setProvider(provider);
    notifyListeners();
  }

  Future<void> setOpenRouterApiKey(String apiKey) async {
    await _aiService.setOpenRouterApiKey(apiKey);
    notifyListeners();
  }

  Future<void> setOpenRouterModel(String model) async {
    await _aiService.setOpenRouterModel(model);
    notifyListeners();
  }

  Future<void> setMistralApiKey(String apiKey) async {
    await _aiService.setMistralApiKey(apiKey);
    notifyListeners();
  }

  Future<void> setMistralModel(String model) async {
    await _aiService.setMistralModel(model);
    notifyListeners();
  }

  Future<void> saveProxyUrl(String url) async {
    await _storageService.saveProxyUrl(url);
    notifyListeners();
  }


  /// Verifies the proxy connection. Returns a map with success flag and message.
  Future<Map<String, dynamic>> verifyCredentials() async {
    return await _aiService.testConnection();
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

  /// Преобразует Set<GenerationType> в List<String> для поля generatedMaterials
  List<String>? _mapGenerationTypesToStrings(Set<GenerationType>? types) {
    if (types == null || types.isEmpty) return null;
    
    return types.map((type) {
      switch (type) {
        case GenerationType.conspect:
          return 'conspect';
        case GenerationType.worksheet:
          return 'worksheet';
        case GenerationType.homework:
          return 'homework';
      }
    }).toList();
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
    Set<GenerationType>? materials,
    bool useEnhancedPrompts = true, // Новый параметр для использования улучшенных промптов
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

      // Используем улучшенные промпты, если включено
      String finalSystemPrompt = systemPrompt;
      String finalUserPrompt = userPrompt;
      
      if (useEnhancedPrompts) {
        final enhancedPrompt = PromptBuilder.buildEnhancedPrompt(
          methodBlock: method.promptBlock,
          topic: topicTitle,
          ageGroup: Topic.getAgeGroupLabel(ageGroup),
          duration: duration,
          subject: method.subject, // Добавляем subject из метода
          review: review,
          notes: notes,
          situationRules: situation?.extraPromptRules,
          activitySamples: activities?.map((a) => a.sampleText).toList(),
          historicalFeedbackTags: historyTags,
          variantIndex: variantIndex,
          totalVariants: totalVariants,
        );
        
        finalSystemPrompt = enhancedPrompt['systemPrompt']!;
        finalUserPrompt = enhancedPrompt['userPrompt']!;
      }

      final generatedText = await _aiService.generate(
        systemPrompt: finalSystemPrompt,
        userPrompt: finalUserPrompt,
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
        content: finalSystemPrompt,
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
        generatedMaterials: _mapGenerationTypesToStrings(materials) ?? const ['conspect'],
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
    Set<GenerationType>? materials,
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
          materials: materials,
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
      final response = await _aiService.generate(
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

  // Recent PDFs
  void addRecentPdf(String name) {
    if (name.trim().isEmpty) return;
    _recentPdfs.removeWhere((item) => item.name == name);
    _recentPdfs.insert(0, RecentPdf(name: name, createdAt: DateTime.now()));
    if (_recentPdfs.length > 3) {
      _recentPdfs.removeRange(3, _recentPdfs.length);
    }
    notifyListeners();
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
