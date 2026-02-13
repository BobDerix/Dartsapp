import 'dart:math';
import '../models/chaos_card.dart';

class ChaosCardService {
  final _random = Random();

  /// How often a chaos card appears (every N rounds on average).
  static const _chaosInterval = 3;

  /// Minimum rounds before first chaos card.
  static const _minRoundsBeforeFirst = 2;

  int _roundsSinceLastCard = 0;

  void reset() {
    _roundsSinceLastCard = 0;
  }

  /// Check if a chaos card should appear this round.
  /// Returns a card or null.
  ChaosCard? maybeDrawCard({
    required int roundNumber,
    required bool isTwoPlayer,
  }) {
    // No chaos cards in single player
    if (!isTwoPlayer) return null;

    // Wait a few rounds before first card
    if (roundNumber <= _minRoundsBeforeFirst) return null;

    _roundsSinceLastCard++;

    // Increasing probability: starts at ~25% and grows
    final chance = _roundsSinceLastCard / (_chaosInterval * 2);
    if (_random.nextDouble() > chance) return null;

    _roundsSinceLastCard = 0;

    // Pick a random card
    const cards = ChaosCard.allCards;
    return cards[_random.nextInt(cards.length)];
  }

  /// Calculate points for a player based on active chaos card.
  /// Returns (hitPoints, missPoints) tuple.
  ({int hitPts, int missPts, int stealPts}) calculatePoints({
    required ChaosCard? activeCard,
    required bool isHit,
    required bool isBidWinner,
  }) {
    if (activeCard == null) {
      return (hitPts: isHit ? 1 : 0, missPts: 0, stealPts: 0);
    }

    switch (activeCard.type) {
      case ChaosCardType.doubleOrNothing:
        return (
          hitPts: isHit ? 2 : 0,
          missPts: isHit ? 0 : -1,
          stealPts: 0,
        );

      case ChaosCardType.steal:
        return (
          hitPts: isHit ? 1 : 0,
          missPts: 0,
          stealPts: isHit ? 1 : 0,
        );

      case ChaosCardType.blindfold:
        return (
          hitPts: isHit ? 3 : 0,
          missPts: 0,
          stealPts: 0,
        );

      case ChaosCardType.pressure:
        // Normal points, the pressure is psychological
        return (hitPts: isHit ? 1 : 0, missPts: 0, stealPts: 0);

      case ChaosCardType.allIn:
        return (
          hitPts: isHit ? 4 : 0,
          missPts: isHit ? 0 : -2,
          stealPts: 0,
        );

      case ChaosCardType.redemption:
        // Normal points, trailing player got to pick category
        return (hitPts: isHit ? 1 : 0, missPts: 0, stealPts: 0);
    }
  }
}
