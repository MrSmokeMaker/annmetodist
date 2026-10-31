import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../data/method_repository.dart';
import '../models/activity_technique.dart';
import '../models/conspect.dart';
import '../models/tariff.dart';
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
import '../services/yandex_art_service.dart';
import '../services/surgical_ai_service.dart';
import '../services/lesson_cache_service.dart';
import '../services/lesson_rubric_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final MethodRepository _methodRepository;
  late final YandexGptService _yandexGptService;
  late final AiService _aiService;
  late final YandexArtService _artService;
  late final SurgicalAiService _surgicalAiService;

  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  List<Conspect> _conspects = [];
  final List<RecentPdf> _recentPdfs = [];
  List<ScheduledLesson> _scheduledLessons = [];
  bool _isDarkMode = true;
  TariffLevel _currentTariff = TariffLevel.director;

  TariffLevel get currentTariff => _currentTariff;
  bool get isDirector => _currentTariff.isDirector;
  bool get isDeveloper => isDirector;
  bool get canSwitchThematicWorlds => _currentTariff.canSwitchThematicWorlds;

  void setTariff(TariffLevel level) {
    _currentTariff = level;
    _storageService.saveUserTier(level.id);
    notifyListeners();
  }

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
    _artService = YandexArtService(storageService: _storageService);
    _surgicalAiService = SurgicalAiService(gptService: _yandexGptService);
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
  YandexArtService get yandexArtService => _artService;
  SurgicalAiService get surgicalAiService => _surgicalAiService;
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
      _currentTariff = TariffLevelExtension.fromId(_storageService.getUserTier());
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
  bool get isProUser => _storageService.hasProAccess;

  Future<void> setUserTier(String tier) async {
    await _storageService.saveUserTier(tier);
    _currentTariff = TariffLevelExtension.fromId(tier);
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
    bool isDeepLesson = false,
  }) async {
    // Проверка кеша для одиночной генерации
    final cacheKey = LessonCacheService.computeCacheKey(
      methodId: method.id,
      topic: topicTitle,
      ageGroup: ageGroup,
      duration: duration,
      isDeepLesson: isDeepLesson,
      materials: materials?.map((m) => m.name).toList(),
    );

    if (totalVariants == 1) {
      final cachedConspect = LessonCacheService.get(cacheKey);
      if (cachedConspect != null) {
        return cachedConspect;
      }
    }

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
        materials: materials,
      );

      final userPrompt = PromptBuilder.buildUserPrompt(
        methodName: method.name,
        topic: topicTitle,
        ageGroup: Topic.getAgeGroupLabel(ageGroup),
        duration: duration,
        situationTitle: situation?.title,
        variantIndex: totalVariants > 1 ? variantIndex : null,
        materials: materials,
        isDeepLesson: isDeepLesson,
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
          materials: materials,
          isDeepLesson: isDeepLesson,
        );
        
        finalSystemPrompt = enhancedPrompt['systemPrompt']!;
        finalUserPrompt = enhancedPrompt['userPrompt']!;
      }

      final generatedText = isDeepLesson
          ? await _aiService.generateDeepLesson(
              systemPrompt: finalSystemPrompt,
              userPrompt: finalUserPrompt,
            )
          : await _aiService.generate(
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

      final effectiveMaterials = _mapGenerationTypesToStrings(materials) ?? const ['conspect'];
      var effectiveContent = PromptBuilder.filterContentByMaterials(generatedText, effectiveMaterials);

      // Проход 2: Строгая верификация и самоочистка (Self-Refine) для тарифа Pro
      if (isProUser && effectiveMaterials.contains('worksheet')) {
        try {
          final sanitizePrompt = PromptBuilder.buildSanitizerVerificationPrompt(effectiveContent);
          final cleaned = await _yandexGptService.generateConspect(
            systemPrompt: sanitizePrompt['systemPrompt']!,
            userPrompt: sanitizePrompt['userPrompt']!,
            temperature: 0.2,
            maxTokens: 3500,
          );
          if (cleaned.trim().isNotEmpty) {
            effectiveContent = cleaned.trim();
          }
        } catch (e) {
          print('Self-Refine pass bypassed: $e');
        }
      }

      List<PrintableCard>? effectiveCards = cards.isNotEmpty ? cards : null;
      String? illustrationMascot;
      String? illustrationColoring;
      String? illustrationReward;

      // В тарифе Metodist PRO иллюстрации генерируются автоматически по умолчанию
      if (isProUser) {
        if (cards.isNotEmpty) {
          final enriched = <PrintableCard>[];
          for (final c in cards) {
            try {
              final img = await _artService.generateCardIllustration(
                c.imageHint ?? c.frontText,
                word: c.frontText,
              );
              enriched.add(c.copyWith(imageUrl: img));
            } catch (_) {
              enriched.add(c);
            }
          }
          effectiveCards = enriched;
        }
        try {
          illustrationMascot = await _artService.generateMascotBanner(topicTitle, ageGroup);
          illustrationColoring = await _artService.generateColoringActivity(topicTitle);
          illustrationReward = await _artService.generateRewardSticker(topicTitle);
        } catch (_) {}
      }

      final rubricEval = LessonRubricService.evaluateLesson(
        content: effectiveContent,
        topic: topicTitle,
        ageGroup: ageGroup,
        subject: method.subject,
        methodName: method.name,
      );

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
        content: effectiveContent,
        variantIndex: variantIndex,
        batchGroupId: batchGroupId,
        cards: effectiveCards,
        generatedMaterials: effectiveMaterials,
        parentAudioScript: parentAudio,
        promptVersionId: promptVersion.id,
        illustrationMascot: illustrationMascot,
        illustrationColoring: illustrationColoring,
        illustrationReward: illustrationReward,
        isDeepLesson: isDeepLesson,
        rubricScore: rubricEval.overallScore,
        createdAt: DateTime.now(),
      );

      if (totalVariants == 1) {
        LessonCacheService.put(cacheKey, conspect);
      }

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
    bool isDeepLesson = false,
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
          isDeepLesson: isDeepLesson,
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

  /// Генерация полного арт-пакета YandexART для Pro-пользователей
  Future<void> generateArtPackageForConspect(String conspectId) async {
    final index = _conspects.indexWhere((c) => c.id == conspectId);
    if (index == -1) return;

    final conspect = _conspects[index];
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Генерация картинок для карточек
      List<PrintableCard>? updatedCards;
      if (conspect.cards != null && conspect.cards!.isNotEmpty) {
        final cardsList = <PrintableCard>[];
        for (final card in conspect.cards!) {
          final imgBase64 = await _artService.generateCardIllustration(
            card.imageHint ?? card.frontText,
            word: card.frontText,
          );
          cardsList.add(PrintableCard(
            id: card.id,
            frontText: card.frontText,
            backText: card.backText,
            imageHint: card.imageHint,
            imageUrl: imgBase64,
            type: card.type,
          ));
        }
        updatedCards = cardsList;
      }

      // 2. Генерация маскота, раскраски и наградного стикера
      final mascot = await _artService.generateMascotBanner(conspect.topic, conspect.ageGroup);
      final coloring = await _artService.generateColoringActivity(conspect.topic);
      final reward = await _artService.generateRewardSticker(conspect.topic);

      final updatedConspect = conspect.copyWith(
        cards: updatedCards ?? conspect.cards,
        illustrationMascot: mascot,
        illustrationColoring: coloring,
        illustrationReward: reward,
        updatedAt: DateTime.now(),
      );

      await saveConspect(updatedConspect);
    } catch (e) {
      _errorMessage = 'Ошибка генерации YandexART: $e';
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

  // Функция 1: Точечная регенерация блоков урока (Хирургический AI)
  Future<Conspect> updateConspectBlock({
    required Conspect conspect,
    required String oldBlockText,
    required String newBlockText,
  }) async {
    final updatedContent = conspect.content.replaceFirst(oldBlockText, newBlockText);
    final updatedConspect = conspect.copyWith(
      content: updatedContent,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveConspect(updatedConspect);
    final idx = _conspects.indexWhere((c) => c.id == conspect.id);
    if (idx != -1) {
      _conspects[idx] = updatedConspect;
    }
    notifyListeners();
    return updatedConspect;
  }

  // Функция 2: Пакетная дифференциация «3 в 1» (Опора / База / Детектив Pro)
  Future<List<Conspect>> generateDifferentiatedPackage(Conspect baseConspect) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batchId = baseConspect.batchGroupId ?? '${DateTime.now().millisecondsSinceEpoch}_batch';

      // 1. Обновляем базовый вариант как Вариант Б
      final baseUpdated = baseConspect.copyWith(
        title: baseConspect.title.startsWith('[') ? baseConspect.title : '[База ФГОС] ${baseConspect.title}',
        variantIndex: 2,
        batchGroupId: batchId,
        updatedAt: DateTime.now(),
      );
      await _storageService.saveConspect(baseUpdated);
      final baseIdx = _conspects.indexWhere((c) => c.id == baseConspect.id);
      if (baseIdx != -1) {
        _conspects[baseIdx] = baseUpdated;
      }

      // 2. Генерируем Вариант А: Опора (ОВЗ / Адаптивный)
      final supportPrompt = PromptBuilder.buildDifferentiationPrompt(
        baseConspect: baseConspect,
        variantType: 'support',
      );
      final supportContent = await _yandexGptService.generateConspect(
        systemPrompt: supportPrompt['systemPrompt']!,
        userPrompt: supportPrompt['userPrompt']!,
        temperature: 0.4,
        maxTokens: 3000,
      );
      final variantA = Conspect(
        id: '${DateTime.now().millisecondsSinceEpoch}_var1',
        title: '[Опора / ОВЗ] ${baseConspect.title}',
        methodId: baseConspect.methodId,
        methodName: baseConspect.methodName,
        subject: baseConspect.subject,
        ageGroup: baseConspect.ageGroup,
        topic: baseConspect.topic,
        duration: baseConspect.duration,
        content: supportContent,
        variantIndex: 1,
        batchGroupId: batchId,
        generatedMaterials: const ['worksheet'],
        createdAt: DateTime.now(),
      );
      await _storageService.saveConspect(variantA);
      _conspects.insert(0, variantA);

      // 3. Генерируем Вариант В: Детектив Pro (Олимпиада / ТРИЗ)
      final olympiadPrompt = PromptBuilder.buildDifferentiationPrompt(
        baseConspect: baseConspect,
        variantType: 'olympiad',
      );
      final olympiadContent = await _yandexGptService.generateConspect(
        systemPrompt: olympiadPrompt['systemPrompt']!,
        userPrompt: olympiadPrompt['userPrompt']!,
        temperature: 0.5,
        maxTokens: 3000,
      );
      final variantC = Conspect(
        id: '${DateTime.now().millisecondsSinceEpoch}_var3',
        title: '[Детектив Pro / ТРИЗ] ${baseConspect.title}',
        methodId: baseConspect.methodId,
        methodName: baseConspect.methodName,
        subject: baseConspect.subject,
        ageGroup: baseConspect.ageGroup,
        topic: baseConspect.topic,
        duration: baseConspect.duration,
        content: olympiadContent,
        variantIndex: 3,
        batchGroupId: batchId,
        generatedMaterials: const ['worksheet'],
        createdAt: DateTime.now(),
      );
      await _storageService.saveConspect(variantC);
      _conspects.insert(0, variantC);

      _isLoading = false;
      notifyListeners();
      return [variantA, baseUpdated, variantC];
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ошибка генерации пакета дифференциации: $e';
      notifyListeners();
      rethrow;
    }
  }
}
