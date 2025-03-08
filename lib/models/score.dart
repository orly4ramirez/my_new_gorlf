class Score {
  final int holeNumber;
  final int? scoreValue;
  final int? putts;
  final bool? gir;
  final bool? skinsWinner;

  Score({
    required this.holeNumber,
    this.scoreValue,
    this.putts,
    this.gir,
    this.skinsWinner,
  });

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      holeNumber: map['holeNumber'] ?? 0,
      scoreValue: map['scoreValue'] as int?,
      putts: map['putts'] as int?,
      gir: map['gir'] as bool?,
      skinsWinner: map['skinsWinner'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holeNumber': holeNumber,
      'scoreValue': scoreValue,
      'putts': putts,
      'gir': gir,
      'skinsWinner': skinsWinner,
    };
  }
}