class ActivityTechnique {
  final String id;
  final String category;
  final String title;
  final String shortDescription;
  final String sampleText;

  const ActivityTechnique({
    required this.id,
    required this.category,
    required this.title,
    required this.shortDescription,
    required this.sampleText,
  });

  factory ActivityTechnique.fromJson(Map<String, dynamic> json) {
    return ActivityTechnique(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      sampleText: json['sample_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'short_description': shortDescription,
      'sample_text': sampleText,
    };
  }
}
