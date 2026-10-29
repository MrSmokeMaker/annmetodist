class RecentPdf {
  final String name;
  final DateTime createdAt;

  const RecentPdf({
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecentPdf.fromJson(Map<String, dynamic> json) => RecentPdf(
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
