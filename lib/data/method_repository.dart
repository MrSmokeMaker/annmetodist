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
      final methodsJsonString =
          await rootBundle.loadString('assets/data/methods.json');
      final List<dynamic> methodsRaw =
          jsonDecode(methodsJsonString) as List<dynamic>;
      _methods = methodsRaw
          .map((item) => MethodPrompt.fromJson(item as Map<String, dynamic>))
          .toList();

      final topicsJsonString =
          await rootBundle.loadString('assets/data/topics.json');
      final List<dynamic> topicsRaw =
          jsonDecode(topicsJsonString) as List<dynamic>;
      _topics = topicsRaw
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList();

      final situationsJsonString =
          await rootBundle.loadString('assets/data/situations.json');
      final List<dynamic> situationsRaw =
          jsonDecode(situationsJsonString) as List<dynamic>;
      _situationTemplates = situationsRaw
          .map((item) => SituationTemplate.fromJson(item as Map<String, dynamic>))
          .toList();

      final activitiesJsonString =
          await rootBundle.loadString('assets/data/activities.json');
      final List<dynamic> activitiesRaw =
          jsonDecode(activitiesJsonString) as List<dynamic>;
      _activityLibrary = activitiesRaw
          .map((item) => ActivityTechnique.fromJson(item as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
    } catch (e) {
      _methods = [];
      _topics = [];
      _situationTemplates = [];
      _activityLibrary = [];
      rethrow;
    }
  }

  MethodPrompt? getMethodById(String id) {
    try {
      return _methods.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  SituationTemplate? getSituationById(String id) {
    try {
      return _situationTemplates.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  ActivityTechnique? getActivityById(String id) {
    try {
      return _activityLibrary.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

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

    final methodPrompt = definition.toMethodPrompt();
    _methods.removeWhere((m) => m.id == definition.id);
    _methods.add(methodPrompt);
  }

  /// Удаление пользовательской методики
  void removeCustomMethodology(String id) {
    _customMethodologies.removeWhere((m) => m.id == id);
    _methods.removeWhere((m) => m.id == id);
  }

  /// Получение расширенного описания методики по ID
  MethodologyDefinition? getCustomMethodologyById(String id) {
    try {
      return _customMethodologies.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}