import 'dart:convert';

class DepartmentMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'Заведующий кафедрой' | 'Старший методист' | 'Учитель' | 'Ассистент'
  final DateTime joinedAt;
  final bool isActive;

  DepartmentMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory DepartmentMember.fromMap(Map<String, dynamic> map) {
    return DepartmentMember(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'Учитель',
      joinedAt: map['joinedAt'] != null
          ? DateTime.tryParse(map['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

class DepartmentTeam {
  final String id;
  final String teamName;
  final int maxSeats;
  final List<DepartmentMember> members;
  final String inviteCode;
  final List<String> sharedConspectIds;

  DepartmentTeam({
    required this.id,
    required this.teamName,
    this.maxSeats = 5,
    required this.members,
    required this.inviteCode,
    this.sharedConspectIds = const [],
  });

  int get activeSeatsCount => members.where((m) => m.isActive).length;
  int get remainingSeats => (maxSeats - activeSeatsCount).clamp(0, maxSeats);
  bool get canAddMember => activeSeatsCount < maxSeats;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamName': teamName,
      'maxSeats': maxSeats,
      'members': members.map((m) => m.toMap()).toList(),
      'inviteCode': inviteCode,
      'sharedConspectIds': sharedConspectIds,
    };
  }

  factory DepartmentTeam.fromMap(Map<String, dynamic> map) {
    return DepartmentTeam(
      id: map['id'] as String? ?? 'team_default',
      teamName: map['teamName'] as String? ?? 'Кафедра учителей',
      maxSeats: (map['maxSeats'] as int?) ?? 5,
      members: (map['members'] as List<dynamic>?)
              ?.map((item) => DepartmentMember.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      inviteCode: map['inviteCode'] as String? ?? 'METOD-KAF-2026',
      sharedConspectIds: (map['sharedConspectIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DepartmentTeam.fromJson(String source) =>
      DepartmentTeam.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static DepartmentTeam createDefault() {
    return DepartmentTeam(
      id: 'team_dept_alpha',
      teamName: 'Кафедра начального и среднего образования',
      maxSeats: 5,
      inviteCode: 'METOD-KAF-5SEATS',
      members: [
        DepartmentMember(
          id: 'mem_1',
          name: 'Анна Сергеевна (Владелец)',
          email: 'anna.teacher@school-lyceum.ru',
          role: 'Заведующий кафедрой',
          joinedAt: DateTime.now().subtract(const Duration(days: 30)),
          isActive: true,
        ),
        DepartmentMember(
          id: 'mem_2',
          name: 'Михаил Юрьевич',
          email: 'mikhail.math@school-lyceum.ru',
          role: 'Старший методист',
          joinedAt: DateTime.now().subtract(const Duration(days: 14)),
          isActive: true,
        ),
        DepartmentMember(
          id: 'mem_3',
          name: 'Елена Викторовна',
          email: 'elena.rus@school-lyceum.ru',
          role: 'Учитель',
          joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          isActive: true,
        ),
      ],
      sharedConspectIds: [],
    );
  }
}
