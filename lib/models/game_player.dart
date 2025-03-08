import 'package:my_new_gorlf/models/score.dart';

class GamePlayer {
  final String playerId;
  final List<Score> scores;
  final int totalScore;
  final double girPercentage;
  final int holeInOneCount;
  final double handicapAdjustment;

  GamePlayer({
    required this.playerId,
    required this.scores,
    required this.totalScore,
    required this.girPercentage,
    required this.holeInOneCount,
    required this.handicapAdjustment,
  });

  factory GamePlayer.fromMap(Map<String, dynamic> map) {
    return GamePlayer(
      playerId: map['playerId'] ?? '',
      scores: (map['scores'] as List<dynamic>?)
          ?.map((s) => Score.fromMap(s as Map<String, dynamic>))
          .toList() ??
          [],
      totalScore: map['totalScore'] ?? 0,
      girPercentage: (map['girPercentage'] as num?)?.toDouble() ?? 0.0,
      holeInOneCount: map['holeInOneCount'] ?? 0,
      handicapAdjustment: (map['handicapAdjustment'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'scores': scores.map((s) => s.toMap()).toList(),
      'totalScore': totalScore,
      'girPercentage': girPercentage,
      'holeInOneCount': holeInOneCount,
      'handicapAdjustment': handicapAdjustment,
    };
  }

  GamePlayer copyWith({
    String? playerId,
    List<Score>? scores,
    int? totalScore,
    double? girPercentage,
    int? holeInOneCount,
    double? handicapAdjustment,
  }) {
    return GamePlayer(
      playerId: playerId ?? this.playerId,
      scores: scores ?? List.from(this.scores),
      totalScore: totalScore ?? this.totalScore,
      girPercentage: girPercentage ?? this.girPercentage,
      holeInOneCount: holeInOneCount ?? this.holeInOneCount,
      handicapAdjustment: handicapAdjustment ?? this.handicapAdjustment,
    );
  }
}