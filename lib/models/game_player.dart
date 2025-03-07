import 'package:my_new_gorlf/models/score.dart';

class GamePlayer {
  final String playerId;
  final List<Score> scores;
  final int totalScore;
  final double girPercentage;
  final int? stablefordPoints;
  final int holeInOneCount;
  final double handicapAdjustment;

  GamePlayer({
    required this.playerId,
    required this.scores,
    required this.totalScore,
    required this.girPercentage,
    this.stablefordPoints,
    required this.holeInOneCount,
    required this.handicapAdjustment,
  });

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'scores': scores.map((s) => s.toMap()).toList(),
    'totalScore': totalScore,
    'girPercentage': girPercentage,
    'stablefordPoints': stablefordPoints,
    'holeInOneCount': holeInOneCount,
    'handicapAdjustment': handicapAdjustment,
  };

  factory GamePlayer.fromMap(Map<String, dynamic> map) => GamePlayer(
    playerId: map['playerId'] ?? '',
    scores: (map['scores'] as List<dynamic>? ?? []).map((s) => Score.fromMap(s as Map<String, dynamic>)).toList(),
    totalScore: map['totalScore'] ?? 0,
    girPercentage: (map['girPercentage'] as num?)?.toDouble() ?? 0.0,
    stablefordPoints: map['stablefordPoints'],
    holeInOneCount: map['holeInOneCount'] ?? 0,
    handicapAdjustment: (map['handicapAdjustment'] as num?)?.toDouble() ?? 0.0,
  );

  GamePlayer copyWith({
    String? playerId,
    List<Score>? scores,
    int? totalScore,
    double? girPercentage,
    int? stablefordPoints,
    int? holeInOneCount,
    double? handicapAdjustment,
  }) => GamePlayer(
    playerId: playerId ?? this.playerId,
    scores: scores ?? this.scores,
    totalScore: totalScore ?? this.totalScore,
    girPercentage: girPercentage ?? this.girPercentage,
    stablefordPoints: stablefordPoints ?? this.stablefordPoints,
    holeInOneCount: holeInOneCount ?? this.holeInOneCount,
    handicapAdjustment: handicapAdjustment ?? this.handicapAdjustment,
  );
}