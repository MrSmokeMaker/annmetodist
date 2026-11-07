import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/activity_technique.dart';
import '../models/method_prompt.dart';
import '../models/methodology_definition.dart';
import '../models/situation_template.dart';
import '../models/topic.dart';

class MethodRepository {
  List<MethodPrompt> _methods = [];
  final List<MethodologyDefinition> _customMethodologies = [];
  List<Topic> _topics = [];
  List<SituationTemplate> _situationTemplates = [];
  List<ActivityTechnique> _activityLibrary = [];
  bool _isLoaded = false;

  // Fast $O(1)$ lookup maps
  final Map<String, MethodPrompt> _methodsMap = {};
  final Map<String, SituationTemplate> _situationsMap = {};
  final Map<String, ActivityTechnique> _activitiesMap = {};
  final Map<String, MethodologyDefinition> _customMethodologiesMap = {};

  bool get isLoaded => _isLoaded;
  List<MethodPrompt> get methods => List.unmodifiable(_methods);
  List<MethodologyDefinition> get customMethodologies => List.unmodifiable(_customMethodologies);
  List<Topic> get topics => List.unmodifiable(_topics);
  List<SituationTemplate> get situationTemplates =>
      List.unmodifiable(_situationTemplates);
  List<ActivityTechnique> get activityLibrary =>
      List.unmodifiable(_activityLibrary);

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Load all data files concurrently for minimal cold start overhead
      final results = await Future.wait([
        rootBundle.loadString('assets/data/methods.json'),
        rootBundle.loadString('assets/data/topics.json'),
        rootBundle.loadString('assets/data/situations.json'),
        rootBundle.loadString('assets/data/activities.json'),
      ]);

      final List<dynamic> methodsRaw = jsonDecode(results[0]) as List<dynamic>;
      _methods = methodsRaw
          .map((item) => MethodPrompt.fromJson(item as Map<String, dynamic>))
          .toList();
      _methodsMap.clear();
      for (final m in _methods) {
        _methodsMap[m.id] = m;
      }

      final List<dynamic> topicsRaw = jsonDecode(results[1]) as List<dynamic>;
      _topics = topicsRaw
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList();

      final List<dynamic> situationsRaw = jsonDecode(results[2]) as List<dynamic>;
      _situationTemplates = situationsRaw
          .map((item) => SituationTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
      _situationsMap.clear();
      for (final s in _situationTemplates) {
        _situationsMap[s.id] = s;
      }

      final List<dynamic> activitiesRaw = jsonDecode(results[3]) as List<dynamic>;
      _activityLibrary = activitiesRaw
          .map((item) => ActivityTechnique.fromJson(item as Map<String, dynamic>))
          .toList();
      _activitiesMap.clear();
      for (final a in _activityLibrary) {
        _activitiesMap[a.id] = a;
      }

      _isLoaded = true;
    } catch (e) {
      _methods = [];
      _topics = [];
      _situationTemplates = [];
      _activityLibrary = [];
      _methodsMap.clear();
      _situationsMap.clear();
      _activitiesMap.clear();
      rethrow;
    }
  }

  MethodPrompt? getMethodById(String id) => _methodsMap[id];

  SituationTemplate? getSituationById(String id) => _situationsMap[id];

  ActivityTechnique? getActivityById(String id) => _activitiesMap[id];

  List<Topic> getTopicsByFilter({
    required String methodId,
    required String ageGroup,
  }) {
    return _topics.where((t) {
      final matchMethod = t.methodId == methodId;
      final matchAge = t.ageGroup == ageGroup;
      return matchMethod && matchAge;
    }).toList();
  }

  /// Регистрация новой авторской методики в системе
  void registerCustomMethodology(MethodologyDefinition definition) {
    _customMethodologies.removeWhere((m) => m.id == definition.id);
    _customMethodologies.add(definition);
    _customMethodologiesMap[definition.id] = definition;

    final methodPrompt = definition.toMethodPrompt();
    _methods.removeWhere((m) => m.id == definition.id);
    _methods.add(methodPrompt);
    _methodsMap[methodPrompt.id] = methodPrompt;
  }

  /// Удаление пользовательской методики
  void removeCustomMethodology(String id) {
    _customMethodologies.removeWhere((m) => m.id == id);
    _customMethodologiesMap.remove(id);
    _methods.removeWhere((m) => m.id == id);
    _methodsMap.remove(id);
  }

  /// Получение расширенного описания методики по ID
  MethodologyDefinition? getCustomMethodologyById(String id) => _customMethodologiesMap[id];
}
