enum ChallengeCategory {
  precision,
  scoring,
  finish,
  battle,
  special;

  String get displayName => switch (this) {
    precision => 'PRECISION',
    scoring => 'SCORING',
    finish => 'FINISH',
    battle => 'BATTLE',
    special => 'SPECIAL',
  };
}

/// Determines how player input is collected and scored.
enum ChallengeType {
  /// Binary hit or miss. Hit = 1 point.
  hitMiss,

  /// Both players enter a score. Highest score = 1 point.
  bestScore,

  /// Judge decides who was closest. Winner = 1 point.
  closest,

  /// Enter a score. Meet or exceed threshold = 1 point.
  threshold,

  /// Multiple sub-rounds. Most hits out of N rounds = 1 point.
  elimination,

  /// Players bid how many darts they need. Lowest bidder executes.
  auction,

  /// Players alternate scoring. Each must beat the previous score.
  progressive;

  String get dbValue => switch (this) {
    hitMiss => 'hit_miss',
    bestScore => 'best_score',
    closest => 'closest',
    threshold => 'threshold',
    elimination => 'elimination',
    auction => 'auction',
    progressive => 'progressive',
  };

  static ChallengeType fromDb(String value) => switch (value) {
    'hit_miss' => hitMiss,
    'best_score' => bestScore,
    'closest' => closest,
    'threshold' => threshold,
    'countdown' => hitMiss,
    'elimination' => elimination,
    'auction' => auction,
    'progressive' => progressive,
    _ => hitMiss,
  };
}

class Challenge {
  final int? id;
  final ChallengeCategory category;
  final ChallengeType type;
  final String text;
  final String emoji;
  final int difficulty; // 1-5
  final int? targetValue; // for threshold/countdown/auction
  final int subRounds; // for elimination (default 1)
  final bool isRoulette; // show roulette spinner animation
  final bool hasTimer; // show countdown timer overlay
  final int timerSeconds; // timer duration (default 15)

  const Challenge({
    this.id,
    required this.category,
    required this.type,
    required this.text,
    required this.emoji,
    this.difficulty = 1,
    this.targetValue,
    this.subRounds = 1,
    this.isRoulette = false,
    this.hasTimer = false,
    this.timerSeconds = 15,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category.name,
    'type': type.dbValue,
    'text': text,
    'emoji': emoji,
    'difficulty': difficulty,
    'target_value': targetValue,
    'sub_rounds': subRounds,
  };

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
    id: map['id'] as int?,
    category: ChallengeCategory.values.firstWhere(
      (c) => c.name == map['category'],
      orElse: () => ChallengeCategory.precision,
    ),
    type: ChallengeType.fromDb(map['type'] as String),
    text: map['text'] as String,
    emoji: map['emoji'] as String,
    difficulty: map['difficulty'] as int? ?? 1,
    targetValue: map['target_value'] as int?,
    subRounds: map['sub_rounds'] as int? ?? 1,
  );

  Challenge copyWith({
    String? text,
    String? emoji,
    int? targetValue,
    bool? isRoulette,
    bool? hasTimer,
    int? timerSeconds,
  }) =>
      Challenge(
        id: id,
        category: category,
        type: type,
        text: text ?? this.text,
        emoji: emoji ?? this.emoji,
        difficulty: difficulty,
        targetValue: targetValue ?? this.targetValue,
        subRounds: subRounds,
        isRoulette: isRoulette ?? this.isRoulette,
        hasTimer: hasTimer ?? this.hasTimer,
        timerSeconds: timerSeconds ?? this.timerSeconds,
      );

  @override
  String toString() => 'Challenge($category/$type: $text)';
}
