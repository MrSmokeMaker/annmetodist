class SituationTemplate {
  final String id;
  final String title;
  final String description;
  final String autoDuration;
  final String extraPromptRules;

  const SituationTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.autoDuration,
    required this.extraPromptRules,
  });

  factory SituationTemplate.fromJson(Map<String, dynamic> json) {
    return SituationTemplate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      autoDuration: json['auto_duration'] as String? ?? '',
      extraPromptRules: json['extra_prompt_rules'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'auto_duration': autoDuration,
      'extra_prompt_rules': extraPromptRules,
    };
  }
}
