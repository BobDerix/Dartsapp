class ChallengeResult {
  final int? id;
  final int gameSessionId;
  final int roundNumber;
  final String challengeText;
  final String challengeCategory;
  final String challengeType;
  final int playerId;
  final bool hit;
  final int? score; // for score-entry challenges
  final int pointsAwarded;

  ChallengeResult({
    this.id,
    required this.gameSessionId,
    required this.roundNumber,
    required this.challengeText,
    required this.challengeCategory,
    required this.challengeType,
    required this.playerId,
    required this.hit,
    this.score,
    required this.pointsAwarded,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'game_session_id': gameSessionId,
    'round_number': roundNumber,
    'challenge_text': challengeText,
    'challenge_category': challengeCategory,
    'challenge_type': challengeType,
    'player_id': playerId,
    'hit': hit ? 1 : 0,
    'score': score,
    'points_awarded': pointsAwarded,
  };

  factory ChallengeResult.fromMap(Map<String, dynamic> map) => ChallengeResult(
    id: map['id'] as int?,
    gameSessionId: map['game_session_id'] as int,
    roundNumber: map['round_number'] as int,
    challengeText: map['challenge_text'] as String,
    challengeCategory: map['challenge_category'] as String,
    challengeType: map['challenge_type'] as String,
    playerId: map['player_id'] as int,
    hit: (map['hit'] as int) == 1,
    score: map['score'] as int?,
    pointsAwarded: map['points_awarded'] as int,
  );
}
