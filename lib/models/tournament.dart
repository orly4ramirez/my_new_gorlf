class Tournament {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final List<String> teamIds;
  final String courseId;

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.teamIds,
    required this.courseId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startDate': startDate,
    'endDate': endDate,
    'teamIds': teamIds,
    'courseId': courseId,
  };

  factory Tournament.fromMap(Map<String, dynamic> map) => Tournament(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    startDate: map['startDate'] ?? '',
    endDate: map['endDate'] ?? '',
    teamIds: (map['teamIds'] as List<dynamic>?)?.cast<String>() ?? [],
    courseId: map['courseId'] ?? '',
  );
}