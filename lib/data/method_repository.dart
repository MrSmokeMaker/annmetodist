import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/method_prompt.dart';
import '../models/topic.dart';

class MethodRepository {
  List<MethodPrompt> _methods = [];
  List<Topic> _topics = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<MethodPrompt> get methods => List.unmodifiable(_methods);
  List<Topic> get topics => List.unmodifiable(_topics);

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      final methodsJsonString =
          await rootBundle.loadString('assets/data/methods.json');
      final List<dynamic> methodsRaw = jsonDecode(methodsJsonString) as List<dynamic>;
      _methods = methodsRaw
          .map((item) => MethodPrompt.fromJson(item as Map<String, dynamic>))
          .toList();

      final topicsJsonString =
          await rootBundle.loadString('assets/data/topics.json');
      final List<dynamic> topicsRaw = jsonDecode(topicsJsonString) as List<dynamic>;
      _topics = topicsRaw
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
    } catch (e) {
      // In case of asset loading error before Flutter bindings
      _methods = [];
      _topics = [];
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
}
