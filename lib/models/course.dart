class Course {
  final String id;
  final String name;
  final String status;
  final int slopeRating;
  final int yardage;
  final int totalPar;
  final List<Hole> holes;
  final String userId; // Must be here

  Course({
    required this.id,
    required this.name,
    required this.status,
    required this.slopeRating,
    required this.yardage,
    required this.totalPar,
    required this.holes,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'status': status,
    'slopeRating': slopeRating,
    'yardage': yardage,
    'totalPar': totalPar,
    'holes': holes.map((h) => h.toMap()).toList(),
    'userId': userId,
  };

  Course.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        status = map['status'],
        slopeRating = map['slopeRating'],
        yardage = map['yardage'],
        totalPar = map['totalPar'],
        holes = (map['holes'] as List).map((h) => Hole.fromMap(h)).toList(),
        userId = map['userId'];
}

class Hole {
  final int holeNumber;
  final int par;
  final int yards;

  Hole({required this.holeNumber, required this.par, required this.yards});

  Map<String, dynamic> toMap() => {
    'holeNumber': holeNumber,
    'par': par,
    'yards': yards,
  };

  factory Hole.fromMap(Map<String, dynamic> map) => Hole(
    holeNumber: map['hole'] ?? map['holeNumber'] ?? 0,
    par: map['par'] ?? 0,
    yards: map['yards'] ?? 0,
  );
}