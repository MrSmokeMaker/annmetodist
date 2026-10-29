class PrintableCard {
  final String id;
  final String frontText;
  final String backText;
  final String? imageHint;
  final String? imageUrl;
  final String type;

  PrintableCard({
    required this.id,
    required this.frontText,
    required this.backText,
    this.imageHint,
    this.imageUrl,
    this.type = 'word',
  });

  factory PrintableCard.fromJson(Map<String, dynamic> json) {
    String readString(String snakeCase, String camelCase) =>
        (json[snakeCase] ?? json[camelCase] ?? '').toString().trim();
    final imageHint = readString('image_hint', 'imageHint');
    final imageUrl = readString('image_url', 'imageUrl');
    final type = readString('type', 'type');
    return PrintableCard(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString().trim()
          : DateTime.now().microsecondsSinceEpoch.toString(),
      frontText: readString('front_text', 'frontText'),
      backText: readString('back_text', 'backText'),
      imageHint: imageHint.isEmpty ? null : imageHint,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      type: type.isEmpty ? 'word' : type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front_text': frontText,
      'back_text': backText,
      if (imageHint != null) 'image_hint': imageHint,
      if (imageUrl != null) 'image_url': imageUrl,
      'type': type,
    };
  }

  static String getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'letter': return 'Буква';
      case 'syllable': return 'Слог';
      case 'word': return 'Слово';
      case 'task': return 'Задание';
      default: return 'Карточка';
    }
  }
}
