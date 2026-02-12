class GameSession {
  final int? id;
  final int player1Id;
  final int? player2Id; // null for practice mode
  final int targetScore;
  final String focusArea;
  final bool isSinglePlayer;
  final DateTime startedAt;
  DateTime? endedAt;
  int? winnerId;
  int player1FinalScore;
  int player2FinalScore;
  int totalRounds;

  GameSession({
    this.id,
    required this.player1Id,
    this.player2Id,
    required this.targetScore,
    this.focusArea = 'all',
    this.isSinglePlayer = false,
    DateTime? startedAt,
    this.endedAt,
    this.winnerId,
    this.player1FinalScore = 0,
    this.player2FinalScore = 0,
    this.totalRounds = 0,
  }) : startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'player1_id': player1Id,
    'player2_id': player2Id,
    'target_score': targetScore,
    'focus_area': focusArea,
    'is_single_player': isSinglePlayer ? 1 : 0,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'winner_id': winnerId,
    'player1_final_score': player1FinalScore,
    'player2_final_score': player2FinalScore,
    'total_rounds': totalRounds,
  };

  factory GameSession.fromMap(Map<String, dynamic> map) => GameSession(
    id: map['id'] as int?,
    player1Id: map['player1_id'] as int,
    player2Id: map['player2_id'] as int?,
    targetScore: map['target_score'] as int,
    focusArea: map['focus_area'] as String? ?? 'all',
    isSinglePlayer: (map['is_single_player'] as int? ?? 0) == 1,
    startedAt: DateTime.parse(map['started_at'] as String),
    endedAt: map['ended_at'] != null
        ? DateTime.parse(map['ended_at'] as String)
        : null,
    winnerId: map['winner_id'] as int?,
    player1FinalScore: map['player1_final_score'] as int? ?? 0,
    player2FinalScore: map['player2_final_score'] as int? ?? 0,
    totalRounds: map['total_rounds'] as int? ?? 0,
  );
}
