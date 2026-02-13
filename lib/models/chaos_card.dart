/// Chaos cards add unpredictable modifiers to challenges,
/// changing point values and adding special rules.
enum ChaosCardType {
  /// Hit = 2 points, Miss = -1 point.
  doubleOrNothing,

  /// If you hit, steal 1 point from your opponent.
  steal,

  /// 3 points if hit (themed as a blindfold / eyes-closed throw).
  blindfold,

  /// Opponent is allowed to distract you. Visual pressure effect.
  pressure,

  /// Both players wager 2 points. Winner takes all 4.
  allIn,

  /// Player with fewest points picks the next challenge category.
  redemption,
}

class ChaosCard {
  final ChaosCardType type;
  final String name;
  final String description;
  final String emoji;

  const ChaosCard({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
  });

  static const List<ChaosCard> allCards = [
    ChaosCard(
      type: ChaosCardType.doubleOrNothing,
      name: 'DOUBLE OR NOTHING',
      description: 'Hit = 2 points, Miss = LOSE 1 point!',
      emoji: '2x',
    ),
    ChaosCard(
      type: ChaosCardType.steal,
      name: 'STEAL',
      description: 'Hit this challenge and steal 1 point from your opponent!',
      emoji: '🏴‍☠️',
    ),
    ChaosCard(
      type: ChaosCardType.blindfold,
      name: 'BLINDFOLD',
      description: 'Close your eyes for 1 dart. Hit = 3 points!',
      emoji: '🙈',
    ),
    ChaosCard(
      type: ChaosCardType.pressure,
      name: 'PRESSURE',
      description: 'Your opponent may distract you while throwing!',
      emoji: '😤',
    ),
    ChaosCard(
      type: ChaosCardType.allIn,
      name: 'ALL IN',
      description: 'Both wager 2 points. Winner takes all!',
      emoji: '🃏',
    ),
    ChaosCard(
      type: ChaosCardType.redemption,
      name: 'REDEMPTION',
      description: 'Trailing player gets to pick the category!',
      emoji: '⚡',
    ),
  ];

  /// Apply chaos card point modifier for a hit.
  int hitPoints(ChaosCardType? activeCard) {
    return switch (type) {
      ChaosCardType.doubleOrNothing => 2,
      ChaosCardType.blindfold => 3,
      ChaosCardType.allIn => 4,
      _ => 1,
    };
  }

  /// Apply chaos card point modifier for a miss.
  int missPoints(ChaosCardType? activeCard) {
    return switch (type) {
      ChaosCardType.doubleOrNothing => -1,
      ChaosCardType.allIn => -2,
      _ => 0,
    };
  }
}
