class PromptVersion {
  final String id;
  final String methodId;
  final int version;
  final String content;
  final DateTime createdAt;

  PromptVersion({
    required this.id,
    required this.methodId,
    required this.version,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method_id': methodId,
      'version': version,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PromptVersion.fromMap(Map<dynamic, dynamic> map) {
    return PromptVersion(
      id: map['id']?.toString() ?? '',
      methodId: map['method_id']?.toString() ?? '',
      version: (map['version'] as num?)?.toInt() ?? 1,
      content: map['content']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory PromptVersion.fromJson(Map<String, dynamic> json) => PromptVersion.fromMap(json);
}
