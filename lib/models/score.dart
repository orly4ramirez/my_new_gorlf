class Score {
  final int holeNumber;
  final int? scoreValue;
  final int? putts;
  final bool gir;
  final bool? skinsWinner;

  Score({
    required this.holeNumber,
    this.scoreValue,
    this.putts,
    required this.gir,
    this.skinsWinner,
  });

  Map<String, dynamic> toMap() => {
    'holeNumber': holeNumber,
    'scoreValue': scoreValue,
    'putts': putts,
    'gir': gir,
    'skinsWinner': skinsWinner,
  };

  factory Score.fromMap(Map<String, dynamic> map) => Score(
    holeNumber: map['holeNumber'] ?? 0,
    scoreValue: map['scoreValue'],
    putts: map['putts'],
    gir: map['gir'] ?? false,
    skinsWinner: map['skinsWinner'],
  );
}