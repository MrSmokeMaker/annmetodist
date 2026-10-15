class PrintableCard {
  final String id;
  final String frontText;
  final String backText;
  final String? imageHint;
  final String type; // letter, syllable, word, task

  PrintableCard({
    required this.id,
    required this.frontText,
    required this.backText,
    this.imageHint,
    this.type = 'word',
  });

  factory PrintableCard.fromJson(Map<String, dynamic> json) {
    return PrintableCard(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      frontText: json['front_text']?.toString() ?? '',
      backText: json['back_text']?.toString() ?? '',
      imageHint: json['image_hint']?.toString(),
      type: json['type']?.toString() ?? 'word',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front_text': frontText,
      'back_text': backText,
      if (imageHint != null) 'image_hint': imageHint,
      'type': type,
    };
  }

  static String getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'letter':
        return 'Буква';
      case 'syllable':
        return 'Слог';
      case 'word':
        return 'Слово';
      case 'task':
        return 'Задание';
      default:
        return 'Карточка';
    }
  }
}
