class Course {
  final String id;
  final String name;
  final String userId;
  final String status;
  final int slopeRating;
  final int yardage;
  final int totalPar;
  final List<Hole> holes;

  Course({
    required this.id,
    required this.name,
    required this.userId,
    required this.status,
    required this.slopeRating,
    required this.yardage,
    required this.totalPar,
    required this.holes,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'Unknown',
      slopeRating: map['slopeRating'] ?? 113,
      yardage: map['yardage'] ?? 0,
      totalPar: map['totalPar'] ?? 72,
      holes: (map['holes'] as List<dynamic>?)
          ?.map((h) => Hole.fromMap(h as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'status': status,
      'slopeRating': slopeRating,
      'yardage': yardage,
      'totalPar': totalPar,
      'holes': holes.map((h) => h.toMap()).toList(),
    };
  }

  Course copyWith({
    String? id,
    String? name,
    String? userId,
    String? status,
    int? slopeRating,
    int? yardage,
    int? totalPar,
    List<Hole>? holes,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      slopeRating: slopeRating ?? this.slopeRating,
      yardage: yardage ?? this.yardage,
      totalPar: totalPar ?? this.totalPar,
      holes: holes ?? List.from(this.holes),
    );
  }
}

class Hole {
  final int holeNumber;
  final int par;
  final int yards;

  Hole({
    required this.holeNumber,
    required this.par,
    required this.yards,
  });

  factory Hole.fromMap(Map<String, dynamic> map) {
    return Hole(
      holeNumber: map['holeNumber'] ?? 0,
      par: map['par'] ?? 4,
      yards: map['yards'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holeNumber': holeNumber,
      'par': par,
      'yards': yards,
    };
  }
}