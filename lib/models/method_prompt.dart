class MethodPrompt {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String promptBlock;

  const MethodPrompt({
    required this.id,
    required this.name,
    required this.subject,
    required this.description,
    required this.promptBlock,
  });

  factory MethodPrompt.fromJson(Map<String, dynamic> json) {
    return MethodPrompt(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      promptBlock: json['promptBlock'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'description': description,
      'promptBlock': promptBlock,
    };
  }
}
