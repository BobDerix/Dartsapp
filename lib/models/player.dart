class Player {
  final int? id;
  final String name;
  final DateTime createdAt;
  int gamesPlayed;
  int gamesWon;
  int totalChallengesAttempted;
  int totalChallengesHit;
  int bestStreak;

  Player({
    this.id,
    required this.name,
    DateTime? createdAt,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalChallengesAttempted = 0,
    this.totalChallengesHit = 0,
    this.bestStreak = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  double get hitRate =>
      totalChallengesAttempted > 0
          ? totalChallengesHit / totalChallengesAttempted
          : 0.0;

  double get winRate =>
      gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'games_played': gamesPlayed,
    'games_won': gamesWon,
    'total_challenges_attempted': totalChallengesAttempted,
    'total_challenges_hit': totalChallengesHit,
    'best_streak': bestStreak,
  };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
    id: map['id'] as int?,
    name: map['name'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    gamesPlayed: map['games_played'] as int? ?? 0,
    gamesWon: map['games_won'] as int? ?? 0,
    totalChallengesAttempted: map['total_challenges_attempted'] as int? ?? 0,
    totalChallengesHit: map['total_challenges_hit'] as int? ?? 0,
    bestStreak: map['best_streak'] as int? ?? 0,
  );

  Player copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    int? gamesPlayed,
    int? gamesWon,
    int? totalChallengesAttempted,
    int? totalChallengesHit,
    int? bestStreak,
  }) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    gamesWon: gamesWon ?? this.gamesWon,
    totalChallengesAttempted: totalChallengesAttempted ?? this.totalChallengesAttempted,
    totalChallengesHit: totalChallengesHit ?? this.totalChallengesHit,
    bestStreak: bestStreak ?? this.bestStreak,
  );

  @override
  String toString() => 'Player(id: $id, name: $name)';
}
