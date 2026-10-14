class Topic {
  final String id;
  final String methodId;
  final String ageGroup;
  final String title;
  final String description;

  const Topic({
    required this.id,
    required this.methodId,
    required this.ageGroup,
    required this.title,
    this.description = '',
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      methodId: json['methodId'] as String? ?? '',
      ageGroup: json['ageGroup'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'methodId': methodId,
      'ageGroup': ageGroup,
      'title': title,
      'description': description,
    };
  }

  static String getAgeGroupLabel(String ageGroup) {
    switch (ageGroup) {
      case 'preschool':
        return 'Дошкольники 4–6 лет';
      case 'grade_1':
        return '1 класс';
      case 'grade_2':
        return '2 класс';
      default:
        return ageGroup;
    }
  }
}
