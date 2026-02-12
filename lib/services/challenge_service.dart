import 'dart:math';
import '../models/challenge.dart';

class ChallengeService {
  final _random = Random();
  final List<int> _segments = List.generate(20, (i) => i + 1);

  // Bogey checkouts (impossible to finish)
  static const _bogeyCheckouts = {159, 162, 163, 165, 166, 168, 169};

  /// Master list of static challenges.
  final List<Challenge> _staticChallenges = const [
    // ── PRECISION (Hit/Miss) ──
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🐂', text: 'Hit Bull (25 or 50)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎯', text: 'Hit Double Bull (50)', difficulty: 5),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🔝', text: 'Hit Tops (Double 20)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '👇', text: 'Hit D3 (Bottom of the board)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🧱', text: 'Hit D14 (The Mensur)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🍜', text: 'Shanghai! (Single, Triple, Double of same number)', difficulty: 5),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '2️⃣', text: 'All 3 darts in EVEN numbers', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '1️⃣', text: 'All 3 darts in ODD numbers', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎪', text: 'Hit 3 different doubles', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🔺', text: 'Hit 3 different triples', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎨', text: 'Hit all 3 colours (red, green, white/black)', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🏠', text: 'All 3 darts in the same number', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🪜', text: 'Hit 3 consecutive numbers (e.g. 18-19-20)', difficulty: 3),

