class Team {
  final String id;
  final String name;

  Team({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Team.fromMap(Map<String, dynamic> map) => Team(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
  );
}