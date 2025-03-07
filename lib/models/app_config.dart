class AppConfig {
  final bool enableTournaments;
  final bool enableHoleAchievements; // Hole in one, nearest, longest
  final bool enableSkinsBetting;
  final bool enableStatsTracking;
  final bool enableMultiPlayer;

  AppConfig({
    required this.enableTournaments,
    required this.enableHoleAchievements,
    required this.enableSkinsBetting,
    required this.enableStatsTracking,
    required this.enableMultiPlayer,
  });

  Map<String, dynamic> toMap() => {
    'enableTournaments': enableTournaments,
    'enableHoleAchievements': enableHoleAchievements,
    'enableSkinsBetting': enableSkinsBetting,
    'enableStatsTracking': enableStatsTracking,
    'enableMultiPlayer': enableMultiPlayer,
  };

  factory AppConfig.fromMap(Map<String, dynamic> map) => AppConfig(
    enableTournaments: map['enableTournaments'] ?? true,
    enableHoleAchievements: map['enableHoleAchievements'] ?? true,
    enableSkinsBetting: map['enableSkinsBetting'] ?? true,
    enableStatsTracking: map['enableStatsTracking'] ?? true,
    enableMultiPlayer: map['enableMultiPlayer'] ?? true,
  );
}