    // ── SCORING (Threshold) ──
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.threshold, emoji: '📈', text: 'Score 60+', targetValue: 60, difficulty: 2),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.threshold, emoji: '📈', text: 'Score 80+', targetValue: 80, difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.threshold, emoji: '📈', text: 'Score 100+', targetValue: 100, difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.threshold, emoji: '📈', text: 'Score 120+', targetValue: 120, difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.threshold, emoji: '📈', text: 'Score 140+', targetValue: 140, difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.threshold, emoji: '🔥', text: 'Score 180!', targetValue: 180, difficulty: 5),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🧱', text: 'No 1s or 5s allowed', difficulty: 2),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🚫', text: 'Score under 20 (low is hard!)', difficulty: 3),

    // ── SCORING (Best Score) ──
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.bestScore, emoji: '⚔️', text: 'Highest 3-dart score wins!', difficulty: 2),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.bestScore, emoji: '🏹', text: 'Trebles only: highest score wins!', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.bestScore, emoji: '🎰', text: 'Doubles only: highest score wins!', difficulty: 3),

    // ── FINISH (Countdown/Hit-Miss) ──
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🍺', text: 'Checkout 138 (Deller!)', targetValue: 138, difficulty: 5),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🐅', text: 'Checkout 156 (Barneveld!)', targetValue: 156, difficulty: 5),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🐟', text: 'Checkout 170 (Big Fish!)', targetValue: 170, difficulty: 5),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🎯', text: 'Checkout 32 (Double 16)', targetValue: 32, difficulty: 2),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🎯', text: 'Checkout 40 (Double 20)', targetValue: 40, difficulty: 2),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🏁', text: 'Checkout 80', targetValue: 80, difficulty: 3),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.countdown, emoji: '🏁', text: 'Checkout 100', targetValue: 100, difficulty: 4),

    // ── BATTLE (Closest / Judge) ──
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🎯', text: 'Closest to the Bull!', difficulty: 3),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🏹', text: 'Closest to Triple 20!', difficulty: 4),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🎪', text: 'Closest to Double 16!', difficulty: 3),

    // ── SPECIAL (Elimination) ──
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '💀', text: 'Hit any Double (3 lives)', subRounds: 3, difficulty: 3),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '💀', text: 'Hit any Triple (3 lives)', subRounds: 3, difficulty: 4),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '☠️', text: 'Hit the Bull (3 lives)', subRounds: 3, difficulty: 4),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '🫣', text: 'Hit any number > 10 (5 lives)', subRounds: 5, difficulty: 2),
  ];

  /// Generate a random checkout value, avoiding bogey numbers.
  int _randomCheckout() {
    int num;
    do {
      if (_random.nextDouble() > 0.7) {
        num = _random.nextInt(70) + 101; // 101-170
      } else {
        num = _random.nextInt(99) + 2; // 2-100
      }
    } while (_bogeyCheckouts.contains(num));
    return num;
  }

  /// Generate a challenge based on game settings.
  Challenge generate({
    required String focusArea,
    required bool isTwoPlayer,
    Challenge? lastChallenge,
  }) {
    // 15% chance of battle in 2P mode
    if (isTwoPlayer && _random.nextDouble() < 0.15) {
      return _pickBattle();
    }

    // 10% chance of elimination in 2P mode
    if (isTwoPlayer && _random.nextDouble() < 0.12) {
      return _pickElimination();
    }

    final pool = <Challenge>[];

    // Build pool based on focus area
    if (focusArea == 'all' || focusArea == 'scoring') {
      pool.addAll(_staticChallenges.where(
        (c) => c.category == ChallengeCategory.scoring,
      ));
      // Add dynamic scoring challenges
      final target = 20 + (_random.nextInt(13) * 10); // 20-140
      pool.add(Challenge(
        category: ChallengeCategory.scoring,
        type: ChallengeType.threshold,
        emoji: '💯',
        text: 'Score $target+',
        targetValue: target,
        difficulty: (target / 40).ceil().clamp(1, 5),
      ));
    }

    if (focusArea == 'all' || focusArea == 'doubles') {
      pool.addAll(_staticChallenges.where(
        (c) => c.category == ChallengeCategory.precision,
      ));
      // Add dynamic precision challenges
      final seg = _segments[_random.nextInt(_segments.length)];
      pool.add(Challenge(
        category: ChallengeCategory.precision,
        type: ChallengeType.hitMiss,
        emoji: '👀',
        text: 'Hit Double $seg',
        difficulty: 3,
      ));
      pool.add(Challenge(
        category: ChallengeCategory.precision,
        type: ChallengeType.hitMiss,
        emoji: '💥',
        text: 'Hit Triple $seg',
        difficulty: 4,
      ));
    }

    if (focusArea == 'all' || focusArea == 'checkouts') {
      pool.addAll(_staticChallenges.where(
        (c) => c.category == ChallengeCategory.finish,
      ));
      // Add dynamic checkout
      final co = _randomCheckout();
      pool.add(Challenge(
        category: ChallengeCategory.finish,
        type: ChallengeType.countdown,
        emoji: '🏁',
        text: 'Checkout $co',
        targetValue: co,
        difficulty: co > 100 ? 5 : co > 60 ? 4 : co > 30 ? 3 : 2,
      ));
    }

    if (pool.isEmpty) {
      // Fallback: use full pool
      pool.addAll(_staticChallenges);
    }

    // Filter out bestScore/closest challenges in single-player mode
    if (!isTwoPlayer) {
      pool.removeWhere(
        (c) => c.type == ChallengeType.bestScore || c.type == ChallengeType.closest,
      );
    }

    // Try to avoid repeating the last challenge
    if (lastChallenge != null && pool.length > 1) {
      pool.removeWhere((c) => c.text == lastChallenge.text);
    }

    return pool[_random.nextInt(pool.length)];
  }

  Challenge _pickBattle() {
    final battles = _staticChallenges.where(
      (c) => c.category == ChallengeCategory.battle,
    ).toList();
    // Add dynamic battle
    final seg = _segments[_random.nextInt(_segments.length)];
    battles.add(Challenge(
      category: ChallengeCategory.battle,
      type: ChallengeType.closest,
      emoji: '🏹',
      text: 'Closest to $seg!',
      difficulty: 3,
    ));
    return battles[_random.nextInt(battles.length)];
  }

  Challenge _pickElimination() {
    final elims = _staticChallenges.where(
      (c) => c.type == ChallengeType.elimination,
    ).toList();
    return elims[_random.nextInt(elims.length)];
  }

  /// Get a sudden-death challenge for tied games.
  Challenge suddenDeath() {
    return const Challenge(
      category: ChallengeCategory.battle,
      type: ChallengeType.closest,
      emoji: '💀',
      text: 'SUDDEN DEATH: Closest to Bull!',
      difficulty: 5,
    );
  }
}
