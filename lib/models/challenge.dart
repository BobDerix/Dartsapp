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

  /// Check out a specific number. Success = 1 point.
  countdown,

  /// Multiple sub-rounds. Most hits out of N rounds = 1 point.
  elimination;

  String get dbValue => switch (this) {
    hitMiss => 'hit_miss',
    bestScore => 'best_score',
    closest => 'closest',
    threshold => 'threshold',
    countdown => 'countdown',
    elimination => 'elimination',
  };

  static ChallengeType fromDb(String value) => switch (value) {
    'hit_miss' => hitMiss,
    'best_score' => bestScore,
    'closest' => closest,
    'threshold' => threshold,
    'countdown' => countdown,
    'elimination' => elimination,
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
  final int? targetValue; // for threshold/countdown
  final int subRounds; // for elimination (default 3)

  const Challenge({
    this.id,
    required this.category,
    required this.type,
    required this.text,
    required this.emoji,
    this.difficulty = 1,
    this.targetValue,
    this.subRounds = 1,
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

  Challenge copyWith({String? text, String? emoji, int? targetValue}) =>
      Challenge(
        id: id,
        category: category,
        type: type,
        text: text ?? this.text,
        emoji: emoji ?? this.emoji,
        difficulty: difficulty,
        targetValue: targetValue ?? this.targetValue,
        subRounds: subRounds,
      );

  @override
  String toString() => 'Challenge($category/$type: $text)';
}
